l%Setting Up Psychtoolbox to run experiment    
sca;
close all;
clear;
clc;

Screen('Preference', 'SkipSyncTests', 0);
screenNumber=max(Screen('Screens'));

%Gathering Demographic info (need to figure otu what we want to store, all going to eventually go into a combined code line)
%ID=input('Enter Participant ID: ','s');

%Define colors and stimulus list
white = [255 255 255];
black = [0 0 0];

stimuli =char(readcell('CPT_List.xlsx'));
length_stim=length(stimuli);
randIdx = randperm(length_stim, length_stim);
responses = zeros(1, length_stim);
response_time = zeros(1, length_stim);
response_check = zeros(1, length_stim);

%Response Variables for Mind Wandering Probes
frequency = 50;
amt_probe = length_stim/frequency;
probe_response = zeros(1, amt_probe);
probe_index = 1;
prompt = ['On a Scale from 1-10, how focused were you on the task? \n' ...
    '(5 very focused, 1 unfocused):'];

%Defining time limit
timeout = 0.75;

%Defining Screen Dimensions and font size
w=Screen('OpenWindow', screenNumber, black);
Screen('TextSize',w, 50);

DrawFormattedText(w, ['Press Space if Letter shown is not X\n' ...
    'Every 50 Trials, a mind wandering probe will be presented\n' ...
    'For these probes, please answer on a  scale of 1-5\n' ...
    'how focused you were on the task\n' ...
    '(5: very focused, 1: not focused at all)\n' ...
    'Press any key to continue' ...
    ''], 'center', 'center', white);
Screen('Flip', w);
KbWait();
WaitSecs(0.5);


for i=1:length(randIdx)

    %Defining time window and key press to collect data
    startTime = GetSecs;
    deadline = startTime + timeout;
    keyPressed = NaN;
    timePressed = NaN;

    %Defining blank Text Response
    typedText = '';

    %Present letter to participant for 1 second
    letter = stimuli(randIdx(i));
    isTarget = false; 
    if letter=='X'
        isTarget=true;
    end
    DrawFormattedText(w, letter, 'center', 'center', white);
    Screen('Flip', w);

    %Waiting for a response, deadline set to two seconds
    %logs time of response and sets special value if response
    while GetSecs < deadline
        [keyIsDown, pressTime, keyCode] = KbCheck;
        if keyIsDown
            keyPressed = find(keyCode);
            timePressed = pressTime - startTime;
        end
    end

    %Logging results in repsonses
    if isnan(keyPressed)
        responses(i) = 0;
        response_time(i) = timeout;
    else
        responses(i) = keyPressed;
        response_time(i) = timePressed;
    end

    %Check for correct answer
    if responses(i)==0 && isTarget
        response_check(i)=1;
    elseif responses(i)~=0 && ~isTarget
        response_check(i)=1;
    else   
        response_check(i)=0;
    end

    WaitSecs(0.5);  

    i_mod=mod(i, frequency);
    if i_mod==0
        while true
            % Combine prompt and typed text
            fullLine = [prompt typedText];

            % Draw the combined line
            DrawFormattedText(w, fullLine, 'center', 'center', [255 255 255]);

            % Show it
            Screen('Flip', w);

            % Check keyboard
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyIsDown
                keyName = KbName(keyCode);

                % If multiple keys pressed, take first
                if iscell(keyName)
                    keyName = keyName{1};
                end

                % Handle Enter = finish input
                if strcmpi(keyName, 'Return')
                    break;

                % Handle Backspace = delete last digit
                elseif strcmpi(keyName, 'BackSpace') && ~isempty(typedText)
                    typedText(end) = [];

                % Handle top row numbers, numpad numbers, or shifted symbols like '1!' 
                elseif ~isempty(regexp(keyName, '^\d', 'once')) || ...        % starts with digit
                    ~isempty(regexp(keyName, '^numpad\d$', 'once'))        % numpad

                    % Extract just the first digit
                    digit = regexp(keyName, '\d', 'match');
                    typedText = [typedText digit{1}];
                end

                KbReleaseWait; % Prevent repeats
            end
        end
        probe_response(1, probe_index)=str2double(typedText);
        probe_index = probe_index + 1;
        WaitSecs(0.5);
    end

    %Crosshair delay of 1 second
    DrawFormattedText(w, '+', 'center', 'center', white);
    Screen('Flip', w);
    WaitSecs(1);

end
sca