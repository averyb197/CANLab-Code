Screen('Preference', 'SkipSyncTests', 1);
[win, winRect] = Screen('OpenWindow', 0, [0 0 0]); % black background
Screen('TextSize', win, 40);

% First text (top of screen)
DrawFormattedText(win, 'This is text block 1', 'center', winRect(4)*0.3, [255 255 255]);

% Second text (bottom of screen)
DrawFormattedText(win, 'This is text block 2', 'center', winRect(4)*0.7, [0 255 0]);

% Show both at once
Screen('Flip', win);

KbWait;
Screen('CloseAll');