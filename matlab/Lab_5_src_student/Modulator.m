function y=Modulator(u, Mode)
%% Processing - D. Tan 2024-09-13
switch Mode
    case 1
        y=pskmod(u, 4, pi/4, [0 2 3 1], InputType='bit');
    case 2
        y=qammod(u, 16, [11 10 14 15 9 8 12 13 1 0 4 5 3 2 6 7],...
            InputType='bit', UnitAveragePower=true);
    case 3
        y=qammod(u, 64, [47 46 42 43 59 58 62 63 45 44 40 41 ...
            57 56 60 61 37 36 32 33 49 48 52 53 39 38 34 35 51 50 54 55 7 ...
            6 2 3 19 18 22 23 5 4 0 1 17 16 20 21 13 12 8 9 25 24 28 29 15 ...
            14 10 11 27 26 30 31],...
            InputType='bit', UnitAveragePower=true);
    otherwise
        error('Invalid Modulation Mode. Use {1,2, or 3}');
end