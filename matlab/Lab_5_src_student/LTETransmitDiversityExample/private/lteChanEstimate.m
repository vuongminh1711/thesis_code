function [h, hp] = lteChanEstimate(prmLTEPDSCH, Rx, Ref)
%#codegen

% Copyright 2012 The MathWorks, Inc.

% LTE Channel Estimator
%   Using the CSR reference signals and the received signals,
%   form the estimates of the MIMO channel - per tx-rx link
%       only one coefficient per link - due to OFDM CP assumption.
%       i.e. single-tap complex coefficient based on CSR
%   for 2 and 4 layers (antenna ports) only
%
% Pseudo logic to implement
% Rx - 200x2x2x4 => received reference signals 
% Ref - 220x2x2x4 => transmitted reference signals
% get H - channel estimates - using Ref and Rx - N_rx x N_tx
%   For a 4x4 system - 4 CSR have to be used at 1Rx to get 4 coeffs
%       = 4x4 => 16 coeffs    
%   Use the nulling of the symbols to advantage
%       per Rx antenna - contribution per CSR is only from one RE per port
%           => this gives the channel coefficient for that link.   

NmaxDL_RB = 110;    % largest downlink bandwidth configuration in RB
% Get input params
Nrb              = prmLTEPDSCH.Nrb;              % = 100 for 20 MHz
numLayers        = prmLTEPDSCH.numLayers;
numDataResources = prmLTEPDSCH.numDataResources; 

% Assume same number of Tx and Rx antennas = numLayers
numTx = prmLTEPDSCH.numTx;
numRx = prmLTEPDSCH.numRx; % == size(Rx, 4), == numLayers

% Estimate channel based on CSR - per antenna port
% hp are the pilot symbols channel estimate only
%   4 symbols for 1,2 Tx ant, 2sym for 3,4 Tx ant
hp = complex(zeros(2*Nrb, 4, numTx, numRx)); 
% h are the packed coefficients per link for the length of numDataResources.
h = complex(zeros(numDataResources, numTx, numRx));
len = size(Rx, 1);
delta = complex(zeros(1));

