function [y,Fs,bits,opt_ck] = wavreadandadd(varargin)
%WAVREAD Read Microsoft WAVE (".wav") sound file.
%   Y=WAVREAD(FILE) reads a WAVE file specified by the string FILE,
%   returning the sampled data in Y. The ".wav" extension is appended
%   if no extension is given.
%
%   [Y,FS,NBITS]=WAVREAD(FILE) returns the sample rate (FS) in Hertz
%   and the number of bits per sample (NBITS) used to encode the
%   data in the file.
%
%   [...]=WAVREAD(FILE,N) returns only the first N samples from each
%       channel in the file.
%   [...]=WAVREAD(FILE,[N1 N2]) returns only samples N1 through N2 from
%       each channel in the file.
%
%   [Y,...]=WAVREAD(...,FMT) specifies the data type format of Y used
%       to represent samples read from the file.
%       If FMT='double', Y contains double-precision normalized samples.
%       If FMT='native', Y contains samples in the native data type
%       found in the file.  Interpretation of FMT is case-insensitive,
%       and partial matching is supported.  If omitted, FMT='double'.
%
%   SIZ=WAVREAD(FILE,'size') returns the size of the audio data contained
%       in the file in place of the actual audio data, returning the
%       2-element vector SIZ=[samples channels].
%
%   [Y,FS,NBITS,OPTS]=WAVREAD(...) returns a structure OPTS of additional
%       information contained in the WAV file.  The content of this
%       structure differs from file to file.  Typical structure fields
%       include '.fmt' (audio format information) and '.info' (text
%       which may describe title, author, etc.)
%
%   Output Scaling
%   The range of values in Y depends on the data format FMT specified.
%   Some examples of output scaling based on typical bit-widths found
%   in a WAV file are given below for both 'double' and 'native' formats.
%   FMT='native'
%      #Bits   MATLAB data type          Data range
%      -----   ------------------------- -------------------
%        8     uint8  (unsigned integer)      0 <= Y <= 255
%       16     int16  (signed integer)   -32768 <= Y <= +32767
%       24     int32  (signed integer)    -2^23 <= Y <= 2^23-1
%       32     single (floating point)     -1.0 <= Y < +1.0
%   FMT='double'
%      #Bits   MATLAB data type          Data range
%      -----   ------------------------- -------------------
%       N<32   double                     -1.0 <= Y <  +1.0
%       N=32   double                     -1.0 <= Y <= +1.0
%      Note: Values in Y may achieve +1.0 for the case of N=32
%            bit data samples stored in the WAV file.
%
%   Supports multi-channel data, with up to 32 bits per sample.
%   Supports Microsoft PCM data format only.
%
%   See also WAVWRITE, AUREAD, AUWRITE.

%   Copyright 1984-2006 The MathWorks, Inc. 
%   $Revision: #1 $  $Date: 2010/11/01 $

% Parse input arguments:
[file,ext,y,isNative] = parseArgs(varargin{:});

%c
% If input is a vector, force it to be a column:
if ndims(y) > 2,
  error('Data array cannot be an N-D array.');
end
if size(y,1)==1,
   y = y(:);
end

%check if the data has the same number of channel than the file
siz=wavread(file,'size'); %c
if size(y,2)>siz(2)
    error('The data must have the same number of channel than the file')
end
if ext(2)>siz(1) || ext(2)-ext(1)+1~=size(y,1)
    error('Wrong length of the data')
end
%c

% Open WAV file:
[fid,msg] = open_wav(file);
if ~isempty(msg)
    error('wavread:InvalidFile', msg);
end

% Now the file is open - wrap remaining code in try/catch so we can 
% close the file if an error occurs
try

% Find the first RIFF chunk:
[riffck,msg] = find_cktype(fid,'RIFF');
if ~isempty(msg)
   error('wavread:InvalidFile','Not a WAVE file.');
end

% Verify that RIFF file is WAVE data type:
msg = check_rifftype(fid,'WAVE');
if ~isempty(msg)
    error('wavread:InvalidFile', msg);
end

% Find optional chunks, and don't stop till <data-ck> found:
end_of_file = 0;
opt_ck      = [];

