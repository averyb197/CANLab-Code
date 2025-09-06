function FullTableRAT = Run_VNFB_RAT_Practice(windowPtr, ID, textColor, bgColor, block, sessiontable, rect)
   PsychDefaultSetup(1); 
    Time2Res = 15; % Set the response time limit to 15 seconds
    HideCursor

    % Set fixation jitter
    permtarget = linspace(3,5,15);
    randtarget = randperm(numel(permtarget))';
    for i = 1:length(permtarget)
        JitterDist(1,i) = permtarget(randtarget(i,1));
    end

    % Get today's session words
    PromptWordsList = transpose(sessiontable{block+1, 16});
    
    % Define vertical offsets for prompt and response text positions
    promptYPos = ((rect(4) - rect(2)) / 2) - 200;  % Position of the prompt word

    ListenChar(2);

    % lib = lsl_loadlib();      
    % info = lsl_streaminfo(lib,'MyMarkerStream','Markers',1,0,'cf_string');
    % outlet = lsl_outlet(info);
    % pause(5);

    % Display the instructions
    image = imread("C:\Users\User\OneDrive - Loyola University Chicago\Documents\MATLAB\CANLab-Code\RAT_Instructions.jpg");
    image2 = imread("C:\Users\User\OneDrive - Loyola University Chicago\Documents\MATLAB\CANLab-Code\RAT_Instructions2.jpg");
    Showimg = Screen('MakeTexture', windowPtr, image);
    Screen(windowPtr, 'DrawTexture', Showimg, [], []);
    Screen('Flip', windowPtr);
    ExTime.InsStart = GetSecs();
    KbWait([], 3); % Wait for a key press
    ExTime.InsEnd = GetSecs();

    Showimg2 = Screen('MakeTexture', windowPtr, image2);
    Screen(windowPtr, 'DrawTexture', Showimg2, [], []);
    Screen('Flip', windowPtr);
    ExTime.InsStart = GetSecs();
    KbWait([], 3); % Wait for a key press
    ExTime.InsEnd = GetSecs();


    % Start connection for recording
    %  lr = tcpip('localhost', 22345);
    %  fopen(lr);
    %  fprintf(lr, 'select all');
    %  fprintf(lr, "update");
    %  fprintf(lr, ['filename {root:C:\Users\canla\Documents\NFB_volatility\Data\VNFB_data\raw}' ...
    %              '{task:', char('RAT'), '} ' ...
    %              '{template:%p_%s_%b_%n.xdf} ' ...
    %              '{run:', num2str(block), '}' ...
    %              '{participant:', num2str(ID), '}' ...
    %              '{session:', num2str(sessiontable.Session(1)), '}' ...
    %              '{modality:eeg}']);
    %  fprintf(lr, 'start');
    % pause(2);

    % Initialize full response table
    ResponseTableFull = table();

    % Loop through each word prompt
 for i = 1:size(PromptWordsList, 1)
    jitter = JitterDist(i);
    
    % Show fixation cross
    Screen('TextSize', windowPtr, 90);
    DrawFormattedText(windowPtr, '+', 'center', 'center', textColor);
    Screen('Flip', windowPtr);
    ExTime.FixStart(i) = GetSecs();
    WaitSecs(jitter);
    ExTime.FixEnd(i) = GetSecs();

    % Display prompt word and capture response
    CurrentWord = char(PromptWordsList(i));
    Screen('TextSize', windowPtr, 56);
    DrawFormattedText(windowPtr, CurrentWord, 'center', promptYPos, [0 150 0]);
    % outlet.push_sample({strcat(CurrentWord,'_shown')});
   % Screen('Flip', windowPtr);  % Flip to show the prompt word
    ExTime.StartPromptWord(i) = GetSecs();

    % Capture the response using GetEchoStringNFB with the prompt word on screen
    ResponseTable = table({CurrentWord}, 1, 0, 0, "", 0, 0,"", ...
        'VariableNames', ["PromptWord", "NumRes", "StartTime", "EndTime", "Response", "RT", "Tsequence","SolutionType"]);
    ResponseTable.StartTime(1) = GetSecs();

    % Use GetEchoStringNFB for input with the prompt word displayed
    % ResponseTable.Response(1) = GetEchoStringNFB(windowPtr, 'Enter answer:', 25, ((rect(4) - rect(2)) / 2), textColor, bgColor, ExTime.StartPromptWord(i), Time2Res);
    ResponseTable.Response(1) = GetEchoString(windowPtr, 'Enter answer:', 25, ((rect(4) - rect(2)) / 2), textColor, bgColor, [], Time2Res);
    % Store response and timing
    ResponseTable.EndTime(1) = GetSecs();
    ResponseTable.RT(1) = ResponseTable.EndTime(1) - ResponseTable.StartTime(1);
    ResponseTable.Tsequence(1) = ResponseTable.EndTime(1) - ExTime.StartPromptWord(i);
    % outlet.push_sample({strcat(CurrentWord,'_answered')});

        % Clear the screen after capturing the response
        Screen('FillRect', windowPtr, bgColor); % Clear all text by filling the screen with the background color
        Screen('Flip', windowPtr); % Flip to show the cleared screen
        WaitSecs(0.5); % Optional brief pause before showing the next screen

         %Insight or Analysis
          % Check if a response was provided
        if any(isstrprop(ResponseTable.Response{1}, 'alphanum'))
           % Display "Insight or Analysis" question
            Screen('TextSize', windowPtr, 40);
            DrawFormattedText(windowPtr, 'Did you solve the problem through Insight or Analysis:\n\n1 - Insight\n2 - Analysis', ...
                              'center', 'center', textColor);
            Screen('Flip', windowPtr);

            % Wait for the user to enter 1 or 2
            while true
                [~, ~, keyCode] = KbCheck;
                if keyCode(KbName('1!'))
                    ResponseTable.SolutionType{1} = 'Insight';
                    break;
                elseif keyCode(KbName('2@'))
                    ResponseTable.SolutionType{1} = 'Analysis';
                    break;
                end
            end 
           
        else
             ResponseTable.SolutionType{1} = 'No Response';   
        
        end

    % Append response to the full table
    ResponseTableFull = [ResponseTableFull; ResponseTable];

    % Mark the end time for the current prompt word
    ExTime.EndPromptWord(i) = GetSecs();

    % Clear the screen after capturing the response
    Screen('FillRect', windowPtr, bgColor); % Clear all text by filling the screen with the background color
    Screen('Flip', windowPtr); % Flip to show the cleared screen
end

    % Stop recording
     % fprintf(lr, 'stop');

    % Save the responses to an output file
    % FileName = [folder, 'Sub', char(num2str(ID)), '_NFB', char(num2str(block-1)), '_RAT_Practice_ResponseTable.xlsx'];
   % writetable(ResponseTableFull, FileName, 'FileType', 'spreadsheet');

    % End screen message
    Screen('TextSize', windowPtr, 56);
    DrawFormattedText(windowPtr, 'The End', 'center', 'center', textColor);
    Screen('Flip', windowPtr);
    WaitSecs(2);
    Screen('Flip', windowPtr);

    ListenChar(0);

    FullTableRAT = ResponseTableFull;
end
