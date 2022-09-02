% LoRAmRIR
% 
% Compute the LoRA multichannel room impulse response (mRIR) of the room.
%
% input:
%   path        name of the path where the odeon text file is
%   room        string: name of the room (ex: 'Elmia RoundRobin2 detailed.Job03.00001')
%   renderDS    integer: Ambisonic order for the direct sound. 0 -> closest loudspeaker
%   renderER    integer: Ambisonic order for the early refelction. 0 -> closest loudspeaker
%
% output
%   out         matrix (samples,channels) multichannel RIR
%
% uses ReadEnergyCurves.m, ReadEarlyReflections.m, ReadParameters.m, fDS.m, fER.m and
% fLATE.m. 
%___________________________________
% $Revision: #3 $ 
%    - global LoRA removed, logdest added
%
% $Revision: #3 $ 
%    - no padding for the DS and ER (done in the function AddDSERlate)
%
% $Revision: #3 $ 
%    - Using the pseudo-inverse decoding matrix computed in LoRA_startup
%
% $Revision: #3 $ 
%    - Initial version.
%___________________________________
% (c) 2007 S. Favrot, CAHR

function [mIRearly,ylate,Param] = LoRAmRIR(path,room,renderDS,renderER,LoRA,move_ER,isylate,...
    logdest) %#ok<STOUT>

if nargin<5
    LoRA=LoRA_startup;
end
if nargin<6
    move_ER = 0;
end
if nargin<7
    isylate=1;
end
if nargin<8
    logdest=0;
end
writelog(logdest,'.')

LsLoRA_fname_Declared = LoRA.LoudSetName;
LsLoRA_Declared = eval(LsLoRA_fname_Declared);

% Load data form ODEON's ASCII files
try NRG     =   ReadEnergyCurves(path,room); catch NRG=0;isylate=0;warning('NolateReflectionFile'); end
ER      =   ReadEarlyReflections(path,room);
% assignin('base','ER',ER)

% ---------------------------------------------------------------------
if LoRA.ShiftFlag == 1 % Shift DS & ER to align with USyd HRTF data set points
    load pos_HRTFUSyd
    for iRefl = 1:size(ER,1)
        dEl = (pos_HRTFUSyd(:,2) - ER(iRefl,14))*pi/180; % 14th column is elevation of reflection in deg
        dAz = (pos_HRTFUSyd(:,1) - ER(iRefl,13))*pi/180; % 13th column is azimuth of reflection in deg
        dp = 2*asin(min(1,sqrt(sin(dEl/2).^2 + cos(pos_HRTFUSyd(:,2)*pi/180).*cos(ER(iRefl,14)*pi/180).*sin(dAz/2).^2)));
        [~,clPtIndx] = min(dp); % index of closest point in sphere200chChris layout
        ER(iRefl,13) = pos_HRTFUSyd(clPtIndx,1);
        ER(iRefl,14) = pos_HRTFUSyd(clPtIndx,2);
    end
end
% ---------------------------------------------------------------------

%%%If a parameter files has been exported from ODEON
try Param   =   ReadParameters(path,room); catch Param={}; end;

Param.DS    = ER(1,4:11); % The direct sound is assumed to be the first "reflection" in the reflectogram
Param.az    = ER(1,13);    
Param.el    = ER(1,14);

fc=10^3*(2.^(-4:3));%octave-filters centre frequency only for processing Odeon data
fbw=fc/sqrt(2);%octave bandwidths
fbw(1)=fc(1)*sqrt(2); 
fbw(end)=LoRA.fs/2-fc(end)/sqrt(2);
hsquare=fbw*2/LoRA.fs;

if size(ER,1)>1
    kDS = 2;
else 
    kDS = 0; % if no reflection
end