while ~end_of_file
    [ck,msg] = find_cktype(fid);
    if ~isempty(msg)
        error('wavread:InvalidFile',msg);
    end

   switch lower(ck.ID)
   
   case 'end of file'
      end_of_file = 1;
   
   case 'fmt'
      % <fmt-ck> found      
      [opt_ck,msg] = read_wavefmt(fid,ck,opt_ck);
      if ~isempty(msg)
          error('wavread:InvalidFile',msg);
      end
      
   case 'data'
      % <data-ck> found:
      if ~isfield(opt_ck,'fmt'),
         error('wavread:InvalidFile', ...
             'Corrupt WAV file - found audio data before format information.');
      end
      
      if strcmpi(ext,'size')
         % Caller doesn't want data - just data size:
         [samples,msg] = read_wavedat(ck, opt_ck.fmt, -1, isNative);
         if ~isempty(msg)
             error('wavread:InvalidFile',msg);
         end
         y = [samples opt_ck.fmt.nChannels];
         
      else
         % Read <wave-data>:
         [datack,msg] = read_wavedat(ck, opt_ck.fmt, ext, y, isNative); %c
         if ~isempty(msg)
             error('wavread:InvalidFile',msg);
         end
         y = datack.Data;
         
      end
      
   case 'fact'
      % Optional <fact-ck> found:
      [opt_ck,msg] = read_factck(fid, ck, opt_ck);
      if ~isempty(msg)
          error('wavread:InvalidFile',msg);
      end

   case 'disp'
       % Optional <disp-ck> found:
       [opt_ck,msg] = read_dispck(fid, ck, opt_ck);
       if ~isempty(msg)
           error('wavread:InvalidFile',msg);
       end

   case 'list'
       % Optional <list-ck> found:
       [opt_ck, msg] = read_listck(fid, ck, opt_ck);
       if ~isempty(msg)
           error('wavread:InvalidFile',msg);
       end

   otherwise
      % Skip over data in unprocessed chunks:
      if rem(ck.Size,2), ck.Size=ck.Size+1; end
      if fseek(fid,ck.Size,0) == -1
         error('wavread:InvalidFile', ...
             'Incorrect chunk size information in WAV file.');
      end
   end
end

catch
    fclose(fid);
    rethrow(lasterror);
end

fclose(fid);

%c
% % Parse structure info for return to user:
% Fs = opt_ck.fmt.nSamplesPerSec;
% if opt_ck.fmt.wFormatTag == 1 || opt_ck.fmt.wFormatTag == 3,
% %   Type 3 floating point has no nBitsPerSample field, so use 
% %   nBlockAlign to figure out number of bits
%     bits = (opt_ck.fmt.nBlockAlign / opt_ck.fmt.nChannels) * 8;
% else
%    bits = [];  % Unknown
% end
%c
% end of wavread()


% ------------------------------------------------------------------------
% Local functions:
% ------------------------------------------------------------------------

% ---------------------------------------------
% OPEN_WAV: Open a WAV file for reading
% ---------------------------------------------
function [fid,msg] = open_wav(file)
% Append .wav extension if it's missing:
[pat,nam,ext] = fileparts(file);
if isempty(ext),
  file = [file '.wav'];
end
[fid,msg] = fopen(file,'r+b','l');   % Little-endian %c
if fid == -1,
	msg = 'Cannot open file.';
end


% ---------------------------------------------
% READ_CKINFO: Reads next RIFF chunk, but not the chunk data.
%   If optional sflg is set to nonzero, reads SUBchunk info instead.
%   Expects an open FID pointing to first byte of chunk header.
%   Returns a new chunk structure.
% ---------------------------------------------
function [ck,msg] = read_ckinfo(fid)

msg     = '';
ck.fid  = fid;
ck.Data = [];
err_msg = 'Truncated chunk header found - possibly not a WAV file.';

[s,cnt] = fread(fid,4,'char');

% Do not error-out if a few (<4) trailing chars are in file
% Just return quickly:
if (cnt~=4),
   if feof(fid),
   	% End of the file (not an error)
   	ck.ID = 'end of file';  % unambiguous chunk ID (>4 chars)
   	ck.Size = 0;
   else
      msg = err_msg;
   end
   return
end

