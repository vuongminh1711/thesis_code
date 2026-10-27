%% LTE PHY Downlink with Spatial Multiplexing
%
% This example shows the Downlink Shared Channel (eNodeB to UE) physical
% layer (PHY) processing of the Long Term Evolution (LTE) wireless
% communication system [ <#24 1-3>, <#24 7> ].
%
% This example includes:
%
% * A Simulink(R) implementation, using both Simulink blocks and MATLAB(R)
% System objects from the Communications System Toolbox(TM):
% <matlab:LTEDownlinkExample LTEDownlinkExample.slx>
% * A component Simulink model highlighting only the downlink physical
% channel (PDSCH) processing: <matlab:LTEPDSCHExample LTEPDSCHExample.slx>
% * A component Simulink model highlighting only the downlink transport
% channel (DL-SCH) processing: <matlab:LTEDLSCHExample LTEDLSCHExample.mdl>
% * A MATLAB implementation using System objects from the Communications
% System Toolbox, employing sphere decoding:
% <matlab:edit([matlabroot,'\toolbox\comm\commdemos\LTEPDSCHwSphereDecodingSim.m'])
% LTEPDSCHwSphereDecodingSim.m>.
%
% Refer to the <http://www.mathworks.com/products/lte-system/ LTE System
% Toolbox(TM)> product and its set of
% <http://www.mathworks.com/products/lte-system/code-examples.html code
% examples> for specialized LTE compliant building components in MATLAB.
% Relevant examples from the LTE System Toolbox include:
%
% * <http://www.mathworks.com/help/lte/examples/pdsch-2x2-spatial-multiplexing-throughput-conformance-test.html 
% PDSCH 2x2 Spatial Multiplexing Throughput Conformance Test>
% * <http://www.mathworks.com/help/lte/examples/release-10-pusch-multiple-codeword-throughput-conformance-test.html
% Release 10 PUSCH Multiple Codeword Throughput Conformance Test>
%
% *Keywords:* LTE, MIMO-OFDM, spatial multiplexing, codebook-based
%             precoding, MMSE, rate-matching, turbo coding, sphere
%             decoding.

%   Copyright 2012-2014 The MathWorks, Inc. 

%% 

% CD to temp folder
currDir = pwd;
tmpDir = tempdir;
cd(tmpDir);

mdlName = 'LTEDownlinkExample';
open_system(mdlName);
% Turn off result plots
set_param([mdlName '/Model Parameters'], 'showResults', 'off');
sim(mdlName)

%% Introduction 
%
% Using the Release 10 specifications of LTE-Advanced (the 4G air interface
% for mobile communications), this example highlights a multi-antenna
% transmission scheme that enables dowlink peak data rates in excess of
% 1Gbps. It employs a multi-codeword spatial multiplexed transmission using
% closed-loop codebook-based precoding. Using multiple antennas at both
% transmitter and receiver, the example shows the Release 10 (compatible
% with Release 8) modes of 2-by-2 and 4-by-4 antenna configurations using
% UE category 5 parameters. The 4-by-4 mode allows for up to a 300 Mbps
% downlink transmission rate.
%
% The key components highlighted in the example include
%
% * Variable-size payload generation
% * CRC insertion per tranport block
% * Code-block segmentation with per code-block CRC insertion
% * Channel (turbo) coding
% * Rate matching with bit selection
% * Bit-level scrambling
% * Data modulation (QPSK, 16QAM or 64QAM)
% * Layer mapping for two and four antennas
% * Codebook-based precoding
% * Resource-element mapping and
% * OFDM signal generation
%
% In addition to the above, the example models a receiver that uses
%
% * Least-squares channel estimation with interpolation
% * Minimum-mean-squared-error (MMSE) based criteria for codebook selection
% when precoding matrix indicator (PMI) feedback is enabled,
% * MMSE-based linear MIMO receiver, and
% * Two-stage early termination channel decoder [ <#24 8> ].
%
% The Simulink model uses colors to highlight the purpose of the different
% model components:
%
% * blocks highlighted in orange correspond to the downlink channel
% processing components,
% * blocks highlighted in light blue correspond to the modeling harness,
% * blocks highlighted in cyan aid in verification and visualization, and
% * blocks in yellow allow for user interaction.
%
% The model highlights the frequency division duplex (FDD) mode of the
% specifications and thus uses a radio frame of 10ms composed of 10
% subframes. Each subframe of 1ms duration has two consecutive slots.
%
% <<LTEDownlinkExample_FS1.png>>
%
% The Simulink model processes one subframe per time step.
%
% The downlink shared channel processing at the base station (eNodeB)
% includes transport channel processing and physical channel processing
% (PDSCH), with corresponding duality at the receiver (UE) to retrieve the
% transmitted data bits. The following sub-sections briefly describe the
% processing involved, with reference to the relevant sections of the
% specifications [ <#24 1-6> ].

%% Transport Channel Processing
% 
% Transport channels provide the interface between the MAC layer and the
% physical layer. The Downlink Shared Channel (DL-SCH) is the main downlink
% transport channel type in LTE. It is used for both user data and
% dedicated control information as well as part of downlink system
% information.
%
% This example models a two codeword transmission, i.e. two transport
% blocks per transmission time interval (TTI), with both codewords having
% the same size, modulation and code rate. Each codeword corresponds to a
% single transport block.

%%
% *CRC insertion per transport block*
%
% The example calculates and appends a 24-bit CRC to each generated
% transport block. This allows for detection of errors at the receive end
% for the decoded block.

%%
% *Code-block segmentation and per code-block CRC insertion*
%
% Due to the turbo-coding interleaver block lengths supported by LTE (a
% maximum of 6144 bits), any transport block that exceeds this size is
% segmented into smaller code-blocks. Based on the link parameters
% configured and the transport block size determined, the example
% determines the number of segments (code-blocks) and processes them
% sequentially (|TB Channel Coding| blocks). Based on the sizes that
% Section 7.1.7.2 of [ <#24 3> ] specifies, no filler bits are
% necessary as part of the segmentation process. For multiple code-blocks
% per transport block, the example calculates and appends a 24-bit CRC to
% each code block. This allows for early detection of correctly decoded
% code blocks, and, as a result, early termination of the iterative decoding
% for that code block. Refer to <matlab:doc('commLTETurboDecoder')
% commLTETurboDecoder>  - a MATLAB-authored System object which implements
% the decoding per code-block.

%%
% *Channel coding*
%
% DL-SCH uses turbo coding as the channel coder. The <commpccc.html
% Parallel Concatenated Convolutional Coding: Turbo Codes> example
% describes this further in detail.

%%
% *Rate Matching*
%
% Rate matching extracts the exact set of bits to be transmitted within a
% subframe from the encoded bits. This example implements the sub-block
% interleaving, creation of the circular buffer and the actual bit
% selection using UE Category 5 parameters (Table 4.1-1 of [ <#24 5> ]).
% The multiple code-blocks are then concatenated together for downstream
% physical channel processing.

%% Physical Channel (PDSCH) Processing
%
% A physical channel corresponds to a set of time-frequency resources used
% for transmission of a particular transport channel. Each transport
% channel maps to a corresponding physical channel. The Physical
% Downlink Shared Channel (PDSCH) is the main physical channel used for
% unicast data transmission. This example uses spatial multiplexed
% codebook-based transmission, and, as a result, the downlink physical
% channel processing includes:

%%
% *Scrambling*
%
% The transport channel encoded bits are scrambled by a bit-level
% scrambling sequence (Section 7.2 and 6.3.1 of [ <#24 1> ]).
% The scrambling sequence depends on the physical layer cell identity to
% ensure interference randomization between cells. For the single-user
% single cell downlink transmission, the example assumes a cell ID, but
% differentiates the sequence per transmitted codeword.

%%
% *Data Modulation*
%
% Downlink data modulation converts the scrambled bits into complex
% modulated symbols. The set of modulation schemes supported include QPSK,
% 16QAM and 64QAM, corresponding to two, four, and six bits per modulation
% symbol respectively (Section 7.1 and 6.3.2 of [ <#24 1> ]). The
% modulation scheme is chosen by the *PDSCH modulation type* parameter on
% the |Model Parameters| block.

%%
% *Layer Mapping*
%
% The complex modulated symbols from both codewords are mapped to layers
% (antenna ports) as per Section 6.3.3.2 of [ <#24 1> ]. Since full rank
% transmission is assumed, the number of layers is equal to the number of
% transmit antennas (the latter determined from the *Antenna configuration*
% parameter on the |Model Parameters| block).

%%
% *Codebook-based Precoding*
%
% The modulated symbols per layer are precoded using the codebooks
% specified in Section 6.3.4.2 of [ <#24 1> ]. For two antennas (layers),
% the DFT-based codebook is used which allows for only two entries, while
% for four antennas (layers) 16 entries from the Householder matrix are
% used. The parameters *Enable PMI feedback* and *Codebook index* on the
% |Model Parameters| block allow selection of the codebook based on
% feedback from UE or initial user-specification. This example does not
% model any of the control signals used to convey the codebook index from
% eNodeB to UE and in the case of feedback, from UE back to eNodeB (i.e.
% assumes an error free transmission for the index).

%%
% *Resource Element Mapping*
%
% The precoded symbols to be transmitted on each antenna are mapped to the
% resource elements of the resource blocks available for
% transmission. The number of available resource blocks is a function of
% the *Channel bandwidth* parameter on the |Model Parameters| block, as per
% the table below (reproduced from [ <#24 6> ])
%
% <<LTEDownlinkExample_nrb.png>>
%
% For the chosen configuration, each resource block corresponds to 12
% sub-carriers, which at 15 KHz subcarrier spacing amounts to 180 KHz of
% spectrum. Hence, at 20 MHz channel bandwidth, the 100 available resource
% blocks occupy 18 MHz of channel bandwidth.
%
% The actual number of data symbols mapped to resource elements per
% subframe depends on the
%
% * resource elements occupied by Cell-Specific Reference (CSR) signals
% used for channel estimation
% * control signaling region (PDCCH)
% * resource elements occupied by primary (PSS) and secondary (SSS)
% synchronization signals
% * resource elements occupied by transmission of the broadcast channel
% (PBCH).
%
% Since some of these signals are not transmitted every subframe, the size
% of the data payload varies over the subframes in a radio frame.

%%
% *Cell-Specific Reference Signals*
%
% The most basic of the LTE reference signals, Cell-Specific Reference
% (CSR) signals are specified for one, two, or four antennas in a cell and
% used for channel estimation at the receiver.
%
% This example models the structure of CSR signals, per resource block,
% used for two and four antennas, as shown below (reproduced from [ <#24 1>
% ])
%
% <<LTEDownlinkExample_csr.png>>
%
% Note that for the resource element carrying the reference signal for an
% antenna, the corresponding resource elements in other antennas have null
% transmissions. This allows the CSR signals to transmit without
% interference from the other antenna transmissions.
%
% Also observe the reference-symbol density of the reference signals for
% third and fourth antennas is lower, compared to the density of the first
% and second antennas. This has the effect of reducing the overhead for
% higher number of antennas and also limiting the ability to track fast
% channel variations.

%%
% *OFDM Transmission*
%
% The complex-valued time-domain OFDM signal per antenna is generated from
% the fully populated resource grid, using the OFDM Modulator block. The
% number of FFT points depends on the channel bandwidth specified, as per
% Table F.5.3-1 of [ <#24 4> ]. For normal cyclic prefix, the seven OFDM
% symbols in a slot use different cyclic prefix lengths.

%% MIMO Channel Model
%
% The |MIMO Fading Channel| block implements the MIMO fading profiles as
% per Annex B.2 of [ <#24 4> ]. The higher mobility profiles are excluded
% as the closed-loop spatial multiplexing mode would be applicable to high
% data rate and low mobility scenarios only. It uses the
% <matlab:doc('comm.LTEMIMOChannel') comm.LTEMIMOChannel> System object and
% the <matlab:doc('comm.MIMOChannel') comm.MIMOChannel> System object, with
% low correlation setting between the multiple links.
%
% Refer to the accompanying component model <matlab:LTEPDSCHExample
% LTEPDSCHExample.slx> for parameteric control of the correlation levels
% for LTE MIMO channel profiles.
 
%% Receiver (UE) Processing
%
% The main elements of the receiver processing (at the UE) modeled in this
% example include:
%
% *OFDM receiver* - undoes the unequal cyclic prefix lengths per OFDM
% symbol in a slot and converts back to the time- and frequency-domain grid
% structure, using the OFDM Demodulator block.
%
% *MIMO receiver* subsystem which includes:
%
% # *Channel Estimation* employs least-squares estimation using averaging
% over a subframe for noise reduction for the reference signals, and linear
% interpolation over the subcarriers for the data elements. This uses the
% CSR signals for the channel estimates.
% # *Codebook selection* employs the minimum-mean-squared-error (MMSE)
% criterion to calculate the codebook index per subframe [ <#24 9> ]. When
% the *Enable PMI Feedback* parameter is on, this index is fed back to the
% transmitter for use at the next time step. Otherwise, the user-specified
% codebook index is used for the duration of the simulation. The feedback
% granularity modeled is once for the whole subframe (wideband) and applied 
% to the next transmission subframe.
% # *MIMO receiver* employs a linear MMSE receiver to combat the
% interference from the multiple antenna transmissions.
%
% *Soft-decision demodulation* is employed per codeword to facilitate
% downstream turbo decoding.
%
% *Two-stage early termination channel decoding* to decode the received
% blocks of data (|TB Channel Decoding| blocks). The *Disable
% transport-block level early termination* parameter on the |Model
% Parameters| block controls whether to fully decode the transport block.
% The per code-block early termination of the iterative decoding is always
% on. Refer to the accompanying component model <matlab:LTEDLSCHExample
% LTEDLSCHExample.mdl> for direct parametric control on the transport
% block length, the two-stage decoding and its effect on simulation.

%% Assumptions and Simplifications
%
% For the simulation, the following assumptions and simplifications are
% made:
%
% * Single-user downlink transmission (NcellID = 0, RNTI = 1)
% * No HARQ support (redundancy version number, rvIdx = 0)
% * Normal cyclic prefix which specifies seven OFDM symbols per slot
% * Full bandwidth data allocation based on user selection of the channel
% bandwidth via the |Model Parameters| block
% * Constant, user-specifiable control region for the duration of the
% simulation
% * Localized resource mapping only
% * Resource grid filling accounts for PDCCH, PBCH channels and PSS, SSS
% signals but does not model the individual signals. This allows for data
% throughput measurements without affecting the receiver processing for the
% data symbols.
% * Full rank modeling only, i.e. a 2-by-2 antenna configuration has 2 layers
% and a 4-by-4 antenna configuration has 4 layers. As a consequence, rank
% estimation is not modeled.
% * The transport block size is predetermined based on the specified
% parameters, using _min|R -(A+24)/N|_ where _R_ is the target coding rate,
% _A_ is the transport block size as per Section 7.1.7.2 of [ <#24 3> ] and
% _N_ is the number of PDSCH data bits available for the given allocation
% and configuration.
% * Baseband processing only with no RF component modeling.
% * Aside from the feedback of the precoding matrix indicator and
% variable-size data payloads, the model does not adapt any other
% attribute during a simulation run.

%% Results and Displays
%
% For the chosen parameters, the following displays validate and verify the
% modeling during simulation:
%
% * Bit error rate meters for PDSCH bits per codeword (PBER)
% * Block error rate meters for the transport blocks (BLER)
% * Bit error rate meters for the data bits per codeword (CBER)
% * Received signal scatter plots per received antenna after OFDM receiver
% processing 
%
% <<LTEDownlinkExample_scp1.png>>
%
% and after MIMO receiver processing. 
%
% <<LTEDownlinkExample_scp2.png>>
%
% The figures above show the results for the default configuration of the
% model. Comparing the two sets of plots enables you to gauge the signal
% separation the MIMO receiver achieves, which directly impacts the
% PDSCH bit error rate performance.

%%
% * Transmitted and received signal spectrum. Comparing both the spectrum 
% plots per subframe highlights the frequency selectivity in the fading 
% channel over time. Note that only the last OFDM symbol in a subframe is 
% displayed. 
%
% <<LTEDownlinkExample_spectrum.png>>
%
% * Codebook index signal scope - allows you to see the variation in the 
% applied codebook when feedback is enabled
% * Maximum throughput per codeword over a simulation run
% 
% Upon completion of the simulation, two 3D plots display the number of
% decoding iterations used per code-block per transport block over time
% (less than or equal to the maximum default value of eight). 
%
% <<LTEDownlinkExample_iters1.png>>
%
% <<LTEDownlinkExample_iters2.png>>

%% 
% These plots help you validate the maximum decoding iterations parameter
% value used for turbo decoding. 
%
% Also, the workspace variables _cbFlags1_ and _cbFlags2_ hold the error
% status for each code-block per transport block over time (1 for an error,
% 0 for no error, for each of the code blocks in the transport blocks). For
% the example's default settings, observe the transport blocks in error per
% codeword, for the whole simulation run.

errCW1 = cbFlags1(find(sum(squeeze(cbFlags1).')>0), :) %#ok

errCW2 = cbFlags2(find(sum(squeeze(cbFlags2).')>0), :) %#ok

%%
% These values also match the displayed transport block error rate per
% codeword.

%% Further Exploration
%
% This example offers insight into the required processing of the
% 4G LTE system with some parameter control on the transmitter, channel and
% receiver subsystems. It enables one to study the dependent attributes and
% their effect on the link performance with bit error rate and block error
% rate as the figure of merits. The example showcases features such as
%
% * Variable-sized signals in Simulink,
% * Communications System Toolbox System objects and blocks,
% * MATLAB-authored System objects, and
% * MATLAB Function block for simpler control flow modeling in Simulink.
%
% Some areas of user exploration include
%
% * Use the |Model Parameters| block to configure different fixed reference
% measurement channels as per Tables A.3.3.2.1-1 and A.3.3.2.2-1 of [ <#24
% 4> ] and analyze the system performance for different channel conditions
% and receiver parameters. Since the example does not model the
% transmission of system information blocks (SIB) in subframe 5, the
% throughput measures are higher for the example than shown in the tables.
% Also for four antenna ports, since Table A.3.3.2.2-1 assumes transmit
% diversity, the payload sizes are different for the example.
% * Use the component model <matlab:LTEPDSCHExample LTEPDSCHExample.slx> to
% analyze the physical channel processing without the effects of channel
% coding. It additionally offers control of the correlation levels between
% the multiple fading links and allows you to assess the BER performance
% over the multiple LTE MIMO channel profiles.
% * Use the component model <matlab:LTEDLSCHExample LTEDLSCHExample.mdl> to
% analyze the transport channel processing without the effects of physical
% channel processing. It additionally offers control on the transport block
% length allowing verification of the channel coding at the individual
% code-block level.
% * Experiment with the alternate algorithms provided (e.g. codebook
% selection criteria and/or the linear MIMO receiver functions) by
% uncommenting the code or trying one of your own. The use of MATLAB code
% enables you to study the existing implementation and modify algorithms
% with ease.
%
% For complete LTE link modeling in MATLAB, including uplink processing and
% TDD support, refer to the <http://www.mathworks.com/products/lte-system/
% LTE System Toolbox> product.

close_system(mdlName, 0);
cd(currDir);

%% Selected References
% # 3GPP Technical Specification Group Radio Access Network; Evolved
% Universal Terrestrial Radio Access (E-UTRA); Physical channels and
% Modulation (Release 10)", 3GPP TS 36.211 v10.7.0 (2013-02)
% http://www.3gpp.org/ftp/Specs/html-info/36-series.htm.
% # 3GPP Technical Specification Group Radio Access Network; Evolved
% Universal Terrestrial Radio Access (E-UTRA); Multiplexing and channel
% coding (Release 10)", 3GPP TS 36.212 v10.8.0 (2013-06).
% # 3GPP Technical Specification Group Radio Access Network; Evolved
% Universal Terrestrial Radio Access (E-UTRA); Physical layer procedures
% (Release 10)", 3GPP TS 36.213 v10.12.0 (2014-03).
% # 3GPP Technical Specification Group Radio Access Network; Evolved
% Universal Terrestrial Radio Access (E-UTRA); User Equipment(UE) radio
% transmission and reception (Release 10)", 3GPP TS 36.101 v10.14.0
% (2014-03).
% # 3GPP Technical Specification Group Radio Access Network; Evolved
% Universal Terrestrial Radio Access (E-UTRA); User Equipment(UE) radio
% access capabilities (Release 10)", 3GPP TS 36.306 v10.11.0 (2013-12).
% # 3GPP Technical Specification Group Radio Access Network; Evolved
% Universal Terrestrial Radio Access (E-UTRA); Base station radio
% transmission and reception (Release 10)", 3GPP TS 36.104 v10.11.0
% (2013-07).
% # E. Dahlman, S. Parkvall, and J. Skold, "4G LTE/LTE-Advanced for Mobile
% Broadband", Elsevier, 2011.
% # Cheng, J.-F., "Two-Level Early Stopping Algorithm for LTE Turbo
% Decoding", IEEE 68th Vehicular Technology Conference, 2008, pp. 1-5.
% # D. J. Love & R. W. Heath, "Limited Feedback Unitary Precoding for
% Spatial Multiplexing Systems", IEEE Trans. Info. Theory, Vol. 51, No. 8,
% Aug 2005, pp. 2967-2976.

displayEndOfDemoMessage(mfilename)
