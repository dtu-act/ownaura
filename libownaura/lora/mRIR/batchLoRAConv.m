% batchLoRAConv
%
% Batch computation of convolution of multichannel IR and anechoic 
% sound files. Store sound files ready to be played in 
% [LoRA.PathStoreConv \ 'room name' \ 'JobXX.'soundsconv (i)'.wav]
%   (ex: LoRA.PathStoreConv\shoe75\Job02\Sentence001.wav )
%
% inputs:
%   rooms       string cell containing the names of the room 
%                (ex:{'shoe75.Job02.00001';'shoe75.Job03.00001'})
%   soundsconv  string cell containing the file names of the anechoic
%                signal to convolve
%
% uses convmat.m, (dBSPLA.m), AddDSERlate.m
%___________________________________
% $Revision: #1 $ 
%    - function AddDSERlate
%    - taking the frequency sampling used to compute the response (not
%    LoRA.fs) rev
%    - input can be a data vector
%
% $Revision: #1 $ 
%    - normalization by playback coefficient
%
% $Revision: #1 $ 
%    - Initial version.
%___________________________________
% (c) 2007 S. Favrot, CAHR

function batchLoRAConv(rooms,soundsconv) 

global LoRA

% Creating path
pathstoreconv = [LoRA.PathStoreConv,LoRA.session];
pathstoreresp = [LoRA.PathStoreIR,LoRA.session];

if iscell(soundsconv)
    Lc = length(soundsconv);
    isdvct = 0;
elseif isvector(soundsconv)% if soundsconv is a data vector  
    Lc = 1;
    isdvct = 1;
else 
    error('Syntax error')
end

Lk = length(rooms);

% display and log
fid = fopen([LoRA.PathLoRAlog,'LoRAConv.txt'], 'at');
fprintf(fid,[num2str(Lk),' rooms - ',num2str(Lc),' sounds files. - ',datestr(now),' \n']);
tmplog='For the rendering configurations (DS ER): ';
fprintf(tmplog);
fprintf(fid,tmplog);
for nr = 1:size(LoRA.rendering,1)
    tmplog=[num2str(LoRA.rendering(nr,:)),' ; '];
    fprintf(tmplog);
    fprintf(fid,tmplog);
end
fprintf('\n')
fprintf(fid,'\n');
fclose(fid);
disp('Computing convolution with IR of room:')

% try load([fileparts(fileparts(which(mfilename))),'\Log\dBvalue.mat']), catch end

% For each room IR
tic;
for k = 1:Lk        

    % jobname and roomname
    strIdx = strfind(rooms{k},'.');
    if length(strIdx) == 2 % if standard filename format with 2 dots (Roomname.Jobname.idx)
        savedir = [pathstoreconv,rooms{k}(1:strIdx-1),filesep];
        jobname = rooms{k}(strIdx(1)+1:strIdx(2)-1);
        IRf = [pathstoreresp,rooms{k}(1:strIdx(1)-1),filesep,jobname];
    else % this was the way it was done before: fixed number of chars
        savedir = [pathstoreconv,rooms{k}(1:end-12),filesep];
        jobname = rooms{k}(end-10:end-6);
        IRf = [pathstoreresp,rooms{k}(1:end-12),filesep,jobname];
    end
    
    
    if ~isdir(savedir) %Check if directory exists; otherwise, create
        mkdir(savedir)
    end


%     try load([IRf,'.param.mat']);
%     catch error('IR not found')
%     end
    fprintf([num2str(k),'/',num2str(Lk),' - ',rooms{k}(1:end-6),' - sound file: \n']);
    fid = fopen([LoRA.PathLoRAlog,'LoRAConv.txt'], 'at');
    fprintf(fid,[regexprep(IRf,'\','\\\'),' \n']);
    fclose(fid);
    try 
        load([IRf,'.Early.mat']);
    catch
        error([IRf,'.Early.mat - file not found'])
    end
    try 
        load([IRf,'.Late.mat']);
    catch
        error([IRf,'.Late.mat - file not found'])
    end
    try 
        load([IRf,'.param.mat']);
    catch
        error([IRf,'.param.mat - file not found'])
    end
    try 
        fscomputed=fscomp; % samping frequency used to compute the response
    catch
        error('fs used to compute the IR was not found. Recompute the IR')
    end
    if fscomputed~=LoRA.fs
        warning(['LoRA.fs and fs used to compute the IR do not match. fs used: ',num2str(fscomputed)])
        LoRA.fs=fscomputed;
    end
    
%     % path to save the sound
%     savedir     = [pathstoreconv,rooms{k}(1:end-12),filesep];
%     if ~isdir(savedir), mkdir(savedir),end
%     savedir     = [savedir,jobname,filesep];
%     if ~isdir(savedir), mkdir(savedir),end
    %savedir     = [pathstoreconv,LoRA.LoudSetName(end-2:end),'-',rooms{k}(1:6),'-',jobname,'-'];
    % for each sound file 
    for nc = 1:Lc     
        if ~isdvct
            sndfilename = soundsconv{nc};
            [sig,fssig] = audioread([LoRA.PathSoundSamples,sndfilename]);
            if fssig~=fscomputed
                sig         = resample(sig(:,1),fscomputed,fssig);
                Resampled = 1;
            else 
                Resampled = 0;
            end
            
        else
            sig=soundsconv;
            rmssig=sqrt(mean(sig.^2));
            sig = sig/rmssig;
            sndfilename = ['data',num2str(length(sig)),'.wav'];
        end
        
        fprintf('\t%2.f/%2.f\t%s\t',nc,Lc,sndfilename)
        
        % for all the rendering conditions
        for nr = 1:size(LoRA.rendering,1)
            nDS     = num2str(LoRA.rendering(nr,1));
            nER     = num2str(LoRA.rendering(nr,2));

            mIR = AddDSERlate(mIRearly,ylate,nDS,nER);
            % scale mIR as wave file IR
            mIR = mIR./Param.IRscaleCoeff.(['DS',nDS,'ER',nER]);
            
            sndname     = [jobname, '_', nDS, '_', nER, '_', sndfilename];
            
            % convolve signal with mIR
            try %check if processing can be done on GPU
                gpu = true;
                g = gpuDevice();
            catch
                gpu = false;
            end
            mIRsize = size(mIR);
            
            % zero pad the signal for reverb tail
            
            signalZeroPad = [sig; zeros(mIRsize(1)-1,1)];

            if gpu && (length(signalZeroPad)>500000) %only use GPU for long files
                fprintf('Convolution. Using GPU...')
                yout = zeros(length(signalZeroPad), mIRsize(2));%preallocate some space
                for n = 1:mIRsize(2)
                    yP = fftfilt(gpuArray(mIR(:,n)),gpuArray(signalZeroPad));
                    yout(:,n) = gather(yP);
                end
            else
                fprintf('Convolution...')
                yout        = fftfilt(mIR,signalZeroPad);
            end
            
            %youtNormalized = (yout ./ max(max(abs(yout))))*(1-eps);
            fprintf('\b\b Writing audio...')
            audiowrite([savedir,sndname], yout, LoRA.fs, 'BitsPerSample', 32,...
                'Title', jobname, 'Comment', ['DS: ', nDS,', ER: ', nER], 'Artist', getenv('USERNAME'));
            
            clear yout mIR sig signalZeroPad
            reset(g)
            
            fid = fopen([LoRA.PathLoRAlog,'LoRAConv.txt'], 'at');
            if Resampled
                fprintf(fid,['\t\t',sndname,' Resampled ', num2str(fscomputed),'\n']);
            else
                fprintf(fid,['\t\t',sndname,' ', num2str(fscomputed),'\n']);
            end
            fclose(fid);
            fprintf('\b\b Done!\n');
        end
    end
    fprintf('\n');
end
t=toc;
disp([num2str(Lk*Lc),' convolved in ',num2str(round(t),4),'s. (',num2str(t/(Lk*Lc),3),'s per file)']);
disp('___________________________________________________________________');
fid = fopen([LoRA.PathLoRAlog,'LoRAConv.txt'], 'at');
fprintf(fid,[num2str(Lk*Lc),' files processed in ',num2str(round(t),4),'s. \n']);
fprintf(fid,'___________________________________________________________________\n');
fclose(fid);


% ______________________
% ||||||||||||||||||||||
