function read_radiosonde( year, ptu_data )
%RADIOSONDE read sonde data for a given year
%   Read radiosonde data for any given year, save in file for later
%   If file exists, add only launches not already saved
%   INPUT: year to be analysed
%          ptu_data: empty structure to save data in
%   OUTPUT: saved file 'radiosonde_year.mat'
%               ptu_data: structure with sonde profiles 
%               header: headers for profile data
%               f_list: names of structure fields, one for each sonde

% debug
% year=2018;
% ptu_data=struct();

%% input parameters %%

% keep current directory
cur_dir=(pwd);

% folder to save radiosonde data in
save_dir='/home/kristof/work/radiosonde/Eureka/';
% check if save folder exixts
if ~exist(save_dir,'dir'), mkdir(save_dir), end

% save file name
savename=[save_dir, 'radiosonde_',num2str(year),'.mat'];

path=['/home/kristof/cube/RADIOSONDE/torcube8/RADIOSONDE/', num2str(year), '/'];
cd(path);

% recent sonde data is on Cube
if any(year==2006:2018)
    
    %%% vaisala sonde files %%%
    
    %% check for previous versions

    just_append=false;
    if exist(savename,'file')

        load(savename)
        f_list_old=f_list;
        just_append=true;

    end

    %% make list of all files

    % make list of all files
    tmp = dir('*.ptu*'); 
    f_list = {tmp.name}; % cell array of file names

    % check for upper case extensions
    tmp = dir('*.PTU*'); 
    f_list_tmp = {tmp.name}; % cell array of file names
    if ~isempty(f_list_tmp), f_list=sort([f_list, f_list_tmp]); end

    % remove bad files (different format) from 2016 data
    if year==2016, 
        try f_list(find_in_file(f_list,'16120623.ptu.tsv'))=[]; end
        try f_list(find_in_file(f_list,'16121311.ptu.tsv'))=[]; end
    end

    % split filename and extension (sonde names are YYMMDDhh)
    f_list_1=cell(size(f_list));
    f_list_2=cell(size(f_list));

    for i=1:size(f_list,2)
        tmp=strsplit(char(f_list{i}),'.');

        % check if name contains (), remove if yes
        test=strfind(tmp{1},'(');
        if ~isempty(test)
            test2=strfind(tmp{1},')');
            tmp{1}(test:test2)=[];
        end

        f_list_1{i}=tmp{1};
        f_list_2{i}=['ptu_' tmp{1}];

    end

    %% read data
    n=0;
    noread=[];
    for i=1:size(f_list,2)

        % display progress info
        disp_str=['Reading file ',num2str(i),'/',num2str(size(f_list,2)),' (',f_list{i},')'];
        % stuff to delete last line and reprint updated message
        fprintf(repmat('\b',1,n));
        fprintf(disp_str);
        n=numel(disp_str);    

        % skip files already saved
        if just_append && ~isempty(find_in_cell(f_list_old,f_list_1{i}))
            continue
        end

        % read file
        try
            data=read_ptu(f_list{i});
        catch
            noread=[noread,i];
            continue
        end

        % check if there are NaNs and remove affected rows
        data(any(isnan(data), 2), :) = [];

        % check if data is cropped or columns are not filled
        if size(data,1)<50 || size(data,2)<7
            noread=[noread,i];
            continue
        end

        % save pressure (convert to Pa) and temperatures (in C)
        P=data(:,3)*100;
        T=data(:,5);
        T_dew=data(:,7);
        % save altitude (in m)
        alt=data(:,4);
        % save RH data
        RH=data(:,6);

        %% Save data in structure
        ptu_data.(char(f_list_2{i}))=[alt,P,T,RH,T_dew];

    end 
    
