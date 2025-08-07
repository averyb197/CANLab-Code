%gets the actual response with response and response times from participant

function [keyCode, rt, responded] = get_yn(params, onsetTime)

keyCode = [];
rt = NaN;
responded = false;

while GetSecs - onsetTime < params.stimDuration
    [pressed, secs, keys] = KbCheck;
    if pressed
        if keys(params.escapeKey)
            sca; ShowCursor; ListenChar(0);
            error('Experiment aborted via ESC');
        end

        if keys(params.responseKeys.yes) || keys(params.responseKeys.no)
            keyCode = keys;
            rt = secs - onsetTime;
            responded = true;
            return;
        end
    end
end
end
