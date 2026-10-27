function Exp1_Channel_Response(sel)
switch sel
    case 2
        % Frequency selective channel A
        b = firpm(4,[0 .2 .4 1],[1 0.01 0.01 1]);
        figure(10);
        freqz_OFDM(b,1,12);
        figure(11);
        impz(b,1);title('Channel Impulse Response A');


    case 3
        % Frequency selective channel B
        b = firpm(6,[0 .2 .4 1],[1 0.01 0.01 1]);
        figure(10);
        freqz_OFDM(b,1,12);
        figure(11);
        impz(b,1);title('Channel Impulse Response A');

    case  4
        % Frequency selective channel LTEA
        b = firpm(24,[0 .2 .4 1],[1 0.02 0.02 1]);
        figure(10);
        freqz_OFDM(b,1,301);
        figure(11);
        impz(b,1);title('Channel Impulse Response LTEA');
 
    case  5
        % Frequency selective channel LTEB
        b = firpm(60,[0 .25 .35 1],[1 0.02 0.02 1]);
        figure(10);
        freqz_OFDM(b,1,601);
        figure(11);
        impz(b,1);title('Channel Impulse Response LTEB');
     
    otherwise
    msgbox('This is ideal channel');
end 
        
        
     