function [ theta ] = get_theta( P_in, T_in )
%GET_THETA(P_in, T_in) Calculate potential temperature
%
% P_in must be Pa, and T_in must be K
% P_in and T_in must be the same size

if sum(size(P_in)==size(T_in))~=2
    error('P and T arrays must have the same size')
end

% potential temperature
P0=1e5; % 1000 hPa
R_cp=0.286; % R/cp for air

theta=T_in .* ( (P0./P_in).^R_cp );

end

