function read_radiosonde_wnd( year, wnd_data )
%RADIOSONDE read sonde data for a given year
%   Read radiosonde data for any given year, save in file for later
%   INPUT: year to be analysed
%          wnd_data: empty structure to save data in
%   OUTPUT: saved file 'radiosonde_year.mat'
%               wnd_data: structure with sonde profiles 
%               header: headers for profile data
%               f_list: names of structure fields, one for each sonde

% debug
% year=2016;
% wnd_data=struct();

%% input parameters %%

% folder to save radiosonde data in
% save_dir=['/home/kristof/work/radiosonde/Eureka/', num2str(year), '/'];
save_dir='/home/kristof/work/radiosonde/Eureka/';
% check if save folder exixts
% if ~exist(save_dir), mkdir(save_dir), end

savename=[save_dir, 'radiosonde_wnd_',num2str(year),'.mat'];

% keep current directory
cur_dir=(pwd);

% sonde data is on Cube
path=['/home/kristof/cube/RADIOSONDE/torcube8/RADIOSONDE/', num2str(year), '/'];
cd(path);


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
    tmp = dir('*.wnd.tsv'); 
    f_list = {tmp.name}; % cell array of file names

    % remove bad files
    if year==2017, 
        f_list(find_in_file(f_list,'17030923(2).wnd.tsv'))=[]; % second launch, don't want to deal with it
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
        f_list_2{i}=['wnd_' tmp{1}];

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
            data=read_wnd(f_list{i});
        catch
            noread=[noread,i];
            continue
        end

        % check if data is cropped or columns are not filled
        if size(data,1)<50 || size(data,2)<7 || any(isnan(data(:,4)))
            noread=[noread,i];
            continue
        end

        % save wind speed (m/s) and wind direction (deg)
        speed=data(:,6);
        direction=data(:,7);
        % save altitude (in m)
        alt=data(:,4);
        % save pressure data (convert to P)
        P=data(:,3)*100;

        % Save data in structure
        wnd_data.(char(f_list_2{i}))=[alt,speed,direction,P];

    end 
    
elseif any(year==2019:2100)
    
    %%% GRAW sonde files %%%
    % wind data is saved by read_radiosonde.m, since GRAW files have both pt and wind data
    error('Use read_radiosonde.m for GRAW files')
    
end

%% print info about files that could not be read
fprintf('\n');
if ~isempty(noread)
    fprintf('Could not read:');
    disp_str=[];
    for i=1:size(noread,2)
        disp_str=[disp_str; f_list{noread(i)}];
    end
    disp(disp_str);
    fprintf('File(s) are either corrupted or incomplete\n');
end
fprintf('Done\n');

% define header
header={'altitude (m)','wind speed (m/s)','wind direction (deg)','pressure (Pa)'};

% save data and the important variables

% remove filenames that weren't read in
f_list_1(noread)=[];
f_list=unique(f_list_1)';

save(savename,'wnd_data','header','f_list');

% name of interpolated file
interp_file=[save_dir, 'radiosonde_wnd_',num2str(year),'_interp.mat'];

if exist(interp_file,'file'), delete(interp_file); end

cd(cur_dir)



