% function to read in retrieved VCD data and format them appropriately to
% create the NDACC HDF files
% Created by Kristof Bognar, 2017
%
% Code saves bash script that can be run on berg (to create HDF files in IDL)
%
% Runs for specified instrument/tracegas
%
% Creates either monthly or yearly HDF files
%
% GBS VCDs are loaded from saved .mat files
% Ozonesonde and radiosonde data are retrieved from saved files
% Averaging kernels are retrieved runtime from NDACC LUT
%
% Input files are generated using write_HDF_input_file.m, from template files
%   originator attributes, dataset attributes and variable
%   descriptions/notes are hardcoded in template files
%
%%% Old version (prior to QA/QC with Bravo):
    % use ozonesonde P, T data to calculate air number densities, since
    % this is used to calculate the total column apriori (and it's not
    % needed for anything else) -- note in variable description!!
    %    
    % use AVK LUT profile for partial column apriori for O3 and NO2
%    
%%% Current:
    % use radiosonde P, T data (extended by AFGL) to recalculate air
    % number densities after all the interpolation is complete, so P, T
    % and n columns match in HDF file (required for QA/QC)
    %
    % For ozone, use ozonesonde VMR data and air number density to get partial profile
    % apriori!! For NO2, still use AVK LUT profile 
    % Related: no scaling of partial column profile for O3
%
% Not very well written, feel free to improve any part of it

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    

%% control variables %%

% rapid delivery or yearly submission?

% Generates yearly files for submission to NDACC archive
% if false, rapid delivery options are selected
standard_submission=true;

% RD file to process, keep format as '_<number>'
batch='_10'; 

instr='UT-GBS';
% instr='PEARL-GBS';

% select tracegas to archive
% 1: O3
% 2: NO2
% 3: NO2 UV
tg=2;

% how to break up measurements (files created from first to last measurement date)
% true: yearly files
% false: monthly files
yearly_files=true;

% discard high uncertainty data until file passes CAMS filter?
% if true, measurements are discarded until data outside limits is <50%
do_cams_filter=true;
if tg==3, do_cams_filter=false; end

if standard_submission
    
    % select datafile version
    version='003';

    % start/end of measurements
    startyear=2019;
    endyear=2019;
    
    % location of VCD files
    % filenames hardcoded
    vcd_dir='/home/kristof/work/GBS/VCD_results/';
    
    batch_tag='';

else % rapid delivery setup
    
    % select datafile version
    version='002';
    
    % start/end of measurements is always current year
    startyear=year(datetime(now,'convertfrom','datenum'));
    endyear=year(datetime(now,'convertfrom','datenum'));

    % location of VCD files
    % filenames hardcoded
    vcd_dir='/home/kristof/work/GBS/VCD_results/NDACC_RD/';
    
    batch_tag=batch;
    
end

%% misc control variables

% AVK LUT parent directory (contains ozone and no2 folders, default folder names)
AVK_LUT_dir='/home/kristof/work/NDACC/guidelines/2012/';

% directory on berg where input files are saved for HDF file generation
bergdir='/home/kristof/berg/NDACC_HDF/';

% save working directory
cur_dir = pwd;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
%% loop over measurements
for year=startyear:endyear
    

if year==2001 || year==2002, continue, end


%% asign month boundaries (with leap years)
if ~yearly_files
    % using day of year (jan 1 = 1), not fractional day (jan 1 = 0.xx) 
    % our dataset uses DoY + fractional time instead of fractional day
    if mod(year,4)==0
        month_bounds=[[1,31];[32,60];[61,91];[92,121];[122,152];[153,182];...
                      [183,213];[214,244];[245,274];[275,305];[306,335];[336,366]];
    else
        month_bounds=[[1,31];[32,59];[60,90];[91,120];[121,151];[152,181];...
                      [182,212];[213,243];[244,273];[274,304];[305,334];[335,365]];
    end
    month_names={'January','February','March','April','May','June','July',...
                 'August','September','October','Novermber','December'};
end
         
%% variables for instrument location
lat=80.053;
long=-86.416;
alt_instr=610;

%% define altitude grid (based on AVK LUT)
% altitude of instrument is lowest boundary
% alt_grid contains layer center values
alt_grid=[0.795, [1.5:1:59.5]]'; % in km

grid_bound=[alt_instr/1000,1];
for i=1:max(size(alt_grid))-1
    grid_bound=[grid_bound; [i,i+1]];
