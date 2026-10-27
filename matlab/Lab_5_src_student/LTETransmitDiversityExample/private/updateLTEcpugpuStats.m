function updateLTEcpugpuStats(rth, runtime)
%UPDATELTECPUGPUSTATS update the runtime in the LTEDLSCHcpugpuExample

%   Copyright 2012 The MathWorks, Inc.

%Compute runtime string
if runtime < 60,
    timestr = sprintf('%d sec', fix(runtime));
else
    m = fix(runtime ./ 60);
    if m > 59,
        h = fix(m ./ 60);
        hstr = sprintf('%d hr, ', h);
        m = fix( (runtime - h*3600)./60);
        mstr = sprintf('%d min', m);
    else
        hstr = '';
        mstr = sprintf('%d min', m);
    end
    timestr = [hstr, mstr];
end
set(rth, 'String', timestr);
       
        