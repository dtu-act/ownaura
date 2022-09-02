%   ReadEarlyReflections.m
%  Read information from the ASCII files containing the reflectogram data
% from ODEON. The script return ER containing the data matrix. each line
% correspond to a reflection and the colomns are:
% 1:Refl	2:ms(source)	3:ms(direct)	4:63	5:125	6:250	7:500	
% 8:1000	9:2000	10:4000   11:8000	12:Order	13:Azimuth(deg)	14:elevation(deg)	
% 15:Source	

% open filename in the read mode
% path=['C:\Odeon 8.5 Combined\rooms\test\'];
% filename = [path,'shoebox.Job01.00001EarlyReflections.Txt'];
% path=['C:\Odeon 8.5 Combined\rooms\'];
% filename = [path,'auditorium21 at DTU.Job03.00001EarlyReflections.Txt'];
function ER=ReadEarlyReflections(path,room)
fid = fopen([path,filesep,room,'EarlyReflections.Txt'],'r');
if fid==-1
    error('File not found.')
end

ER=[];
% skip the 3 first lines
for k=1:3
   tline = fgetl(fid);
end
while 1
    tline = fgetl(fid);
    if ~ischar(tline), break, end
    tline=regexprep(tline, ',', '.');
    tmp=str2num(tline);
    ER=[ER;tmp];
end
fclose(fid);




