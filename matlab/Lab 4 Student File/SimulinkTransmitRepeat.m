classdef SimulinkTransmitRepeat < matlab.System

    properties (Nontunable)

        % Radio Connection
        Platform = "B210"
        % Serial Number
        SerialNum = "313FAA8"

        % Channel Mapping
        ChannelMapping = 1
        % Center Frequency (Hz)
        CenterFrequency = 922e6
        % LO Offset (Hz)
        LocalOscillatorOffset = 0
        % Gain (dB)
        Gain = 60
        % PPS Source
        PPSSource (1,1) string ...
        {mustBeMember(PPSSource, ["Internal","External","GPSDO"])} = "Internal"

    
        % Clock Source
        ClockSource (1,1) string ...
        {mustBeMember(ClockSource, ["Internal","External","GPSDO"])} = "Internal"

        % Baseband / rate properties
        MasterClockRate = 15.36e6
        InterpolationFactor = 6

    end

    properties (Access = private)
        tx
        started = false
    end

    methods (Access = protected)

        % Called ONCE when the Simulink model starts
        function setupImpl(obj, ~)

            obj.tx = comm.SDRuTransmitter( ...
                Platform = obj.Platform, ...
                SerialNum = obj.SerialNum, ...
                ChannelMapping = obj.ChannelMapping, ...
                CenterFrequency = obj.CenterFrequency, ...
                LocalOscillatorOffset = obj.LocalOscillatorOffset, ...
                Gain = obj.Gain, ...
                PPSSource = obj.PPSSource, ...
                ClockSource = obj.ClockSource, ...
                MasterClockRate = obj.MasterClockRate, ...
                InterpolationFactor = obj.InterpolationFactor);

            obj.tx.InterpolationFactor = obj.InterpolationFactor;

            obj.started = false;
        end


        % Simulink calls this every simulation step
        function stepImpl(obj, u)

            % But transmitRepeat is called only the FIRST time
            if ~obj.started

                x = u(:);

                % USRP floating-point input must be within range
                if max(abs(x)) > 1
                    x = 0.9*x/max(abs(x));
                end

                transmitRepeat(obj.tx, x);

                obj.started = true;

            end
        end


        % Called when Simulink releases/stops the block
        function releaseImpl(obj)

            if ~isempty(obj.tx)

                if isTransmitting(obj.tx)
                    stopTransmission(obj.tx);
                end

                release(obj.tx);
            end

            obj.started = false;
        end

    end
    methods (Static, Access = protected)

        function simMode = getSimulateUsingImpl
            simMode = "Interpreted execution";
        end

    end

end