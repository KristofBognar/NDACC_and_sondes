function data = read_graw(filename)
% read data from GRAW sondes
% multiple output formats:
%   txt files: tab separated, lots of info
%   csv files: comma separated, basic info only
%
% units are: alt (m), pres (hPa), temp (c), RH (%), dewp (C)
%
%%% ozone files are mixed with radiosonde files, with no change in filenames...
%%% format is of course different, ozone files have more data.......
%%% why...........?

filetype=filename(end-2:end);

if strcmp(filetype,'txt')
    %% get row and column range for data
    % ozone file: 19 cols; radiosonde file, 13 or 14 cols

    fid=fopen(filename,'r');
    
    % get second line
    header_char = fgets(fid);
    fclose(fid);
    header_char = strrep(header_char,'Dew','Dewp');
    
    % convert to cell for later
    header_cell=strsplit(header_char,'\t');
        
    % remove units, brackets, and spaces
    for i=1:length(header_cell)
        
        tmp=strfind(header_cell{i},'[');
        header_cell{i}(tmp-1:end)=[];
        
        tmp=strfind(header_cell{i},' ');
        header_cell{i}(tmp)=[];

    end
    
    %% read data
    
    % read data and cut empty columns
    data_tmp=dlmread(filename,'\t',1, 0);

    % convert to table
    data=array2table(data_tmp,'VariableNames',header_cell);
    
    data(data.Geopot==999999,:)=[];

elseif strcmp(filetype,'csv')
    %% get row and column range for data
    % ozone file: 19 cols; radiosonde file: 13 or 14 cols

    fid=fopen(filename,'r');
    
    % get second line
    line = fgets(fid);
    header_char = fgets(fid);
    try header_char = strrep(header_char,'Dewp.','Dewp'); end

    % convert to cell for later
    header_cell=strsplit(header_char,',');
        
    % really ncols-1, but it's all I need for dlmread (cannot use
    % header_cell since strsplit skips empty fields)
    ncols=length(strfind(header_char,','));
    
    % there's text at the end of each file...
    % have to find where data ends
    search=1;
    data_end=0; % to get last line -1 for dlmread
    
    while search
       data_end=data_end+1;
       line = fgets(fid);
       if ~isempty(strfind(line,'Tropopauses')), search=0; end
    end
    
    fclose(fid);
    
    %% read data
    
    % read data and cut empty columns
    data_tmp=dlmread(filename,',',[3 0 data_end, ncols]);

    data_tmp(:,sum(data_tmp,1)==0)=[];

    % convert to table
    data=array2table(data_tmp,'VariableNames',header_cell);
        
    data(data.Geopot==999999,:)=[];
    
end

%% filter data from falling sonde
% that's where vaisala data end; might confuse interpolation code

tmp=find(diff(data.Geopot)<0);
if ~isempty(tmp), data(tmp(1)+1:end,:)=[]; end



