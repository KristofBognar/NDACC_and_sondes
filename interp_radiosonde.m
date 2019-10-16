function [ alt_grid, P_out, T_out, RH_out, theta_out ] = interp_radiosonde( year, ft )
%Interp_sonde: interpolate radiosonde profiles to specified time and altitude grid
%
%   On first call, function interpolates all sonde data for given year onto a common
%   altitude grid, and saves these arrays after interpolation.
%   On all subsequent runs for the same year the saved file is read in to
%   speed up the process.
%
%   INPUT:
%       year: year of interest
%       ft:   fractional date (jan. 1, 00:00 = 0) where profile data is needed
%   OUTPUT: 
%       alt_grid: grid used to standardize sonde altitude levels, all
%                 output is reported on this grid
%       vmr_out: interpolated profile information (unitless)
%       P_out, T_out, RH_out: pressure, temperature, and relative humidity profiles
%                 interpolated onto measurement time


% debug
% year=2016;
% ft=[74.25];


%% input parameters

% convert ft to array
ft=[ft];

% % %% skip years with no sonde data
% % if any(year==[2010,2013])
% %    
% %     alt_grid=[15:10:40005]';
% %     P_out=NaN(size(alt_grid));
% %     T_out=NaN(size(alt_grid));
% %     
% %     return
% %     
% % end

%% see if this function has run before, if yes, load pre-saved file
fname2=['/home/kristof/work/radiosonde/Eureka/radiosonde_',num2str(year),'_interp.mat'];

if exist(fname2,'file')==2

    load(fname2);
    alt_grid=y;
    
    % interpolate profiles
    P_out=interp2(x,y,P_arr,ft,y);
    T_out=interp2(x,y,T_arr,ft,y);
    RH_out=interp2(x,y,RH_arr,ft,y);
    
    % get potential temperature
    theta_out=T_out * ( (1e5/P_out)^0.286 );
    
else % do interpolation from scratch

    % load appropriate data file
    fname=['/home/kristof/work/radiosonde/Eureka/radiosonde_',num2str(year),'.mat'];
    
    if exist(fname,'file')
        load(fname);
    else
        error(['No saved radiosonde data for ' num2str(year)]);
    end
    
    % number of sonde profiles
    len=max(size(f_list));

    % new altitude grid since sonde data have uneven altitude spacing
    % grid from 10 to 40 010 m, grid represents center of each layer
    alt_grid=[15:10:40005]';

    %% arrays to store interpolated profiles

    P_arr=NaN(size(alt_grid,1),len);
    T_arr=NaN(size(alt_grid,1),len);
    RH_arr=NaN(size(alt_grid,1),len);

    %% convert launch dates to fractional day

    % get matlab time at start of given year
    % matlab datenum runs from jan 1, 0000, 00:00:00 which is equal to 1!!
    year_time=yeartime(year);
    
    % filenames are yymmddHH
    formstr='yymmddHH';
    launch_time=datenum(f_list,formstr);

    % convert to fractional time (jan.1, 00:00 = 0)
    launch_time=launch_time-year_time;

    %% interpolate profiles 
    for i=1:len

        % get profile information
        alt=ptu_data.(['ptu_' f_list{i}])(:,1); % in m
        P=ptu_data.(['ptu_' f_list{i}])(:,2); % P in file is Pa
        T=ptu_data.(['ptu_' f_list{i}])(:,3)+273.15; % T in file is celsius, need K!
        RH=ptu_data.(['ptu_' f_list{i}])(:,4); % RH in %

        % first remove duplicate altitude values
        [~,ind,~]=unique(alt);

        % interpolate profile information
        P_arr(:,i)=interp1(alt(ind),P(ind),alt_grid);
        T_arr(:,i)=interp1(alt(ind),T(ind),alt_grid);
        RH_arr(:,i)=interp1(alt(ind),RH(ind),alt_grid);

    end
    
    %% fill in NaNs in data
    % loop over all rows of data (altitude layers)
    for i=1:length(alt_grid)
        
        % missing values for each layer + corresponding launch dates
        nans=isnan(P_arr(i,:));
        lt2=launch_time(~nans);
        lt2_nan=launch_time(nans);
        
        if alt_grid(i)<=15000
            % interpolate all missing values below 15 km
            P_arr(i,nans)=interp1(lt2,P_arr(i,~nans),lt2_nan);
            T_arr(i,nans)=interp1(lt2,T_arr(i,~nans),lt2_nan);
            RH_arr(i,nans)=interp1(lt2,RH_arr(i,~nans),lt2_nan);
        
        else
            % above 15 km, don't interpolate if difference is >2 days
            % check if there are any large gaps at given alt, interpolate all if no
            if max(lt2(2:end)-lt2(1:end-1))<= 2.1
            
                % interpolate all missing values
                P_arr(i,nans)=interp1(lt2,P_arr(i,~nans),lt2_nan);
                T_arr(i,nans)=interp1(lt2,T_arr(i,~nans),lt2_nan);
                RH_arr(i,nans)=interp1(lt2,RH_arr(i,~nans),lt2_nan);
               
            else
                % loop over pairs of existing values
                for jj=2:length(lt2)
                    
                    % find nans between the existing values
                    lt2_tmp=lt2_nan(lt2_nan>lt2(jj-1) & lt2_nan<lt2(jj));
                    
                    if (lt2(jj)-lt2(jj-1) > 2.1)
                        % if values are >2 days apart, skip
                        continue
                    elseif isempty(lt2_tmp)
                        % if there are no nans in between, skip
                        continue
                    else
                        % find index of existing values
                        l_ind=find(launch_time==lt2(jj-1));
                        r_ind=find(launch_time==lt2(jj));
                        
                        % interpolate missing values
                        P_arr(i,l_ind+1:r_ind-1)=...
                            interp1([lt2(jj-1),lt2(jj)],[P_arr(i,l_ind),P_arr(i,r_ind)],lt2_tmp);
                        T_arr(i,l_ind+1:r_ind-1)=...
                            interp1([lt2(jj-1),lt2(jj)],[T_arr(i,l_ind),T_arr(i,r_ind)],lt2_tmp);
                        RH_arr(i,l_ind+1:r_ind-1)=...
                            interp1([lt2(jj-1),lt2(jj)],[RH_arr(i,l_ind),RH_arr(i,r_ind)],lt2_tmp);
                        
                    end
                end
            end
        end        
    end

    %% interpolate profile data onto measurement time
    % x coordinate (need row vector)
    x=launch_time';
    % y coordinate (need column vector)
    y=alt_grid;

    % find profile at measurement time
    P_out=interp2(x,y,P_arr,ft,y);
    T_out=interp2(x,y,T_arr,ft,y);
    RH_out=interp2(x,y,RH_arr,ft,y);

    % get potential temperature
    theta_out=T_out*(1e5/P_out)^0.286;
    
    %% save  data so next function call is faster
    save(fname2,'x','y','P_arr','T_arr','RH_arr');
end
end



