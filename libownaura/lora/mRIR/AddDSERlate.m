% AddDSERlate
% 
% Derive the multichannel response by adding the direct sound the early reflections
% and the late part
%
% mIR = AddDSERlate(mIRearly,ylate,DSorder,ERorder)
%
% input:
%   mIRearly    struct    name of the path where the odeon text file is
%   ylate       (samples,channels): late part response
%   DSorder     int: Ambisonic order for the direct sound. 0 -> closest loudspeaker
%   ERorder     int: Ambisonic order for the early refelction. 0 -> closest loudspeaker
%
% output
%   out         matrix (samples,channels) multichannel IR
%
% uses ReadEnergyCurves.m, ReadEarlyReflections.m, ReadParameters.m, fDS.m, fER.m and
% fLATE.m. 
%___________________________________
% $Revision: #3 $ 
%    - Order as an integer.
%
% $Revision: #3 $ 
%    - Initial version.
%___________________________________
% (c) 2007 S. Favrot, CAHR

function mIR = AddDSERlate(mIRearly,ylate,DSordern,ERordern,ignore_DS)

if isnan(sum(sum(ylate,2)))
    ylate=0;
end

if isstruct(mIRearly)
    if nargin<3
        fnames = fieldnames(mIRearly);
        nf = strmatch('yDS',fnames);
        if nf, DSorder = fnames{nf(end)}(end);isDS =1; end
        fnames = fieldnames(mIRearly);
        nf = strmatch('yER',fnames);
        if nf, ERorder = fnames{nf(end)}(end);isER =1; end
    else
        DSorder=num2str(DSordern);
        ERorder=num2str(ERordern);
        isDS = isfield(mIRearly, ['yDS',DSorder]);
        isER = isfield(mIRearly, ['yER',ERorder]);
    end
    if isDS && ~ignore_DS
        eval(['yDS = mIRearly.yDS',DSorder,';'])
        ld=size(yDS,1);
        if ylate==0
            ylate=yDS;
        else
            ylate(1:ld,:) = ylate(1:ld,:)+yDS;
        end

%         ylate(1:ld,:) = ylate(1:ld,:)+yDS;
    else
        warning(['yDS',DSorder,' cannot be found'])
    end
    if isER
        eval(['yER = mIRearly.yER',ERorder,';'])
        if size(yER,1) > size(ylate,1)
            le=size(ylate,1);
            yER(1:le,:) = yER(1:le,:)+ylate;
            ylate = yER;
            warning('Late reverb tail is shorter than early reflections...')
        else
            le=size(yER,1);
            ylate(1:le,:) = ylate(1:le,:)+yER;
        end
    else
%         warning(['yER',ERorder,' cannot be found'])
    end
    mIR=ylate;
else
    error('First argument not a structure')
end

