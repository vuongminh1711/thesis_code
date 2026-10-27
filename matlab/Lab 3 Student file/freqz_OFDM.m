function freqz_OFDM(b,a,nSubCar)
% FREQZOFDM marks subcarrier frequencies on 2-sided freqz plots
% Copywright 2015 by MathWork

[h,w] = freqz(b,a);
hext = [conj(flipud(h(2:end))); h];
wext = [-flipud(w(2:end)); w];
nPts = length(hext)-1;
plotIdx = round((0:nSubCar-1)/(nSubCar)*nPts+1);

subplot(2,1,1)
plot(wext/pi,20*log10(abs(hext)),...
    wext(plotIdx)/pi,20*log10(abs(hext(plotIdx))),'ro')
title('Frequency Selective Channel')
xlabel('Normalized Frequency (\times\pi rad/sample)')
ylabel('Magnitude (dB)')
grid
for lIdx = 1:nSubCar
    text(wext(plotIdx(lIdx))/pi+0.02,20*log10(abs(hext(plotIdx(lIdx))))+5,...
        num2str(lIdx),'Color',[1 0 0])
end

subplot(2,1,2)
plot(wext/pi,180/pi*angle(hext),...
    wext(plotIdx)/pi,180/pi*angle(hext(plotIdx)),'ro')
xlabel('Normalized Frequency (\times\pi rad/sample)')
ylabel('Phase (degrees)')
grid
for lIdx = 1:nSubCar
    text(wext(plotIdx(lIdx))/pi+0.02,180/pi*angle(hext(plotIdx(lIdx)))+10,...
        num2str(lIdx),'Color',[1 0 0])
end