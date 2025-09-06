function [results, params] = runTwoBackPTB(params)
% runTwoBackPTB — A clean, timing-accurate 2-back (n=2) task in Psychtoolbox.
%
% Usage:
% [results, params] = runTwoBackPTB(); % use defaults
% [results, params] = runTwoBackPTB(customParams); % override any field in params
%
% Core features:
% • Single-key target detection (press to indicate "match"). No response = non-target.
% • Accurate frame-locked timing with Screen('Flip').
% • Spatial fixation jitter (optional) and temporal ISI jitter (optional).
% • Block structure with practice + main blocks, with per-block target rate control.
% • Robust keyboard handling with KbQueue. ESC to abort safely.
% • Saves trial-by-trial CSV and summary.
%
% Tested with Psychtoolbox-3 on MATLAB. Adjust fonts/sizes for your display.
%
% ---------------------------------------------------------------
% LICENSE: Public domain / CC0. No warranty. Use at your own risk.
% ---------------------------------------------------------------


try
 %% ----------------------- Defaults -----------------------
    if nargin < 1 || isempty(params), params = struct(); end


    % General
    params.debug = getdef(params, 'debug', false); % if true, small window
    params.bgColor = getdef(params, 'bgColor', [0 0 0]);
    params.textColor = getdef(params, 'textColor', [255 255 255]);
    params.screenNumber = getdef(params, 'screenNumber', max(Screen('Screens')));
    params.fontName = getdef(params, 'fontName', 'Arial');
    params.fontSize = getdef(params, 'fontSize', 60);
    params.fixationSize = getdef(params, 'fixationSize', 12); % pixels (half-length of bar)


    % Task design
    params.nBack = getdef(params, 'nBack', 2); % fixed to 2 but kept flexible
    params.stimSet = getdef(params, 'stimSet', char('A':'Z')); % letters A–Z
    params.excludeLetters = getdef(params, 'excludeLetters', ['I','O']); % avoid confusables
    params.blocks = getdef(params, 'blocks', 3); % main blocks
    params.trialsPerBlock = getdef(params, 'trialsPerBlock', 40);
    params.targetRate = getdef(params, 'targetRate', 0.25); % proportion targets per block
    params.minLagSpacing = getdef(params, 'minLagSpacing', 0); % 0 = allow back-to-back targets


    % Timing (seconds)
    params.stimDur = getdef(params, 'stimDur', 0.5); % on-screen time per stimulus
    params.isiMean = getdef(params, 'isiMean', 1.0); % mean ISI
    params.isiJitter = getdef(params, 'isiJitter', 0.3); % uniform jitter ± around mean
    params.preBlockFix = getdef(params, 'preBlockFix', 1.0);
    params.postBlockFix = getdef(params, 'postBlockFix', 0.5);


    % Fixation jitter (spatial)
    params.fixJitterPx = getdef(params, 'fixJitterPx', 0); % e.g., 5–10 px recommended


    % Input & responses
    params.responseKey = getdef(params, 'responseKey', 'space'); % press for TARGET
    params.quitKey = getdef(params, 'quitKey', 'ESCAPE');
    params.deviceIndex = getdef(params, 'deviceIndex', []); % keyboard device for KbQueue
    params.requireHold = getdef(params, 'requireHold', false); % if true, registers first keydown only
    params.feedbackPractice = getdef(params, 'feedbackPractice', true);


    % Practice block
    params.includePractice = getdef(params, 'includePractice', true);
    params.practiceTrials = getdef(params, 'practiceTrials', 24);
    params.practiceTargetRate= getdef(params, 'practiceTargetRate', 0.25);



    % Output
    params.outDir = getdef(params, 'outDir', fullfile(pwd,'nback_output'));
    params.subject = getdef(params, 'subject', datestr(now,'yyyymmdd_HHMMSS'));


    % Random seed
    rng('shuffle');


    %% ----------------------- Screen setup -----------------------
    PsychDefaultSetup(2);
    KbName('UnifyKeyNames');


    if params.debug
    PsychDebugWindowConfiguration([0 0 0], 0.5);
    end


    [win, winRect] = Screen('OpenWindow', params.screenNumber, params.bgColor);
    Priority(MaxPriority(win));


    % Text/alpha settings
    Screen('TextFont', win, params.fontName);
    Screen('TextSize', win, params.fontSize);
    Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);


    [cx, cy] = RectCenter(winRect);


    % Response keys
    keyTarget = KbName(params.responseKey);
    keyQuit = KbName(params.quitKey);


    % Prepare KbQueue
    KbQueueCreate(params.deviceIndex);
    KbQueueStart;


    % Stimulus set
    letters = setdiff(cellstr(params.stimSet.'), cellstr(params.excludeLetters.')); % cellstr of single chars


    % Ensure output dir
    if ~exist(params.outDir, 'dir'), mkdir(params.outDir); end


    %% ----------------------- Instructions -----------------------
    DrawFormattedText(win, '2-BACK TASK\n\nPress the key if the CURRENT letter matches the letter from TWO trials ago.\n\nRespond only to matches.\n\n(Press any key to begin practice)', 'center', 'center', params.textColor);
    Screen('Flip', win);
    KbStrokeWait;


    %% ----------------------- Practice (optional) -----------------------
    results = [];
    blockIndex = 0;
    if params.includePractice
        blockIndex = blockIndex + 1;
        thisBlock = makeBlock(params.practiceTrials, params.nBack, params.practiceTargetRate, letters, params.minLagSpacing);
        blkRes = runBlock(win, cx, cy, params, thisBlock, keyTarget, keyQuit, true);
        results = [results; blkRes]; %#ok<AGROW>
        showBlockFeedback(win, blkRes, 'Practice complete.');
    end


%% ----------------------- Main blocks -----------------------
    for b = 1:params.blocks
        blockIndex = blockIndex + 1;
        thisBlock = makeBlock(params.trialsPerBlock, params.nBack, params.targetRate, letters, params.minLagSpacing);


        msg = sprintf('Block %d of %d\n\nPress a key to start.', b, params.blocks);
        DrawFormattedText(win, msg, 'center', 'center', params.textColor);
        Screen('Flip', win);
        KbStrokeWait;


        blkRes = runBlock(win, cx, cy, params, thisBlock, keyTarget, keyQuit, false);
        blkRes.Block = repmat(b, height(blkRes), 1);
        results = [results; blkRes]; %#ok<AGROW>


        showBlockFeedback(win, blkRes, sprintf('Block %d complete.', b));
    end


    %% ----------------------- Save & summary -----------------------
    T = struct2table(results);
    % Compute summary metrics
    [summary, summaryStr] = computeSummary(T, params);


    % Save files
    ts = datestr(now,'yyyymmdd_HHMMSS');
    csvFile = fullfile(params.outDir, sprintf('nback_%s_%s_trials.csv', params.subject, ts));
    sumFile = fullfile(params.outDir, sprintf('nback_%s_%s_summary.txt', params.subject, ts));
    writetable(T, csvFile);
    fid = fopen(sumFile, 'w'); fprintf(fid, '%s', summaryStr); fclose(fid);


    % Goodbye
    DrawFormattedText(win, 'All done! Thank you.', 'center', 'center', params.textColor);
    Screen('Flip', win); WaitSecs(1.0);


    % Return
    params.savedCsv = csvFile; params.savedSummary = sumFile; params.table = T; params.summary = summary;


    catch ME
    sca; ListenChar(0);
    rethrow(ME)
end


sca; ListenChar(0);
   



sca; ListenChar(0);


end % function