end

%% load appropriate tracegas VCD file

if tg==1
%     vcd_file=['/home/kristof/work/GBS/', instr, '/', num2str(year), '/VCD/ozone/ozone_v2_86-90.mat'];
%     vcd_file=['/home/kristof/work/GBS/', instr, '/ozone_v2_86-90_2016.mat'];
%     vcd_file=['/home/kristof/work/GBS/VCD_results/VCD_compare_cristen/2010_myDSCD_use_sonde.mat'];
    vcd_file=[vcd_dir instr '_O3_VCD_' num2str(year) batch_tag '.mat'];
elseif tg==2        
%     vcd_file=['/home/kristof/work/GBS/', instr, '/', num2str(year), '/VCD/no2/no2_v1_86-91.mat'];
    vcd_file=[vcd_dir instr '_NO2_VCD_' num2str(year) batch_tag '.mat'];
elseif tg==3 
    vcd_file=[vcd_dir instr '_NO2_UV_VCD_' num2str(year) batch_tag '.mat'];
end

try load(vcd_file); catch, continue, end
clearvars vcd_file;

% check year
if year~=VCD_table.year(1), error('VCD file contains wrong year'), end

%% filter VCD file

if strcmp(instr,'UT-GBS')
    instr_in=1;
else
    instr_in=2;
end

% fiter VCDs
%   add syst error to VCDs that are otherwise fine but other twilight is missing
%   use CAMS error filter to throuw out bad data
[ind_goodvcd,VCD_table]=filter_VCD_output(tg,VCD_table,rcd_S,instr_in,true,do_cams_filter);

if isempty(ind_goodvcd), continue, end

%% plot vcds and error stats

% [UVVIS.DOAS.ZENITH.O3]
% SYSTEMATIC=[2.8,10]
% RANDOM=[3.5,5]
%
% [UVVIS.DOAS.ZENITH.NO2]
% SYSTEMATIC=[1.5,24]
% RANDOM=[2.8,18]

sys=(VCD_table.sigma_mean_vcd(ind_goodvcd)./VCD_table.mean_vcd(ind_goodvcd))*100;
rand=(VCD_table.std_vcd(ind_goodvcd)./VCD_table.mean_vcd(ind_goodvcd))*100;

figure()

subplot(311)
gscatter(VCD_table.fd(ind_goodvcd), VCD_table.mean_vcd(ind_goodvcd), VCD_table.ampm(ind_goodvcd), 'rb', '..')
ylabel('VCD (molec/cm^2)')
legend('am','pm')

subplot(312)
plot(VCD_table.fd(ind_goodvcd), sys, 'k.')
ylabel('Systematic error (%)')
grid on
grid minor

subplot(313)
plot(VCD_table.fd(ind_goodvcd), rand, 'k.')
ylabel('Random error (%)')
xlabel(['Fractional day, ' num2str(year) ' (UTC)'])
grid on
grid minor

%% load standard atm
load('/home/kristof/work/NDACC/HDF4_data_submission/US_standard_AFGL1976/USstandard.mat');

%% use AVK LUT to get averaging kernels and partial profiles for the year

disp(['Processing ' num2str(year) ' data'])
disp('Generating and reading AVK LUTs')

if tg==1
    lut_input_arr=[VCD_table.year(ind_goodvcd), VCD_table.day(ind_goodvcd),...
                   VCD_table.mean_vcd(ind_goodvcd)];
else
    lut_input_arr=[VCD_table.year(ind_goodvcd), VCD_table.fd(ind_goodvcd)-1];
end

[lut_prof,lut_avk] = read_DOAS_prof_avk( tg, lut_input_arr, AVK_LUT_dir );


%% scale partial profiles to match twilight VCD (Francois)

% integrate profiles and convert to cm^2
% (profile starts in 4th column in o3 file, 3rd column in no2 file)
lut_prof_sum=nansum(lut_prof(:,end-59:end),2)*1e5;

% get ratio of integrated profile to actual VCD
prof_ratio=VCD_table.mean_vcd(ind_goodvcd)./lut_prof_sum;

% scale profile (result still in molec/cm^3)
lut_prof_scaled=lut_prof;
for i=1:size(prof_ratio,1)
    lut_prof_scaled(i,end-59:end)=lut_prof(i,end-59:end).*prof_ratio(i);
end
    
%% Create shell script to run idlcr8hdf.sav on berg

