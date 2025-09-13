
Screen('Preference', 'SkipSyncTests', 1);
[win, winRect] = Screen('OpenWindow', 0 ...
    , [0 0 0]); % black background
Screen('TextSize', win, 50);
[xCenter, yCenter] = RectCenter(winRect);

% First text (top of screen)
DrawFormattedText(win, ['This is text block 1\n' ...
    'hi'], 'center', winRect(4)*0.3, [255 255 255]);

% Second text (bottom of screen)
prompt1 = ['On a Scale from 1-5, how focused were you on the task?'];
DrawFormattedText(win, prompt1, 'center', 'center', [255 255 255]);
prompt2 = ['(5 very focused, 1 unfocused):' ];
answer= GetEchoString(win,prompt2, xCenter-325, winRect(4)*0.55, [255 255 255]);

% Show both at once
Screen('Flip', win);

KbWait;
Screen('CloseAll');
