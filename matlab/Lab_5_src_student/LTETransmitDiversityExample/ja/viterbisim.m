% VITERBISIM   BERToolのビタビ復号化シミュレーションの例題
%
% 4相違相シフトキーイング(QPSK)または2相PSK(BPSK)でかつ畳込み符号化
% およびビタビ複合化を硬判定複合した信号のAWGNチャンネル上でのシュミレーションです。 
% BERToolに対するMATLABシミュレーション関数の作成方法をデモします。
% BERToolがないと実行できません。BERTool は、この関数について3つの変数を
% 与えます： EbNo, maxNumErrs (シミュレーションに入る前に収集するビット
% エラー数), maxNumBits (シミュレートする最大ビット数)
% 関数は、ビットエラーレートを BER に、実際にシミュレートされたビット数を
% NUMBITS に出力します。
%
% VITERBISIM は、畳込みトレリス生成器(POLY2TRELLIS)、符号化器(CONVENC)、
% 復号化器(VITDEC)の利用方法を説明します。 その他の関数の利用方法も
% 示します: PSKMOD, PSKDEMOD, BITERR, BERCODING, RANDINT, AWGN


%   Copyright 1996-2004 The MathWorks, Inc.
