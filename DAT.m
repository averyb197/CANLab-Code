%Need to fix entering infols

%Setting Up Psychtoolbox to run experiment    
sca;
close all;
clear;
clc;
PsychDefaultSetup(1);

Screen('Preference', 'SkipSyncTests', 1);-

screenNumber=max(Screen('Screens'));

%Defining Colors and screen window variable
text_color = [255 255 255];
bg_color = [0 0 0];
[windowPtr, rect] = Screen('OpenWindow', screenNumber, bg_color);
[xCenter, yCenter] = RectCenter(rect);
Screen('TextSize',windowPtr, 50);

%Preparing Response Matrix, task info, and word prompt
responses=strings(1, 10);
task_info= ['In this task, you will be asked \n' ...
    'to list a series of 10 words that you think\n' ...
    'are not related to one another\n' ...
    'please use only single words\n' ...
    'and refrain from using proper nounse\n' ...
    'press any key to continue'];
prompt='Enter word: ';
current_prompt='Current Words: ';

DrawFormattedText(windowPtr, task_info, 'center', 'center', text_color);
Screen('Flip', windowPtr);

KbWait();
WaitSecs(0.5);

%Response loop
for i=1:10
    %Show Current Responses
    combine_resp=char(strjoin(responses, ' '));
    current_resp = [current_prompt combine_resp];

    DrawFormattedText(windowPtr, current_resp, 10, rect(4)*0.10, text_color);
    typedText = GetEchoString(windowPtr,prompt, xCenter-325, rect(4)/2, text_color);
    Screen('Flip', windowPtr);
    responses(i)=typedText;
    KbReleaseWait;
    WaitSecs(0.5);
end

sca

