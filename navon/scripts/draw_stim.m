%Draws the selected image file on the screen
function onset = draw_stim(window, imgPath)
    img = imread(imgPath);
    tex = Screen('MakeTexture', window, img);
    Screen('DrawTexture', window, tex);
    onset = Screen('Flip', window);
    Screen('Close', tex);
end