% Average over the two same Freq subcarriers, and then interpolate between
% them - get all 12 estimates and then repeat over all columns (symbols).
%   For 3,4 Tx ant - no averaging, just interpolate over an F column and repeat.
%   The interpolation assmues NCellID = 0.                       
if (numTx == 2)
    % For 2 antenna ports, assuming 20Mhz (100 Nrb) BW allocation
    %   Rx - 1600x2 => 400*2*2x2 -> samples*2symbols*2slots*2ports
    %   Ref - 220x2x2x2 -> samples*2symbols*2slots*2ports
    %       offset to use only 200 off the 220    
    for j = 1:numRx
        % Per Rx antenna
        csrRx = reshape(Rx(:, j), len/4, 4); % 400x4
        %   process per RB
        for i = 1:Nrb
            csrRefRB = Ref((2*(i-1)+1:2*i)+NmaxDL_RB-Nrb, :, :, :); % 2x2x2x2
            csrRxRB  = csrRx(4*(i-1)+1:4*i, :);  % 4x4
            
            % First slot
            % Section 1 - hx_y => x is Tx number, y is section number per Rx
            h1_1 = csrRxRB(1, 1)/csrRefRB(1, 1, 1, 1);
            h2_1 = csrRxRB(2, 1)/csrRefRB(1, 1, 1, 2);
            
            % Section 2 - hx_y => x is Tx number, y is section number per Rx
            h1_2 = csrRxRB(3, 1)/csrRefRB(2, 1, 1, 1);
            h2_2 = csrRxRB(4, 1)/csrRefRB(2, 1, 1, 2);
            
            % Section 3 - hx_y => x is Tx number, y is section number per Rx
            h1_3 = csrRxRB(2, 2)/csrRefRB(1, 2, 1, 1);
            h2_3 = csrRxRB(1, 2)/csrRefRB(1, 2, 1, 2);
            
            % Section 4 - hx_y => x is Tx number, y is section number per Rx
            h1_4 = csrRxRB(4, 2)/csrRefRB(2, 2, 1, 1);
            h2_4 = csrRxRB(3, 2)/csrRefRB(2, 2, 1, 2);
            
            % Second slot
            % Section 5 - hx_y => x is Tx number, y is section number per Rx
            h1_5 = csrRxRB(1, 3)/csrRefRB(1, 1, 2, 1);
            h2_5 = csrRxRB(2, 3)/csrRefRB(1, 1, 2, 2);
            
            % Section 6 - hx_y => x is Tx number, y is section number per Rx
            h1_6 = csrRxRB(3, 3)/csrRefRB(2, 1, 2, 1);
            h2_6 = csrRxRB(4, 3)/csrRefRB(2, 1, 2, 2);
            
            % Section 7 - hx_y => x is Tx number, y is section number per Rx
            h1_7 = csrRxRB(2, 4)/csrRefRB(1, 2, 2, 1);
            h2_7 = csrRxRB(1, 4)/csrRefRB(1, 2, 2, 2);
            
            % Section 8 - hx_y => x is Tx number, y is section number per Rx
            h1_8 = csrRxRB(4, 4)/csrRefRB(2, 2, 2, 1);
            h2_8 = csrRxRB(3, 4)/csrRefRB(2, 2, 2, 2);

            % Package pilot estimates
            hp((i-1)*2+1:i*2, :, 1, j) = [h1_1 h1_3 h1_5 h1_7; h1_2 h1_4 h1_6 h1_8];
            hp((i-1)*2+1:i*2, :, 2, j) = [h2_1 h2_3 h2_5 h2_7; h2_2 h2_4 h2_6 h2_8];
        end % for i = 1:Nrb
        
        % Time average two pilots over the slots, then interpolate (F)
        % between the 4 averaged values, repeat for all symbols in sframe
        %   Have all the pilot estimates over the subframe
        % For First antenna port processing
        h1_a1 = mean([hp(:, 1, 1, j) hp(:, 3, 1, j)],2);
        h1_a2 = mean([hp(:, 2, 1, j) hp(:, 4, 1, j)],2);
        h1_a_mat = [h1_a1 h1_a2].';
        h1_a = h1_a_mat(:);
        
        h1_all = complex(zeros(length(h1_a)*3,1));
        for i = 1:length(h1_a)-1
            delta = (h1_a(i+1)-h1_a(i))/3;
            h1_all((i-1)*3+1) = h1_a(i);
            h1_all((i-1)*3+2) = h1_a(i)+delta;
            h1_all((i-1)*3+3) = h1_a(i)+2*delta;
        end
        % fill the last three - use the last delta
        h1_all(end-2) = h1_a(end);
        h1_all(end-1) = h1_a(end)+delta;
        h1_all(end) = h1_a(end)+2*delta;
        
        h1_d_mat = reshape(h1_all, 12, length(h1_all)/12);
        h1_d_rmat = h1_d_mat([2:3 5:6 8:9 11:12], :);
        h1_d = h1_d_rmat(:);
        h1_slot = [h1_d; h1_all; h1_all; h1_all; h1_d; h1_all; h1_all];
        h1_sf = [h1_slot; h1_slot];
        h(:, 1, j) = h1_sf;

        % For Second antenna port processing
        h2_a2 = mean([hp(:, 1, 2, j) hp(:, 3, 2, j)],2);
        h2_a1 = mean([hp(:, 2, 2, j) hp(:, 4, 2, j)],2);
        h2_a_mat = [h2_a1 h2_a2].';
        h2_a = h2_a_mat(:);
        
        h2_all = complex(zeros(length(h2_a)*3,1));
        for i = 1:length(h2_a)-1
            delta = (h2_a(i+1)-h2_a(i))/3;
            h2_all((i-1)*3+1) = h2_a(i);
            h2_all((i-1)*3+2) = h2_a(i)+delta;
            h2_all((i-1)*3+3) = h2_a(i)+2*delta;
        end
        % fill the last three - use the last delta
        h2_all(end-2) = h2_a(end);
        h2_all(end-1) = h2_a(end)+delta;
        h2_all(end) = h2_a(end)+2*delta;
        
        h2_d_mat = reshape(h2_all, 12, length(h2_all)/12);
        h2_d_rmat = h2_d_mat([2:3 5:6 8:9 11:12], :);
        h2_d = h2_d_rmat(:);
        h2_slot = [h2_d; h2_all; h2_all; h2_all; h2_d; h2_all; h2_all];
        h2_sf = [h2_slot; h2_slot];
        h(:, 2, j) = h2_sf;

    end % for j = 1:numRx

