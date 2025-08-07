%Setting Up Psychtoolbox to run experimentl
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
randIdx = randperm(150, 3);
responses = zeros(1, length(randIdx));
response_time = zeros(1, length(randIdx));
response_check = zeros(1, length(randIdx));

%Defining time limit
timeout = 1;

%Defining Screen Dimensions and font size
w=Screen('OpenWindow', screenNumber, black);
Screen('TextSize',w, 50);

DrawFormattedText(w, 'Press Space if Letter shown is not X', 'center', 'center', white);
Screen('Flip', w);
KbWait();
WaitSecs(0.5);


for i=1:length(randIdx)

    %Defining time window and key press to collect data
    startTime = GetSecs;
    deadline = startTime + timeout;
    keyPressed = NaN;
    timePressed = NaN;

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

    %Crosshair delay of 1 second
    DrawFormattedText(w, '+', 'center', 'center', white);
    Screen('Flip', w);
    WaitSecs(1);

end
sca