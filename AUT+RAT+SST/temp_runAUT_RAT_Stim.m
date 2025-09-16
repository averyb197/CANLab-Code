%Below is a template code to run all of the RAT and AUT tasks while a stim
%table is being worked on. Each function is still missing a folder to store
%the data, which will be added and changed in the future
%time data is not correct on final tables


Screen('Preference', 'SkipSyncTests', 1);
textColor = [0 0 0];
bgColor = [255 255 255];
CountNFB=0;

%Read Stim table
folder = fileparts(which(['Run_NFB_volatility.m']));
StimOrderTable=readtable([folder,filesep,'FullNFBTable_volatility.xls'],"FileType","spreadsheet","ReadVariableNames",true);
StimOrderTable.Trial = categorical(StimOrderTable.Trial);

answer = strings(3,1);
answer(1,1) = input('Enter participants ID(40??): ','s');
if str2num(answer(1,1))-4000<0
    answer(1,1) = input('Enter participants ID(30??): ','s');
end
answer(2,1) = input('Did it crash?(yes,no) ','s');
if strcmp(answer(2,1),'yes')
    CountNFB = input('What was the last NFB trial you completed? (0=Prac,1-2=NFB: ');
end

answer(3,1) = input('What session number? (e.g. 1 = Day 1, 2 = Day 2, 3 = Day 3): ', 's');
session = str2num(answer(3,1));


task_run = input(['What Task Would you like to run?\n' ...
    '1: AUT Practice\n' ...
    '2: AUT Full\n' ...
    '3: RAT Practice\n' ...
    '4: RAT Full\n' ...
    '5: Stop Signal\n' ...
    'Enter Number: ']);

ID = answer(1,1);
id = ID;
idx = StimOrderTable.SN == str2num(ID);
shorttable = StimOrderTable(idx,:);

sessionIndices = shorttable.Session == session;
sessiontable = shorttable(sessionIndices, :);

selectedCondition = sessiontable.Condition{1};

% Convert the session number input to a character vector
sessionNum = char(answer(3,1));

block = CountNFB+1;

[windowPtr,rect]=Screen('OpenWindow',0,[],[]);
%AUT works, AUT prac works, RAT prac works,
if task_run == 1
    Run_VNFBAUT_Practice(windowPtr,ID,textColor,bgColor,block, sessiontable, rect);
elseif task_run == 2
    Run_VNFBAUT_Task(windowPtr, ID, textColor, bgColor, block, sessiontable, rect);
elseif task_run == 3
    Run_VNFB_RAT_Practice(windowPtr, ID, textColor, bgColor, block, sessiontable, rect);
elseif task_run == 4
    Run_NFB_RAT_Task(windowPtr, ID, textColor, bgColor, block, sessiontable, rect);
elseif task_run == 5
    while true
        task_or_prac = input(['Practice (0) or Full (1)']);
        if (task_or_prac == 0 | task_or_prac == 1)
            break;
        else
            fprintf('Incorrect number, please try again\n');
        end
    end
    Run_VNFB_StopSignalIm(task_or_prac, windowPtr, ID, textColor, bgColor, block, sessiontable, rect);
end

sca;
