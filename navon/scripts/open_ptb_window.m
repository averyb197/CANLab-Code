function [window, windowRect, black, white] = open_ptb_window(params)
    Screen('Preference', 'SkipSyncTests', 1); % <=== WILL PUT A BANDAID ON THE PROBLEM BUT IS NOT GOOD ENOUGH
 %   Screen('Preference','SkipSyncTests', 0); 
    screens = Screen('Screens');
    screenNumber = max(screens);
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, white);
end
