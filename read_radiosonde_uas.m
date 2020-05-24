function read_radiosonde_uas( year, ptu_data )
%read_radiosonde_uas Read radiosonde data from archived UAS format (on Cube)
%   Use instead of read_radiosonde.m for 1999-2007 (no .ptu.tsv data), this
%   function produces the same output
%   INPUT: year to be analysed
%          ptu_data: empty structure to save data in
%   OUTPUT: saved file 'radiosonde_year.mat'
%               ptu_data: structure with sonde profiles 
%               header: headers for profile data
%               f_list: names of structure fields, one for each sonde


% % debug
% year=2007;
% ptu_data=struct();


%% setup
if ismac
    
    error('Set file paths')
    
elseif isunix

    % where to save resulting mat files
    save_dir='/home/kristof/work/radiosonde/Eureka/';

    % open radiosonde file
    file_in=['/home/kristof/cube/RADIOSONDE/torcube8/RADIOSONDE/UAS18.L2401205.INT.P' num2str(year)];
end

fid=fopen(file_in,'r');

%% loop over lines in file
count=0;
n=0;

while true
    %% line checks
    % get current line
    line=fgetl(fid);
    
    % check for empty line
    if isempty(line), continue, end
    
    % check for end of file
    if line==-1, break, end

    % check file format consistency
    if max(size(line))~=656, error('file format changed'); end
    
    % read data from given line into array
    tmp = str2double(strsplit(line(20:648),{' ','M'},'CollapseDelimiters',true))';
    % replace missing values with NaNs
    tmp(tmp==-99999)=NaN;
    
    % get parameter identifier
    par=str2double(line(17:19));

    %% loop over measured parameters
    % 181 Pressure (0.01 kPa)
    % 182 Altitude above sea level (m)
    % 183 Temperature (0.1 deg C)
    % 184 Relative humidity (%)
    % 185 Wind direction (deg)
    % 186 Wind speed (m/s)
    
    if par==181
        P=tmp*10; % convert to Pa

        % display progress info
        disp_str=['Reading record ', num2str(count+1)];
        % stuff to delete last line and reprint updated message
        fprintf(repmat('\b',1,n));
        fprintf(disp_str);
        n=numel(disp_str);    
        
    elseif par==182
        alt=tmp; 
    elseif par==183
        T=tmp*0.1; % convert to C 
    elseif par==184
        RH=tmp;
    elseif par==185 % don't save wind dir
    elseif par==186 % don't save wind spd
        %% save sonde data
        
        % create single array
        data=[alt,P,T,RH];

        % remove all rows with invalid values (end of profile)
        data(any(isnan(data),2),:)=[];
        
        % check for bad profiles
        if size(data,1)<10, continue, end
        
        % check if profile is sorted (problem starting from sept. 2008)
        % if not sorted, sort by pressure
        if ~issorted(flipud(P)), data=sortrows(data,-2); end
        
        % save results in structure
        ptu_data.(['ptu_' line(9:16)])=data;
        
        % save field name (also time info)
        count=count+1;
        f_list(count)={line(9:16)};

    end
end

fclose(fid);

fprintf('\n');
fprintf('Done\n');

f_list=f_list';

header={'altitude (m)','pressure (Pa)','temperature (C)','RH (%)'};

savename=[save_dir, 'radiosonde_',num2str(year),'.mat'];

save(savename,'ptu_data','header','f_list');



