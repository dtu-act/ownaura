%   ReadEnergyCurves.m
% Read information from the ASCII files containing Energy curve information
% from ODEON. The function return a structure NRG which contains for each of
% the 4 curves the time vector and the energy data.


% 1: a)Energy-time histogram.
% 2: b)Reverse-integrated decay curve (dB SPL)
% 3: c)Reverse-integrated decay curve (dB SPL), corrected for missing energy due to truncation.
% 4: d)Energy-time histogram for Sqr(Px),Sqr(Py) and Sqr(Pz) - only if calculated by Odeon 6.1 or later
% d1)Hint! The energy-intensity curve can be obtained by the formulae 10*log10(Sqrt(Sqr(Px)+Sqr(Py)+Sqr(Pz)
% d2)Note! Sqr(Px),Sqr(Py) and Sqr(Pz) are signed values, the sign is part the directional information

% open filename in read mode
% path=[cd,filesep];
% filename = [path,'Elmia RoundRobin2 detailed.Job03.00001EnergyCurves.Txt'];

function NRG=ReadEnergyCurves(path,room)

fid = fopen([path,filesep,room,'EnergyCurves.Txt'],'r');
if fid==-1
    error(['''',path,filesep,room,'EnergyCurves.Txt'' File not found.'])
end

NRG=struct('t',0,'data',[]);
for k=1:9
    tline = fgetl(fid); % to read a line
end
while 1
    tline = fgetl(fid);
    if ~ischar(tline), break, end
    if ~isempty(findstr(tline,'a) '))
        id=1;
        tline = fgetl(fid);
        tline = fgetl(fid);
        tline = fgetl(fid);
    end
    if ~isempty(findstr(tline,'b) '))
        id=2;
        tline = fgetl(fid);
        tline = fgetl(fid);
        tline = fgetl(fid);
    end
    if ~isempty(findstr(tline,'c) '))
        id=3;
        tline = fgetl(fid);
        tline = fgetl(fid);
        tline = fgetl(fid);
    end
    if ~isempty(findstr(tline,'d) '))
        id=4;
        tline = fgetl(fid);
        tline = fgetl(fid);
        tline = fgetl(fid);
        tline = fgetl(fid);
        tline = fgetl(fid);
    end

    % Storing data in NRG
    [NRG(id).t,NRG(id).data]=ReadLine(fid);
end
fclose(fid);

temp=NRG(4).data;
% if ODEON v8.5
if NRG(1).data(1,1)==0
    % reshape the data, shifting the data to put the 2 zeros at the end
    for kid=1:3
        tmplin=reshape(NRG(kid).data',1,size(NRG(kid).data,1)*size(NRG(kid).data,2));
        tmplin=tmplin([3:end 1 2]);
        NRG(kid).data=reshape(tmplin,size(NRG(kid).data,2),size(NRG(kid).data,1))';
        NRG(kid).data = NRG(kid).data(1:end-1,:);
    end

    % reshaping for id=4 directional information
    tmplin=reshape(NRG(4).data',1,size(NRG(4).data,1)*size(NRG(4).data,2));
    tmplin=tmplin([7:end 1 2 3 4 5 6]);
    temp=reshape(tmplin,size(NRG(4).data,2),size(NRG(4).data,1))';
    % endif ODEON v8.5
    NRG(4).data=reshape(temp,size(temp,1),3,8);
    NRG(4).data = NRG(4).data(1:end-1,:,:);
else
    NRG(4).data=reshape(temp,size(temp,1),3,8);
end



% for each line, store the time in t and the data for each band in data
function [t,data]=ReadLine(fid)
data=[];t=[];
while 1
    tline = fgetl(fid);
    if ~ischar(tline), break, end
    if isempty(tline), break, end
    % reading a typical line (time, 8 bands)
    tline=regexprep(tline, ',', '.');
    tmp=str2num(tline);
    t=[t;tmp(1)];
    data=[data;tmp(2:end)];
end


