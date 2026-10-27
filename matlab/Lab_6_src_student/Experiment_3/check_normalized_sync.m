% Run from Experiment_2 to check normalized frame synchronization.
assert(strcmp(which('FrameFormation'),fullfile(pwd,'FrameFormation.m')));
header = [1;1;1;1;1;-1;-1;1;1;-1;1;-1;1];
for dataType = {'double','single'}
    expectedFrame = cast([header; zeros(581-numel(header),1)]*exp(0.37j),dataType{1});
    for delay = [0 5 580]
        synchronizer = FrameFormation('OutputFrameLength',581,'FrameHeader',header);
        signal = [zeros(delay,1,'like',expectedFrame); repmat(expectedFrame,4,1); ...
            zeros(numel(header)-1,1,'like',expectedFrame)];
        for frameIndex = 1:4
            if frameIndex == 1
                [frame,valid] = synchronizer(signal);
            else
                [frame,valid] = synchronizer(zeros(0,1,'like',signal));
            end
            assert(valid && isequal(frame,expectedFrame));
        end
        reset(synchronizer);
        [frame,valid] = synchronizer(signal);
        assert(valid && isequal(frame,expectedFrame));
        release(synchronizer);
    end
end
expectedFrame = [0.1*header; zeros(581-numel(header),1)];
wrongHeader = header;
wrongHeader(7) = -wrongHeader(7);
expectedFrame(400:412) = 10*wrongHeader;
signal = [expectedFrame; zeros(numel(header)-1,1)];
[~,rawPeak] = max(abs(conv(signal,flipud(header),'valid')));
assert(rawPeak~=1);
synchronizer = FrameFormation('OutputFrameLength',581,'FrameHeader',header);
[frame,valid] = synchronizer(signal);
assert(valid && isequal(frame,expectedFrame));
release(synchronizer);
disp('PASS: phase/type/alignment/reset checks; weak true header beats strong false peak.');
