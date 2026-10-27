% 畳込み符号化とViterbi復号のデモンストレーション
%
% このデモは、通信回線のシミュレーションで畳み込み符号器と復号器をどのように
% 使用するかを示します。畳み込み符号の誤り訂正の性能についても示します。
% これは、畳込みトレリス生成器である POLY2TRELLIS 、符号器である CONVENC 、
% 復号器である VITDEC をデモします。また、PSKMOD, PSKDEMOD, INTDUMP, 
% RECTPULSE, BITERR, BERCODING, RANDSRC, AWGN もデモンストレーションします。
% 後者の関数は、"ガウスノイズを付加した位相シフトキーイングのシミュレーション"
% デモにさらに詳細が記述されています。最後に、このデモは、例題 VITSIMEXAMPLE 
% によって得られたデータを使って、Gray コードの QPSK についての実験値の
% 性能曲線を表示します。


% Copyright 1996-2004 The MathWorks, Inc.
