function [ alt_grid, vmr_out, n_out, tot_col_out, P_out, T_out ] = interp_ozonesonde( year, ft, opt )
%Interp_sonde: interpolate ozonesonde profiles to specified time and altitude grid
%
%   On first call, function interpolates all sonde data for given year onto a common
%   altitude grid, interpolates missing values, and saves these arrays after
%   interpolation.
%
%   On all subsequent runs for the same year the saved file is read in to
%   speed up the process.
%
%   INPUT:
%       year: year of interest
%       ft:   fractional date (jan. 1, 00:00 = 0) where profile data is needed
%
%   OUTPUT: 
%       alt_grid: grid used to standardize sonde altitude levels, all
%                 output is reported on this grid
%       vmr_out: interpolated profile information (unitless)
%       n_out: air number density from P, T data (use this in NDACC files
%              since this is used to calculate the total column apriori)
%              (molec/cm^3)
%       (P, T can also be output if needed. Use radiosonde for NDACC files) 
%       tot_col: interpolated total column ozone (molec/cm2)

% debug
% year=2016;
% ft=[(60.96875+61.96875)/2];


%% input parameters

if ~exist('opt','var'), opt=''; end

% convert ft to array?
ft=[ft];

% no altitude data in sodes from 1999, don't use profile data
% load total columns from VCD sonde file
if ismac
   load('/Users/raminaalwarda/Desktop/PhysicsPhD/ozonesonde/Eureka/sonde_for_VCD.mat');

elseif isunix
    load('/home/kristof/work/ozonesonde/Eureka/sonde_for_VCD.mat');
end

if year==1999
    
    alt_grid=[15:10:40005]';
    vmr_out=NaN(size(alt_grid));
    n_out=NaN(size(alt_grid));
    
    P_out=NaN(size(alt_grid));
    T_out=NaN(size(alt_grid));
    
    % get total column from VCD sonde file, and convert from DU to molec/cm2
    tot_col_out=interp1((sonde(1:63,2)-1 + sonde(1:63,3)/24),...
                        sonde(1:63,4),ft)*2.6868e16;
    
    return
    
end

%% see if this function has run before, if yes, load pre-saved file
if ismac
    fname2=['/Users/raminaalwarda/Desktop/PhysicsPhD/ozonesonde/Eureka/o3sonde_',num2str(year),'_interp.mat'];
elseif isunix
    fname2=['/home/kristof/work/ozonesonde/Eureka/o3sonde_',num2str(year),'_interp.mat'];
end

if exist(fname2,'file')==2
    
    load(fname2);
    alt_grid=y;

    if ~strcmp(opt,'nearest')
        % interpolate profiles
        vmr_out=interp2(x,y,vmr_arr,ft,y);
        n_out=interp2(x,y,n_arr,ft,y);

        P_out=interp2(x,y,P_arr,ft,y);
        T_out=interp2(x,y,T_arr,ft,y);

        % interpolate total column data
        tot_col_out=interp1(x,tot_col_arr,ft);
    
    else
        % return nearest sonde profile instead of interpolating
        
        [~,ind]=min(abs(x-ft));

        vmr_out=vmr_arr(:,ind);
        n_out=n_arr(:,ind);

        P_out=P_arr(:,ind);
        T_out=T_arr(:,ind);

        % interpolate total column data
        tot_col_out=tot_col_arr(ind);
        
    end

else % do interpolation from scratch
    
    % load appropriate data file
    if ismac
        fname=['/Users/raminaalwarda/Desktop/PhysicsPhD/ozonesonde/Eureka/o3sonde_',num2str(year),'.mat'];
    elseif isunix
        fname=['/home/kristof/work/ozonesonde/Eureka/o3sonde_',num2str(year),'.mat'];
    end
    
    load(fname);

    % number of sonde profiles
    len=max(size(f_list));

    % new altitude grid since sonde data have uneven altitude spacing
    % grid from 10 to 40 010 m, grid represents center of each layer
    alt_grid=[15:10:40005]';

    %% arrays to store interpolated profiles

    tot_col_arr=NaN(1,len);
    n_arr=NaN(size(alt_grid,1),len);
    P_arr=NaN(size(n_arr));
    T_arr=NaN(size(n_arr));
    vmr_arr=NaN(size(n_arr));

    %% convert launch dates to fractional day

    % get matlab time at start of given year
    % matlab datenum runs from jan 1, 0000, 00:00:00 which is equal to 1!!
    year_time=yeartime(year);

    % array to store converted launch times
    launch_time=zeros(len,1);

    % convert launch dates/times to matlab time
    formstr='yyyy-mm-dd HH:MM:SS';
    for i=1:len
        datestr=[launchtime{i,1}, ' ', launchtime{i,2}];
        launch_time(i)=datenum(datestr,formstr);
    end

    % convert to fractional time (jan.1, 00:00 = 0)
    launch_time=launch_time-year_time;

    %% interpolate profiles and calculate total column ozone 
    for i=1:len

        % get profile information
        alt=sonde_data.(f_list{i})(:,1); % in m
        vmr=sonde_data.(f_list{i})(:,2); % ozone mixing ratio
        P=sonde_data.(f_list{i})(:,3); % P in file is Pa
        T=sonde_data.(f_list{i})(:,4)+273.15; % T in file is celsius, need K!

