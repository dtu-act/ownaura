% plotIR
%
% plot the multichannel impulse response.
%
% plotIR(path,roomjob) or plotIR(path,roomjob,'amb1st')
%       -plot the 1st order ambisonic encoded response
% plotIR(path,roomjob,gplot,gpart)
%       -gplot    'energypolar' plot the energy in a polar shape
%                 'energyrect' plot the energy in a rectangular shape
%       -gpart    'er' plot the early part of the response (discrete reflections)
%                 'late' plot envelopes of the late part of the response 
%
% uses wavplot and colorplot
%
% (c) 2007 S. Favrot, CAHR
function  plotIR(varargin)
% varargin={path,room, 'amb1st','part','er'};

% global LoRA
% 
% try isstruct(LoRA); catch,    LoRA_startup, end

error(nargchk(2, 4, nargin))
path=varargin{1};
room=varargin{2};
try gplot=varargin(3); 		  catch, gplot		= 'amb1st'; 	end;
try gpart=varargin(4); 		  catch, gpart		= 'late'; 	k=1; end;

if strcmp(gpart,'late'), k=1; end
if strcmp(gpart,'er'), k=0; end


if strcmp(gplot,'amb1st')
    wavplot(path,room,job)
elseif strcmp(gplot,'energyrect')
    colorplot(path,room,'energyrect',k)
elseif strcmp(gplot,'energypolar')
    colorplot(path,room,'energypolar',k)
end

