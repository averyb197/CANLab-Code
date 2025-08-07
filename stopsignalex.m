%Stop Signal Task
%2016-10-13
%By TanHY, Shanghai Mental Health Center
%Shanghai Jiao Tong University, China

KbName('UnifyKeyNames');

bgnset=inputdlg({'编号','任务次数','停止比例'},'设置',1,{'001','48','0.25'});
if isempty(bgnset)
    ListenChar(0); % if broken in running, it can not input, just run again then cancel
    return
end
ListenChar(2);
%a session
%a block
rslt=struct('id',{},'sstf',{},'kp',{},'crans',{},'anstf',{},'rt',{},'ssd',{});
% ID,is there stop signal,keypress,correct answer,is answer true,keypress
% RT,SSD
trials=round(str2double(bgnset{2})); % trials amount
stppct=str2double(bgnset{3}); % stop signal percentage
i=0; % trial count
stptf=0; % stop signal bool
tmpssd=0.2; % per trial SSD
anstf=-1;% per trial answer T or F
tmpans=' ';% per trial answer
trlrdm=randperm(trials); % random order

%open window
scnsize = get(0,'MonitorPosition');
xW0=(scnsize(1)+scnsize(3))/2;
yW0=(scnsize(2)+scnsize(4))/2;
[wPtr,wRect]=Screen('OpenWindow',0,[255,255,255],[xW0-300,yW0-300,xW0+300,yW0+300]);
%introduction window
intropic=imread([pwd '\sstintro.png']);
Screen('PutImage',wPtr,intropic);
Screen('Flip',wPtr);
while 1
    [intropass]=KbCheck;
    if intropass
        break
    end
end
%set x0&y0
x0=(wRect(1)+wRect(3))/2;
y0=(wRect(2)+wRect(4))/2;

% buffer wave
[y, freq] = psychwavread([pwd '\tada.wav']);
wavedata = y';
nrchannels = size(wavedata,1);
InitializePsychSound;
pahandle = PsychPortAudio('Open', [], [], 0, freq, nrchannels);
PsychPortAudio('FillBuffer', pahandle, wavedata);

% a trial
while i<trials
    i=i+1;
    
    %fixtation
    Screen('DrawLine',wPtr,[0,0,0],x0-30,y0,x0+30,y0,5);
    Screen('DrawLine',wPtr,[0,0,0],x0,y0+30,x0,y0-30,5);
    Screen('Flip',wPtr);
    pause(0.5);
    %clear window
    Screen('FillRect',wPtr,255);
    Screen('Flip',wPtr);
    
    % GoTask set, left(0) or right(1)
    if rand(1)>0.5
        points=[x0-50,y0;x0,y0+30;x0,y0-30];
        Screen('FillPoly',wPtr,0,points);
        Screen('FillRect',wPtr,0,[x0,y0-20,x0+50,y0+20]);
        rslt(i).crans='left-F';
        tmpans='f';
    else
        points=[x0+50,y0;x0,y0+30;x0,y0-30];
        Screen('FillPoly',wPtr,0,points);
        Screen('FillRect',wPtr,0,[x0-50,y0-20,x0,y0+20]);
        rslt(i).crans='right-J';
        tmpans='j';
    end
    %allow show
    Screen('Flip',wPtr);
   
    
    stptf=(trlrdm(i)<=(ceil(trials*stppct))); % 36 GoTask & 12 StopTask
    
    % stop signal prepare      
    % stptf=(rand(1)>0.3);
    if stptf % buffer wave
%         [y, freq] = psychwavread([pwd '\tada.wav']);
%         wavedata = y';
%         nrchannels = size(wavedata,1);
%         InitializePsychSound;
%         pahandle = PsychPortAudio('Open', [], [], 0, freq, nrchannels);
%         PsychPortAudio('FillBuffer', pahandle, wavedata);
        plyaudio=1;
    end 
    
    % write ID & is there stop signal
    rslt(i).id=i;
    rslt(i).sstf=stptf;
    
    %start time
    stt=GetSecs;
    %detecting keyboard    
    while 1  
        %time out & no keypress
        if GetSecs-stt>1.3 % 1300ms 
            % write keypress, RT, judge answer
            rslt(i).kp='-1';
            rslt(i).rt=-1;
            rslt(i).anstf=-1;
            rslt(i).ssd=-1; % if there stop signal, it will re-write
            if stptf                
                rslt(i).ssd=tmpssd; % write SSD
                if tmpssd<0.5
                    tmpssd=tmpssd+0.05; % adjust SSD, inhibit succeed
                end
            end
            break
        end % detecting keyboard end...
       
        % play stop signal audio
        if stptf
            if plyaudio
                if GetSecs-stt>tmpssd
                    t1 = PsychPortAudio('Start', pahandle, 1, 0, 1);
                    plyaudio=0; % do not play audio again when detecting keyboard
                end
            end
        end
        
        %get keyboard signal
        [kD,secs,kC]=KbCheck;            
        if kD
            kpchar=char(KbName(kC));
            rslt(i).kp=kpchar;
            rslt(i).rt=sprintf('%10.3f',(secs-stt));
            %pause(1);
            if stptf % response StopTask
                % PsychPortAudio('Stop', pahandle); % stop audio play
                rslt(i).ssd=tmpssd; % write SSD
                if kpchar==tmpans
                    rslt(i).anstf=1; % write judge T
                else
                    rslt(i).anstf=0; % write judge F
                end 
                if tmpssd>0
                    tmpssd=tmpssd-0.05; % adjust SSD, inhibit fail
                end
            else % response GoTask
                if kpchar==tmpans
                    rslt(i).anstf=1; % write judge T
                else
                    rslt(i).anstf=0; % write judge F
                end 
                rslt(i).ssd=-1; % write SSD
            end
            break;        
        end % detecting keyboard end...       
    end
    
    % buffer screen
    Screen('FillRect',wPtr,255);
    Screen('Flip',wPtr);
    pause(0.2) % 200ms
    
    if stptf
        PsychPortAudio('Stop', pahandle); % stop audio play
        %PsychPortAudio('Close', pahandle);
        stptf=0;
    end % thia trail end...
    
end
%introduction window
endpic=imread([pwd '\sstend.png']);
Screen('PutImage',wPtr,endpic);
Screen('Flip',wPtr);
pause(0.5);
% write table to xls
filename=[pwd '\SSTData\SSTData-' sprintf('%s-%s',bgnset{1},datestr(now,29))];
if exist([filename '.xls'],'file')==2
    filename=[filename '-' strrep(datestr(now,13),':','-')];
end
PsychPortAudio('Close', pahandle);
%WriteStructsToText(filename,rslt);
writetable(struct2table(rslt), [filename '.xls']);
fclose('all');
ListenChar(0);
sca