elseif (numTx == 4)
    % For 4 antenna ports, assuming 20Mhz (100 Nrb) BW allocation
    %   Rx - 2400x4 => 400*3*2x4 -> samples*3symbols*2slots*4ports
    %   Ref - 220x2x2x4 -> samples*2symbols*2slots*4ports
    %       offset to use only 200 off the 220    
    for j = 1:numRx
        % Per Rx antenna
        csrRx = reshape(Rx(:, j), len/6, 6); % 400x6
        %   process per RB
        for i = 1:Nrb
            csrRefRB = Ref((2*(i-1)+1:2*i)+NmaxDL_RB-Nrb, :, :, :); % 2x2x2x4
            csrRxRB  = csrRx(4*(i-1)+1:4*i, :);  % 4x6
            
            % First slot
            % Section 1 - hx_y => x is Tx number, y is section number per Rx
            h1_1 = csrRxRB(1, 1)/csrRefRB(1, 1, 1, 1);
            h2_1 = csrRxRB(2, 1)/csrRefRB(1, 1, 1, 2);
            h3_1 = csrRxRB(1, 2)/csrRefRB(1, 1, 1, 3);
            h4_1 = csrRxRB(2, 2)/csrRefRB(1, 1, 1, 4);
            
            % Section 2 - hx_y => x is Tx number, y is section number per Rx
            h1_2 = csrRxRB(3, 1)/csrRefRB(2, 1, 1, 1);
            h2_2 = csrRxRB(4, 1)/csrRefRB(2, 1, 1, 2);
            h3_2 = csrRxRB(3, 2)/csrRefRB(2, 1, 1, 3);
            h4_2 = csrRxRB(4, 2)/csrRefRB(2, 1, 1, 4);
            
            % Section 3 - hx_y => x is Tx number, y is section number per Rx
            h1_3 = csrRxRB(2, 3)/csrRefRB(1, 2, 1, 1);
            h2_3 = csrRxRB(1, 3)/csrRefRB(1, 2, 1, 2);
            
            % Section 4 - hx_y => x is Tx number, y is section number per Rx
            h1_4 = csrRxRB(4, 3)/csrRefRB(2, 2, 1, 1);
            h2_4 = csrRxRB(3, 3)/csrRefRB(2, 2, 1, 2);
            
            % Second slot
            % Section 5 - hx_y => x is Tx number, y is section number per Rx
            h1_5 = csrRxRB(1, 4)/csrRefRB(1, 1, 2, 1);
            h2_5 = csrRxRB(2, 4)/csrRefRB(1, 1, 2, 2);
            h3_5 = csrRxRB(2, 5)/csrRefRB(1, 1, 2, 3);
            h4_5 = csrRxRB(1, 5)/csrRefRB(1, 1, 2, 4);
            
            % Section 6 - hx_y => x is Tx number, y is section number per Rx
            h1_6 = csrRxRB(3, 4)/csrRefRB(2, 1, 2, 1);
            h2_6 = csrRxRB(4, 4)/csrRefRB(2, 1, 2, 2);
            h3_6 = csrRxRB(4, 5)/csrRefRB(2, 1, 2, 3);
            h4_6 = csrRxRB(3, 5)/csrRefRB(2, 1, 2, 4);
            
            % Section 7 - hx_y => x is Tx number, y is section number per Rx
            h1_7 = csrRxRB(2, 6)/csrRefRB(1, 2, 2, 1);
            h2_7 = csrRxRB(1, 6)/csrRefRB(1, 2, 2, 2);
            
            % Section 8 - hx_y => x is Tx number, y is section number per Rx
            h1_8 = csrRxRB(4, 6)/csrRefRB(2, 2, 2, 1);
            h2_8 = csrRxRB(3, 6)/csrRefRB(2, 2, 2, 2);

            % Package pilot estimates
            hp((i-1)*2+1:i*2, :, 1, j) = [h1_1 h1_3 h1_5 h1_7; h1_2 h1_4 h1_6 h1_8];
            hp((i-1)*2+1:i*2, :, 2, j) = [h2_1 h2_3 h2_5 h2_7; h2_2 h2_4 h2_6 h2_8];
            % Only half the pilot symbols for 3, 4 antennas
            hp((i-1)*2+1:i*2, 1:2, 3, j) = [h3_1 h3_5; h3_2 h3_6];
            hp((i-1)*2+1:i*2, 1:2, 4, j) = [h4_1 h4_5; h4_2 h4_6];

        end %for i = 1:Nrb

        % Time average two pilots over the slots, then interpolate (F)
        % between the 4 averaged values, repeat for all symbols in sframe
        %   Have all the pilot estimates over the subframe
        % For First antenna port processing
        h1_a1 = mean([hp(:, 1, 1, j) hp(:, 3, 1, j)],2);
        h1_a2 = mean([hp(:, 2, 1, j) hp(:, 4, 1, j)],2);
        h1_a_mat = [h1_a1 h1_a2].';
        h1_a = h1_a_mat(:);
        
        h1_all = complex(zeros(length(h1_a)*3,1));
        for i = 1:length(h1_a)-1
            delta = (h1_a(i+1)-h1_a(i))/3;
            h1_all((i-1)*3+1) = h1_a(i);
            h1_all((i-1)*3+2) = h1_a(i)+delta;
            h1_all((i-1)*3+3) = h1_a(i)+2*delta;
        end
        % fill the last three - use the last delta
        h1_all(end-2) = h1_a(end);
        h1_all(end-1) = h1_a(end)+delta;
        h1_all(end) = h1_a(end)+2*delta;
        
        h1_d_mat = reshape(h1_all, 12, length(h1_all)/12);
        h1_d_rmat = h1_d_mat([2:3 5:6 8:9 11:12], :);
        h1_d = h1_d_rmat(:);
        h1_slot = [h1_d; h1_d; h1_all; h1_all; h1_d; h1_all; h1_all];
        h1_sf = [h1_slot; h1_slot];
        h(:, 1, j) = h1_sf;

        % For Second antenna port processing
        h2_a2 = mean([hp(:, 1, 2, j) hp(:, 3, 2, j)],2);
        h2_a1 = mean([hp(:, 2, 2, j) hp(:, 4, 2, j)],2);
        h2_a_mat = [h2_a1 h2_a2].';
        h2_a = h2_a_mat(:);
        
        h2_all = complex(zeros(length(h2_a)*3,1));
        for i = 1:length(h2_a)-1
            delta = (h2_a(i+1)-h2_a(i))/3;
            h2_all((i-1)*3+1) = h2_a(i);
            h2_all((i-1)*3+2) = h2_a(i)+delta;
            h2_all((i-1)*3+3) = h2_a(i)+2*delta;
        end
        % fill the last three - use the last delta
        h2_all(end-2) = h2_a(end);
        h2_all(end-1) = h2_a(end)+delta;
        h2_all(end) = h2_a(end)+2*delta;
        
        h2_d_mat = reshape(h2_all, 12, length(h2_all)/12);
        h2_d_rmat = h2_d_mat([2:3 5:6 8:9 11:12], :);
        h2_d = h2_d_rmat(:);
        h2_slot = [h2_d; h2_d; h2_all; h2_all; h2_d; h2_all; h2_all];
        h2_sf = [h2_slot; h2_slot];
        h(:, 2, j) = h2_sf;
        
        % For third antenna port processing
        %   No averaging - only interp here using the 4 pilots
        h3_mat = hp(:, 1:2, 3, j).';
        h3 = h3_mat(:);

        h3_all = complex(zeros(length(h3)*3,1));
        for i = 1:length(h3)-1
            delta = (h3(i+1)-h3(i))/3;
            h3_all((i-1)*3+1) = h3(i);
            h3_all((i-1)*3+2) = h3(i)+delta;
            h3_all((i-1)*3+3) = h3(i)+2*delta;
        end
        % fill the last three - use the last delta
        h3_all(end-2) = h3(end);
        h3_all(end-1) = h3(end)+delta;
        h3_all(end) = h3(end)+2*delta;
        
        h3_d_mat = reshape(h3_all, 12, length(h3_all)/12);
        h3_d_rmat = h3_d_mat([2:3 5:6 8:9 11:12], :);
        h3_d = h3_d_rmat(:);
        h3_slot = [h3_d; h3_d; h3_all; h3_all; h3_d; h3_all; h3_all];
        h3_sf = [h3_slot; h3_slot];
        h(:, 3, j) = h3_sf;
        
        % For fourth antenna port processing
        %   No averaging - only interp here using the 4 pilots
        h4_mat = hp(:, 1:2, 4, j).';
        h4 = h4_mat(:);

        h4_all = complex(zeros(length(h4)*3,1));
        for i = 1:length(h4)-1
            delta = (h4(i+1)-h4(i))/3;
            h4_all((i-1)*3+1) = h4(i);
            h4_all((i-1)*3+2) = h4(i)+delta;
            h4_all((i-1)*3+3) = h4(i)+2*delta;
        end
        % fill the last three - use the last delta
        h4_all(end-2) = h4(end);
        h4_all(end-1) = h4(end)+delta;
        h4_all(end) = h4(end)+2*delta;
        
        h4_d_mat = reshape(h4_all, 12, length(h4_all)/12);
        h4_d_rmat = h4_d_mat([2:3 5:6 8:9 11:12], :);
        h4_d = h4_d_rmat(:);
        h4_slot = [h4_d; h4_d; h4_all; h4_all; h4_d; h4_all; h4_all];
        h4_sf = [h4_slot; h4_slot];
        h(:, 4, j) = h4_sf;

    end %for j = 1:numRx
    
end % if numTx

% [EOF]
