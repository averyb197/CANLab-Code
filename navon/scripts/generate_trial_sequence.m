%this script generates a trial sequence
%master stim folder is navon/assets/navon_stims/
%Within navon_stims/ there is a folder for every letter A-Z which indicates
%the shape letter (hollistic). Inside the folder for each letter is 26
%images for each permutation of fill letter. 


function trials = generate_trial_sequence(params)
% generate_trial_sequence  Generates randomized Navon trials
%   Uses files in the format <stimDir>/<ShapeLetter>/<Shape-Fill>.png

    letters = 'A':'Z';
    ntrials = params.ntrials;
    stimDir = params.stimDir;
    targets = upper(params.targetLetters);  % ensure all caps

    if params.debug
        disp([targets stimDir])

    allCombos = {};

    % Iterate through all shape and fill combinations
    for i = 1:length(letters)
        shape = letters(i);
        for j = 1:length(letters)
            fill = letters(j);

            % Construct expected file path
            filename = sprintf('%s-%s.png', shape, fill);
            folder = fullfile(stimDir, shape);
            imagePath = fullfile(folder, filename);

            % Check file exists
            if exist(imagePath, 'file')
                hasTarget = ismember(shape, targets) || ismember(fill, targets);

                allCombos{end+1} = struct( ...
                    'filename', filename, ...
                    'shapeLetter', shape, ...
                    'fillLetter', fill, ...
                    'hasTarget', hasTarget, ...
                    'imagePath', imagePath ...
                );
            end
        end
    end

    % Shuffle
    allCombos = allCombos(randperm(length(allCombos)));

    % Sample
    if length(allCombos) < ntrials
        error('Not enough stimuli to sample %d trials (only %d available).', ntrials, length(allCombos));
    end

    trials = allCombos(1:ntrials);
end


