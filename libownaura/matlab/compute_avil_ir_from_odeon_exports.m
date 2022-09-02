function compute_avil_ir_from_odeon_exports(path, room, outfile, ...
    ignore_direct, move_ER, debug, trim)

% parse args
if (nargin < 3)
    outfile = 'ir.wav';
end
if (nargin < 4)
    ignore_direct = 0;
end
if (nargin < 5)
    move_ER = 0;
end
if (nargin < 6)
    debug = 0;
end
if (nargin < 7)
    trim = 1;
end

addpath('../lora')
LoRA_addpath()

samplerate = 48000;
% Initialisation of the LoRA Toolbox
LoRA = LoRA_startup(...
    'fs',samplerate,...
    'LoudSetName','LoudspeakersPos3D_AVIL',...
    'isnfc',0,...
    'LoudR',2.4,...
    'renderDS',0,...  % there is no direct sound so this should not make any difference
    'renderER',0);

% Compute each part of the multichannel room impulse response (mRIR)
[mIRearly,ylate,~] = LoRAmRIR(...
    path,room,LoRA.renderDS,LoRA.renderER,LoRA,move_ER);
% Add the direct sound, the early reflections and the late reflections
ymRIR = AddDSERlate(...
    mIRearly,ylate,LoRA.renderDS,LoRA.renderER,ignore_direct);

% trim response tail that holds only zero
if trim
    energy = sum(ymRIR.^2,2);
    trim_idx = find(energy == 0, 1, 'first');
    disp(['trimming after ', num2str(trim_idx / samplerate), 's']);
    ymRIR = ymRIR(1:trim_idx, :);
end

if debug
    time = (0:size(ymRIR,1)-1) * 1/samplerate;
    figure,plot(time, ymRIR);
    title('mRIR')
end

% save to wav
audiowrite(outfile, ymRIR, samplerate, 'BitsPerSample', 32)
disp(['Saved IR in ', outfile]);

end