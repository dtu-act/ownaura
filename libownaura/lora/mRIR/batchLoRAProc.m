% batchLoRAProc
%
% Bath processing of comptutation of mIR of rooms (ODEON textfiles in path
% LoRA.PathReadODEON) and convolution with anechoic sound files (in path
% LoRA.PathSoundSamples). Make you choose the rooms and the sound files (no option) or
% process the files indicates in the arguments.
%
% Possible use:
%   batchLoRAProc or batchLoRAProc(1, 1)
%           select rooms and sound files and process both
%   batchLoRAProc(1, 0)
%           select rooms and sound files and process only the mIR
%   batchLoRAProc(0, 1)
%           select rooms and sound files and process only the convolution. Assumed
%           that the mIR is already computed
%   batchLoRAProc(roomsfilestruct,soundsfilestruct)
%           process both with the rooms and the sound files which names are indicated
%           in the arguments
%   batchLoRAProc(roomsfilestruct,soundsfilestruct, 0, 1)
%           convolved mIR and the sound files which names are indicated
%           in the arguments
%
% uses batchLoRAmRIR.m and batchLoRAConv.m
%___________________________________
% (c) 2007 S. Favrot, CAHR

function batchLoRAProc(varargin)

global LoRA

if ~isstruct(LoRA)
    LoRA = LoRA_startup;
end

try load([fileparts(fileparts(which(mfilename))),filesep,'Log',filesep,'history.mat']),catch,end
if ~isempty(varargin)
    if nargin == 2 && iscellstr(varargin{1}) && iscellstr(varargin{2})
        kin = [1,1];
        RoomsNames = varargin{1};
        RoomsSel = 1:length(RoomsNames);
        SoundsNames = varargin{2};
        SoundsSel = 1:length(SoundsNames);
    elseif nargin == 2 && ~iscellstr(varargin{1}) && ~iscellstr(varargin{2})
        kin = [varargin{1},varargin{2}];
    elseif nargin == 4 %&& iscellstr(varargin{1}) && iscellstr(varargin{2})
        kin = [varargin{3},varargin{4}];
        RoomsNames = varargin{1};
        RoomsSel = 1:length(RoomsNames);
        SoundsNames = varargin{2};
        SoundsSel = 1:length(SoundsNames);
        %         if kin == [0,0]
        %             disp('nothing to do')
        %             return
        %         end
    else
        help batchLoRAProc
        error('Wrong number of arguments')
    end
    try 
        tmp=isempty(RoomsNames);
    catch
        RoomsNames = LoRA.history.RoomsNames;
    end
    %     if isempty(SoundsNames), SoundsNames=LoRA.history.SoundsNames; end
else
    kin = [1,1];

end

%% Select room files to compute IR
if kin(1)>-1

    disp('___________________________________________________________________')
    disp('Multichannel IR computation. Room selection. ')
%     dirodeon = LoRA.PathReadODEON;
    v=0;
    while ~v
        d = dir(LoRA.PathReadODEON);
        str = {d.name};
        str = str(3:end);
        nf = 1; kk = 1; strdisp={};
        while nf < length(str)
            strtmp = str{nf}(1:strfind(str{nf}, 'EarlyReflections.Txt')-1);
            strtmp2 = str{nf+1}(1:strfind(str{nf+1}, 'EnergyCurves.Txt')-1);
            if ~isempty(strtmp) && strcmp(strtmp,strtmp2)
                strdisp{kk}=strtmp;
                kk = kk+1; nf = nf + 2;
            else
                nf = nf + 1;
            end
        end
        RoomsNames  = strdisp;
        % preselection
        inVal = [];
        if length(strdisp)==length(LoRA.history.RoomsNames)
            if sum(strcmp(strdisp,LoRA.history.RoomsNames)) == length(strdisp)
                inVal = LoRA.history.RoomsSel;
            end
        end
        if ~isempty(strdisp)
            % selection of room files
            [RoomsSel,v] = listdlg('PromptString','Select rooms: (use Ctrl+click or Shift+click)',...
                'SelectionMode',    'multiple',...
                'ListSize',         [300 300],...
                'Name',             'ODEON files',...
                'InitialValue',     inVal,...
                'ListString',strdisp);
        else
            disp('No room data found in ''LoRA.PathReadODEON'':')
            disp(['        ',LoRA.PathReadODEON])
        end
        if ~v
            dirodeon = uigetdir(LoRA.PathReadODEON,'Select another directory');
            if ~dirodeon
                disp('No room selected.')
                return
            end
            LoRA.PathReadODEON = [dirodeon,filesep];
