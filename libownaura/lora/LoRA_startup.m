% LoRA_startup
%
% Initialize the Loudspeaker Room Auralization (LoRA) toolbox and creates the LoRA 
% structure. Need to be run at the beginning of your LoRA Matlab session.
%
% ex: LoRA_startup('session',SessionName) -> Read and Save files in a subfolder
% indicated by the string SessionName. (PathStoreIR, PathStoreConv and PathReadODEON)
%
% Description:
%       - Add directories containing mIR computation and resources functions 
%         to Matlab search path. (LoRA_addpath.m)
%       - Compute the filter bank impulse response (OctFiltBank.m)
%       - Load loudspeaker positions (LoudspeakersPos.m)
%       - Compute Ambisonic decoding matrix (using spherical harmonics functions: YmnsM.m)
%       - Pre-compute band pass noise if not done before
%
% Options:              Class:      default:    Description:
%       - fs                num     44100   Sampling frequency
%       - session           string  []      Name of the current session
%       - PathStoreIR       string  []      Path where Impulse responses are stored
%       - PathStoreConv     string  []      Path where Convolved sound are stored
%       - PathReadODEON     string  []      Path where room data text files are stored
%       - PathSoundSamples  string  []      Path where anechoic sound files are stored
%       - LoudSetName       string  []      m-file name containing azimuth and
%                                           elevation of the loudspeakers
%       - renderDS       	num     max     Selection of the Ambisonic order for DS
%       - renderER       	num     max     Selection of the Ambisonic order for DS
%       - rendering       	numcell {maxmax}Selection of the Amb order for convolution
%       - isnfc             Bool.   0       Near field coding for HOA
%       - LoudR             num     1.8     Loudspeaker array radius (used with NFC)
%
% Decoding matrix from :
%       Daniel, J., Nicol, R. & Moreau, S. (2003), ‘Further investigations of high order
% ambisonics and wavefield synthesis for holophonic sound imaging’, Presented
% at the AES 114th convention p. preprint 5788.
%
% uses LoRA_addpath.m, pathstore.m, OctFiltBank.m, YmnsM.m, LoudspeakersPos.m, 
%       preBpNoise.m 

%___________________________________
% $Revision: #3 $ 
%    - CalPath as input argument and in LoRA structure
%
% $Revision: #3 $ 
%    - Near field coding option for HOA (isnfc and LoudR)
%
% $Revision: #3 $ 
%    - 2D case taking into account (also changes in YmnsM and gm)
%
% $Revision: #3 $ 
%    - Computing of the decoding matrix, the filter bank and the bandpass noise.
%
% $Revision: #3 $ 
%    - Initial version.
%___________________________________
% (c) 2009 S. Favrot (sf@elektro.dtu.dk)
%       Center for Applied Hearing Research, (CAHR)
%       Technical University of Denmark (DTU)


function LoRAout=LoRA_startup(varargin)

v = 0;
% if nargout
%     v=0;
% else
%     v=1;
%     global LoRA
% end

if v,disp('_____________________'),end
if v,disp('LoRA initialisation...'),end

% Addpath
LoRA_addpath

%% Default values (depending on the loudspeaker setup)
pathstore           % Path definition
renderDS = 5; % HOA order of the direct sound; 0 corresponds to nearest-loudspeaker method
renderER = 5; % HOA order of the early reflections; 0 corresponds to nearest-loudspeaker method
rendering = [];
session = '';
LoudSetName = 'LoudspeakersPos3D_AVIL';
LoudR = 2.4; % loudspeaker array radius
isnfc = 0; % near field compensation
fs      = 48000;    % Sampling frequency
seed = 1;
ShiftFlag = 0;
ReverbFlag = 'All';
    