ck.ID = deblank(char(s'));

% Read chunk size (skip if subchunk):
[sz,cnt] = fread(fid,1,'uint32');
if cnt~=1,
   msg = err_msg;
   return
end
ck.Size = sz;


% ---------------------------------------------
% FIND_CKTYPE: Finds a chunk with appropriate type.
%   Searches from current file position specified by fid.
%   Leaves file positions to data of desired chunk.
%   If optional sflg is set to nonzero, finds a SUBchunk instead.
% ---------------------------------------------
function [ck,msg] = find_cktype(fid,ftype)

if nargin<2, ftype = ''; end

[ck,msg] = read_ckinfo(fid);
if ~isempty(msg), return; end

% Was a required chunk type specified?
if ~isempty(ftype) && ~strcmpi(ck.ID,ftype)
   msg = ['<' ftype '-ck> did not appear as expected'];
end


% ---------------------------------------------
% CHECK_RIFFTYPE: Finds the RIFF data type.
%   Searches from current file position specified by fid.
%   Leaves file positions to data of desired chunk.
% ---------------------------------------------
function msg = check_rifftype(fid,ftype)
msg = '';
[rifftype,cnt] = fread(fid,4,'char');
rifftype = char(rifftype)';

if cnt~=4,
   msg = 'Not a WAVE file.';
elseif ~strcmpi(rifftype,ftype),
   msg = ['File does not contain required ''' ftype ''' data chunk.'];
end


% ---------------------------------------------
% READ_LISTCK: Read the FLIST chunk:
% ---------------------------------------------
function [opt_ck,msg] = read_listck(fid,ck, orig_opt_ck)

opt_ck = orig_opt_ck;

orig_pos    = ftell(fid);
total_bytes = ck.Size; % # bytes in subchunk
nbytes      = 4;       % # of required bytes in <list-ck> header
msg = '';
err_msg = 'Error reading <list-ck> chunk.';

if total_bytes < nbytes,
   msg = err_msg;
   return
end

% Read standard <list-ck> data:
listdata = char(fread(fid,total_bytes,'uchar')');

listtype = lower(listdata(1:4)); % Get LIST type
listdata = listdata(5:end);      % Move past INFO

if strcmp(listtype,'info'),
    % Information:
    while(~isempty(listdata)),
        id = listdata(1:4);
        if ~isfield(opt_ck,'info'),
            opt_ck.info = [];
        end
        len = listdata(5:8) * 2.^[0 8 16 24]';
        txt = listdata(9:9+len-1);

        % Fix up text: deblank, and replace CR/LR with LF
        txt = deblank(txt);
        idx=findstr(txt,char([13 10]));
        txt(idx) = '';

        % Store - don't include the "name" info
        opt_ck.info.(lower(id)) =  txt;

        if rem(len,2), len=len+1; end
        listdata = listdata(9+len:end);
    end
   
else
   if ~isfield(opt_ck,'list'),
      opt_ck.list = [];
   end
   opt_ck.list.(listtype) = listdata;
end

% Skip over any unprocessed data:
if rem(total_bytes,2), total_bytes=total_bytes+1; end
rbytes = total_bytes - (ftell(fid) - orig_pos);
if rbytes~=0,
   if (fseek(fid,rbytes,'cof')==-1),
      msg = err_msg;
   end
end


% ---------------------------------------------
% READ_DISPCK: Read the DISP chunk:
% ---------------------------------------------
function [opt_ck, msg] = read_dispck(fid,ck,orig_opt_ck)

opt_ck = orig_opt_ck;

orig_pos    = ftell(fid);
total_bytes = ck.Size; % # bytes in subchunk
nbytes      = 4;       % # of required bytes in <disp-ck> header
msg = '';
err_msg = 'Error reading <disp-ck> chunk.';

if total_bytes < nbytes,
   msg = err_msg;
   return
end

% Read standard <disp-ck> data:
data = fread(fid,total_bytes,'uchar');

% Process data:

% First few entries are size info:
icon_data = data;
siz_info = reshape(icon_data(1:2*4),4,2)';
siz_info = siz_info*(2.^[0 8 16 24]');
is_icon = isequal(siz_info,[8;40]);

if ~is_icon,
   % Not the icon:
   opt_ck.disp.name = 'DisplayName';
   txt = deblank(char(data(5:end)'));
   opt_ck.disp.text = txt;
end

% Skip over any unprocessed data:
if rem(total_bytes,2), total_bytes=total_bytes+1; end
rbytes = total_bytes - (ftell(fid) - orig_pos);
if rbytes~=0,
   if(fseek(fid,rbytes,'cof')==-1),
      msg = err_msg;
   end
end


% ---------------------------------------------
% READ_FACTCK: Read the FACT chunk:
% ---------------------------------------------
function [opt_ck,msg] = read_factck(fid,ck,orig_opt_ck)

opt_ck      = orig_opt_ck;
orig_pos    = ftell(fid);
total_bytes = ck.Size; % # bytes in subchunk
nbytes      = 4;       % # of required bytes in <fact-ck> header
msg = '';
err_msg = 'Error reading <fact-ck> chunk.';

if total_bytes < nbytes,
   msg = err_msg;
   return
end

% Read standard <fact-ck> data:
opt_ck.fact = char(fread(fid,total_bytes,'uchar')');

% Skip over any unprocessed data:
if rem(total_bytes,2), total_bytes=total_bytes+1; end
rbytes = total_bytes - (ftell(fid) - orig_pos);
if rbytes~=0,
   if(fseek(fid,rbytes,'cof')==-1),
      msg = err_msg;
   end
end


% ---------------------------------------------
% READ_WAVEFMT: Read WAVE format chunk.
%   Assumes fid points to the <wave-fmt> subchunk.
%   Requires chunk structure to be passed, indicating
%   the length of the chunk in case we don't recognize
%   the format tag.
% ---------------------------------------------
function [opt_ck,msg] = read_wavefmt(fid,ck,orig_opt_ck)

opt_ck = orig_opt_ck;

orig_pos    = ftell(fid);
total_bytes = ck.Size; % # bytes in subchunk
nbytes      = 14;  % # of required bytes in <wave-format> header
msg = '';
err_msg = 'Error reading <wave-fmt> chunk.';

if total_bytes < nbytes,
   msg = err_msg;
   return
end

% Read standard <wave-format> data:
opt_ck.fmt.wFormatTag      = fread(fid,1,'uint16'); % Data encoding format
opt_ck.fmt.nChannels       = fread(fid,1,'uint16'); % Number of channels
opt_ck.fmt.nSamplesPerSec  = fread(fid,1,'uint32');  % Samples per second
opt_ck.fmt.nAvgBytesPerSec = fread(fid,1,'uint32');  % Avg transfer rate
opt_ck.fmt.nBlockAlign     = fread(fid,1,'uint16'); % Block alignment

% Read format-specific info:
switch opt_ck.fmt.wFormatTag
case 1
   % PCM Format:
   [opt_ck.fmt, msg] = read_fmt_pcm(fid, ck, opt_ck.fmt);
end

% Skip over any unprocessed fmt-specific data:
if rem(total_bytes,2), total_bytes=total_bytes+1; end
rbytes = total_bytes - (ftell(fid) - orig_pos);
if rbytes~=0,
   if(fseek(fid,rbytes,'cof')==-1),
      msg = err_msg;
   end
end


% ---------------------------------------------
% READ_FMT_PCM: Read <PCM-format-specific> info
% ---------------------------------------------
function [fmt,msg] = read_fmt_pcm(fid, ck, fmt)

% There had better be a bits/sample field:
total_bytes = ck.Size; % # bytes in subchunk
nbytes      = 14;  % # of bytes already read in <wave-format> header
msg = '';
err_msg = 'Error reading PCM <wave-fmt> chunk.';

if (total_bytes < nbytes+2),
   msg = err_msg;
   return
end

[bits,cnt] = fread(fid,1,'uint16');
nbytes=nbytes+2;
if (cnt~=1),
   msg = err_msg;
   return
end 
fmt.nBitsPerSample=bits;

% Are there any additional fields present?
if (total_bytes > nbytes),
   % See if the "cbSize" field is present.  If so, grab the data:
   if (total_bytes >= nbytes+2),
      % we have the cbSize uint16 in the file:
      [cbSize,cnt]=fread(fid,1,'uint16');
      nbytes=nbytes+2;
      if (cnt~=1),
         msg = err_msg;
         return
      end
      fmt.cbSize = cbSize;
   end
   
   % Simply skip any remaining stuff - we don't know what it is:
   if rem(total_bytes,2), total_bytes=total_bytes+1; end
   rbytes = total_bytes - nbytes;
   if rbytes~=0,
      if (fseek(fid,rbytes,'cof') == -1);
         msg = err_msg;
      end
   end    
end

  
% ---------------------------------------------
% READ_WAVEDAT: Read WAVE data chunk
%   Assumes fid points to the wave-data chunk
%   Requires <data-ck> and <wave-format> structures to be passed.
%   Requires extraction range to be specified.
%   Setting ext=[] forces ALL samples to be read.  Otherwise,
%       ext should be a 2-element vector specifying the first
%       and last samples (per channel) to be extracted.
%   Setting ext=-1 returns the number of samples per channel,
%       skipping over the sample data.
% ---------------------------------------------
function [dat,msg] = read_wavedat(datack,wavefmt,ext,data,isNative)

% In case of unsupported data compression format:
dat     = [];
fmt_msg = '';

switch wavefmt.wFormatTag
case 1
   % PCM Format:
   [dat,msg] = read_dat_pcm(datack,wavefmt,ext,data,isNative);
case 2
   fmt_msg = 'Microsoft ADPCM';
case 3
   % normalized floating-point
   [dat,msg] = read_dat_pcm(datack,wavefmt,ext,data,isNative);
case 6
   fmt_msg = 'CCITT a-law';
case 7
   fmt_msg = 'CCITT mu-law';
case 17
   fmt_msg = 'IMA ADPCM';   
case 34
   fmt_msg = 'DSP Group TrueSpeech TM';
case 49
   fmt_msg = 'GSM 6.10';
case 50
   fmt_msg = 'MSN Audio';
case 257
   fmt_msg = 'IBM Mu-law';
case 258
   fmt_msg = 'IBM A-law';
case 259
   fmt_msg = 'IBM AVC Adaptive Differential';
otherwise
   fmt_msg = ['Format #' num2str(wavefmt.wFormatTag)];
end
if ~isempty(fmt_msg),
   msg = ['Data compression format (' fmt_msg ') is not supported.'];
end


% ---------------------------------------------
% READ_DAT_PCM: Read PCM format data from <wave-data> chunk.
%   Assumes fid points to the wave-data chunk
%   Requires <data-ck> and <wave-format> structures to be passed.
%   Requires extraction range to be specified.
%   Setting ext=[] forces ALL samples to be read.  Otherwise,
%       ext should be a 2-element vector specifying the first
%       and last samples (per channel) to be extracted.
%   Setting ext=-1 returns the number of samples per channel,
%       skipping over the sample data.
% ---------------------------------------------
function [dat,msg] = read_dat_pcm(datack,wavefmt,ext,data,isNative)

dat = [];
msg = '';

% Determine # bytes/sample - format requires rounding
%  to next integer number of bytes: 
BytesPerSample = ceil(wavefmt.nBlockAlign / wavefmt.nChannels);
if (BytesPerSample == 1),
   dtype='uchar'; % unsigned 8-bit
elseif (BytesPerSample == 2),
   dtype='int16'; % signed 16-bit
elseif (BytesPerSample == 3)
	dtype='bit24'; % signed 24-bit
elseif (BytesPerSample == 4),
    % 32-bit 16.8 float (type 1 - 32-bit)
    % 32-bit normalized floating point
    dtype = 'float';    
    % 32-bit 24.0 float (type 1 - 24-bit)
    if wavefmt.wFormatTag ~= 3 && wavefmt.nBitsPerSample == 24,
        BytesPerSample = 3;
    end
else
   msg = 'Cannot read PCM file formats with more than 32 bits per sample.';
   return
end
if isNative
	dtype=['*' dtype];
end

total_bytes       = datack.Size; % # bytes in this chunk
total_samples     = total_bytes / BytesPerSample;
SamplesPerChannel = total_samples / wavefmt.nChannels;
if ~isempty(ext) && isscalar(ext) && ext==-1
       % Just return the samples per channel, and fseek past data:
       dat = SamplesPerChannel;

       % Add in a pad-byte, if required:
       total_bytes = total_bytes + rem(datack.Size,2);

       if(fseek(datack.fid,total_bytes,'cof')==-1),
           msg = 'Error reading PCM file format.';
       end

       return
end

% Determine sample range to read:
if isempty(ext),
   ext = [1 SamplesPerChannel];    % Return all samples
else
   if numel(ext)~=2,
      msg = 'Sample limit vector must have 2 elements.';
      return
   end
   if ext(1)<1 || ext(2)>SamplesPerChannel,
      msg = 'Sample limits out of range.';
      return
   end
   if ext(1)>ext(2)
      msg = 'Sample limits must be given in ascending order.';
      return
   end
end

bytes_remaining = total_bytes;  % Preset byte counter

% Skip over leading samples:
if ext(1)>1
   % Skip over leading samples, if specified:
   skipcnt = BytesPerSample * (ext(1)-1) * wavefmt.nChannels;
   if(fseek(datack.fid, skipcnt,'cof') == -1),
	   msg = 'Error reading PCM file format.';
      return
   end
   %
   % Update count of bytes remaining:
   bytes_remaining = bytes_remaining - skipcnt;
end

% Read desired data:
nSPCext    = ext(2)-ext(1)+1; % # samples per channel in extraction range
dat        = datack;  % Copy input structure to output
% extSamples = wavefmt.nChannels*nSPCext;
%c
yr   = fread(datack.fid, [wavefmt.nChannels nSPCext], dtype);
readcnt    = BytesPerSample * nSPCext * wavefmt.nChannels;
if(fseek(datack.fid, -readcnt,'cof') == -1),
	   msg = 'Error reading PCM file format.';
      return
end
data = PCM_Quantize(data, wavefmt);

% Write data, one row at a time (one sample from each channel):
[samples,channels] = size(data);
total_samples = samples*channels;

if (fwrite(datack.fid, reshape(data'+yr,total_samples,1), dtype) ~= total_samples),
    err = 'Failed to write PCM data samples.'; return;
end
%c dat.Data   = fread(datack.fid, [wavefmt.nChannels nSPCext], dtype);

%
% Update count of bytes remaining:
skipcnt = BytesPerSample*nSPCext*wavefmt.nChannels;
bytes_remaining = bytes_remaining - skipcnt;

% if cnt~=extSamples, dat='Error reading file.'; return; end
% Skip over trailing samples:
if(fseek(datack.fid, BytesPerSample * ...
      (SamplesPerChannel-ext(2))*wavefmt.nChannels, 'cof')==-1),
   msg = 'Error reading PCM file format.';
   return
end
% Update count of bytes remaining:
skipcnt = BytesPerSample*(SamplesPerChannel-ext(2))*wavefmt.nChannels;
bytes_remaining = bytes_remaining - skipcnt;

% Determine if a pad-byte is appended to data chunk,
%   skipping over it if present:
if rem(datack.Size,2),
   fseek(datack.fid, 1, 'cof');
end
% Rearrange data into a matrix with one channel per column:
dat.Data = dat.Data';

if ~isNative
    % Normalize data range: min will hit -1, max will not quite hit +1.
    if BytesPerSample==1,
        dat.Data = (dat.Data-128)/128;  % [-1,1)
    elseif BytesPerSample==2,
        dat.Data = dat.Data/32768;      % [-1,1)
    elseif BytesPerSample==3,
        dat.Data = dat.Data/(2^23);     % [-1,1)
    elseif BytesPerSample==4,
        if wavefmt.wFormatTag ~= 3,    % Type 3 32-bit is already normalized
            dat.Data = dat.Data/32768; % [-1,1)
        end
    end
end


return

% -----------------------------------------------------------------------
function y = PCM_Quantize(x, fmt)
% PCM_Quantize:
%   Scale and quantize input data, from [-1, +1] range to
%   either an 8-, 16-, or 24-bit data range.

% Clip data to normalized range [-1,+1]:
ClipMsg  = ['Data clipped during write to file' ];
ClipWarn = 0;

% Determine slope (m) and bias (b) for data scaling:
nbits = fmt.nBitsPerSample;
m = 2.^(nbits-1);

switch nbits
case 8,
   b=128;
case {16,24},
   b=0;
otherwise,
   error('Invalid number of bits specified.');
end

y = round(m .* x + b);

% Determine quantized data limits, based on the
% presumed input data limits of [-1, +1]:
ylim = [-1 +1];
qlim = m * ylim + b;
qlim(2) = qlim(2)-1;

% Clip data to quantizer limits:
i = find(y < qlim(1));
if ~isempty(i),
   warning(ClipMsg); ClipWarn=1;
   y(i) = qlim(1);
end

i = find(y > qlim(2));
if ~isempty(i),
   if ~ClipWarn, warning(ClipMsg); end
   y(i) = qlim(2);
end



% ---------------------------------------------
function [file,ext,y,isNative] = parseArgs(varargin)
%ParseArgs Parse input arguments to wavread
% Supported syntax:
% WAVREAD(FILE)
%   Caller must provide FILE
% WAVREAD(FILE,EXT,y)
%   EXT may be N or [N1 N2]
%   If omitted, returns ext=[] (e.g., read all samples)
% WAVREAD(FILE,EXT,y,FMT)
%   FMT = 'native' or 'double'
%   Default if omitted: 'double'
% WAVREAD(FILE,'size')
%   No FMT arg can be passed with 'size'
%
% An apparently undocument behavior was:
%   EXT=[] maps to 'size' call
% This behavior is maintained.
%
% Another apparently undocumented behavior was:
%   EXT=0 or EXT=[0 0] also map to 'size'
% We maintain this behavior as well, but issue a warning.
%
% In the future, we will process this as "no data to read" and
% return with an empty data set and no error.

% Defaults:
ext=[];  % extent: start and stop index of samples to read
isNative=false;
isSize=false;
y=0; %c

if nargin==0
    error('wavread:TooFewArguments', ...
        'Too few input arguments.');
end

% Get file name: WAVREAD(FILE, ...)
file = varargin{1};
varargin(1)=[];
if isempty(varargin), return; end

% See if a FMT option or 'size' was passed
fmt=varargin{end};
if ischar(fmt)
    idx = find(strncmpi(fmt,{'double','native','size'},numel(fmt)));
    if isempty(idx)
        error('wavread:UnrecognizedDataFormatSpecified', ...
            'Unrecognized data format specified: "%s"', fmt);
    elseif idx==2
        isNative=true;
    elseif idx==3
        ext='size';
        isSize=true;
    else % idx==1
        isNative=false;
    end
    % Remove parsed option
    varargin(end)=[];
    if isempty(varargin), return; end
end

% Another arg is present
nargs = numel(varargin);
if isSize && (nargs>0)
    error('wavread:SizeAndSampleRange', ...
        'Too many arguments with ''size'' option.');
end
% % Can only be one more argument passed: extent
% if nargs>1
%     error('wavread:TooManyInputArgs', ...
%         'Too many input arguments, or invalid argument order.');
% end
ext = varargin{1};
exts = numel(ext);     % length of extent info
if ~isnumeric(ext) || ~isreal(ext) || ~isreal(ext) ...
        || issparse(ext) || (exts>2)
    error('wavread:InvalidSampleRange', ...
        'Index range must be specified as a scalar or 2-element vector.');
end
if isempty(ext)
    warning('wavread:ReturnZeroSamples', ...
        sprintf(['Passing [] for sample range currently returns total file size,\n', ...
                 'equivalent to the ''size'' option.  In the future, this behavior\n', ...
                 'will be removed.  Use the ''size'' option if you wish to obtain\n', ...
                 'the file size.']));
    % For now, map this to a 'size' call
    % In the future, remove this "elseif" entirely and flow
    % into the "isscalar" test below
    ext='size';
    
elseif isequal(ext,0)
    warning('wavread:ReturnZeroSamples', ...
        sprintf(['Requesting 0 samples currently returns total file size,\n', ...
                 'equivalent to the ''size'' option.  In the future, this\n', ...
                 'behavior will change to return zero data samples from the\n', ...
                 'file (i.e., return with an empty matrix).  Use the ''size''\n', ...
                 'option if you wish to obtain the file size.']));
    % For now, map this to a 'size' call
    % In the future, remove this "elseif" entirely and flow
    % into the "isscalar" test below
    ext='size';
    
elseif isscalar(ext)
    if (ext ~= floor(ext)) || (ext<0)
        error('wavread:IntegerSampleCount', ...
            'Sample count must be a positive integer value');
    end
    ext = [1 ext];  % make into a 2-element sample range
else
    if any(ext ~= floor(ext))
        error('wavread:IntegerSampleCount', ...
            'Sample indices must be integer values');
    end
end
varargin(1)=[];
y = varargin{1};


% [EOF]
