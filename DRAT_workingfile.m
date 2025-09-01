%Setting Up Psychtoolbox to run experiment
sca;
close all;
clear;
clc;

Screen('Preference', 'SkipSyncTests', 1);
screenNumber=max(Screen('Screens'));

%Define colors
white= [255 255 255];
black= [0 0 0];
alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

%Gathering Demographic info (need to figure otu what we want to store, all going to eventually go into a combined code line)
%ID=input('Enter Participant ID: ','s');

%Defining Screen Dimensions and font size
w=Screen('OpenWindow', screenNumber, black);
Screen('TextSize',w, 50);

%Restrict keys to A, L, or P
% targetKeys = [KbName('A'), KbName('L'), KbName('P')];
% RestrictKeysForKbCheck(targetKeys);
responses=zeros(1, 75);

%Text with Instructions
DrawFormattedText(w, 'hi this is test', 'center', 'center', white);
Screen('Flip', w);
KbWait();
WaitSecs(0.5);

%Creating and Pasting a Sequence of 10 random sets of 4 letters
for i= 1:15   

    %Generate Sequence of Letters
    randIdx = randperm(length(alphabet), 4);
    rand_letters = alphabet(randIdx);
    DrawFormattedText(w, rand_letters, 'center', 'center', white);
    Screen('Flip', w);
    WaitSecs(3);

    %Crosshair pause time
    DrawFormattedText(w, '+', 'center', 'center', white);
    Screen('Flip', w);
    WaitSecs(5);

    % for j=1:5
    %     %Stimuli of position and letter, as for response (A, L, P)
    %     DrawFormattedText(w, ['3\n' ...
    %         'L'], 'center', 'center', white);
    %     Screen('Flip', w);
    %     [secs, keys]=KbWait();
    %     responses(i)=find(keys);
    %     WaitSecs(0.5);
    % 
    %     %Crosshair pause time
    %     DrawFormattedText(w, '+', 'center', 'center', white);
    %     Screen('Flip', w);
    %     WaitSecs(0.5);
    % end
end


sca;