%% Argument values
if ~isempty(varargin)
    r = struct(varargin{:});
    try fs = r.fs;                                  catch    end 
    try session = [r.Session,filesep];              catch    end 
    try renderDS       = r.renderDS;                catch    end
    try renderER       = r.renderER;                catch    end
    try rendering       = r.rendering;              catch    end
    try PathStoreIR        = r.PathStoreIR;         catch    end
    try PathStoreConv      = r.PathStoreConv;       catch    end
    try PathReadODEON      = r.PathReadODEON;       catch    end
    try PathSoundSamples   = r.PathSoundSamples;    catch    end
    try LoudSetName        = r.LoudSetName ;        catch    end
    try LoudR        = r.LoudR ;        catch    end
    try isnfc        = r.isnfc ;        catch    end
   
    try seed = r.seed; % seed for rand noise generation (for Late part)
    catch
        seed = [];
    end
    
    try ShiftFlag = r.ShiftFlag; % if 1 it shifts ER and NLS layout to align
                                 % with the USyd HRTF data set points
    catch
        ShiftFlag = 0;
    end
    
    try ReverbFlag = r.ReverbFlag; % 'DE' for (DS+ER), 'L' for (Late) and
                                   % 'All' for (DS+ER+Late) [default]
    catch
        ReverbFlag = 'All';
    end
end;
if ~isempty(session)
    if v,disp(['session: ',session(1:end-1)]),end
else
    if v,disp('No session'),end
end

%% Load Log
pathlog = fullfile(fileparts(which(mfilename)), 'Log',filesep);

try
    history = load(fullfile(pathlog,'history.mat'));
catch
    history = struct('RoomsNames',{''},'RoomsSel',[],...
        'SoundsNames',{''},'SoundsSel',[]);
end


%% Filter
if v,disp(['fs: ',num2str(fs),' Hz']),end
% BP-filter bank
%%%[h,len]       = OctFiltBank(fs);
load BPfilters h
len = size(h,1);%length of BP filters
L = size(h,2);%number of frequency bands
H=fft(h);
if v,disp(['Filter length (BP filterbank): ',num2str(len)]),end

%% Derive the decoding matrix
s = which(LoudSetName);
if isempty(s)
    error([LoudSetName ,'.m, file not found.'])
else
    eval(['Loudset = ',LoudSetName,';'])    % Loudspeaker positions (in rad [theta, delta])
end
if size(Loudset,2)~=2
    error([LoudSetName ,'.m must return a 2-column array (in rad [theta, delta]).'])
