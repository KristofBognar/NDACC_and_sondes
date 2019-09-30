% interpolate US standard atmosphere profile to given altitude grid
% use US standard for Eureka since AFGL 1976 has the following profiles:
%       tropical, midlat summer/winter, subarctic summer/winter, US standard


cd('/home/kristof/work/NDACC/HDF4_data_submission/US_standard_AFGL1976')

load('alt_km');
load('pres_mb');
load('temp_K');
load('dens_cm-3');
load('ozone_ppm');
load('no2_ppm');

% grid for NDACC HDF files
alt_grid=[0.795, [1.5:1:60.5]]; % in km

USstandard_P=interp1(alt_km,pres_mb*100,alt_grid); % convert to Pa
USstandard_T=interp1(alt_km,temp_K,alt_grid); % 
USstandard_dens=interp1(alt_km,dens_cm_3,alt_grid); % 
USstandard_o3=interp1(alt_km,ozone_ppm*1e-6,alt_grid); % convert to unitless ratio
USstandard_no2=interp1(alt_km,no2_ppm*1e-6,alt_grid); % convert to unitless ratio

USstandard_alt=alt_grid;

save('USstandard.mat','USstandard_P','USstandard_T','USstandard_dens',...
     'USstandard_o3','USstandard_no2','USstandard_alt');