% trace gas name strings
if tg==1
    gas='o3';
    gas_input='O3';
elseif tg==2
    gas='no2';
    gas_input='NO2';
elseif tg==3
    gas='no2uv';
    gas_input='NO2UV';
end

% directory on berg
if year==startyear
    
    % shell script file name
    shell_script=[bergdir 'run_idl_' gas_input '_' instr batch_tag '.sh'];

    % check if script exists, wipe if yes
    if exist(shell_script,'file')
        system(['rm ' shell_script]);
        system(['touch ' shell_script]);
    else
        system(['touch ' shell_script]);
    end

    % add some lines to the file
    fid=fopen(shell_script, 'w');
    fprintf(fid,'#!/bin/bash');
    fprintf(fid,'\n');
    fprintf(fid,'# Script to generate HDF files');
    fprintf(fid,'\n');
    fprintf(fid,['# Created by NDACC_data_submission.m on ' date]);
    fprintf(fid,'\n');
    fprintf(fid,'\n');
    fprintf(fid,'cd input_files/');
    fprintf(fid,'\n');
    fprintf(fid,'cp ../idlcr8hdf.sav ../tableattrvalue_04R031.dat .');
    fprintf(fid,'\n');
    fprintf(fid,'\n');
    fprintf(fid,'idl << EOF');
    fprintf(fid,'\n');
    fclose(fid);

end

%% loop over the months / year %%

% select number of loops based on output file format
if yearly_files
    end_loop=1;
else
    end_loop=12;
end

for mm=1:end_loop
    %% find measurements in given month/year

    if yearly_files
        % use all indices where VCD is reported
        ind_current=ind_goodvcd;
        % need separate index for LUT files since they're already in
        % dimensions of ind_goodvcd
        ind_avk=1:length(ind_goodvcd);
    else
        % only use indices for given month
        ind_month_all=find(VCD_table.day>=month_bounds(mm,1) &...
                       VCD_table.day<=month_bounds(mm,2));

        % take only the measurements where VCD is actually reported
        % need separate index for LUT files since they're already in
        % dimensions of ind_goodvcd
        [ind_current,~,ind_avk]=intersect(ind_month_all,ind_goodvcd);
    end
    
    % stop if no measurements for given month/year
    if isempty(ind_current), continue, end

    % length of time series
    len=max(size(ind_current));


    %% convert day of the year to fractional day and calculate time in required format
    % VCD table has day of the year (jan. 1 00:00 = 1)
    % need time from jan 1, 2000, 00:00:00 UTC (which is equal to 0)
    % matlab datenum runs from jan 1, 0000, 00:00:00 which is equal to 1!!
    
    %%% need to recalculate times/SAA for measurements, mean time and mean SZA
    %%% don't match up in VCD files since SZA/SAA are not a linear function of
    %%% time -- use correct_time_to_sza.m to minimize this discrepancy
    %%%
    %%% Leave SZA unchanged and adjust time and SAA -- SZA is the most
    %%% important datapoint
    
%     disp('Correcting measurement timesand SAA to match SZA')
    
% %     % sorry for the ridiculous time-conversion circle...
% %     new_time_in=mjd2k_to_date(ft_to_mjd2k(VCD_table.fd(ind_current)-1,year));
% %     
% %     [new_time_out,new_saa_out]=correct_time_to_sza(new_time_in,...
% %                                                    VCD_table.sza(ind_current),...
% %                                                    VCD_table.ampm(ind_current),...
% %                                                    VCD_table.saa(ind_current)+180);
% %     
% %     [~,new_time_ft]=fracdate(new_time_out);
% %     
% %     datetime=ft_to_mjd2k(new_time_ft,year);
    datetime=ft_to_mjd2k(VCD_table.fd(ind_current)-1,year);
    
    datetime_start=ft_to_mjd2k(VCD_table.fd_min(ind_current)-1,year);
    datetime_stop=ft_to_mjd2k(VCD_table.fd_max(ind_current)-1,year);


    %% find total integration time and AMF for each twilight measurement

    % loop through all measurements in given month
    int_time=zeros(len,1);
    amf_all=zeros(len,1);
    count=1;
    
    for i=ind_current' % only loop throught indices that have good VCDs

        % find min and max time in dscd_S file (evening measuremets slip 
        % into next day in UTC!)
        inds=[0,0];
        inds(1)=find(dscd_S.fd==VCD_table.fd_min(i), 1 ); % fd_min value repeats once in 2015 no2_uv file??

        inds(2)=find(dscd_S.fd==VCD_table.fd_max(i));

        % sum integration times ([tint] = seconds)
        int_time(count)=sum(dscd_S.tot_tint(inds(1):inds(2)));

        % average AMFs ???
        amf_all(count)=nanmean(dscd_S.amf(inds(1):inds(2)));
        
        count=count+1;
    end

    % assign AMF variable
    amfstrato_zenith=amf_all;
    
    %% viewing and solar angles
    sza_f=VCD_table.sza(ind_current);
    saz=VCD_table.saa(ind_current)+180;
