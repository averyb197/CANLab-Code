%Nback Template
clc
clear
pause(.5)
letters = 'ABCDEGIKLMOPTXZ';
trials=50;
back_1 = '';
back_2 = '';
total_match=0;
correctly_matched=0;
false_alarm=0;

for i = 1:trials
    letter = letters(randperm(15,1));
    if (letter==back_2)
        total_match = total_match + 1; 
    end
    disp(letter)
    pause(.5)
    clc
    while true
        res = input('Did you see the same letter in 2 letters ago (y/n)?', 's');
        if (res=='y' | res=='n') 
            break; 
        end
    end
    clc
    if (res=='y')
        if (letter==back_2 | letter==back_1)
            correctly_matched = correctly_matched + 1;
            disp('correct')
        else
            false_alarm = false_alarm + 1;
            disp('wrong')
        end
    elseif(res=='n')
        if (letter==back_2 | letter==back_1)
            false_alarm = false_alarm + 1;
            disp('wrong')
        else
            %correctly_matched = correctly_matched + 1;
            disp('correct')
        end
    end
    back_2 = back_1;
    back_1 = letter;
    pause(.5)
    clc
end

disp(['Total trials that had a match: ', num2str(total_match)])
disp(['Total trials that had not a match: ', num2str(trials - total_match)])
disp(['Number of correctly matched items: ', num2str(correctly_matched)])
disp(['Number of false alarms: ', num2str(false_alarm)])
disp(['Percentage correct matches: ', num2str(round((correctly_matched/total_match)*100)), '%'])
disp(['Percentage false alarms: ', num2str(round((false_alarm/(trials - total_match))*100)), '%'])



