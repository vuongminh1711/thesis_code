function prmLTEDLSCH = lteDLSCHsimsetup()
%LTEDLSCHSIMSETUP-creates a parameter structure for the DLSCH
%simulation with GPU.

%   Copyright 2012-2013 The MathWorks, Inc.

prmLTEDLSCH.tbLen = 75376;
[c, ~, kp] = lteCblkSegParams(prmLTEDLSCH.tbLen);
prmLTEDLSCH.C = c;
prmLTEDLSCH.trellis = poly2trellis(4, [13 15], 13);
prmLTEDLSCH.Kplus = kp; 
prmLTEDLSCH.maxIter = 6;
prmLTEDLSCH.intrlvrIndices = lteIntrlvrIndices(prmLTEDLSCH.Kplus);

prmLTEDLSCH.ebNoVec  = 0.2:0.1:0.6;
