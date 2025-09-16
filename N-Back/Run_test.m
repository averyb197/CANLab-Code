stimuli_full = readtable('N-Back_Stim_List.xlsx',"ReadVariableNames", true);
length_block = height(stimuli_full);
blocks = width(stimuli_full);
randList = randperm(blocks, blocks);

for i = 1:blocks
    list_block = char(stimuli_full {:, randList(i)});
    % stimuli_block = char(list_block);
end