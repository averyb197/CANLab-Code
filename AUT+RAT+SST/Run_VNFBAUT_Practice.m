function FullTableAUT = Run_VNFBAUT_Practice(windowPtr,ID,textColor,bgColor,block,sessiontable, rect)
%Add folder into all tasks soon
PsychDefaultSetup(1); 
Time2Res = 90;
%set fixation jitter
permtarget=linspace(3,5,3);
randtarget=randperm(numel(permtarget))';
for i=1:length(permtarget)
    JitterDist(1,i)=permtarget(randtarget(i,1));
end
%Find today's session
%PromptWordsList = transpose(StimOrderTable{Session+1,11:13});
PromptWordsList = transpose(sessiontable{block+1,13});

ListenChar(2);
%alternative: replace the above with smaller windowPtr for testing
%   [windowPtr,rect]=Screen('OpenWindow',screenNumber,[],[10 20 1200 700]);
%NOTE that smaller windows can induce synchronisation problems
%and other issues, so they're not suitable for running real experiment
%sessions. See >> help SyncTrouble


% Preparing and displaying the welcome screen
% We choose a text size of 24 pixels - Well readable on most screens:
Screen('TextSize', windowPtr, 36);
% 
% % This is our intro text. The '\n' sequence creates a line-feed:
% myText = ['In this task, you will see a series of objects.\n\n'...
%            'Your task is to come up with as many\n'...
%            ' unusual and uncommon uses for each object.\n\n'...
%           'Please think creatively as you complete this task.\n\n' ...
%           ' You will have 45 seconds to think of ideas \n...' ...
%           ' for each object in this session. \n\n'...
%           'Feel free to verbalize your ideas \n' ...
%           ' by speaking them out as they come to mind. \n\n' ...
%           '      (Wait for the start)\n' ];

task = 'AUTPrac';
session = sessiontable.Session(1);

% lib = lsl_loadlib();      
% info = lsl_streaminfo(lib,'MyMarkerStream','Markers',1,0,'cf_string');
% outlet = lsl_outlet(info);
% pause(5);

 


image = imread("C:\Users\User\OneDrive - Loyola University Chicago\Documents\MATLAB\CANLab-Code\AUT+RAT+SST\AUTInstructions.jpg");
%image = imread("/Users/dannyholzman/Library/CloudStorage/OneDrive-Personal/Documents/NFB/AUTInstructions.jpg");
Showimg = Screen('MakeTexture',windowPtr,image);
% Draw 'CurrentImage', centered in the display windowPtr:
Screen(windowPtr, 'DrawTexture', Showimg, [], []);

% Draw 'myText', centered in the display windowPtr:
%DrawFormattedText(windowPtr, myText, 'center', 'center',textColor,bgColor);
% Show the drawn text at next display refresh cycle:
Screen('Flip', windowPtr);
ExTime.InsStart = GetSecs();
 % Wait for key stroke. This will first make sure all keys are
 % released, then wait for a keypress and release:
%WaitSecs(5);

