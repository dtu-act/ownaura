% [pos, layoutS] = GetPos(mode,opt)
%
% Returns a spherical position layout (for microphones,
% loudspeakers, sources, etc.)
% 
% input:
%
%   mode 	mode specifier string:
%    'file'     loads the .mat file specified as a string in 'opt', 
%               containing a ‘pos’ variable (or ‘Mpos’)
%    'rings'	uses 'opt' as a matrix for defining the ring layout: 
%               opt(:,1): no. in the ring, 
%               opt(:,2): elevation of the ring 
%               opt(:,3): [optional], angle offset (phase) of the ring
%    'geo'      produces a quasi-regular 3D layout for a number of points
%               closest to 'opt', using the 3LD toolbox
%               (http://flo.mur.at/software/3ld)
%    'reg2d' 	produces a regular 2D layout (ring) of N=opt points 
%    'spiral' 	produces a spiral layout. First element of 'opt' is how many
%               points, the second is how many loops around the azimuth.
%    'random'   random points distributed on the sphere, number specified
%               in 'opt'
%
%   opt     mode options (see above)         
%
% output:	
%    pos 		(N x 2)	1st col. azimuth [-pi,pi], 2nd col. elevation
%                       angle [-pi/2,pi/2]
% 	 layoutS    Struct containing vertices and faces if derived
%               with 3LD toolbox (mode 'geo').
%___________________________________
% $Revision: 09.02.2012$
%    - Supports old file loading syntax as well, for compatibility.
% $Revision: 30.01.2012$
%    - Merged with updates from SF. 
% $Revision: 18.11.2011$
%    - Initial version. Spiral mode pleriminary. [MM]
%___________________________________

function [m, layoutS] = GetPos(mode,opt)

if strcmp(mode,'reg2d')
    % Regular 2D layout (ring)
    N = opt;
    n = 0:N-1;
    m(:,1) = n.*2*pi/N - pi;
    m(:,2) = zeros(N,1);
elseif strcmp(mode,'geo')
    % 3D layout -- using 3LD toolbox (http://flo.mur.at/software/3ld)
    % Based on subdivision of an icosahedron (creates a Geodesic grid)
    
    % Choose a setup with at least as many points as asked for.
    % [MM] The following calculation is based on solving the Euler's
    % polyhedron formula for an icosahedron whose edges are divided into
    % 'N' segments. ni = 0 and 1 are special cases.
    N = opt;
    if N <= 12
        ni = 0;
        v_n = 12; % number of vertices
    elseif N <= 32
        ni = 1;
        v_n = 32;
    else
        ni = ceil(sqrt((N-2)/10));
        v_n = 2 + 10*ni.^2;
    end
    if N~=v_n
        warning(sprintf('GetPos(): Geosphere mode. %d points requested, closest configuration is %d points.',...
            N, v_n));
    end
    try
        layoutS = geosphere('ico',ni,1); 
        [az,elev,R] = cart3sph(layoutS.vertices);
    catch
        error('GetPos(): 3LD toolbox is required for this option.')
    end
    m = [az, elev];
elseif strcmp(mode,'spiral')
    % Old implementation. To be removed. [MM]
    %     % Spiral layout. TODO: Behavior is not finalized.
    %     N = opt;
    %     if length(N)<2
    %         N(2) = 8; % Default value for azimuthal loops.
    %     end
    %     n = 0:N(1)-1;
    %     m(:,1) = n.*N(2)*pi/N(1) - pi;
    %     %m(:,2) = n.*pi/N(1) - pi/2;
    %     m(:,2) = asin(2*n./N(1)-1);
    %     
    %   SF implementation
    m = SpiralPos(opt);
elseif strcmp(mode,'tdesign')
    % Load t-design data.
    fpath = './data/Layouts/hardin_and_sloane/';
    p = dir(fpath);
    pn = {p(3:end).name};
    fname = ['des.3.',num2str(opt),'.'];
    pData = load([fpath,pn{max(strmatch(fname,pn))}],'-ascii');
    % rearrange to have a set of coordinates x,y,z in every row:
    pData = reshape(pData,3,length(pData)/3)';
    % convert to spherical coordinates
    [az,elev,R] = cart2sph(pData(:,1),pData(:,2),pData(:,3));
    m = [az,elev];
elseif strcmp(mode,'rings')
    % Ring layout. N is a matrix: N(:,1) is the number in each ring, and
    % N(:,2) is the elevation of the ring. N(:,3) is optional and specifies
    % an offset angle. 
    N = opt;
    % Determine the number of rings:
    nRings = size(N,1);
    m = zeros(sum(N(:,1)),2); % Preallocate output matrix
    
    % Check if there is a 3rd column of offset angles
    if (size(N,2) < 3)
        %If not, add zero offsets in 3rd column.
        N = [N, zeros(size(N,1),1)];
    end
    nCount = 1;
    for rCount = 1:nRings
        nInRing = N(rCount,1); % No. of points in the ring
        n = 0:nInRing-1;
        m(nCount:nCount+nInRing-1, 1) = n.*2*pi/nInRing + N(rCount,3) - pi;
        m(nCount:nCount+nInRing-1, 2) = N(rCount,2).*ones(nInRing,1); % Get the elevations;
        nCount = nCount + nInRing;
    end   
% -- Old options -- retained for now for compatibility.
elseif strcmp(mode,'moa36')
    Nt=16;
    horaz = [(0:Nt/2)*2*pi/Nt (-Nt/2+1:1:-1)*2*pi/Nt]';
    Nrest = 9;
    veraz = [(0:(Nrest-1)/2)*2*pi/Nrest (-(Nrest-1)/2:1:-1)*2*pi/Nrest]';
    m = [[horaz;veraz;veraz;0;0] [zeros(Nt,1);veraz*0+0.7268;veraz*0-0.7268;pi/2;-pi/2]];
elseif strcmp(mode,'moa28')
    Nt=16;
    horaz = [(0:Nt/2)*2*pi/Nt (-Nt/2+1:1:-1)*2*pi/Nt]';
    Nrest = 5;
    veraz = [(0:(Nrest-1)/2)*2*pi/Nrest (-(Nrest-1)/2:1:-1)*2*pi/Nrest]';
    m = [[horaz;veraz;veraz;0;0] [zeros(Nt,1);veraz*0+0.7370;veraz*0-0.7370;pi/2;-pi/2]];
% -- End old options.
elseif strcmp(mode,'random')
    % Random positions
    numPos = opt;
    az = 2*pi*rand(numPos,1)-pi;
    elev = asin(2*rand(numPos,1)-1);
    m = [az, elev];
% load file    
elseif strcmp(mode,'file')
    loadS = load(opt,'-mat','-regexp','[Mm]?[pP]os');
    fldName = fieldnames(loadS);
    if isempty(fldName)
        error('GetPos(): No ''pos'' or ''mpos'' variables found in specified .mat file.');
    end
    m = loadS.(fldName{1});
% -- load file -- old syntax!    
elseif exist(mode,'file')
    loadS = load(mode,'-mat','-regexp','[Mm]?[pP]os');
    fldName = fieldnames(loadS);
    if isempty(fldName)
        error('GetPos(): No ''pos'' or ''mpos'' variables found in specified .mat file.');
    end
    warning('GetPos(): Old file loading syntax. Use GetPos(''file'',''loadme.mat'') instead');
    m = loadS.(fldName{1});    
else
    error(['GetPos(): Invalid mode identifier: ' mode]);
end

end