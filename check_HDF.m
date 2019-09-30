function check_HDF()
%Check_HDF: checks NDACC HDF files against TAV file and template file using
%geoms_qa.sav
%
% sometimes it doesn't work..?


%% directories and files
cur_dir=pwd;
bergdir='/home/kristof/berg/NDACC_HDF/';

% file_dir='HDF_files/';
% file_dir='HDF_files_UV/';

file_dir='RD_files/';
% file_dir='RD_files_UV/';

tav_file='tableattrvalue_04R031.dat';

%% list HDF files
cd([bergdir file_dir])

tmp=dir('*.hdf');
fname={tmp.name};

if isempty(fname), error('No HDF files found, check data folder'); end

%% create shell script to run IDL file checker

% shell script file name
shell_script=[bergdir 'check_HDF_.sh'];

% check if script exists, wipe if yes
if exist(shell_script,'file'), system(['rm ' shell_script]); end

system(['touch ' shell_script]);

% add some lines to the file
fid=fopen(shell_script, 'w');
fprintf(fid,'#!/bin/bash');
fprintf(fid,'\n');
fprintf(fid,'# Script to check HDF files against TAV and templates');
fprintf(fid,'\n');
fprintf(fid,'\n');
fprintf(fid,['cd ' file_dir]);
fprintf(fid,'\n');
fprintf(fid,['cp ../geoms_qa.sav ../' tav_file ' ../GEOMS-TE-UVVIS-DOAS-ZENITH-GAS-VA.csv .']);
fprintf(fid,'\n');
fprintf(fid,'\n');
% fprintf(fid,'idl << EOF');
fprintf(fid,'\n');


for i=1:length(fname)
    
    fprintf(fid,['idl -rt=geoms_qa.sav -args ' tav_file ...
                 ' GEOMS-TE-UVVIS-DOAS-ZENITH-GAS-VA.csv ' fname{i}]);
    fprintf(fid,'\n');
 
end

% fprintf(fid,'EOF');
fprintf(fid,'\n');
fprintf(fid,'\n');
fprintf(fid,'rm geoms_qa.sav GEOMS-TE-UVVIS-DOAS-ZENITH-GAS-VA.csv tableattrvalue_*');
fprintf(fid,'\n');
fprintf(fid,'cd ../');
fclose(fid);    


%% ssh to berg and run file manually
% too lazy to figure out ssh within matlab
!ssh berg

% refresh so matlab finds HDF files
cd(cur_dir)
pause(10) % ned to wait in case net is slow and server file list doesn't update
cd([bergdir file_dir])

%% Check log files for exit codes

% log file names
tmp=dir('*.log');
logname={tmp.name};

% make sure all HDF files were processed
if length(logname)~=length(fname)
    error('QA code missed some HDF files')
end

% read exit code (last line)    
exit_codes=NaN(1,length(logname));

for i=1:length(logname)
    
    fid=fopen(logname{i},'r');
    
    % loop over file lines to find relevant entries
    search=true;
    while search

        line = fgets(fid);

        % find exit code
        if strcmp(cellstr(line(3:end)),'(Total QA/TC error)')
            exit_codes(i)=str2double(line(1));
            search=false;
        end

    end
    fclose(fid);

end

% Desired exit code is 4 (Passed QA, passed template check)

if any(exit_codes~=4)
    % some files didn't pass
    disp('The following files failed the QA check:')
    celldisp(logname(exit_codes~=4));
else
    % all files passed
    disp('All files passed QA check, removing log files')
    
    % deleting log files
    for i=1:length(logname), delete *.log; end
       
end

cd(cur_dir)

end