%             v = 1;
        end
        drawnow
    end
    if isempty(RoomsSel)
        disp('No rooms selected.')
        return
    end
    SoundsNames = LoRA.history.SoundsNames;
    SoundsSel = LoRA.history.SoundsSel;
    % Save history
    save([fileparts(fileparts(which(mfilename))),filesep,'Log',filesep,'history.mat'],...
        'RoomsNames','RoomsSel','SoundsNames','SoundsSel');
    LoRA.history.RoomsSel=RoomsSel;
    LoRA.history.RoomsNames=RoomsNames;
    % else
    %     LoRA.history.RoomsSel=1:length(RoomsNames);
end



%% Select  Sounds to be convolved
if kin(2)>0
    disp('Convolving IRs with anechoic sound samples. Sound selection. ')
%     dirsound = LoRA.PathSoundSamples;
    v=0;
    while ~v
        d       = dir(LoRA.PathSoundSamples);
        str     = {d.name};
        tmpi    = regexpi(str,'.wav');
        jj=1;
        for ii = 1:length(tmpi)
            if ~isempty(tmpi{ii})
                tmpsnd{jj} = str{ii};
                jj = jj+1;
            end
        end
        SoundsNames=tmpsnd;
        % preselection
        inVal = [];
        if length(SoundsNames)==length(LoRA.history.SoundsNames)
            if sum(strcmp(SoundsNames,LoRA.history.SoundsNames)) == length(SoundsNames)
                inVal = LoRA.history.SoundsSel;
            end
        end
        if ~isempty(SoundsNames)
            [SoundsSel,v] = listdlg('PromptString','Select sounds files: (use Ctrl+click or Shift+click)',...
                'SelectionMode',    'multiple',...
                'ListSize',         [300 300],...
                'Name',             'WAV files',...
                'InitialValue',     inVal,...
                'ListString',SoundsNames);
       else
            disp('No sound files found in ''LoRA.PathSoundSamples'':')
            disp(['        ',LoRA.PathSoundSamples])
        end
        if ~v
            dirsound = uigetdir('LoRA.PathSoundSamples','Select a directory');           
            if ~dirsound
                disp('No room selected.')
                return
            end
            LoRA.PathSoundSamples = [dirsound,filesep];
%             v = 1;
        end
    end
    drawnow
    RoomsNames = LoRA.history.RoomsNames;
    RoomsSel = LoRA.history.RoomsSel;
    LoRA.history.SoundsNames = SoundsNames;
    save([fileparts(fileparts(which(mfilename))),filesep,'Log',filesep,'history.mat'],...
        'RoomsNames','RoomsSel','SoundsNames','SoundsSel');
    LoRA.history.SoundsNames=SoundsNames;
    LoRA.history.SoundsSel=SoundsSel;
    % else
    %     LoRA.history.SoundsSel=1:length(SoundsNames);
end
% LoRA.SoundsNames=SoundsNames;


%%
if kin(1)>0
    
    % Computation of the room IRs
    batchLoRAmRIR(LoRA.history.RoomsNames(LoRA.history.RoomsSel))
end
if kin(2)>0
    % Convolve IRs with sound files.
    % LoRA.history.RoomsSel
    % LoRA.history.RoomsNames
%      assignin('base','LoRA',LoRA)
    batchLoRAConv(LoRA.history.RoomsNames(LoRA.history.RoomsSel),LoRA.history.SoundsNames(LoRA.history.SoundsSel));
end
assignin('base','LoRA',LoRA)