% ---------------------------------------------------------------------
if LoRA.ShiftFlag == 1 % Shift L/S layout to align with USyd HRTF data set points
    LsLoRA_Shifted = LsLoRA_Declared;
    for iLS = 1:size(LsLoRA_Declared,1)
        dEl = pos_HRTFUSyd(:,2)*pi/180 - LsLoRA_Declared(iLS,2);
        dAz = pos_HRTFUSyd(:,1)*pi/180 - LsLoRA_Declared(iLS,1);
        dp = 2*asin(min(1,sqrt(sin(dEl/2).^2 + ...
            cos(pos_HRTFUSyd(:,2)*pi/180).*cos(LsLoRA_Declared(iLS,2)).*sin(dAz/2).^2)));
        [~,clPtIndx] = min(dp); % index of closest to the iLS-th loudspeaker point from USyd HRTF data set
        LsLoRA_Shifted(iLS,1) = pos_HRTFUSyd(clPtIndx,1)*pi/180;
        LsLoRA_Shifted(iLS,2) = pos_HRTFUSyd(clPtIndx,2)*pi/180;
        pos = LsLoRA_Shifted;
    end
    save('LoudSet3D_HRTFUSyd','pos') % save layout points in .mat file
    LoRA.LoudSetName = 'LoudSet3D_HRTFUSyd_fcn'; % name of function that retrieves above points file
    LoRA.pos = pos;
end
% ---------------------------------------------------------------------

%%%Compute late reflections response
if isylate
    ylate_unnorm    = fLATE(LoRA,NRG,ER,LoRA.fs,0,logdest);
else
    ylate_unnorm    = 0;
end
Param.length    = size(ylate_unnorm,1);

writelog(logdest,'.')

% ---------------------------------------------------------------------
if LoRA.ShiftFlag == 1
    if renderDS*renderER == 0 % Use USyd HRTF data set points as layout for NLS (DS+ER) case
        load pos_HRTFUSyd
        pos = pos_HRTFUSyd*pi/180;
        save('LoudSet3D_HRTFUSyd_NLS','pos') % save layout points in .mat file
        LoRA.LoudSetName = 'LoudSet3D_HRTFUSyd_NLS_fcn'; % name of function that retrieves above points file
        LoRA.pos = pos;
    end
end
% ---------------------------------------------------------------------

% ---------------------------------------------------------------------
if renderDS*renderER ~= 0
    pos = eval(LoRA.LoudSetName);
    ovrlpERInd = 0;
    for iRefl = 1:size(ER,1)
        dEl = pos(:,2) - ER(iRefl,14)*pi/180; % 14th column is elevation of reflection in deg
        dAz = pos(:,1) - ER(iRefl,13)*pi/180; % 13th column is azimuth of reflection in deg
        dp = 2*asin(min(1,sqrt(sin(dEl/2).^2 + cos(pos(:,2)).*cos(ER(iRefl,14)*pi/180).*sin(dAz/2).^2)));
        [minAng,~] = min(dp); % min angle between given ER and closest loudspeaker
        if abs(minAng) < 1*pi/180
            ovrlpERInd = ovrlpERInd + 1;
        end
    end
    disp([num2str(ovrlpERInd) ' out of ' num2str(size(ER,1)) ' ('...
        num2str(round(ovrlpERInd/size(ER,1)*100)) '%)'...
        ' single reflections overlapping with one of the '...
        num2str(size(pos,1)) ' L/S of the array'])
end
% ---------------------------------------------------------------------

% Compute Direct sound response
for M = renderDS
    DS=ER(1,:);
    yDS     = fDS(LoRA,DS(1,:),LoRA.fs,M);
%     sd      = size(yDS,1);
    eval(['mIRearly.yDS',num2str(M),'=yDS;']);
end
writelog(logdest,'.')

% Compute early reflections response
if kDS
    for M = renderER
        yER     = fER(LoRA,ER(kDS:end,:),LoRA.fs,M,move_ER);
%         se      = size(yER,1);
        eval(['mIRearly.yER',num2str(M),'=yER;']);
    end 
end
% writelog(logdest,'\b\b\b')

%%%(Optional calculation of the output level
try

levtot  = sum(10.^(Param.SPL/10).*hsquare);
levDS   = sum(10.^(ER(1,4:11)/10).*hsquare);
Param.lev.inDS = 10*log10(levDS);
if kDS
    levER   = sum(sum(10.^(ER(kDS:end,4:11)/10)).*hsquare);
    Param.lev.inER = 10*log10(levER);
    levlate = levtot-levDS-levER;
else
    levlate = levtot-levDS;
end
Param.lev.inlate = 10*log10(levlate);
mlate   = sqrt(sum(sum(ylate,2).^2));
Param.lev.late = 20*log10(mlate);
catch
end
%)
ylate   = ylate_unnorm;
