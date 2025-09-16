%Setting Up Psychtoolbox to run experiment    
sca;
close all;
clear;
rng("default");
clc;

Screen('Preference', 'SkipSyncTests', 1);
screenNumber=max(Screen('Screens'));

%Gathering Demographic info (need to figure otu what we want to store, all going to eventually go into a combined code line)
%ID=input('Enter Participant ID: ','s');

%Define colors and stimulus list
text_color = [255 255 255];
black = [0 0 0];

stimuli =char(readcell('CPT_List.xlsx'));
blocks=3;
length_block=length(stimuli);
length_exp=length_block*blocks;
stim_target = zeros(length_exp, 1);
responses = zeros(length_exp, 1);
response_time = zeros(length_exp, 1);
response_check = zeros(length_exp, 1);
stim_is_target = zeros(length_exp, 1);
letters_exp = strings(length_exp, 1);

%Response Variables for Mind Wandering Probes
amt_probe = blocks;
probe_response = zeros(length_exp, 1);
prompt1 = 'On a Scale from 1-5, how focused were you on the task?';
prompt2 = '(5 very focused, 1 unfocused):';

%Defining time limit
timeout = 0.75;

%Defining Screen Dimensions and font size
[w, winRect] = Screen('OpenWindow', screenNumber, black);
[xCenter, yCenter] = RectCenter(winRect);
Screen('TextSize',w, 50);

DrawFormattedText(w, ['Press Space if Letter shown is not X\n' ...
    'Every 50 Trials, a mind wandering probe will be presented\n' ...
    'For these probes, please answer on a  scale of 1-5\n' ...
    'how focused you were on the task\n' ...
    '(5: very focused, 1: not focused at all)\n' ...
    'Press any key to continue' ...
    ''], 'center', 'center', text_color);
Screen('Flip', w);
KbWait();
WaitSecs(0.5);

for j=1:blocks
    randIdx = randperm(length_block, length_block);
    for i=1:length(randIdx)
        %Crosshair delay of 1 second
        DrawFormattedText(w, '+', 'center', 'center', text_color);
        Screen('Flip', w);
        WaitSecs(1);

        %Defining time window and key press to collect data
        startTime = GetSecs;
        deadline = startTime + timeout;
        keyPressed = NaN;
        timePressed = NaN;

        %Defining letter, and target values
        idx=i+((j-1)*50);
        letter = stimuli(randIdx(i));
        letters_exp(idx) = letter;
        isTarget = false; 

        %Check if letter is target
        if letter=='X'
            isTarget=true;   
        end
        stim_is_target(idx)=isTarget;

        %Present Stimuli
        DrawFormattedText(w, letter, 'center', 'center', text_color);
        Screen('Flip', w);

        %Waiting for a response, deadline set to 750 ms
        while GetSecs < deadline
            [keyIsDown, pressTime, keyCode] = KbCheck;
            if keyIsDown
                keyPressed = find(keyCode);
                timePressed = pressTime - startTime;
            end
        end

        %Logging results in repsonses
        if isnan(keyPressed)
            responses(idx) = 0;
            response_time(idx) = timeout;
        else
            responses(idx) = keyPressed;
            response_time(idx) = timePressed;
        end

        %Check for correct answer
        if responses(idx)==0 && isTarget
            response_check(idx)=1;
        elseif responses(idx)~=0 && ~isTarget
            response_check(idx)=1;
        else   
            response_check(idx)=0;
        end
    end

    WaitSecs(0.5); 
    DrawFormattedText(w, prompt1, 'center', 'center', text_color);
    typedText= GetEchoString(w,prompt2, xCenter-325, winRect(4)*0.55, text_color, black, [], 100);
    Screen('Flip', w);
    probe_response(j, 1)=str2double(typedText);
    WaitSecs(0.5);
  

    %Crosshair delay of 1 second
    DrawFormattedText(w, '+', 'center', 'center', text_color);
    Screen('Flip', w);
    WaitSecs(1);
end

final_table = table(responses, letters_exp, stim_is_target, response_check, response_time, probe_response);

sca
