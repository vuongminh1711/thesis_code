% 適応イコライザのシミュレーション (Part II)
%
% このスクリプトは、PSK変調、raised-cosineパルス成形、マルチパスフェージング、
% および適応等化を使って通信回線のシミュレーションを行います。
%
% 2つのパートの後半の部分です: Part I (adapteqpt1.m) は、シミュレーション
% パラメータを設定し、チャネルとイコライザオブジェクトを作成します。
% Part II (adapteqpt2.m) は、MATLABのワークスペースに格納されたこれらの
% 設定を元に回線のシミュレーションを実行します。Part I は3つのシナリオが
% 用意されており、これらのそれぞれにおいて Part II を複数回呼び出します。
% Part I のスクリプトの情報については、MATLABのプロンプトで demo('toolbox','comm') 
% を入力して "Adaptive Equalizer Simulation (Part I)" を選択してください。
% 異なるシミュレーション設定を使って実験するために、Part I スクリプトを
% 編集することが可能です


%   Copyright 1996-2004 The MathWorks, Inc.
