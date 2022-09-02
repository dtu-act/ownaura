% LoRA_addpath
% 
% Add path to the Matlab list of path for using VAE. To be used only once.
% and set path for computing and storing responses.

p=path;
ptarget={'Resources';'mRIR'};
for np=1:length(ptarget)
    if isempty(strfind(path,[fileparts(which(mfilename)), filesep, ptarget{np}]))
        addpath([fileparts(which(mfilename)), filesep, ptarget{np}])
    end
end


