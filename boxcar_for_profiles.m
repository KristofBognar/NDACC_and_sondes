function [smoothed] = boxcar_for_profiles(x,a,h,join)
%boxcar: smoothes the kink between profiles stiched together
%   Only smoothes profile around the kink, leaves the rest unchanged
%   Input:
%       x,a(x): data points to average - must be line or column vectors!
%       h: half-width of averaging window, in points of x
%       join: index of last point of bottom profile (for increasing x)

% keep original data far from the kink
smoothed=a;

% check if window is larger than profile coverage before/after the kink,
% take half the size if not
if join-2*h < 1 || join+2*h+1 > max(size(x))
    h=h/2;
end

% test again, abort if still not good
if join-2*h < 1 || join+2*h+1 > max(size(x))
    if join==0
        % no profile, all NaNs -- return original profiles
        smoothed=a;
        return
    else
        error('Even reduced averaging window is too large')
    end
end

% smooth out the kink
for i=join-h:join+h+1

    smoothed(i)=nanmean(a(i-h:i+h));
    
end

