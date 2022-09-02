%   ReadParameters.m
% Read information from the ASCII files containing Parameters information
% from ODEON. 


% path='C:\Odeon 8.5 Combined\rooms\test\testerlate';
% room = 's2oe100.Job04.00001';

function Param=ReadParameters(path,room)

% open filename in read mode
fid = fopen([path,filesep,room,'Parameters.Txt'],'r');
if fid==-1
        error('File not found.');
    Param={'File not found.'};
end

        Param.room          = room;
        Param.path          = path;
for k=1:6
    tline = fgetl(fid);% 6
end
            Param.source        = stget(tline,'Description	'); 
            
tline = fgetl(fid);% 7
tmp = stget(tline(1:end-1),'= ('); 
            Param.PosSrc        = readpos(tmp(1:end-1));
            
tline = fgetl(fid);% 8
ids = regexp(tline,' ');
            Param.theta         = str2double(regexprep(tline(ids(2)+1:ids(3)-1), ',', '.'));
            Param.delta         = str2double(regexprep(tline(ids(5)+1:ids(6)-1), ',', '.'));

tline = fgetl(fid);% 9
            Param.directivity   = stget(tline,'Directivity file	');
            
ptres = 0;            
while ptres == 0
    tline = fgetl(fid);% 14
    if ~ischar(tline), break, end
    if ~isempty(regexp(tline,'POINT RESPONSE','ONCE')), ptres=1; end;
end
target = 'job ';
            Param.job           = str2double(stget(tline,target));

tline = fgetl(fid);% 15
tmp = stget(tline,'Receiver Number: ');
            Param.receiver      = tmp(3:regexp(tmp,'(','ONCE')-10);
tmp = stget(tline,'= (');
            Param.PosRec        = readpos(tmp(1:end-1));
tline = fgetl(fid);% 16
tline = fgetl(fid);% 17
Param.EDT        = str2num(regexprep(stget(tline,'EDT	'),',','.'));
tline = fgetl(fid);% 17
Param.T30        = str2num(regexprep(stget(tline,'T30	'),',','.'));
tline = fgetl(fid);% 17
Param.SPL        = str2num(regexprep(stget(tline,'SPL	'),',','.'));
tline = fgetl(fid);% 17
Param.C80        = str2num(regexprep(stget(tline,'C80	'),',','.'));
tline = fgetl(fid);% 17
Param.D50	     = str2num(regexprep(stget(tline,'D50	'),',','.'));
tline = fgetl(fid);% 17
Param.Ts	     = str2num(regexprep(stget(tline,'Ts	'),',','.'));
tline = fgetl(fid);% 17
Param.LF80	     = str2num(regexprep(stget(tline,'LF80	'),',','.'));
tline = fgetl(fid);% 17
Param.SPLA	 = str2num(regexprep(stget(tline,'A)	'),',','.'));
tline = fgetl(fid);% 17
Param.LG80	     = str2num(regexprep(stget(tline,'	'),',','.'));
tline = fgetl(fid);% 17
Param.STI	     = str2num(regexprep(stget(tline,'STI	'),',','.'));

fclose(fid);

Param.distance   = sqrt(sum((Param.PosRec-Param.PosSrc).^2)); % in meters


% read cartesian position in the form f.ex.: 0,750, -0,900, 1,650
function pos=readpos(tmp)

idc = findstr(tmp, ',');
idc = [0 idc length(tmp)]; 
for k = 1:3
    pos(k)=str2num(regexprep(tmp(idc(2*k-1)+1:idc(2*k+1)-1), ',', '.'));
end

% read string after target string in tmp
function aftertarget=stget(tmp,target)

aftertarget='';
if ischar(tmp) && ischar(target)
    id=regexp(tmp,target,'ONCE');
    if ~isempty(id) && id(1)<length(tmp)-length(target)+1
        aftertarget=tmp(id(1)+length(target):end);
    end   
end