KbWait([], 3);

           
% lr = tcpip('localhost', 22345);
% fopen(lr)
% fprintf(lr, 'select all');
% fprintf(lr, "update");
% idnum = sessiontable.SN(1);
% 
%      fprintf(lr, ['filename {root:C:\Users\canla\Documents\NFB_volatility\Data\VNFB_data\raw}' ...
%             '{task:',char(task),'} ' ...
%             '{template:%p_%s_%b_%n.xdf} '...
%             '{run:',num2str(block),'}'...
%             '{participant:',num2str(idnum),'}'...
%             '{session:', num2str(session), '}'...
%             '{modality:eeg}']); 
%             fprintf(lr, 'start');
% 
% pause(2);
ExTime.InsEnd = GetSecs();
for i = 1:size(PromptWordsList,1) % height(PromptWordsList)%length(PromptWordsList)
    num = 1;
    jitter = JitterDist(i);
    Screen('TextSize', windowPtr, 90);
    FixCr= '+';
    DrawFormattedText(windowPtr, FixCr, 'center', 'center',textColor);
    Screen('Flip', windowPtr);
    ExTime.FixStart(i) = GetSecs();
    WaitSecs(jitter);
    ExTime.FixEnd(i) = GetSecs();
     %Start recording to avoid loss from premature start
    Screen('TextSize', windowPtr, 56);
    % Referance word:
    
    %DrawFormattedText(windowPtr, Condition, 'center', my+100,textColor,bgColor);
    % Show the drawn text at next display refresh cycle:
    ResponseList = strings(1,20);
    ResStartTime = zeros(1,20);
    ResEndTime = zeros(1,20);
    ResponseCount = 1:1:20;
    ResponseRT = zeros(1,20);
    ResponseTimeSequence = zeros(1,20);
    ResponsePromptWord = repmat(PromptWordsList(i),20,1);
    ResponseTable = table(ResponsePromptWord,ResponseCount',ResStartTime',ResEndTime',ResponseList',ResponseRT',ResponseTimeSequence',...
        'VariableNames',["PromptWord","NumRes","StartTime","EndTime","Response","RT","Tsequence"]);
    ExTime.StartPromptWord(i) = GetSecs();
    CountResponses = 1;
    while (GetSecs()-ExTime.StartPromptWord(i) < Time2Res)
        [keyIsDown, keysecs, keyCode] = KbCheck;
        if keyCode(KbName('escape'))
            Screen('CloseAll');
            break;
        end
        
        CurrentWord = char(PromptWordsList(i));
    %Condition = 'Think Uses Creative';
    % Draw 'myText', centered in the display windowPtr:
    %ResponseTable.Response(CountResponses) =
    %GetEchoString(windowPtr,'Enter use: ', 25, ((rect(4)-rect(2))/2),
    %textColor, bgColor, ExTime.StartPromptWord(i), Time2Res);
    %figure out meaning of code, replacing ExTime.StartPromptWord(i) with
    %[]
       
        DrawFormattedText(windowPtr, CurrentWord, 'center', ((rect(4)-rect(2))/2)-100,[0 150 0]);
      % outlet.push_sample({strcat(CurrentWord, num2str(num))});

        ResponseTable.StartTime(CountResponses) = GetSecs();
        ResponseTable.Response(CountResponses) = GetEchoString(windowPtr,'Enter use: ', 25, ((rect(4)-rect(2))/2), textColor, bgColor, [], Time2Res);
        ResponseTable.EndTime(CountResponses) = GetSecs();
        ResponseTable.RT(CountResponses) = ResponseTable.EndTime(CountResponses)-ResponseTable.StartTime(CountResponses);
        ResponseTable.Tsequence(CountResponses) = ResponseTable.EndTime(CountResponses) - ExTime.StartPromptWord(i); 
        CountResponses = CountResponses+1;
        Screen('Flip', windowPtr);
        num = num +1;
        WaitSecs(1);
    end
    ExTime.EndPromptWord(i) = GetSecs();
    if i == 1
        ResponseTableFull = ResponseTable;
    else
        ResponseTableFull = [ResponseTableFull; ResponseTable];
    end
    DrawFormattedText(windowPtr, 'end of trial', 'center', 'center',textColor);
    % Show the drawn text at next display refresh cycle:
    Screen('Flip', windowPtr);
    WaitSecs(2);
end

%Start Eval trial
for i = 1:size(PromptWordsList,1)
    jitter = JitterDist(i);
    Screen('TextSize', windowPtr, 90);
    FixCr= '+';
    DrawFormattedText(windowPtr, FixCr, 'center', 'center',textColor);
    Screen('Flip', windowPtr);
    ExTime.FixStart(i) = GetSecs();
    WaitSecs(jitter);
    ExTime.FixEnd(i) = GetSecs();
     %Start recording to avoid loss from premature start
    Screen('TextSize', windowPtr, 35);
    ResponseTableFull.PromptWord = categorical(ResponseTableFull.PromptWord);
    indxShortResponseTable = (ResponseTableFull.PromptWord==PromptWordsList(i)) & ~strcmp(ResponseTableFull.Response,"");
    ShortResponseList = ResponseTableFull.Response(indxShortResponseTable);
    %[windowPtr,rect]=Screen('OpenWindow',0,[],[10 20 1200 700]);
    %Screen('TextBackgroundColor', windowPtr, bgColor)
   % Screen('FillRect', windowPtr ,bgColor, rect );
    InstructionLine = ['Choose from the list below what you believe was your most creative response\nto ', char(PromptWordsList(i))  ,'. Type the number. Then hit enter to continue.'];
    DrawFormattedText(windowPtr, InstructionLine, 25,40,textColor);
    
   % outlet.push_sample({strcat(PromptWordsList{i}, '_eval')});