end
nL = size(Loudset,1);
if sum(Loudset(:,2).^2) == 0
    isset2D = 1;
    if v,disp(['Loudset: ''',LoudSetName,''', horizontal-only (2D) ',num2str(nL),...
        '-loudspeaker array']),end
else
    isset2D = 0;
    if v,disp(['Loudset: ''',LoudSetName,''', full 3D ',num2str(nL),...
        '-loudspeaker array']),end
end
% For default Ambisonic order, use max possible
if isempty(renderDS) && isempty(renderER) 
    if isset2D
        renderDS = floor((nL-1)/2);
        renderER = renderDS;
    else
        renderDS = floor(sqrt(nL)-1);
        renderER = renderDS;
    end
end
rendering = [renderDS renderER];

for M = union(setdiff(union(renderDS,renderER ),0),1) % ambisonic order
    
    C = YmnsM(Loudset(:,1),Loudset(:,2),M,isset2D)';
%     if M==1
%         D = 1/nL*C';
%     else
        D = pinv(C);
%     end
    
    DecMat.D1{M} = D;                     % Low freq Decoding matrix: Basic
    
%     DecMat.D2{M} = D*diag(gm(M,isset2D)); 
    g = gm(M,isset2D);
    if isset2D
        E = sum((2*(0:M)+1).*g((2*(0:M)+1)).^2);
    else
        E = sum((2*(0:M)+1).*g(((0:M)+1).^2).^2);
    end
%     DecMat.D2{M} = D*diag(g)*sqrt(nL/E);  % High freq Decoding matrix: max rE
    DecMat.D2{M} = D*diag(g);  % High freq Decoding matrix: max rE
    DecMat.energycoeff=sqrt(nL/E);
    %1/sqrt(trace(D*D'))
end

%% Add session to the path name
ispathexist = 0;
if isdir(PathReadODEON)
    if isdir([PathReadODEON,session])
        ispathexist = 1;
        PathReadODEONsl = PathReadODEON;
        PathReadODEON = [PathReadODEON,session];
%     else
%         ispathexist = -1;
    end
end

%% Build LoRA structure
LoRA     = struct(                          ...
    'session',          session,            ... Name of the session
    'PathStoreIR',      PathStoreIR ,       ... Path where Impulse responses are stored
    'PathStoreConv',    PathStoreConv,      ... Path where Convolved sound are stored
    'PathReadODEON',    PathReadODEON,      ... Path where room data text files are stored
    'PathSoundSamples', PathSoundSamples,   ... Path where anechoic sound files are stored
    'PathLoRAlog',      pathlog,            ... Path where logs are stored
    'fs',               fs,                 ... Sampling frequency for response computation    
    'LoudSetName',      LoudSetName,        ... Name of the Loudspeaker array
    'LoudR',            LoudR,              ... Loudspeaker array radius (for NFC filters)
    'pos',              Loudset,            ... Loudspeakers position (azimuth,elevation)
    'nL',               nL,                 ... Number of loudspeakers
    'isnfc',            isnfc,              ... Boolean, is NFC filters used (1) or not (0)
    'isAmb2D',          isset2D,            ... Horizontal-only (1) or full 3D processing (0)
    'DecMat',           DecMat,             ... Decoding matrix
    'h',                h,                  ... impulse response of the octave filter bank
    'H',                H,                  ... freq response of the octave filter bank
    'hlen',             len,                ... length of the filters
    'hL',               L,                  ... number of frequency bands
    'renderDS',         renderDS,           ... ambisonic order for the direct sound
    'renderER',         renderER,           ... ambisonic order for the early reflections
    'rendering',        rendering,          ... rendering
    'history',          history,            ... history: rooms and sound selection 
    'seed',             seed,               ... seed to force randn() to return a repeatable random sequence
    'ShiftFlag',        ShiftFlag,          ...
    'ReverbFlag',       ReverbFlag);

%     'paDeviceID',       0,                  ... DeviceID for pa_wavplay (default = 0)
%     'ok',               0,                  ... Initialisation success
%% Verbose
k = 0;

if ~ispathexist
    if strcmp(LoRA.PathStoreIR,'xx\');
        if v,disp('Paths are not defined in ''pathstore.m''.'),end
    else
        if v,disp(['Warning: PathReadODEON is nonexistent or not a directory: ',LoRA.PathReadODEON]),end
        k = k+1;
    end
if ~isdir(LoRA.PathStoreIR) || ~isdir(LoRA.PathStoreConv) || ~isdir(LoRA.PathReadODEON)
%     if v,disp('Warning: One of the path name is not a directory.')
    
    if ~isdir(LoRA.PathStoreIR)
        if v,disp(['Warning: PathStoreIR is nonexistent or not a directory: ',LoRA.PathStoreIR]),end;
        k = k+1;
    end
    if ~isdir(LoRA.PathStoreConv)
        if v,disp(['Warning: PathStoreConv is nonexistent or not a directory: ',LoRA.PathStoreConv]),end;
        k = k+1;
    end
end
end
if ~isdir(LoRA.PathSoundSamples)
    if v,disp(['Warning: PathSoundSamples is nonexistent or not a directory: ',LoRA.PathSoundSamples]),end;
    k = k+1;
end
if  ~license('test','dsp_toolbox') && ~license('test','signal_toolbox')
    if v,disp('Warning: No license for the DSP toolbox'),end;
    k = k+1;
end
% End message
if ~k
    if v,disp('LoRA initialised.'),end
else
    if v,disp(['LoRA initialised with ',num2str(k),' warning(s).']),end
end
        
if v,disp('_____________________'),end
if v,disp(' '),end
% LoRA.ok = 1;
if ~nargout
    assignin('base','LoRA',LoRA)
end
LoRAout=LoRA;


% RoomsNames  = {};
% RoomsSel    = [];
% SoundsNames  = {};
% SoundsSel    = [];
% save('history.mat','RoomsNames','RoomsSel','SoundsNames','SoundsSel');