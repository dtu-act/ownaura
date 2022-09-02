function pos = LoudspeakersPos3D_AVIL()

% June 2015, by Marton Marschall

ringAngles = [80 56 28]; % Ring elevations <- o.n.e.& cnb optimized for 7/5
noOnRingsUpper = [2 6 12 24]; % Speakers per ring
phaseOffset = [0 0 0 0 0 1 1]; % Rotation phase

noOnRingsFull = [noOnRingsUpper, fliplr(noOnRingsUpper(1:end-1))];
ringAnglesUpper = [ringAngles 0];
ringAnglesFull = [ringAnglesUpper, -fliplr(ringAnglesUpper(1:end-1))];

phases = phaseOffset.*pi./noOnRingsFull;
pos = GetPos('rings',[noOnRingsFull.', ringAnglesFull.'/180*pi, phases.']);
% Add pi to azimuth angle to change range to [0,2*pi)
pos = pos + repmat([pi 0],size(pos,1),1);
end