%     DrawFormattedText(windowPtr, ShortResponseList, 25,60,textColor);
%     Screen('Flip', windowPtr);
    %Draw the rest of the List
    Screen('TextSize', windowPtr, 28);
    StepSizeDiff = 120:(((rect(4)-50)-120)/(length(ShortResponseList))):(rect(4)-50); %change according to screen size in pixels
    for j = 1:length(ShortResponseList)

            WriteExperimentDiff = [num2str(j), ' - ', char(ShortResponseList(j))];
            DrawFormattedText(windowPtr, WriteExperimentDiff, 30, StepSizeDiff(j));

    end

Response = strings(20, 1);
validInput = false;

while ~validInput
    inputStr = GetEchoString(windowPtr, 'Enter number: ', 25, StepSizeDiff(length(ShortResponseList) + 1), textColor, bgColor);
    
    % Check if the input is a valid number
    inputNum = str2double(inputStr);
    if isnan(inputNum) || isempty(inputStr)
        disp('Invalid input. Please enter a valid number.');
    else
        if inputNum >= 1 && inputNum <= length(ShortResponseList)
            validInput = true;
            Response(i) = inputStr;
            ResponseText(i) = ShortResponseList(inputNum);
        else
            disp('Input is out of range. Please enter a valid number.');
        end
    end
end
    
    
%     Response = strings(20,1);
%     Response(i) = GetEchoString(windowPtr,'Enter number: '...
%         , 25, StepSizeDiff(length(ShortResponseList)+1),textColor, bgColor);
%     ResponseText(i) = ShortResponseList(str2num(Response(i)));
    Screen('Flip', windowPtr);
    clear ShortResponseList;
%     idx = StimOrderTable.SN == ID & StimOrderTable.SessionOrder == Session;
%     shorttable = StimOrderTable(idx,:);
%     PromptWordsList = transpose(shorttable{1,35:37});
end

ExTime.End = GetSecs();
Screen('TextSize', windowPtr, 56);
% Referance word:
myText4 = 'The End';
% Draw 'myText', centered in the display windowPtr:
DrawFormattedText(windowPtr, myText4, 'center', 'center',textColor);
% Show the drawn text at next display refresh cycle:
Screen('Flip', windowPtr);
WaitSecs(2);
Screen('Flip', windowPtr);
%ArrangeTimes make table
ListenChar(0);

% fprintf(lr, 'stop');

%prepare XL table
TimeTable = table(ExTime.FixStart',ExTime.FixEnd',ExTime.StartPromptWord',ExTime.EndPromptWord','VariableNames',["FixStart","FixEnd",...
    "ShowPWordStart","ShowPWordEnd"]);
TimeTable.InsStart(1) = ExTime.InsStart(1);
TimeTable.InsEnd(1) = ExTime.InsEnd(1);
TimeTable.End(1) = ExTime.End(1);
TimeTable.FixRT = TimeTable.FixEnd-TimeTable.FixStart;
TimeTable.ResRT = TimeTable.ShowPWordEnd-TimeTable.ShowPWordStart;
TimeTable.ExLen(1) = (TimeTable.End(1)-TimeTable.InsStart(1))/60;
TimeTable.InsRT(1) = (TimeTable.InsEnd(1)-TimeTable.InsStart(1));
IDtable = repmat(ID,height(PromptWordsList),1);
VisitNtable = repmat(block,height(PromptWordsList),1);
PromptWordsListTable = table(IDtable,VisitNtable,PromptWordsList,ResponseText','VariableNames',["ID","BlockN","PromptWord","EvalChoice"]);
FullTableAUT = [PromptWordsListTable,TimeTable];
%for task add trial number 1-3 also to function
% FileName = [folder,'Sub',char(num2str(ID)),'_Session',num2str(sessiontable.Session(1)),'_Block',char(sessiontable.Trial(1)),'_AUTPractice_ResponseTable'];
% writetable(ResponseTableFull,FileName,"FileType","spreadsheet");
%FileName = [folder,filesep,'OutputData',filesep,'Sub', num2str(ID),'_VisitN',num2str(Session),'_FullTable'];
%writetable(FullTableAUT,FileName,'FileType','spreadsheet');