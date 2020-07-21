function [ alt_grid, wspd_out, wdir_out ] = interp_radiosonde_wnd( year, ft )
%Interp_sonde: interpolate radiosonde wind profiles to specified time and altitude grid
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
%       P_out, T_out: pressure and temperature profiles interpolated onto
%                     measurement time


% debug
% year=2016;
% ft=[74.25];

%% input parameters

% convert ft to array
ft=[ft];

%% see if this function has run before, if yes, load pre-saved file
if ismac
    fname2=['/Users/raminaalwarda/Desktop/PhysicsPhD/radiosonde/Eureka/radiosonde_wnd_',num2str(year),'_interp.mat'];
elseif isunix
    fname2=['/home/kristof/work/radiosonde/Eureka/radiosonde_wnd_',num2str(year),'_interp.mat'];
end

if exist(fname2,'file')==2

    load(fname2);
    alt_grid=y;
    
    % interpolate profiles
    wspd_out=interp2(x,y,wspd_arr,ft,y);

    % need to interpolate angles
    wdir_out=NaN(size(wspd_out));
    for i=1:length(alt_grid)
        
        tmp=unwrap(wdir_arr(i,:)*pi/180)*180/pi;
        tmp=interp1(x,tmp,ft);
        wdir_out(i,:)=mod(tmp,360);        

    end
    
else % do interpolation from scratch

    % load appropriate data file
    if ismac
        fname=['/Users/raminaalwarda/Desktop/PhysicsPhD/radiosonde/Eureka/radiosonde_wnd_',num2str(year),'.mat'];
    elseif isunix
        fname=['/home/kristof/work/radiosonde/Eureka/radiosonde_wnd_',num2str(year),'.mat'];
    end
    
    load(fname);

    % number of sonde profiles
    len=max(size(f_list));

    % new altitude grid since sonde data have uneven altitude spacing
    % grid from 10 to 40 010 m, grid represents center of each layer
    alt_grid=[15:10:40005]';

    %% arrays to store interpolated profiles

    wspd_arr=NaN(size(alt_grid,1),len);
    wdir_arr=NaN(size(alt_grid,1),len);

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
        alt=wnd_data.(['wnd_' f_list{i}])(:,1); % in m
        wspd=wnd_data.(['wnd_' f_list{i}])(:,2); % wind speed in m/s
        wdir=wnd_data.(['wnd_' f_list{i}])(:,3); % wind dir in deg

        % first remove duplicate altitude values
        [~,ind,~]=unique(alt);

        % interpolate profile information
        wspd_arr(:,i)=interp1(alt(ind),wspd(ind),alt_grid);
        
        % need to interpolate angles
        tmp=unwrap(wdir(ind)*pi/180)*180/pi;
        tmp=interp1(alt(ind),tmp,alt_grid);
        wdir_arr(:,i)=mod(tmp,360);        
        
    end
    
    %% fill in NaNs in data
    % loop over all rows of data (altitude layers)
    for i=1:length(alt_grid)
        
        % missing values for each layer + corresponding launch dates
        nans=isnan(wspd_arr(i,:));
        lt2=launch_time(~nans);
        lt2_nan=launch_time(nans);
        
        if alt_grid(i)<=15000
            % interpolate all missing values below 15 km
            wspd_arr(i,nans)=interp1(lt2,wspd_arr(i,~nans),lt2_nan);
            
            % need to interpolate angles
            tmp=unwrap(wdir_arr(i,~nans)*pi/180)*180/pi;
            tmp=interp1(lt2,tmp,lt2_nan);
            wdir_arr(i,nans)=mod(tmp,360);        
%             wdir_arr(i,nans)=interp1(lt2,wdir_arr(i,~nans),lt2_nan);
        
        else
            % above 15 km, don't interpolate if difference is >2 days
            % check if there are any large gaps at given alt, interpolate all if no
            if max(lt2(2:end)-lt2(1:end-1))<= 2.1
            
                % interpolate all missing values
                wspd_arr(i,nans)=interp1(lt2,wspd_arr(i,~nans),lt2_nan);
                
                % need to interpolate angles
                tmp=unwrap(wdir_arr(i,~nans)*pi/180)*180/pi;
                tmp=interp1(lt2,tmp,lt2_nan);
                wdir_arr(i,nans)=mod(tmp,360);        
%                 wdir_arr(i,nans)=interp1(lt2,wdir_arr(i,~nans),lt2_nan);
               
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
                        wspd_arr(i,l_ind+1:r_ind-1)=...
                            interp1([lt2(jj-1),lt2(jj)],[wspd_arr(i,l_ind),wspd_arr(i,r_ind)],lt2_tmp);
               
                        % need to interpolate angles
                    tmp=unwrap([wdir_arr(i,l_ind),wdir_arr(i,r_ind)]*pi/180)*180/pi;
                    tmp=interp1([lt2(jj-1),lt2(jj)],tmp,lt2_tmp);
                    wdir_arr(i,l_ind+1:r_ind-1)=mod(tmp,360);        
%                         wdir_arr(i,l_ind+1:r_ind-1)=...
%                             interp1([lt2(jj-1),lt2(jj)],[wdir_arr(i,l_ind),wdir_arr(i,r_ind)],lt2_tmp);
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
    wspd_out=interp2(x,y,wspd_arr,ft,y);
    
    % need to interpolate angles
    wdir_out=NaN(size(wspd_out));
    for i=1:length(alt_grid)
        
        tmp=unwrap(wdir_arr(i,:)*pi/180)*180/pi;
        tmp=interp1(x,tmp,ft);
        wdir_out(i,:)=mod(tmp,360);        

    end
    
    %% save data so next function call is faster
    save(fname2,'x','y','wspd_arr','wdir_arr');
end
