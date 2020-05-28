function read_ozonesonde( year, sonde_data )
%OZONESONDE read sonde data for a given year, calculate total column
%   Read ozonesonde data for any given year, save in file for later

%   INPUT: year to be analysed
%          sonde_data: empty structure to save data in
%   OUTPUT: saved file 'o3sonde_year.mat'
%               sonde_data: structure with sonde profiles + profiles interpolated to NDACC grid 
%               header: headers for profile data
%               launchtime: launch date and time of each sonde
%               f_list_1: names of structure fields, one for each sonde
%               f_list_2: same but for the interpolated files (NAME_ndacc)


% %debug
% year=2007;
% sonde_data=struct();

%% Set input parameters

% save current folder
start_dir=(pwd);

if ismac
    
    error('set file paths')
    
elseif isunix
    
    % go to folder containing yearly sonde files
    path=['/home/kristof/work/ozonesonde/Eureka/', num2str(year), '/'];
    savepath='/home/kristof/work/ozonesonde/Eureka/';
    
end

cd(path);

% make list of all files
% naming convention changes year to year and within some years...
tmp = dir('*.*'); 
f_list = {tmp.name}; % cell array of file names
f_list(1:2)=[]; % ignore first 2 entries (. and ..)

% split filename and extension
f_list_1=cell(size(f_list));
% f_list_2=cell(size(f_list));

for i=1:size(f_list,2)
    tmp=strsplit(char(f_list{i}),'.');
    f_list_1{i}=tmp{1};

end
    
%% Read data

launchtime=cell(size(f_list,2),3);
tot_col_DU=zeros(size(f_list,2),1);

% read all files and save selected variables
n=0;
for i=1:size(f_list,2)
    %% display progress info
    disp_str=['Reading file ', num2str(i), '/', num2str(size(f_list,2)), ' (', f_list{i}, ')'];
    % stuff to delete last line and reprint updated message
    fprintf(repmat('\b',1,n));
    fprintf(disp_str);
    n=numel(disp_str);    
    
    %% find position of relevant entries (format changes from year to year)
    fid=fopen(f_list{i},'r');
    
    % loop over file lines to find relevant entries
    search=true;
    rowcount=1;
    while search

        line = fgets(fid);
        
%         % find length of file for 1999 (there's text after the profile)
%         if year==1999 && ~ischar(line)
%             endrow=rowcount-1;
%             break
%         end

        % find time info (data is two lines below section header)
        if strcmp(cellstr(line),'#TIMESTAMP'), timerow=rowcount+2; end
        % find total column data
        if strcmp(cellstr(line),'#FLIGHT_SUMMARY'), colrow=rowcount+2; end
        % find start of profile data, and end loop
        if strcmp(cellstr(line),'#PROFILE'), 
            profilerow=rowcount+2; 
            search=false;
        end
        
        rowcount=rowcount+1;

    end
    fclose(fid);
    
    %% read profile data
    % csvread row numbering starts with 0
    data=csvread(f_list{i},profilerow-1);

% %         % 1999 data has fields after profile
% %         data=csvread(f_list{i},profilerow-1,0,[profilerow-1,0,endrow-3,4]);
        
    % save pressure (convert to Pa) and temperature (in C)
    P=data(:,1)*100;
    T=data(:,3);
    % save altitude (in m)
    alt=data(:,8);
    % calculate volume mixing ratio ([P_o3]=mPa)
    vmr=((data(:,2)/1000)./P);
    
    % save other data
    w_speed=data(:,4);
    w_dir=data(:,5);
    RH=data(:,9);
        
    %% read in launch time info
    fid=fopen(f_list{i});
    % texscan needs number of rows to skip
    tmp = textscan(fid,'%s',2,'HeaderLines',timerow-1);
    fclose(fid);
    
    temp2=strsplit(char(tmp{1,1}{1}),',');
    launchtime{i,1}=temp2{2};     % launch date
    % there's a space after the date in the 2016 (and earlier) files that messes up reading the line
    if size(temp2,2)==3 && ~isempty(temp2{3})
        launchtime{i,2}=temp2{3}; % launch time
    else
        launchtime{i,2}=tmp{1,1}{2}; % launch time
    end
    launchtime{i,3}=temp2{1};     % UTC offset
    
    %% read total column data
    % read only one line and 3 (or 1) columns
    fid=fopen(f_list{i});
    
    try
        % corrected o3 column present
%         temp = csvread(f_list{i},colrow-1,0,[colrow-1,0,colrow-1,2]);
        tmp = textscan(fid,'%s',1,'HeaderLines',colrow-1);
        temp2=strsplit(char(tmp{1}),',');
        tot_col_DU(i)=str2double(temp2{3});
    catch
        % corrected o3 column missing AND there are no commas for the empty
        % fields (e.e. 2011)
%         temp = csvread(f_list{i},colrow-1,0,[colrow-1,0,colrow-1,0]);
        tot_col_DU(i)=0;
    end

    % NaNs might escape try-catch
    if isnan(tot_col_DU(i)), tot_col_DU(i)=0; end
    
    fclose(fid);
    
    %% Save data in structure
    
    % check if name repeats (multiple sondes on the same day)
    needsort=false;
    if  i~=1 && (strcmp(f_list_1{i},f_list_1{i-1}) ||...
                 strcmp(['EU' char(f_list_1{i})],f_list_1{i-1}))
        
        % rename duplicate field
        f_list_1(i)={[f_list_1{i} 'a']};
        % find launch time (for sorting after data is assigned to structure)
        datestr_i=[launchtime{i,1}, ' ', launchtime{i,2}];
        datestr_i_1=[launchtime{i-1,1}, ' ', launchtime{i-1,2}];
        lt_i=datenum(datestr_i,'yyyy-mm-dd HH:MM:SS');
        lt_i_1=datenum(datestr_i_1,'yyyy-mm-dd HH:MM:SS');
        
        if lt_i_1>lt_i, needsort=true; end
        
    end
    
    try
        % naming convention after mid-2011
        sonde_data.(char(f_list_1{i}))=[alt,vmr,P,T,RH,w_speed,w_dir];
    catch
        % naming convention before mid-2011: add 'EU' so name can be used
        % as structure field
        f_list_1(i)=cellstr(['EU' char(f_list_1{i})]);
        sonde_data.(char(f_list_1{i}))=[alt,vmr,P,T,RH,w_speed,w_dir];
    end

    % switch fields to keep everything sorted by launch time
    if needsort
        f_list_1([i-1,i])=f_list_1([i,i-1]);
        launchtime([i-1,i],:)=launchtime([i,i-1],:);
        tot_col_DU([i-1,i])=tot_col_DU([i,i-1]);
    end
    
end 

fprintf('\n');
fprintf('Done\n');

% define header
header={'altitude (m)','ozone VMR','pressure (Pa)','temperature (C)',...
         'RH (%)','wind speed (??)','wind direction'};

% go to save directory
cd(savepath);
% save data and the important variables
savename=['o3sonde_',num2str(year),'.mat'];
% save(savename,'sonde_data','header','launchtime','f_list_1','f_list_2');
f_list=f_list_1';
save(savename,'sonde_data','header','launchtime','f_list','tot_col_DU');

% remove and recreate interpolated file
interp_file=['o3sonde_',num2str(year),'_interp.mat'];
if exist(interp_file,'file'), delete(interp_file); end

cd(start_dir)


