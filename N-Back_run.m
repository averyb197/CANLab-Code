%Setting Up Psychtoolbox to run experiment, this is N-Back now
sca;
close all;
clear;
clc;

Screen('Preference', 'SkipSyncTests', 1);
screenNumber=max(Screen('Screens'));

%Define colors
text_color= [255 255 255];
bg_color= [0 0 0];
stimuli = 'AAABBBCCCDDDEEEFFFGG';
length_block = length(stimuli);
blocks = 1;
length_exp = length_block*blocks;

%how far back participant should remember;
x_back = 2;
n_back_target = '';

%Defining Screen Dimensions and font size
[windowPtr, rect] = Screen('OpenWindow', screenNumber, bg_color);
Screen('TextSize', windowPtr, 50);

%Restrict keys to A, L, or P
% targetKeys = [KbName('A'), KbName('L'), KbName('P')];
% RestrictKeysForKbCheck(targetKeys);
responses=zeros(1, length_exp);

%Text with Instructions
DrawFormattedText(windowPtr, 'hi this is test', 'center', 'center', text_color);
Screen('Flip', windowPtr);
KbWait();
WaitSecs(0.5);

%Crosshair pause time
DrawFormattedText(windowPtr, '+', 'center', 'center', text_color);
Screen('Flip', windowPtr);
WaitSecs(5);

%Creating and Pasting a Sequence of 10 random sets of 4 letters
for i= 1:blocks
    prev_block1=stimuli(length_block-1);
    prev_block2=stimuli(length_block);

    for j= 1:length_block
        idx=j+((i-1)*50);
        %Generate Sequence of Letters
        letter=stimuli(j);
        
        if idx > 2
            if j==1
                n_back_target = prev_block1;
            elseif j==2
                n_back_target = prev_block2;
            else
                 n_back_target = stimuli(j-2);
            end
        end

        DrawFormattedText(windowPtr, letter, 'center', 'center', text_color);
        Screen('Flip', windowPtr);
        WaitSecs(0.5);  
        
        %Crosshair pause time
        DrawFormattedText(windowPtr, '+', 'center', 'center', text_color);
        Screen('Flip', windowPtr);
        WaitSecs(0.5);

        %Prompt for response
        DrawFormattedText(windowPtr, 'Did you see the same letter 2 letters ago?', 'center', 'center', text_color);
        Screen('Flip', windowPtr);
        [secs, keys]=KbWait();
        responses(idx)=find(keys);
        KbReleaseWait;
    end 
   
end
%a=65, l=76

sca;