elseif any(year==2019:2100)
    
    %%% GRAW sonde files %%%
    
    % save wind data as well, since there are no separate wind files (as for vaisala)
    savename_wnd=[save_dir, 'radiosonde_wnd_',num2str(year),'.mat'];
    wnd_data=ptu_data;
    
    %% read files

    % make list of the txt files
    % use 20* as there are yymmdd files as well -- identical to yyyymmdd files
    tmp = dir('20*.txt'); 
    f_list = {tmp.name}; % cell array of file names

    % add csv files
    tmp = dir('20*.csv'); 
    f_list_tmp = {tmp.name}; % cell array of file names
    
    % list of all files
    f_list=sort([f_list, f_list_tmp]);

    % remove duplicates and ozonesonde files
    % do it manually since system is new, no idea what exceptions will come up
    exceptions={''};
    if year==2019, 
        
        % badly named files to keep, with formatted version of the name
        % this string is the truncated name, not the file name
        exceptions={'19041100 (2)'};
        
        f_list(find_in_file(f_list,'201903120000.csv'))=[]; % duplicate
        f_list(find_in_file(f_list,'201904101200.csv'))=[]; % different format 
        f_list(find_in_file(f_list,'201904110000.csv'))=[]; % standard ozone file
        f_list(find_in_file(f_list,'201904180000ozone.csv'))=[]; % duplicate(ish)
        
    end

    if year==2020, 
        
        % badly named files to keep, with formatted version of the name
        % this string is the truncated name, not the file name
        exceptions={'20022400 (2)'};

        f_list(find_in_file(f_list,...
               '20200222000018061190_ozoneimdreport_cweu.csv'))=[]; % different format 
        f_list(find_in_file(f_list,'202002240000.csv'))=[]; % duplicate(ish)
        
    end
    
    % split filename and extension (sonde names are YYYYMMDDhhmm)
    f_list_1=cell(size(f_list));
    f_list_2=cell(size(f_list));

    for i=1:size(f_list,2)
        tmp=strsplit(char(f_list{i}),'.');
        
        % convert to YYMMDDhh to match vaisala format
        tmp{1}(11:12)=[]; 
        tmp{1}(1:2)=[];

        % check if name is too long, throw error
        if length(tmp{1})~=8
            if find_in_cell(exceptions,tmp{1})
                tmp{1}(9:end)=[];
            else
                error(['Irregular file ' tmp{1} '; check what it is']);
            end
        end
        
        % save name
        f_list_1{i}=tmp{1};
        f_list_2{i}=['ptu_' tmp{1}];
        f_list_2wnd{i}=['wnd_' tmp{1}];

    end

    %% read data
    n=0;
    noread=[];
    for i=1:size(f_list,2)

        % display progress info
        disp_str=['Reading file ',num2str(i),'/',num2str(size(f_list,2)),' (',f_list{i},')'];
        % stuff to delete last line and reprint updated message
        fprintf(repmat('\b',1,n));
        fprintf(disp_str);
        n=numel(disp_str);    

        % read file
        try
            data_tmp=read_graw(f_list{i});
        catch
            noread=[noread,i];
            continue
        end

        % alt (m), pres (Pa), temp (c), RH (%), dewp (C)
        data=[data_tmp.Geopot,data_tmp.P*100,data_tmp.T,data_tmp.Hu,data_tmp.Dewp];

        % alt (m), windspeed (m/s), wind direction (deg), pres (Pa)
        data_wnd=[data_tmp.Geopot,data_tmp.Ws,data_tmp.Wd,data_tmp.P*100];

        %% Save data in structure
        ptu_data.(char(f_list_2{i}))=data;
        wnd_data.(char(f_list_2wnd{i}))=data_wnd;

    end 
    

elseif any(year==[1999:2005])
    error('Use read_radiosonde_uas.m');
end
    

%% print info about files that could not be read

fprintf('\n');
if ~isempty(noread)
    fprintf('Could not read:\n');
    disp_str=[];
    for i=1:size(noread,2)
        disp_str=[disp_str; f_list{noread(i)}];
    end
    disp(disp_str);
    fprintf('File(s) are corrupted, incomplete, or in wrong format\n');
    fprintf('(2019 onward: wrong format is likely summary file with very few altitude levels)\n');
end
fprintf('Done\n');


%% save stuff

% define header
header={'altitude (m)','pressure (Pa)','temperature (C)','RH (%)','dew point (C)'};

% remove filenames that weren't read in
f_list_1(noread)=[];
f_list=unique(f_list_1)';

save(savename,'ptu_data','header','f_list');

% name of interpolated file
interp_file=[save_dir, 'radiosonde_',num2str(year),'_interp.mat'];

if exist(interp_file,'file'), delete(interp_file); end

% save wind data for GRAW files
if exist('wnd_data','var')
    
    header={'altitude (m)','wind speed (m/s)','wind direction (deg)','pressure (Pa)'};
    save(savename_wnd,'wnd_data','header','f_list');

    interp_file=[save_dir, 'radiosonde_wnd_',num2str(year),'_interp.mat'];
    if exist(interp_file,'file'), delete(interp_file); end
    
end

% recreate interpolated files
interp_radiosonde(year,80);
interp_radiosonde_wnd(year,80);

cd(cur_dir)

end



