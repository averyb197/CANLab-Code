%=======================================================================
% Stim set code adapted from: https://arxiv.org/abs/1911.09071 
% code: https://github.com/katherine-h/navon
%========================================================================



%======================  
% Navon Task
%=====================

sca;
clear all; close all; clc;
addpath(genpath('lib'));
addpath('config');

params = config_params();

AssertOpenGL;
KbName('UnifyKeyNames');
HideCursor;
ListenChar(2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%BIG FUCKING PROBLEM:
%Windows 11 does really dumb things with how it handles windows that makes
%it possibly impossible to time reactions rigorously
%psych toolbox keeps failing to be able to actually launch because its
%refresh rate timing tests (so it knows how to handle timing of showing
%stim and such) are failing. Windows 11 is ultimately the problem and there
%is no way to directly solve it, but there are other things we can do that
%will make it work, but are not direct fixes. 
%THIS IS A SERIOUS PROBLEM THAT NEEDS TO BE DEEPLY INVESTIGATED AND
%VALIDATED BEFORE ANY DATA IS COLLECTED
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Setup screen
% Get list of stimuli and trials
%stimList = dir(fullfile(params.stimDir, '*_*-*.png'));
trialStruct = generate_trial_sequence(params);
disp(trialStruct)

[window, windowRect, black, white] = open_ptb_window(params);
% Draw instruction text (centered)
Screen('Preference', 'SkipSyncTests', 1); % <=== WILL PUT A BANDAID ON THE PROBLEM BUT IS NOT GOOD ENOUGH
Screen('TextSize', window, 24);
Screen('TextFont', window, 'Arial');
instruction = 'This is the Navon Task.\n\n[Im not going to tell you how the task works (its a secret) ]\n\nPress any key to begin.';
DrawFormattedText(window, instruction, 'center', 'center', black);
Screen('Flip', window);
KbPressWait;

%% Trial Loop
results = [];
for t = 1:length(trialStruct)
     %use {} to index trialStruct because it is a cell struct array not
     %just struct, use () for structs
    trial = trialStruct{t};

    % Show fixation
    DrawFormattedText(window, '+', 'center', 'center', black);
    Screen('Flip', window);
    WaitSecs(params.fixationDuration);

    % Draw stimulus
    
    onset = draw_stim(window, trial.imagePath);

    % Get response
    [keyCode, rt, responded] = waitForYesNo(params, onset);

    % Determine correctness
    correct = -1; % not applicable if no response
    if responded
        if keyCode == params.responseKeys.yes
            correct = trial.hasTarget;
        elseif keyCode == params.responseKeys.no
            correct = ~trial.hasTarget;
        end
    end

    % Log
    results(t).trial = t;
    results(t).stimFile = trial.filename;
    results(t).shapeLetter = trial.shapeLetter;
    results(t).fillLetter = trial.fillLetter;
    results(t).hasTarget = trial.hasTarget;
    results(t).responseKey = KbName(find(keyCode));
    results(t).rt = rt;
    results(t).correct = correct;

    % ITI
    Screen('Flip', window);
    WaitSecs(params.ITI);
end

% Thank you screen
DrawFormattedText(window, 'Thank you for participating!\n\nPress any key to exit.', 'center', 'center', black);
Screen('Flip', window);
KbPressWait;

% Save and close
sca;
ListenChar(0);
ShowCursor;

if ~exist('results', 'dir'); mkdir('results'); end
save(fullfile('results', ['navon_' datestr(now,'yyyymmdd_HHMMSS') '.mat']), 'results', 'params');