% %     saz=new_saa_out;
    if strcmp(instr,'UT-GBS')
        pointing_az=ones(len,1).*35;
    elseif strcmp(instr,'PEARL-GBS')
        pointing_az=ones(len,1).*330;
    end
    pointing_ze=ones(len,1).*90;

    %% cloud conditions
    % empty character array
    cloud_cond_mat=repmat(char(0),len,1);

    %% assign VCD and error values
    % convert to peta molecules/cm^2
    vcstrato_zenith=VCD_table.mean_vcd(ind_current).*1e-15;
    vcstrato_error_rand_zenith=VCD_table.std_vcd(ind_current).*1e-15;
    vcstrato_error_sys_zenith=VCD_table.sigma_mean_vcd(ind_current).*1e-15;

    %% read P, T from radiosonde data, read O3, air mixing ratios and total column a-priori from ozonesonde data
    
    if yearly_files
        disp(['Interpolating sonde data'])
    else
        disp(['Interpolating sonde data for ', month_names{mm}])
    end
        
    % define arrays that go into HDF file
    % dimensions are time x altitude; initialize with fill values
    pres=ones(len,max(size(alt_grid)))*-90000.0; % 
    temp=ones(len,max(size(alt_grid)))*-90000.0; % 
    air_par_col=ones(len,max(size(alt_grid)))*-90000.0; % air number dens
    apriori_prof_zen=ones(len,max(size(alt_grid)))*-90000.0; % VMR apriori from sonde
    vcstrato_apriori_zenith=ones(len,1)*-90000.0; % tot column apriori from sonde
    col_profile_apriori_zenith=ones(len,max(size(alt_grid)))*-90000.0; % partial col apriori from sonde
    
    % loop over measurements
    nn=0;
    
    do_sonde_PT=true;
    do_sonde_vmr=true;
    
    for i=1:len
        
        % display progress info
        disp_str=['Measurement ', num2str(i), '/', num2str(len)];
        % stuff to delete last line and reprint updated message
        fprintf(repmat('\b',1,nn));
        fprintf(disp_str);
        nn=numel(disp_str);    

        % get fractional day of measurement
        ft=VCD_table.fd(ind_current(i))-1; 
        
        %% get interpolated profiles (alt grid is the same; 10m res to 40.01 km)
        
        if do_sonde_PT % flag checking if radiosonde data exists
            sonde_PT_exists=true; % flag checking if current sonde data is good
            
            try
                [alt_grid_tmp,P_tmp,T_tmp]=interp_radiosonde(year,ft); % Pa and K
            catch ME
                sonde_PT_exists=false;

                alt_grid_tmp=[15:10:40005]';
                P_tmp=NaN(size(alt_grid_tmp));
                T_tmp=NaN(size(alt_grid_tmp));
                
                % if file doesn't exists, skip this part for the rest of the loop
                if (strcmp(ME.identifier,'MATLAB:load:couldNotReadFile'))
                    do_sonde_PT=false;
                end
            end
            
            % no sonde data if output is all NaN (e.g. sonde record stops
            % before current measurement time)
            if sum(isnan(P_tmp))==length(P_tmp)
                sonde_PT_exists=false;
            elseif sum(isnan(T_tmp))==length(T_tmp)
                sonde_PT_exists=false;
            end
            
        end
        
        if tg==1 && do_sonde_vmr % only read ozonesondes for o3 data, check if file actually exists
            sonde_vmr_exists=true; % flag checking if current sonde data is good
            
            try
                [~,vmr_tmp,~,tot_col_tmp]=interp_ozonesonde(year,ft);
            catch ME
                sonde_vmr_exists=false;
                
                vmr_tmp=NaN(size(alt_grid_tmp));
                tot_col_tmp=NaN;
                
                % if file doesn't exists, skip this part for the rest of the loop
                if (strcmp(ME.identifier,'MATLAB:load:couldNotReadFile'))
                    do_sonde_vmr=false;
                end
                
            end
            
            % no sonde data if output is all NaN (e.g. sonde record stops
            % before current measurement time)
            if sum(isnan(vmr_tmp))==length(vmr_tmp)
                sonde_vmr_exists=false;
            end
            
        else
            sonde_vmr_exists=false;
            
            vmr_tmp=NaN(size(alt_grid_tmp));
            tot_col_tmp=NaN;
        end
        
        % sonde alt grid is in meters!
        alt_grid_tmp=alt_grid_tmp/1000;
        
        %% extend to 60 km using interpolated standard atm 
        
        % keep imported 10m grid, but extend to 60 km
        alt_grid_tmp_ext=[alt_grid_tmp;[40.015:0.01:60.005]'];
        
        % do P, T data first
        if sonde_PT_exists
        
            % temporary arrays for individual profiles (extend NaNs to 60 km)
            P=NaN(size(alt_grid_tmp_ext));
            P2=NaN(size(alt_grid));
            P(1:4000)=P_tmp;

            T=NaN(size(alt_grid_tmp_ext));
            T2=NaN(size(alt_grid));
            T(1:4000)=T_tmp;

            % find where profiles are missing
            ind_nan_P=find(isnan(P));
            ind_nan_T=find(isnan(T));

            % and interpolate standard atm onto temporary altitude grid to
            % extend profile (units match)
            P(ind_nan_P)=interp1(USstandard_alt,USstandard_P,alt_grid_tmp_ext(ind_nan_P)); %Pa
            T(ind_nan_T)=interp1(USstandard_alt,USstandard_T,alt_grid_tmp_ext(ind_nan_T)); %K

            % width of smooting window in km:
            fw_km=6; 
            % half width of window in grid points (10m grid)
            hw=fw_km*500/10; 

            % smooth out kinks
            P=boxcar_for_profiles(alt_grid_tmp_ext,P,hw,ind_nan_P(1)-1);
            T=boxcar_for_profiles(alt_grid_tmp_ext,T,hw,ind_nan_T(1)-1);

            % calculate effective layer values for NDACC grid
            %(layers are too thick to just interpolate)
            for j=1:max(size(alt_grid))

                % indices of layer boundaries
                ind_eff=find(alt_grid_tmp_ext>=grid_bound(j,1) & alt_grid_tmp_ext<grid_bound(j,2));

                % use normal mean, so if layer contains NaNs (i.e. profile doesn't cover 
                % entire layer) then result is NaN
                P2(j)=nanmean(P(ind_eff));
                T2(j)=nanmean(T(ind_eff));
                
            end
            
        else 
            
            % if no sonde data, use standard atm
            % (interpolating and then averaging again would change values slightly)
            P2=USstandard_P(1:end-1);
            T2=USstandard_T(1:end-1);
            
        end
        
        % Assign P, T values to final variable
        pres(i,:)=P2/100; % convert to hpa
        temp(i,:)=T2; % already in K
        
        % use P, T profile to calculate air number density
        % convert to partial column (in molec/cm^2) (layers are 1km=1e5cm thick)
        num_dens2=((6.022141e23*P2)./(8.3144598*T2))*1e-6; 
        air_par_col(i,:)=num_dens2*1e5; 

        % do vmr data (code mostly same as for P, T)
        if sonde_vmr_exists % only true for O3 data

            % temporary arrays for individual profiles (extend NaNs to 60 km)
            vmr=NaN(size(alt_grid_tmp_ext));
            vmr2=NaN(size(alt_grid));
            vmr(1:4000)=vmr_tmp;

            % find where profiles are missing
            ind_nan_vmr=find(isnan(vmr));

            % and interpolate standard atm onto temporary altitude grid to
            % extend profile (units match)
            vmr(ind_nan_vmr)=interp1(USstandard_alt,USstandard_o3,alt_grid_tmp_ext(ind_nan_vmr)); %unitless

            % width of smooting window in km:
            fw_km=6; 
            % half width of window in grid points (10m grid)
            hw=fw_km*500/10; 

            % smooth out kinks
            vmr=boxcar_for_profiles(alt_grid_tmp_ext,vmr,hw,ind_nan_vmr(1)-1);

            % calculate effective layer values for NDACC grid
            %(layers are too thick to just interpolate)
            for j=1:max(size(alt_grid))

                % indices of layer boundaries
                ind_eff=find(alt_grid_tmp_ext>=grid_bound(j,1) & alt_grid_tmp_ext<grid_bound(j,2));

                % use normal mean, so if layer contains NaNs (i.e. profile doesn't cover 
                % entire layer) then result is NaN
                vmr2(j)=nanmean(vmr(ind_eff));

            end
            
            % scale VMR to ozone total column
            
            % get total column from VMR*num_dens
            col_from_vmr=sum(num_dens2.*vmr2)*1e5;

            % get ratio of integrated profile to actual VCD
            prof_ratio=tot_col_tmp./col_from_vmr;

            % scale VMR profile to match total column
            vmr2=vmr2*prof_ratio;

            % partial column profile in Pmolec/cm^2
            col_profile_apriori_zenith(i,:)=num_dens2.*vmr2*1e5*1e-15;

            % assign VMR profile
            apriori_prof_zen(i,:)=vmr2*1e12; % convert to ppt        

            % for ozone, use corrected total column from sonde files, no manual correction
            % for extending the profile to 60 km
            % for no2, use value derived from AVK LUT profile (implemented below)
            vcstrato_apriori_zenith(i)=tot_col_tmp*1e-15; % convert to pmolec/cm^2
            
        else % sonde data missing, or NO2 data
            
            % use profiles generated by AVK LUT

            % partial column 
            col_profile_apriori_zenith(i,:)=lut_prof_scaled(ind_avk(i),end-59:end)*1e5*1e-15; % convert to pmolec/cm2

            % calculate VMR so it matches air num dens and partial column apriori
            % molec/cm^2 / n, then convert to ppt
            apriori_prof_zen(i,:)=((col_profile_apriori_zenith(i,:)*1e15)./(air_par_col(i,:)))*1e12;

            % fill apriori values 
            % calculate total column apriori
            vcstrato_apriori_zenith(i)=sum(col_profile_apriori_zenith(i,:),2); 
    
        end
        
    end        
    fprintf('\n')
    
    %% get averaging kernel (o3 or no2)
    vcstrato_akernel_zenith=lut_avk(ind_avk,end-59:end);
    

    %% fill data source variables
%     pressure_ind_source=['Interpolated to the measurement time from twice-daily radiosonde data (when available), extended using AFGL 1976']';
%     temperature_ind_source=['Interpolated to the measurement time from twice-daily radiosonde data (when available), extended using AFGL 1976']';
%     air_par_col_ind_source=['Interpoated to the measurement time from weekly ozonesonde data (when available), extended using AFGL 1976']';
    pressure_ind_source=['.'];
    temperature_ind_source=['.'];
    air_par_col_ind_source=['.'];
    
    %% flip profiles to have coords of alt;date
    pres=pres';
    temp=temp';
    air_par_col=air_par_col';
    apriori_prof_zen=apriori_prof_zen';
    vcstrato_akernel_zenith=vcstrato_akernel_zenith';
    col_profile_apriori_zenith=col_profile_apriori_zenith';
    
    
    %% check variables
    
    %n.o. measurements is variable 'len'
    
    % check if size 'len' variables are present and filled
    for varnames={'datetime',...
                  'datetime_start',...
                  'datetime_stop',...
                  'int_time',...
                  'sza_f',...
                  'saz',...
                  'pointing_az',...
                  'pointing_ze',...
                  'cloud_cond_mat',...
                  'vcstrato_zenith',...
                  'vcstrato_error_rand_zenith',...
                  'vcstrato_error_sys_zenith',...
                  'vcstrato_apriori_zenith',...
                  'amfstrato_zenith'}
    
        % check if variables exist      
        if ~exist(varnames{1},'var'), error(['Variable ' varnames{1} ' is missing']), end
    
        % check if variables have the right size (column vectors)
        if size(eval(varnames{1}),1)~=len
            error([varnames{1} ' not the right size'])
        end
              
    end
    
    % check if gridded variables are present and filled
    for varnames={'pres',...
                  'temp',...
                  'air_par_col',...
                  'apriori_prof_zen',...
                  'vcstrato_akernel_zenith',...
                  'col_profile_apriori_zenith'}
    
        % check if variables exist      
        if ~exist(varnames{1},'var'), error(['Variable ' varnames{1} ' is missing']), end
    
        % check if variables have the right size
        if (size(eval(varnames{1}),1)~=size(alt_grid,1) || size(eval(varnames{1}),2)~=len)
            error([varnames{1} ' not the right size'])
        end
              
    end    
    
    % check if all other variables are present
    for varnames={'lat',...
                  'long',...
                  'alt_instr',...
                  'alt_grid',...
                  'pressure_ind_source',...
                  'temperature_ind_source',...
                  'air_par_col_ind_source',...
                  'grid_bound'}
    
        % check if variables exist      
        if ~exist(varnames{1},'var'), error(['Variable ' varnames{1} ' is missing']), end
    
    end       
   
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    


    %% generate input file for MAT2HDF_In
    
    % filename for output HDF
    root='groundbased_uvvis.doas.zenith.';
    
    if strcmp(instr,'UT-GBS')
        instrument='utoronto001';
        instr_input=1;
    elseif strcmp(instr,'PEARL-GBS')
        instrument='utoronto002';
        instr_input=2;
    end
    
    outstr='yyyymmddtHHMMSSz';
    
    fileinfo.start=mjd2k_to_date(datetime_start(1),outstr);
    fileinfo.stop=mjd2k_to_date(datetime_stop(end),outstr);
    
    fileinfo.fname=[root gas '_' instrument '_eureka.pearl_'...
                  fileinfo.start '_' fileinfo.stop '_007'];
              
    % save in specified directory
%     fileinfo.fdir='/home/kristof/work/NDACC/HDF4_data_submission/input_files/';
    fileinfo.fdir=[bergdir 'input_files/'];
    
    % extra info for writing metadata file
    fileinfo.size_rec=len;
    fileinfo.size_grid=max(size(alt_grid));

    % create input file
    if strcmp(gas_input,'NO2UV'), gas_input='NO2'; end
    write_HDF_input_file(instr_input, gas_input, fileinfo, version, ~standard_submission);
    
    % flip altitude grid!
    % if I start with the correct shape and correct VAR_DEPEND, the NDAC code
    % flips everything at some point, and QA/QC fails
    % start with wrong shape, incl. wrong VAR_DEPEND/VAR_SIZE in write_HDF_input_file.m
    grid_bound=grid_bound';
    
    %% run functions to prepare HDF input
    
    cd(fileinfo.fdir)
    
    [struc]=MAT2HDF_In(['input_' fileinfo.fname '.txt'],'text');
    
    MAT2HDF_Out_AVDC(struc,['data_' fileinfo.fname '.data'],['metadata_' fileinfo.fname '.meta']);

    cd(cur_dir)
    
    %% add command for current month shell script
    
    fid=fopen(shell_script, 'a');
    if tg==1 || tg==2
        if standard_submission
            fprintf(fid,['idlcr8hdf,''metadata_' fileinfo.fname '.meta'',''data_' fileinfo.fname...
                         '.data'',''tableattrvalue_04R031.dat'',''../HDF_files/''']);
        else
            fprintf(fid,['idlcr8hdf,''metadata_' fileinfo.fname '.meta'',''data_' fileinfo.fname...
                         '.data'',''tableattrvalue_04R031.dat'',''../RD_files/''']);
        end            
        
    elseif tg==3
        if standard_submission
            fprintf(fid,['idlcr8hdf,''metadata_' fileinfo.fname '.meta'',''data_' fileinfo.fname...
                         '.data'',''tableattrvalue_04R031.dat'',''../HDF_files_UV/''']);
        else
            fprintf(fid,['idlcr8hdf,''metadata_' fileinfo.fname '.meta'',''data_' fileinfo.fname...
                         '.data'',''tableattrvalue_04R031.dat'',''../RD_files_UV/''']);
        end
    end        
    fprintf(fid,'\n');
    fclose(fid);    
    
end

%% write end of shell sript
if year==endyear
    fid=fopen(shell_script, 'a');
    fprintf(fid,'EOF');
    fprintf(fid,'\n');
    fprintf(fid,'\n');
    fprintf(fid,'rm idlcr8hdf.sav tableattrvalue_04R031.dat');
    fprintf(fid,'\n');
    fprintf(fid,'cd ../');
    fclose(fid);    
end

% clearvars -except year startyear endyear shell_script instr tg version yearly_files ...
%                   vcd_dir AVK_LUT_dir bergdir cur_dir standard_submission batch_tag ...
%                   do_cams_filter
end

clearvars
