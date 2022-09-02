% batchLoRAmRIR
%
% Batch computation of multichannel IR. Store the result in:
% [LoRA.PathStoreIR \ 'room name' \ 'jobXX.Early.mat'] and
% [LoRA.PathStoreIR \ 'room name' \ 'jobXX.Late.mat']
%   (ex:LoRA.PathStoreIR\shoebox\Job02.Early.mat)
%
% inputs:
%   rooms       string cell containing the names of the room 
%                (ex:{'shoebox.Job02.00001';'shoebox.Job03.00001'})
%
% Save text info into 'Log\LoRAIR.txt'
%
% uses LoRAImp.m 
%___________________________________
% (c) 2007 S. Favrot, CAHR

function batchLoRAmRIR(rooms)

global LoRA

% Creating path
pathstoreresp = [LoRA.PathStoreIR,LoRA.session];
if ~isdir(pathstoreresp)
    mkdir(pathstoreresp)
end

disp(['Ambisonic order for the direct sound: ',num2str(LoRA.renderDS)]);
disp(['Ambisonic order for the early part: ',num2str(LoRA.renderER)]);
Lk = length(rooms);
tic
for k = 1:Lk
    fprintf(['Computing room response: ' ,rooms{k},' (',num2str(k),'/',num2str(Lk),')'])
    
    % Calculate mRIR
    [mIRearly,ylate,Param] = LoRAmRIR(LoRA.PathReadODEON,rooms{k},LoRA.renderDS,LoRA.renderER);
    mIR = AddDSERlate(mIRearly,ylate,LoRA.renderDS,LoRA.renderER);
    
    % scale
    scaleCoeff = max(max(abs(mIR)));
    mIRnormalized = (mIR ./ scaleCoeff)*(1-eps);
    Param.IRscaleCoeff.(['DS',num2str(LoRA.renderDS),'ER',num2str(LoRA.renderER)]) = scaleCoeff;
    
    % create folder and filenames
    strIdx = strfind(rooms{k},'.');
    if length(strIdx) == 2 % if standard filename format with 2 dots (Roomname.Jobname.idx)
        savedir = [pathstoreresp,rooms{k}(1:strIdx-1),filesep];
        jobname = rooms{k}(strIdx(1)+1:strIdx(2)-1);
    else % this was the way it was done before: fixed number of chars
        savedir = [pathstoreresp,rooms{k}(1:end-12),filesep];
        jobname = rooms{k}(end-10:end-6);
    end
    
    if ~isdir(savedir) %Check if directory exists; otherwise, create
        mkdir(savedir)
    end
    irName = [jobname, '_', num2str(LoRA.renderDS), '_', num2str(LoRA.renderER)];
    
    % try to load existing mat files and concatenate old and new data (overwrite with new data!)
    try
        early = load([savedir,jobname,'.Early.mat']);
        mIRearly = catstruct(early.mIRearly, mIRearly);
    catch
    end
    try
        para = load([savedir,jobname,'.param.mat']);
        Param.IRscaleCoeff = catstruct(para.Param.IRscaleCoeff, Param.IRscaleCoeff);
    catch
    end
    
    % save data
    fscomp = LoRA.fs;
    save([savedir,jobname,'.Early.mat'],'mIRearly','fscomp') ;
    save([savedir,jobname,'.Late.mat'],'ylate','fscomp') ;
    save([savedir,jobname,'.param.mat'],'Param');
    
    audiowrite([savedir,irName,'.wav'], mIRnormalized, fscomp, 'BitsPerSample', 32,...
        'Title', jobname, 'Comment', ['DS: ',num2str(LoRA.renderDS),', ER: ', num2str(LoRA.renderER)], 'Artist', getenv('USERNAME'));
    
    fprintf('\n')%\b\b\b
%     drawnow
    fid = fopen([LoRA.PathLoRAlog,'LoRAIR.txt'], 'at');
    %     fprintf([regexprep([savedir,'\',rooms{k}(end-10:end-6),'.mat - '],'\','\\\'),datestr(now),' \n'])
    fprintf(fid,[regexprep([savedir,jobname,'.mat - '],...
        '\','\\\'),datestr(now),' \n']);
    fclose(fid);
end
t=toc;
disp([num2str(Lk),' IRs processed in ',num2str(t,4),'s. (',num2str(t/Lk,2),'s per file)'])
disp('___________________________________________________________________')
fid = fopen([LoRA.PathLoRAlog,'LoRAIR.txt'], 'at');
fprintf(fid,['Ambisonic order for DS: ',num2str(LoRA.renderDS),' \n']);
fprintf(fid,['Ambisonic order for ER: ',num2str(LoRA.renderER),' \n']);
fprintf(fid,['\t',num2str(Lk),' files processed in ',num2str(t,2),'s. \n']);
fprintf(fid,'___________________________________________________________________\n');
fclose(fid);
% close(h)