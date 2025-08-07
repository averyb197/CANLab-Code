%Main config files to set global params

function params = config_params()
KbName('UnifyKeyNames');

params.taskName = 'Navon Detection Task';
params.targetLetters = {'A', 'B'};  % The target letters for the participant, prob want to randomize later
params.responseKeys.yes = KbName('L'); % set the keys to be used for yes/no
params.responseKeys.no  = KbName('A');
params.escapeKey = KbName('Escape');

params.fontSize = 24;
%times are all in seconds
params.stimDuration = 1.0;   
params.ITI = 0.5;            
params.fixationDuration = 0.5;


params.ntrials = 5; %NUMBER OF TRIALS
params.stimDir = 'assets/navon_stims'; %Directory for where the stimuli image are pulled ==> DO NOT CHANGE'
params.debug = true; % when set to true it will give extensive printout, set to 0 for actual use
end
