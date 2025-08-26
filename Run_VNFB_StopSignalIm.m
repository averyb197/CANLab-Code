function FullTableSS = Run_VNFB_StopSignalIm(task_or_prac, windowPtr, folder, ID, textColor, bgColor, block, sessiontable, rect)
    % Stop-Signal Task in MATLAB using Psychtoolbox
    exit = 0;

    % Set screen parameters
    [mx, my] = RectCenter(rect); % Center coordinates
    textSize = 50;
    Screen('TextSize', windowPtr, textSize);

    % Load arrow images and create textures
    rightArrow = Screen('MakeTexture', windowPtr, imread('right_arrow.jpg'));
    leftArrow = Screen('MakeTexture', windowPtr, imread('left_arrow.jpg'));
    redArrowRight = Screen('MakeTexture', windowPtr, imread('red_arrow_right.jpg'));
    redArrowLeft = Screen('MakeTexture', windowPtr, imread('red_arrow_left.jpg'));

    % Define arrow size (adjust as needed)
    arrowWidth = 150;  % Width of the arrow in pixels
    arrowHeight = 150;  % Height of the arrow in pixels

    % Task parameters
    stopSignalDelay = 150;           % Initial stop-signal delay (ms)
    stopSignalStep = 16;             % Staircase adjustment (ms)
    minSSD = 20; maxSSD = 380;       % Min and max stop-signal delay (ms)

    % Select stimuli based on task/practice mode
    if task_or_prac == 0
        stimuli = transpose(sessiontable{block+1, 50:69}); % Practice (20 trials)
    else
        stimuli = transpose(sessiontable{block+1, 50:149}); % Full task (100 trials)
    end

    % Timing parameters
    stimDuration = 0.4;              % Stimulus duration (s)
    interTrialMin = 1.0;             % Minimum ITI (s)
    interTrialMax = 1.2;             % Maximum ITI (s)

    % Keys
    leftKey = KbName('LeftArrow');
    rightKey = KbName('RightArrow');
    exitKey = KbName('ESCAPE');

    % Initialize variables
    results = struct('trialType', [], 'response', [], 'RT', [], 'SSD', [], 'success', []);

    HideCursor;

    % Instructions
    instructions = [
        'In this task, you will see an arrow pointing either to the left or to the right on each trial.\n ', ...
        'Your job is to respond as quickly and accurately as possible by pressing the left arrow key if \n', ...
        'the arrow points left and the right arrow key if the arrow points right.\n\n', ...
        'On some trials, the arrow will turn red after a very short delay. \n', ...
        'When this happens, it means you should STOP yourself from pressing any key.\n ', ...
        ['Try to completely inhibit your response when you see the red arrow. \n\n ', ...
        'If the arrow remains white, respond as fast as you can,\n but try not to make mistakes\n\n'], ...
        'Press any key when you are ready to begin.'];

    Screen('TextSize', windowPtr, 30); % Set instructions text size
    DrawFormattedText(windowPtr, instructions, 'center', 'center', textColor, [], [], [], 1.5);
    Screen('Flip', windowPtr);
    KbWait;

    Screen('TextSize', windowPtr, textSize); % Reset to fixation text size

    Screen('FillRect', windowPtr, bgColor);
    Screen('Flip', windowPtr);

    lib = lsl_loadlib();      
    info = lsl_streaminfo(lib,'MyMarkerStream','Markers',1,0,'cf_string');
    outlet = lsl_outlet(info);
    pause(5);


     % Start connection for recording
     lr = tcpip('localhost', 22345);
     fopen(lr);
     fprintf(lr, 'select all');
     fprintf(lr, "update");
     if task_or_prac == 0
         fprintf(lr, ['filename {root:C:\Users\canla\Documents\NFB_volatility\Data\VNFB_data\raw}' ...
                     '{task:', char('SSPrac'), '} ' ...
                     '{template:%p_%s_%b_%n.xdf} ' ...
                     '{run:', num2str(block), '}' ...
                     '{participant:', num2str(ID), '}' ...
                     '{session:', num2str(sessiontable.Session(1)), '}' ...
                     '{modality:eeg}']);
     else
                  fprintf(lr, ['filename {root: C:\Users\canla\Documents\NFB_volatility\Data\VNFB_data\raw}' ...
                     '{task:', char('SS'), '} ' ...
                     '{template:%p_%s_%b_%n.xdf} ' ...
                     '{run:', num2str(block), '}' ...
                     '{participant:', num2str(ID), '}' ...
                     '{session:', num2str(sessiontable.Session(1)), '}' ...
                     '{modality:eeg}']);
     end
     
     fprintf(lr, 'start');
    pause(2);

    % Trial loop
    for t = 1:length(stimuli)
        isStopTrial = stimuli(t); % 1 = Stop trial, 0 = Go trial

        % Randomly choose arrow direction
        if rand < 0.5
            arrowTexture = leftArrow;
            stopArrowTexture = redArrowLeft;
            correctKey = leftKey;
        else
            arrowTexture = rightArrow;
            stopArrowTexture = redArrowRight;
            correctKey = rightKey;
        end

        % Compute the destination rectangle slightly below the fixation cross
        offset = 20; % Pixels to move the arrow downward
        destRect = [mx - arrowWidth/2, my - arrowHeight/2 + offset, mx + arrowWidth/2, my + arrowHeight/2 + offset];

        % Present fixation cross
        DrawFormattedText(windowPtr, '+', 'center', 'center', textColor);
        Screen('Flip', windowPtr);
        WaitSecs(0.5);

        % Present go signal
        goStartTime = GetSecs;
        stopSignalOnset = goStartTime + stopSignalDelay / 1000;

        % Initialize response variables
        responded = false;
        rt = NaN;

        % Display loop for the arrow
        while GetSecs - goStartTime < stimDuration
            % Draw the go signal arrow
            Screen('DrawTexture', windowPtr, arrowTexture, [], destRect);

            % Overlay the stop signal if it's a stop trial
            if isStopTrial && GetSecs >= stopSignalOnset
                Screen('DrawTexture', windowPtr, stopArrowTexture, [], destRect);
            end

            % Update the screen
            Screen('Flip', windowPtr);

            % Check for keypresses
            [keyIsDown, keyTime, keyCode] = KbCheck;
            if keyIsDown && ~responded
                responded = true;
                rt = keyTime - goStartTime;
                responseKey = find(keyCode, 1);
            end
        end

        results(t).SSD = stopSignalDelay;

        if isStopTrial
            if ~responded
                success = 1;
                stopSignalDelay = min(stopSignalDelay + stopSignalStep, maxSSD);
            else
                success = 0;
                stopSignalDelay = max(stopSignalDelay - stopSignalStep, minSSD);
            end
        else
            if responded && responseKey == correctKey
                success = 1;
            else
                success = 0;
            end
        end

        results(t).trialType = isStopTrial;
        results(t).response = responded;
        results(t).RT = rt;
        results(t).success = success;

        Screen('FillRect', windowPtr, bgColor);
        Screen('Flip', windowPtr);
        WaitSecs(interTrialMin + (interTrialMax - interTrialMin) * rand);

        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown && keyCode(exitKey)
            exit = 1;
            break;
        end
    end

    DrawFormattedText(windowPtr, 'Task complete. Thank you!', 'center', 'center', textColor);
    Screen('Flip', windowPtr);
    WaitSecs(1);

    fprintf(lr, 'stop');
    if exit == 1
        Screen('CloseAll');
          % Stop recording
        
    else
        trialNumbers = (1:length(stimuli))';
        stopSignals = [results.trialType]';
        reactionTimes = [results.RT]';
        correctResponses = [results.success]';
        stopSignalDelays = [results.SSD]';

        FullTableSS = table(trialNumbers, stopSignals, reactionTimes, correctResponses, stopSignalDelays, ...
            'VariableNames', {'TrialNumber', 'StopSignal', 'ReactionTime', 'Correct', 'StopSignalDelay'});
    end

    % Close textures
    Screen('Close', rightArrow);
    Screen('Close', leftArrow);
    Screen('Close', redArrowRight);
    Screen('Close', redArrowLeft);
end


