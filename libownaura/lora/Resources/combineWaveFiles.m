%%% Create dummy wave file container, where all wave files will be integrated
[siz,fs] = wavread([LoRA.PathStoreConv fileNames{1}],'size');
nbits = 24; % higher bit-rate since we can't use the full dynamic range at once while mixing
L = siz(1);
disp('--> Allocating disk space for audio file')
wavwriteZeros(siz,fs,nbits,[outName '_No_Norm']) % creates wav file with zeros of size=siz
% disp('Wave file container completed!')

%%% Combine all wave files chunk by chunk

% read all normalisation offsets of all channels of all files to be mixed
for iScene = 1:length(fileNames)
    fname = [LoRA.PathStoreConv fileNames{iScene} '_normOffs.mat'];
    load(fname)
    g(iScene) = min(normOffs);
end

gain = min(g); % reference gain for all extended .wav files to be mixed

chunkLength = 2^17; % number of time samples per chunk
N = ceil(L/chunkLength); % number of chunks in the wave files
maxValueRem = 0; % maximum absolute value of sound file
fprintf(['Mixing ' num2str(length(fileNames)) ' extended .wav files, block '])
for iChunk = 1:N; % loop through all chunks
    dispText = [num2str(iChunk) ' out of ' num2str(N)];
    fprintf(dispText)
    st = (iChunk-1)*chunkLength+1; % start of chunk
    en = min(st + chunkLength - 1,L); % end of chunk
    for i = 1:length(fileNames); % loop through all wave files that need to be combined
        yi = wavread([LoRA.PathStoreConv fileNames{i}],[st en]); % read one chunk of the input wavfiles
%         gainFN = (gain/g(i))/length(fileNames); % normalise all gains so that relative gains are correct; divide by no. of fileNames
        gainFN = (gain/g(i))/2; % division by 2 is rather arbitrary but seems safe for speech files
        wavreadandadd([outName '_No_Norm'],[st en],gainFN*yi); % add the chuck to the output wavfile (after applying gain)
    end
    yi = wavread([outName '_No_Norm'],[st en]); % read one chunk of the mixed file
    maxValue = max(max(abs(yi)));
    if maxValue > maxValueRem;
        maxValueRem = maxValue; % maximum value of mixed file (all channels)
    end
    fprintf([repmat(8,1,length(dispText)) '']) % delete the 'x out of y' part before refreshing in next loop pass
end
fprintf([num2str(N) ' out of ' num2str(N) '... Completed!\n'])

disp(['---> Maximum amplitude value of the output wave file was ' num2str(round(100*maxValueRem)/100) ' before normalisation'])
disp('----------------------------------------------------------------------')

nbits = 16; % the final normalised file doesn't need to be >16bits
disp('--> Allocating disk space for audio file')
wavwriteZeros(siz,fs,nbits,outName)
fprintf('Normalising... block ')
for iChunk = 1:N; % loop through all chunks
    dispText = [num2str(iChunk) ' out of ' num2str(N)];
    fprintf(dispText)
    st = (iChunk-1)*chunkLength+1; % start of chunk
    en = min(st + chunkLength - 1,L); % end of chunk
    yi = wavread([outName '_No_Norm'],[st en]); % read one chunk of the mixed file
    gainOverall = 1/maxValueRem;
    wavreadandadd(outName,[st en],0.95*gainOverall*yi);
    fprintf([repmat(8,1,length(dispText)) '']) % delete the 'x out of y' part before refreshing in next loop pass
end
fprintf([num2str(N) ' out of ' num2str(N) '... Completed!\n'])

effGain = gain/length(fileNames)*gainOverall;
save([outName '_gain'],'effGain') % overall effective gain of this room mixed audio file

delete([outName '_No_Norm.wav'])

% %% Filter with inverse of directional on-axis response
% load InvDirFilter.mat
% 
% disp('----------------------------------------------------------------------')
% disp('Filtering final file')
% disp('--> Allocating disk space for audio file')
% wavwriteZeros(siz,fs,nbits,[outName,'_DirCompens'])
% 
% writeconv([outName,'_DirCompens'],repmat(hinv',1,siz(2)),[],1,outName,[1 siz(1)],10^(-12/20),1,0)

