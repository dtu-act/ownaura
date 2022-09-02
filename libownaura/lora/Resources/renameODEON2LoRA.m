% Rename ODEON exported files for use with LoRA
clear all

% Denis Byrne Seminar Room.Job01.00001Parameters
ODEON_prefix = 'Denis Byrne Seminar Room.Job';
Lstr = length(ODEON_prefix);
LoRA_prefix = 'DByrne_fin7IR';

% flags to rename relevant file types
rnmParameters = 1;
rnmEnergy = 1;
rnmReflections = 1;

listing = dir;

for i = 1:length(listing)
    fName = listing(i).name;
    if strfind(fName, ODEON_prefix)
        nJob = str2num(fName(Lstr+1:Lstr+2));
%             suffix = fName(Lstr+9:end);
        
        kPar = strfind(fName, 'Parameters');
        kEn = strfind(fName, 'EnergyCurves');
        kRef = strfind(fName, 'EarlyReflections');
        
        if ~isempty(kPar) && rnmParameters
            suffix = fName(kPar:end);
        end
        
        if ~isempty(kEn) && rnmEnergy
            suffix = fName(kEn:end);
        end
        
        if ~isempty(kRef) && rnmReflections
            suffix = fName(kRef:end);
        end
        
        new_fName = [LoRA_prefix, num2str(nJob), '_' suffix];
        
        movefile(fName, new_fName)
    end
end