%         % don't count sondes that reach less than 10 km - they don't provide
%         % much info about ozone
%         if max(alt)<10000 && nargin<3
%             continue
%         else
%         ind_goodsonde=[ind_goodsonde, i];
%         end

        % calculate air number density, convert to molec/cm^3
        n=((6.022e23*P)./(8.314*T))*1e-6;


        %% interpolate profile information
        % remove duplicate altitude values
        [~,ind,~]=unique(alt);

        n_arr(:,i)=interp1(alt(ind),n(ind),alt_grid);
        vmr_arr(:,i)=interp1(alt(ind),vmr(ind),alt_grid);
        P_arr(:,i)=interp1(alt(ind),P(ind),alt_grid);
        T_arr(:,i)=interp1(alt(ind),T(ind),alt_grid);


    end
    
    %% replace negative mixing ratios with 0 (below detection limit)
    vmr_arr(vmr_arr<0)=0;
    
    %% fill in NaNs in data
    % loop over all rows of data (altitude layers)
    for i=1:length(alt_grid)
        
        % missing values for each layer + corresponding launch dates
        nans=isnan(vmr_arr(i,:));
        lt2=launch_time(~nans);
        lt2_nan=launch_time(nans);
        
        if alt_grid(i)<=20000
            % interpolate all missing values below 20 km
            vmr_arr(i,nans)=interp1(lt2,vmr_arr(i,~nans),lt2_nan);
            n_arr(i,nans)=interp1(lt2,n_arr(i,~nans),lt2_nan);
            
            P_arr(i,nans)=interp1(lt2,P_arr(i,~nans),lt2_nan);
            T_arr(i,nans)=interp1(lt2,T_arr(i,~nans),lt2_nan);
        
        else
            % above 20 km, don't interpolate if difference is >3 weeks
            if max(lt2(2:end)-lt2(1:end-1))<= 22.5
            
                % interpolate all missing values
                vmr_arr(i,nans)=interp1(lt2,vmr_arr(i,~nans),lt2_nan);
                n_arr(i,nans)=interp1(lt2,n_arr(i,~nans),lt2_nan);
                
                P_arr(i,nans)=interp1(lt2,P_arr(i,~nans),lt2_nan);
                T_arr(i,nans)=interp1(lt2,T_arr(i,~nans),lt2_nan);
               
            else
                % loop over pairs of existing values
                for jj=2:length(lt2)
                    
                    % find nans between the existing values
                    lt2_tmp=lt2_nan(lt2_nan>lt2(jj-1) & lt2_nan<lt2(jj));
                    
                    if (lt2(jj)-lt2(jj-1) > 22.5)
                        % if values are >3 weeks apart, skip
                        continue
                    elseif isempty(lt2_tmp)
                        % if there are no nans in between, skip
                        continue
                    else
                        % find index of existing values
                        l_ind=find(launch_time==lt2(jj-1));
                        r_ind=find(launch_time==lt2(jj));
                        
                        % interpolate missing values
                        vmr_arr(i,l_ind+1:r_ind-1)=...
                            interp1([lt2(jj-1),lt2(jj)],[vmr_arr(i,l_ind),vmr_arr(i,r_ind)],lt2_tmp);
                        n_arr(i,l_ind+1:r_ind-1)=...
                            interp1([lt2(jj-1),lt2(jj)],[n_arr(i,l_ind),n_arr(i,r_ind)],lt2_tmp);

                        P_arr(i,l_ind+1:r_ind-1)=...
                            interp1([lt2(jj-1),lt2(jj)],[P_arr(i,l_ind),P_arr(i,r_ind)],lt2_tmp);
                        T_arr(i,l_ind+1:r_ind-1)=...
                            interp1([lt2(jj-1),lt2(jj)],[T_arr(i,l_ind),T_arr(i,r_ind)],lt2_tmp);
                    
                    end
                end
            end
        end
    end

    %% get total ozone data
    % use sonde data for VCD retrieval here, since that includes multiple
    % years (no missing values at the start/end of year), and that's what
    % is actually used in the retrievals
    if ft>sonde(end,2)-1
        sonde_column_for_VCD(year, year);
    end
    
    tot_col_arr=interp1(ft_to_mjd2k((sonde(:,2)-1 + sonde(:,3)/24),sonde(:,1)),...
                        sonde(:,4),...
                        ft_to_mjd2k(launch_time,year))*2.6868e16; % convert to molec/cm^2
    
% % %     % convert to molec/cm^2
% % %     tot_col_arr=tot_col_DU'*2.6868e16;
% % %     
% % %     % fill in zeroes (where sonde didn't have corrected total ozone column)
% % %     tot_col_arr(tot_col_arr==0)=interp1(...
% % %         launch_time(tot_col_arr~=0),...
% % %         tot_col_arr(tot_col_arr~=0),...
% % %         launch_time(tot_col_arr==0));
     
    %% interpolate profile data onto measurement time
    % x coordinate (need row vector)
    x=launch_time';
    % y coordinate (need column vector)
    y=alt_grid;

    if ~strcmp(opt,'nearest')
        vmr_out=interp2(x,y,vmr_arr,ft,y);
        n_out=interp2(x,y,n_arr,ft,y);

        P_out=interp2(x,y,P_arr,ft,alt_grid);
        T_out=interp2(x,y,T_arr,ft,alt_grid);

        % interpolate total column data
        tot_col_out=interp1(x,tot_col_arr,ft);
    
    else
        % return nearest sonde profile instead of interpolating
        
        [~,ind]=min(abs(x-ft));

        vmr_out=vmr_arr(:,ind);
        n_out=n_arr(:,ind);

        P_out=P_arr(:,ind);
        T_out=T_arr(:,ind);

        % interpolate total column data
        tot_col_out=tot_col_arr(ind);
        
    end
    

    %% save data so next function call is faster
    save(fname2,'x','y','vmr_arr','n_arr','P_arr','T_arr','tot_col_arr');

end


