function [ lut_prof, lut_avk ] = read_DOAS_prof_avk( tg, input_arr, AVK_LUT_dir )
%[ lut_prof, lut_avk ] = read_DOAS_prof_avk( tg, input_arr, AVK_LUT_dir )
%READ_DOAS_PROF_AVK generate O3, NO2 profiles and averaging kernels from
%NDACC look-up tables
%
% INPUT
%       tg: 1 for ozone, 2 for NO2, 3 for NO2 UV
%       input arr: one row represents inputs for one profile/avk
%                  [year, day number, o3 column] for O3 (columnm in molec/cm2)
%                  [year, fractional time] for NO2
% OUTPUT
%       lut_prof: profiles retrieved from look-up table. Cols 1-3: reprint
%           of input_arr, (with tot col in DU for O3); cols 4-63: profile in
%           molec/cm3, 0.5-59.5km with 1km steps
%       lut_avk: averaging kernel retrieved from look-up table. Same
%           dimensions as profile


%debug
% tg=2;
% input_arr=[[2017;2017;2017], [50.2;50.5;50.8], [1;1;1]*8.0700e+18];
% AVK_LUT_dir='/home/kristof/work/NDACC/guidelines/2012/';


cur_dir=pwd();

if tg==1
    % need to work in LUT's own directory
    cd([AVK_LUT_dir 'o3_avk_lut_v2_0/']);

    % first input file doesn't have to be modified
    % (check wavelength though)

    % write second input file
    % year, day number (jan. 1 = 1), o3 column (DU) - convert molec/cm^2 to DU
    fid = fopen('Day_O3_col.dat', 'w');
    fprintf(fid, '%.0f\t%.0f\t%.4f\n', ...
            [input_arr(:,1), input_arr(:,2), input_arr(:,3)/2.69e16]');
    fclose(fid);

    % run LUT
    if ismac
        [status, result] = dos('./o3_avk_interpolation_v2_0.out', '-echo');
        %error('Create executable')
    elseif isunix
        [status, result] = dos('wine o3_avk_interpolation_v2_0.exe', '-echo');
    end
    
    %% read in avk and profile results
    % Format string for each line of text (both files):
    formatSpec = '%6f%8f%19f%24f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%11f%f%[^\n\r]';
    startrow=6;

    % ozone file
    fid = fopen('o3_prof_output.dat','r');
    % read data
    dataArray = textscan(fid, formatSpec, 'Delimiter', '', 'WhiteSpace', '', 'HeaderLines' ,startrow-1, 'ReturnOnError', false);
    fclose(fid);
    % assign ozone profile variable
    lut_prof = [dataArray{1:end-1}]; % not actually used; read anyway so code doesn't break

    % AVK file
    fid = fopen('o3_avk_output.dat','r');
    % read data
    dataArray = textscan(fid, formatSpec, 'Delimiter', '', 'WhiteSpace', '', 'HeaderLines' ,startrow-1, 'ReturnOnError', false);
    fclose(fid);
    % assign ozone avk variable
    lut_avk = [dataArray{1:end-1}];

    clearvars dataArray startrow formatSpec;

elseif tg==2 || tg==3
    % need to work in LUT's own directory
    cd([AVK_LUT_dir 'no2_avk_lut_v2_0/']);

    % select wavelength
    if tg==2
        lambda=457;
    elseif tg==3
        lambda=365;
    end
    
    % write first input file
    fid = fopen('input_file_no2_avk.dat', 'w');
    fprintf(fid, '%s\n', '*Input file for NO2 AMF interpolation program');
    fprintf(fid, '%s\n', '*');
    fprintf(fid, '%s\n', '*Wavelength (350-550 nm) ?');
    fprintf(fid, '%s\n', num2str(lambda));
    fprintf(fid, '%s\n', '*Latitude (-90 (SH) to +90 (NH)) ?');
    fprintf(fid, '%s\n', '80.05');
    fprintf(fid, '%s\n', '*Longitude (-180 (- for W) to +180 (+ for E)) ?');
    fprintf(fid, '%s\n', '-86.42');
    fprintf(fid, '%s\n', '*Ground albedo flag: 1 for Koelemeijer dscd_vecbase and 2 for albedo value defined by the user');
    fprintf(fid, '%s\n', '1');
    fprintf(fid, '%s\n', '*Ground albedo value (if albedo flag = 1, put -99)');
    fprintf(fid, '%s\n', '-99');
    fprintf(fid, '%s\n', '*Name of the file with SZA values for interpolation (less than 30 characters) ?');
    fprintf(fid, '%s\n', 'DAY_FILE.dat');
    fprintf(fid, '%s\n', '*Display flag (1: display the results on the screen; 0: dont display the results on the screen)');
    fprintf(fid, '%s\n', '0');
    fprintf(fid, '%s\n', '*Unit of the interpolated NO2 vertical profile: 0->VMR; 1->molec/cm3');
    fprintf(fid, '%s\n', '1');
    fclose(fid);

    % write second input file
    % year, fractional day (jan. 1, 00:00 = 0)
    fid = fopen('DAY_FILE.dat', 'w');
    fprintf(fid, '%.0f\t%.3f\n', ...
            [input_arr(:,1), input_arr(:,2)]');
    fclose(fid);

    % run LUT
    % run LUT
    if ismac
        [status, result] = dos('./no2_avk_interpolation_v2_0.out', '-echo');
        %error('Create executable')
    elseif isunix
        [status, result] = dos('wine no2_avk_interpolation_v2_0.exe', '-echo');
    end
    
    %% read in avk and profile results
    % Format string for each line of text (both files):
    formatSpec = '%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%[^\n\r]';
    startrow=6;

    % no2 file
    fid = fopen('no2_prof_output.dat','r');
    % read data
    dataArray = textscan(fid, formatSpec, 'Delimiter', ' ', 'MultipleDelimsAsOne', true, 'HeaderLines' ,startrow-1, 'ReturnOnError', false);
    fclose(fid);
    % assign no2 profile variable
    lut_prof = [dataArray{1:end-1}];

    % AVK file
    fid = fopen('no2_avk_output.dat','r');
    % read data
    dataArray = textscan(fid, formatSpec, 'Delimiter', ' ', 'MultipleDelimsAsOne', true, 'HeaderLines' ,startrow-1, 'ReturnOnError', false);
    fclose(fid);
    % assign no2 avk variable
    lut_avk = [dataArray{1:end-1}];

    clearvars dataArray startrow formatSpec;
    
end

% back to original directory
cd(cur_dir)

end

