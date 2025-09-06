Screen('Preference', 'SkipSyncTests', 1);
PsychDefaultSetup(1); 
Time2Res = 90;
%set fixation jitter
permtarget=linspace(3,5,3);
randtarget=randperm(numel(permtarget))';
for i=1:length(permtarget)
    JitterDist(1,i)=permtarget(randtarget(i,1));
    end2
    2
    2
    
[win, winRect] = Screen('OpenWindow', 0, [0 0 0]); % Black background
Screen('TextSize', win, 40);

trials=150;
frequency=50;
amt_probe= trials/frequency;

prompt = ['On a Scale from 1-10, how focused were you on the task? \n' ...
    '(5 very focused, 1 unfocused):'];
probe_response=zeros(1, amt_probe);
probe_index = 1;

for i=1:trials

typedText = ''; % Store numeric input5
i_mod=mod(i, 50);
    if i_mod==0
        while true
            % Combine prompt and typed text
            fullLine = [prompt typedText];

            % Draw the combined line
            DrawFormattedText(win, fullLine, 'center', 'center', [255 255 255]);

            % Show it
            Screen('Flip', win);

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
        WaitSecs(1);
    end
end

% Show confirmation
DrawFormattedText(win, ['You typed: ' ], 'center', 'center', [255 255 0]);
Screen('Flip', win);
WaitSecs(2);

Screen('CloseAll');