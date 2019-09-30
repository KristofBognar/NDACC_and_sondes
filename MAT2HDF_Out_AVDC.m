function MAT2HDF_Out_AVDC(struc,datafile,mdatafile);


% Corinne 2008: modified MAT2HDF_Out from Tim : DATA_TYPE replaced by
% DATA_LEVEL 
%


%-----------------------------------------------------------------
%DESCRIPTION
%-----------------------------------------------------------------
%
%MAT2HDF_Out makes the metadata and data files that are needed
%by ASC2HDF to create a HDF file. This function uses a structure
%that contains the necessary configuration information, in the
%format specified by the MAT2HDF manual document. This structure
%can be created with MAT2HDF_In (that reads in a configuration
%from a text or XML file) and possibly altered by the user. The
%user can of course also create his/her own configuration 
%structure. After the successfull completion of this function,
%you should run ASC2HDF to make the HDF file you want, based
%on the mdatafile (metadata output file), datafile (data output
%file) - both written by this function - and the table.dat file.
%ASC2HDF also requires a logfile as parameter.
%
%This function will check the presence (isfield) of the
%configuration parameters and also checks if the parameters are
%empty. Mandatory parameters that are unspecified or empty will
%result in a warning. Optional parameters that are unspecified
%are assumed to be empty. When VAR_NAME or VALUES is empty or 
%unspecified, an error message is shown and the entire variable
%is skipped, ignoring the rest of the variable configuration
%and without output for that variable. 
%If the FORMAT element, which defines the correct format in
%which the elements of VALUES are to be printed in the data
%output file, does not exist, the VIS_FORMAT is translated into
%a C-style format (e.g. Fa.b => %a.bf) and that format is used.
%If VIS_FORMAT was also unspecified or empty, then a default
%format (depending on VAR_DATA_TYPE, not on the Matlab data
%type) is used. If VAR_DATA_TYPE is also empty or unspecified,
%then an error message is shown and the variable is skipped (no
%output for that variable). If VIS_FORMAT or VAR_DATA_TYPE was
%used, but contained an invalid value, there is also an error
%message and the variable is skipped (without looking for
%other formats, so if VIS_FORMAT is invalid, the default
%format based on VAR_DATA_TYPE is NOT used).
%
%The contents of the configuration parameters is not checked,
%except for DATA_FILE_VERSION (001..999) and VAR_DIMENSION 
%(1..8) and some other parameters like VIS_FORMAT. The contents
%of the other parameters is checked by ASC2HDF.
%
%MAT2HDF_Out will not alter the structure, it will just print
%output based on the configuration inside the structure.
%
%Parameter data type
%
%All parameters are assumed to be in a pre-formatted (e.g.
%user specified) format, except VAR_DIMENSION, DATA_FILE_VERSION,
%VAR_VALID_MIN/MAX, VIS_SCALE_MIN/MAX. Other numerical values
%should be pre-formatted by the user and stored as strings (char
%arrays) in the structure (e.g. using: struc....=sprintf()). 
%If the user does not do that, the numerical value will be printed
%in the '%s\n' format, thus printing the ASCII equivalent
%character (character with the ASCII value equal to the numerical
%value).
%
%Values that can be multiple data types, like VAR_SIZE (can be
%numerical '4' or string '4;3;2') or DATETIME (ISO-string or
%MJD-Double) must be given as pre-formatted string in the 
%structure.
%
%The parameters that may be numerical (like VAR_DIMENSION) are
%printed in a predefined format (if there is one) or in the same
%format as VALUES (this means the FORMAT value, the VIS_FORMAT or
%default format in that order of precedence).
%Example:
%VAR_DIMENSION must be a number between 1 and 8 (metadata guide-
%lines) and is therefor printed as '%d\n' (normal integer format).
%DATA_FILE_VERSION must be a 3 digit integer between 001 and 999.
%It's format is thus '%3.3d\n' (3 digit integer).
%VAR_VALID_MIN/MAX and VIS_SCALE_MIN/MAX are printed in the
%same format as VALUES (if they are numerical and not strings).
%Note that if DATA_FILE_VERSION and VAR_DIMENSION are given as
%strings, the strings are converted to numbers to check their
%validity, but the strings are used without change when printing
%the values to the output files (so the strings are unharmed,
%just as all strings).
%
%NOTE: using numeric values for VAR_VALID_MIN/MAX and VIS_SCALE_
%MIN/MAX can result in loss of precision or unwanted results.
%Example:
%Let's say that VAR_VALID_MIN is set to 12.3456789 (numerical).
%If you specified FORMAT to be '%10.4f\n', then 12.3456789 will
%be printed to the metadata output file as    12.3457. This
%value will be read by ASC2HDF and interpreted as 12.34570000...
%which is higher than the value you wanted. Any data value
%between 12.3456789 and 12.3457 will be refused by ASC2HDF, even
%though they are valid!
%
%NOTE: ASC2HDF reads in any number (float, integer,...) and
%converts it to a high precision floating point value. But if
%the value was printed with only low precision, the value can
%be misinterpreted. The conversion does not matter! Once the
%precision is lost, it's lost for good.
%
%Printing of VALUES
%
%As said above, the format in which the VALUES elements 
%(elements in the VALUES array that is stored per variable in the
%configuration structure) are printed is determined by FORMAT,
%VIS_FORMAT and the default per data type, in that order of
%precedence (so if FORMAT is specified, VIS_FORMAT and the 
%default are ignored, etc).
%
%NOTE: This may lead to unwanted situations, which are not
%prevented. For instance, you can print out a string value (e.g.
%VALUES is a character array) with '%d\n' format, thus printing
%the ASCII values of all the characters in the array, 1 per line.
%This result was probably not desired. So, please be carefull
%when choosing the VALUES and their FORMAT (or VIS_FORMAT).
%No consistency checking between VALUES, FORMAT and VIS_FORMAT is
%done by MAT2HDF_Out.
%
%Strings are printed with 1 string per line ('%s\n' format) and
%must be given in a character array specifying 1 string per row.
%Such character arrays may not have more than 2 dimensions.
%Cell arrays and numerical/logical arrays are printed 1 element
%per row (as needed for ASC2HDF) and the arrays are processed
%columnwise (via the (:) and {:} operators). Remember this when
%storing the VALUES arrays. 
%Note that the consistency between the data type of the cell
%array elements and the format (FORMAT, VIS_FORMAT,...) is NOT
%checked. If the cell array contains for instance strings and
%numeric values and the format is '%s\n', then all numerics
%will be printed as their ASCII equivalent characters, while
%all strings are printed normally. If the format was a
%numerical format like '%d\n' or '%10.4f\n', then the strings
%would be printed as the ASCII numerical values of their
%characters, while the numericals are printed normally. Since
%it is impossible to specify more than 1 format for a certain
%variable, the user is advised to store only 1 data type in
%the cell array (using the appropriate format) instead of
%mixing data types.
%
%The FORMAT must be given in C/Matlab-style formats (like
%'%10.4f\n', preferably ending with '\n' (to print 1 value per
%row) and specifying only 1 column of output (so do not use
%'%10.4f %10.4f\n' or something like that). VIS_FORMAT, as 
%defined in the Metadata Guidelines, is a FORTRAN style format.
%Like all configuration parameters, VIS_FORMAT also has a set
%of allowed values in the guidelines. MAT2HDF_Out can convert
%the allowed formats to C/Matlab style formats, but any other
%formats will result in an error message and the skipping of
%the variable with the illegal format.
%
%Metadata Guidelines
%
%Please also remember the Metadata Guidelines. Some of those
%rules are implictly/explicitly used and/or checked in this
%function. For example, the Metadata Guidelines only provide
%with a 5 data types (4 numerical and String). These data types
%are supported, but other Matlab data types may be unsupported.
%
%Since there are only 5 datatypes supported, there are only
%5 default formats provided (1 per VAR_DATA_TYPE value). This
%assumes that the Metadata Guidelines is followed (implicitly)
%and checks (explicitly) if your VAR_DATA_TYPE is invalid.
%
%-----------------------------------------------------------------
%SYNTAX
%-----------------------------------------------------------------
%
%MAT2HDF_Out(struc,datafile,mdatafile)
%
%"struc" is a Matlab structure containing the fields that need to
%be written to an HDF file. The fields are defined in the 
%Metadata Guidelines document from NILU. The structure is defined
%in the MAT2HDF Manual document.
%"datafile" is the data (output) file, the file that will contain
%the values to be written to an HDF file by ASC2HDF. This function
%will write the necessary values to that file. For a
%description of the format of the data file, please refer to the 
%ASC2HDF manual.
%"mdatafile" is the metadata (output) file, the file that will 
%contain the metadata attribute values to be written to an HDF 
%file by ASC2HDF. This function will write the necessary lines to
%the specified file, following the ASC2HDF format specifications.
%For a description of the format of the metadata file, please 
%refer to the ASC2HDF manual.

%-----------------------------------------------------------------
%INPUT PARAMETERS
%-----------------------------------------------------------------

%"struc" must be a Matlab structure and it must have fields
if isstruct(struc)==0 | isempty(fieldnames(struc))
	disp('Error: Invalid structure');
	return;
end
%whether the correct fields exist within the structure, is tested
%later on (in the main code)

%datafile and mdatafile are tested to see if they can be
%opened for writing (they do not have to exist, but write-
%permission must be OK to create them or to overwrite them).

%open files for writing
%give error if open fails
%datafile
datfid=fopen(datafile,'w');
%metadata output file
mdatfid=fopen(mdatafile,'w');

if mdatfid==-1 
	disp(['Error opening metadata output file ',mdatfile,' for writing.']);
	return;
end
if datfid==-1 
	disp(['Error opening data output file ',datfile,' for writing.']);
	%close metadatafile (has already been opened)
	fclose(mdatfid);
	return;
end

%-----------------------------------------------------------------
%MAIN CODE
%-----------------------------------------------------------------

%INIT
numb=0;
numb2=0;

%Entire code is placed in a try-catch block
%So, if any error occurs => print it and close the 2 files?

% Output is in the same sequence as the example files (in the ASC2HDF distribution)
% FILE_NAME must be left empty (filled in by ASC2HDF)
% FILE_META_VERSION must be omitted if prepared for ASC2HDF because ASC2HDF
% adds it itself; must be kept with idlcr8hdf

try
	%EVT ANDERE NAMEN VOOR STRUCT ELEMENTEN : vb '_attr' weg, gewoon 'orig', 'file', 'dset' en 'var'?
	%DEBUG - testcase input values
	%struc.orig_attr.PI_NAME='Van Roozendael;Michel';
	%struc.orig_attr.PI_AFFILIATION='Belgian Institute for Space Aeronomy; BIRA.IASB';
	%struc.orig_attr.PI_ADDRESS='Avenue Circulaire, 3; B-1180; Belgium';
	%struc.orig_attr.PI_EMAIL='michelv@bira-iasb.oma.be';
	%struc.orig_attr.DO_NAME='Van Roozendael;Michel';
	%struc.orig_attr.DO_AFFILIATION='Belgian Institute for Space Aeronomy; BIRA.IASB';
	%struc.orig_attr.DO_ADDRESS='Avenue Circulaire, 3; B-1180; Belgium';
	%struc.orig_attr.DO_EMAIL='michelv@bira-iasb.oma.be';
	%struc.orig_attr.DS_NAME='Fayt; Caroline';
	%struc.orig_attr.DS_AFFILIATION='Belgian Institute for Space Aeronomy; BIRA.IASB';
	%struc.orig_attr.DS_ADDRESS='Avenue Circulaire, 3; B-1180; Belgium';
	%struc.orig_attr.DS_EMAIL='caroline.fayt@bira-iasb.oma.be';
	%struc.dset_attr.DATA_DESCRIPTION='DOAS MEASUREMENTS AT HARESTUA';
	%struc.dset_attr.DATA_DISCIPLINE='ATMOSPHERIC.PHYSICS; INSITU; GROUNDBASED';
	%struc.dset_attr.DATA_GROUP='EXPERIMENTAL; SCALAR.STATIONARY';
	%struc.dset_attr.DATA_LOCATION='HARESTUA';
	%struc.dset_attr.DATA_SOURCE='UVVIS.DOAS_BIRA.IASB001';
	%struc.dset_attr.DATA_LEVEL='D2';
	%struc.dset_attr.DATA_VARIABLES='DATETIME; LATITUDE.INSTRUMENT';
	%struc.dset_attr.DATA_START_DATE='1142';
	%struc.dset_attr.DATA_FILE_VERSION='001';
	%struc.dset_attr.DATA_MODIFICATIONS='None so far';
    %struc.dset_attr.DATA_QUALITY='Daily HBR cell measurements analysed with Linefit v8. Reference paper Senten et al., ACP 8, 3483-3508,2008. NDACC qualification in progress.';
	%struc.dset_attr.DATA_CAVEATS='';
	%struc.dset_attr.DATA_RULES_OF_USE='';
	%struc.dset_attr.DATA_ACKNOWLEDGEMENT='';
	%struc.file_attr.FILE_GENERATION_DATE='1164.825542430509800';
	%struc.file_attr.FILE_ACCESS='CALVAL';
	%struc.file_attr.FILE_PROJECT_ID='AOID158';
	%struc.file_attr.FILE_ASSOCIATION='';
    %struc.file_attr.FILE_META_VERSION='';
	%struc.var(1).VAR_NAME='O3.VERTICAL_COLUMN.SOLAR';
	%struc.var(1).VAR_DESCRIPTION='Test case';
	%%struc.var(1).VAR_NOTES='';
	%struc.var(1).VAR_DIMENSION='1';
	%struc.var(1).VAR_SIZE='5';
	%struc.var(1).VAR_DEPEND='INDEPENDENT';
	%struc.var(1).VAR_UNITS='molec cm-2';
	%struc.var(1).VAR_DATA_TYPE='DOUBLE';
	%struc.var(1).VAR_SI_CONVERSION='0;1E4;molec m-2';
	%struc.var(1).VAR_VALID_MIN='0';
	%struc.var(1).VAR_VALID_MAX='100';
	%struc.var(1).VAR_MONOTONE='FALSE';
	%struc.var(1).VAR_AVG_TYPE='NONE';
	%struc.var(1).VAR_FILL_VALUE='-999.00';
	%struc.var(1).VIS_LABEL='O3 VCD';
	%struc.var(1).VIS_FORMAT='F8.2';
	%%struc.var(1).VIS_FORMAT='';
	%struc.var(1).VIS_PLOT_TYPE='XY';
	%struc.var(1).VIS_SCALE_TYPE='LINEAR;FALSE';
	%struc.var(1).VIS_SCALE_MIN='0.00';
	%struc.var(1).VIS_SCALE_MAX='100.00';
	%struc.var(1).FORMAT='%10.4e\n';
	%%struc.var(1).FORMAT='';
	%struc.var(1).VALUES=[1;2;3;4;5];
	%%struc.var(1).VALUES=['a';'b';'c';'d';'e'];
	%struc.var(2).VAR_NAME='O3.VERTICAL_COLUMN.SOLAR';
	%struc.var(2).VAR_DESCRIPTION='Test case';
	%%struc.var(2).VAR_NOTES='';
	%struc.var(2).VAR_DIMENSION='1';
	%struc.var(2).VAR_SIZE='5';
	%struc.var(2).VAR_DEPEND='INDEPENDENT';
	%struc.var(2).VAR_UNITS='molec cm-2';
	%struc.var(2).VAR_DATA_TYPE='DOUBLE';
	%struc.var(2).VAR_SI_CONVERSION='0;1E4;molec m-2';
	%struc.var(2).VAR_VALID_MIN='0';
	%struc.var(2).VAR_VALID_MAX='100';
	%struc.var(2).VAR_MONOTONE='FALSE';
	%struc.var(2).VAR_AVG_TYPE='NONE';
	%struc.var(2).VAR_FILL_VALUE='-999.00';
	%struc.var(2).VIS_LABEL='O3 VCD';
	%struc.var(2).VIS_FORMAT='F8.2';
	%%struc.var(2).VIS_FORMAT='';
	%struc.var(2).VIS_PLOT_TYPE='XY';
	%struc.var(2).VIS_SCALE_TYPE='LINEAR;FALSE';
	%struc.var(2).VIS_SCALE_MIN='0.00';
	%struc.var(2).VIS_SCALE_MAX='100.00';
	%struc.var(2).FORMAT='%10.4f\n';
	%%struc.var(2).FORMAT='';
	%struc.var(2).VALUES=[6;7;8;9;10];
	%%struc.var(2).VALUES=['a';'b';'c';'d';'e'];


	%write header to metadata output file
	fprintf(mdatfid,'!\n');
	fprintf(mdatfid,'!NOTE: the section numbers refer to the Metadata Guidelines document.\n');
	fprintf(mdatfid,'!\n');
%	fprintf(mdatfid,'! Global Attributes\n');
%	fprintf(mdatfid,'! =================\n');
%	fprintf(mdatfid,'!\n');
	fprintf(mdatfid,'! Section 4.1: Originator Attributes\n');
	fprintf(mdatfid,'! ----------------------------------\n');

	%checking for invalid values (isfield==0 or isempty==1) isn't necessary (ASC2HDF will catch those errors too)
	%but it is handy for the user and it catches the Matlab errors (if the structure element does not exist => "illegal reference to ...")

	%If the attribute is optional => print empty value in metadatafile if the attribute isn't specified in struct (by user) or if its empty

	%write originator attributes to metadata output file
	fprintf(mdatfid,'!\n');
	if isfield(struc.orig_attr,'PI_NAME')==1 & isempty(struc.orig_attr.PI_NAME)==0 & ischar(struc.orig_attr.PI_NAME)==1
		fprintf(mdatfid,'PI_NAME=%s\n',struc.orig_attr.PI_NAME);
	else
		disp('Warning: invalid PI_NAME');
	end
	if isfield(struc.orig_attr,'PI_AFFILIATION')==1 & isempty(struc.orig_attr.PI_AFFILIATION)==0 & ischar(struc.orig_attr.PI_AFFILIATION)==1
		fprintf(mdatfid,'PI_AFFILIATION=%s\n',struc.orig_attr.PI_AFFILIATION);
	else
		disp('Warning: invalid PI_AFFILIATION');
	end
	if isfield(struc.orig_attr,'PI_ADDRESS')==1 & isempty(struc.orig_attr.PI_ADDRESS)==0 & ischar(struc.orig_attr.PI_ADDRESS)==1
		fprintf(mdatfid,'PI_ADDRESS=%s\n',struc.orig_attr.PI_ADDRESS);
	else
		disp('Warning: invalid PI_ADDRESS');
	end
	if isfield(struc.orig_attr,'PI_EMAIL')==1 & isempty(struc.orig_attr.PI_EMAIL)==0 & ischar(struc.orig_attr.PI_EMAIL)==1
		fprintf(mdatfid,'PI_EMAIL=%s\n',struc.orig_attr.PI_EMAIL);
	else
		disp('Warning: invalid PI_EMAIL');
	end
	fprintf(mdatfid,'!\n');
	if isfield(struc.orig_attr,'DO_NAME')==1 & isempty(struc.orig_attr.DO_NAME)==0 & ischar(struc.orig_attr.DO_NAME)==1
		fprintf(mdatfid,'DO_NAME=%s\n',struc.orig_attr.DO_NAME);
	else
		disp('Warning: invalid DO_NAME');
	end
	if isfield(struc.orig_attr,'DO_AFFILIATION')==1 & isempty(struc.orig_attr.DO_AFFILIATION)==0 & ischar(struc.orig_attr.DO_AFFILIATION)==1
		fprintf(mdatfid,'DO_AFFILIATION=%s\n',struc.orig_attr.DO_AFFILIATION);
	else
		disp('Warning: invalid DO_AFFILIATION');
	end
	if isfield(struc.orig_attr,'DO_ADDRESS')==1 & isempty(struc.orig_attr.DO_ADDRESS)==0 & ischar(struc.orig_attr.DO_ADDRESS)==1
		fprintf(mdatfid,'DO_ADDRESS=%s\n',struc.orig_attr.DO_ADDRESS);
	else
		disp('Warning: invalid DO_ADDRESS');
	end
	if isfield(struc.orig_attr,'DO_EMAIL')==1 & isempty(struc.orig_attr.DO_EMAIL)==0 & ischar(struc.orig_attr.DO_EMAIL)==1
		fprintf(mdatfid,'DO_EMAIL=%s\n',struc.orig_attr.DO_EMAIL);
	else
		disp('Warning: invalid DO_EMAIL');
	end
	fprintf(mdatfid,'!\n');
	if isfield(struc.orig_attr,'DS_NAME')==1 & isempty(struc.orig_attr.DS_NAME)==0 & ischar(struc.orig_attr.DS_NAME)==1
		fprintf(mdatfid,'DS_NAME=%s\n',struc.orig_attr.DS_NAME);
	else
		disp('Warning: invalid DS_NAME');
	end
	if isfield(struc.orig_attr,'DS_AFFILIATION')==1 & isempty(struc.orig_attr.DS_AFFILIATION)==0 & ischar(struc.orig_attr.DS_AFFILIATION)==1
		fprintf(mdatfid,'DS_AFFILIATION=%s\n',struc.orig_attr.DS_AFFILIATION);
	else
		disp('Warning: invalid DS_AFFILIATION');
	end
	if isfield(struc.orig_attr,'DS_ADDRESS')==1 & isempty(struc.orig_attr.DS_ADDRESS)==0 & ischar(struc.orig_attr.DS_ADDRESS)==1
		fprintf(mdatfid,'DS_ADDRESS=%s\n',struc.orig_attr.DS_ADDRESS);
	else
		disp('Warning: invalid DS_ADDRESS');
	end
	if isfield(struc.orig_attr,'DS_EMAIL')==1 & isempty(struc.orig_attr.DS_EMAIL)==0 & ischar(struc.orig_attr.DS_EMAIL)==1
		fprintf(mdatfid,'DS_EMAIL=%s\n',struc.orig_attr.DS_EMAIL);
	else
		disp('Warning: invalid DS_EMAIL');
	end

	fprintf(mdatfid,'!\n');
	fprintf(mdatfid,'! Section 4.2: Dataset Attributes\n');
	fprintf(mdatfid,'! -------------------------------\n');

	%write dataset attributes to metadata output file
	fprintf(mdatfid,'!\n');
	if isfield(struc.dset_attr,'DATA_DESCRIPTION')==1 & isempty(struc.dset_attr.DATA_DESCRIPTION)==0 & ischar(struc.dset_attr.DATA_DESCRIPTION)==1
		fprintf(mdatfid,'DATA_DESCRIPTION=%s\n',struc.dset_attr.DATA_DESCRIPTION);
	else
		disp('Warning: invalid DATA_DESCRIPTION');
	end
	if isfield(struc.dset_attr,'DATA_DISCIPLINE')==1 & isempty(struc.dset_attr.DATA_DISCIPLINE)==0 & ischar(struc.dset_attr.DATA_DISCIPLINE)==1
		fprintf(mdatfid,'DATA_DISCIPLINE=%s\n',struc.dset_attr.DATA_DISCIPLINE);
	else
		disp('Warning: invalid DATA_DISCIPLINE');
	end
	if isfield(struc.dset_attr,'DATA_GROUP')==1 & isempty(struc.dset_attr.DATA_GROUP)==0 & ischar(struc.dset_attr.DATA_GROUP)==1
		fprintf(mdatfid,'DATA_GROUP=%s\n',struc.dset_attr.DATA_GROUP);
	else
		disp('Warning: invalid DATA_GROUP');
	end
	if isfield(struc.dset_attr,'DATA_LOCATION')==1 & isempty(struc.dset_attr.DATA_LOCATION)==0 & ischar(struc.dset_attr.DATA_LOCATION)==1
		fprintf(mdatfid,'DATA_LOCATION=%s\n',struc.dset_attr.DATA_LOCATION);
	else
		disp('Warning: invalid DATA_LOCATION');
	end
	if isfield(struc.dset_attr,'DATA_SOURCE')==1 & isempty(struc.dset_attr.DATA_SOURCE)==0 & ischar(struc.dset_attr.DATA_SOURCE)==1
		fprintf(mdatfid,'DATA_SOURCE=%s\n',struc.dset_attr.DATA_SOURCE);
	else
		disp('Warning: invalid DATA_SOURCE');
	end
	if isfield(struc.dset_attr,'DATA_LEVEL')==1 & isempty(struc.dset_attr.DATA_LEVEL)==0 & ischar(struc.dset_attr.DATA_LEVEL)==1
		fprintf(mdatfid,'DATA_LEVEL=%s\n',struc.dset_attr.DATA_LEVEL);
	else
		disp('Warning: invalid DATA_LEVEL');
	end

	fprintf(mdatfid,'!\n');

	if isfield(struc.dset_attr,'DATA_VARIABLES')==1 & isempty(struc.dset_attr.DATA_VARIABLES)==0 & ischar(struc.dset_attr.DATA_VARIABLES)==1
		fprintf(mdatfid,'DATA_VARIABLES=%s\n',struc.dset_attr.DATA_VARIABLES);
	else
		disp('Warning: invalid DATA_VARIABLES');
	end

	fprintf(mdatfid,'!\n');
    
    % DATA_START_DATE and DATA_STOP_DATE may be empty!
	% if isfield(struc.dset_attr,'DATA_START_DATE')==1 & isempty(struc.dset_attr.DATA_START_DATE)==0 & ischar(struc.dset_attr.DATA_START_DATE)==1
    if isfield(struc.dset_attr,'DATA_START_DATE')==1 
		fprintf(mdatfid,'DATA_START_DATE=%s\n',struc.dset_attr.DATA_START_DATE);
	else
		disp('Warning: invalid DATA_START_DATE');
    end
    % if isfield(struc.dset_attr,'DATA_STOP_DATE')==1 & isempty(struc.dset_attr.DATA_START_DATE)==0 & ischar(struc.dset_attr.DATA_START_DATE)==1
	if isfield(struc.dset_attr,'DATA_STOP_DATE')==1 
        fprintf(mdatfid,'DATA_STOP_DATE=%s\n',struc.dset_attr.DATA_STOP_DATE);
    else
		disp('Warning: invalid DATA_STOP_DATE');
	end
	%DATA_FILE_VERSION CAN BE NUMERIC!
	if isfield(struc.dset_attr,'DATA_FILE_VERSION')==1 & isempty(struc.dset_attr.DATA_FILE_VERSION)==0
		if isnumeric(struc.dset_attr.DATA_FILE_VERSION)==1
			%auto-convert using %3.3d format (1 digit integer)
			struc.dset_attr.DATA_FILE_VERSION=sprintf('%3.3d',struc.dset_attr.DATA_FILE_VERSION);
		end
		%test if string value is between '1' and '8'?
		%(this is not tested by ASC2HDF)
		%we use >= and <= to test the ASCII value of the character(s) stored in VAR_DIMENSTION
		try
			numb=str2num(struc.dset_attr.DATA_FILE_VERSION);
		catch
			disp('Warning: DATA_FILE_VERSION contains invalid characters.');
			%force next test to fail => no fprintf is done for DATA_FILE_VERSION
			numb=0;
		end
		if length(struc.dset_attr.DATA_FILE_VERSION)==3 & numb >= 1 & numb <= 999
			fprintf(mdatfid,'DATA_FILE_VERSION=%s\n',struc.dset_attr.DATA_FILE_VERSION);
		else
			disp(['Warning: DATA_FILE_VERSION should be a 3 digit string.']);
		end
	else
		disp('Warning: invalid DATA_FILE_VERSION');
	end
	if isfield(struc.dset_attr,'DATA_MODIFICATIONS')==1 & isempty(struc.dset_attr.DATA_MODIFICATIONS)==0 & ischar(struc.dset_attr.DATA_MODIFICATIONS)==1
		fprintf(mdatfid,'DATA_MODIFICATIONS=%s\n',struc.dset_attr.DATA_MODIFICATIONS);
	else
		disp('Warning: invalid DATA_MODIFICATIONS');
 end
 if isfield(struc.dset_attr,'DATA_QUALITY')==1 & isempty(struc.dset_attr.DATA_QUALITY)==0 & ischar(struc.dset_attr.DATA_QUALITY)==1
		fprintf(mdatfid,'DATA_QUALITY=%s\n',struc.dset_attr.DATA_QUALITY);
	else
		disp('Warning: invalid DATA_QUALITY');
	end
 if isfield(struc.dset_attr,'DATA_TEMPLATE')==1 & isempty(struc.dset_attr.DATA_TEMPLATE)==0 & ischar(struc.dset_attr.DATA_TEMPLATE)==1
  disp('!!! DATA_TEMPLATE');
		fprintf(mdatfid,'DATA_TEMPLATE=%s\n',struc.dset_attr.DATA_TEMPLATE);
	else
		disp('Warning: invalid DATA_TEMPLATE');
	end	
    %OPTIONAL DATA_CAVEATS
	if isfield(struc.dset_attr,'DATA_CAVEATS')==1 & isempty(struc.dset_attr.DATA_CAVEATS)==0 & ischar(struc.dset_attr.DATA_CAVEATS)==1
		fprintf(mdatfid,'DATA_CAVEATS=%s\n',struc.dset_attr.DATA_CAVEATS);
	else
		%disp('Warning: invalid DATA_CAVEATS');
		%print empty value
		fprintf(mdatfid,'DATA_CAVEATS=\n');
	end
	%OPTIONAL DATA_RULES_OF_USE
	if isfield(struc.dset_attr,'DATA_RULES_OF_USE')==1 & isempty(struc.dset_attr.DATA_RULES_OF_USE)==0 & ischar(struc.dset_attr.DATA_RULES_OF_USE)==1
		fprintf(mdatfid,'DATA_RULES_OF_USE=%s\n',struc.dset_attr.DATA_RULES_OF_USE);
	else
		%disp('Warning: invalid DATA_RULES_OF_USE');
		fprintf(mdatfid,'DATA_RULES_OF_USE=\n');
	end
	%ÚPTIONAL DATA_ACKNOWLEDGEMENT
	if isfield(struc.dset_attr,'DATA_ACKNOWLEDGEMENT')==1 & isempty(struc.dset_attr.DATA_ACKNOWLEDGEMENT)==0 & ischar(struc.dset_attr.DATA_ACKNOWLEDGEMENT)==1
		fprintf(mdatfid,'DATA_ACKNOWLEDGEMENT=%s\n',struc.dset_attr.DATA_ACKNOWLEDGEMENT);
	else
		%disp('Warning: invalid DATA_ACKNOWLEDGEMENT');
		fprintf(mdatfid,'DATA_ACKNOWLEDGEMENT=\n');
	end

	fprintf(mdatfid,'!\n');

	fprintf(mdatfid,'!\n');
	fprintf(mdatfid,'! Section 4.3: File Attributes\n');
	fprintf(mdatfid,'! ----------------------------\n');

	%write file attributes to metadata output file
	fprintf(mdatfid,'!\n');
	
	%FILE_NAME is filled in by ASC2HDF
	%if isfield(struc.file_attr,'FILE_NAME')==1 & isempty(struc.file_attr.FILE_NAME)==0 & ischar(struc.file_attr.FILE_NAME)==1
	%	fprintf(mdatfid,'FILE_NAME=%s\n'); %is filled in by asc2hdf??
	%else
	%	disp('Warning: invalid FILE_NAME');
	%end
	%EVT GEEN ischar() test als je zelf de FILE_GENERATION_DATE invult??

	%YOU NEED TO PRINT A "FILE_NAME=" LINE (with no value) TO ALLOW ASC2HDF TO FILL IN THE FILENAME!
	fprintf(mdatfid,'FILE_NAME=\n');

    % FILE_GENERATION_DATE may be empty; idlcr8hdf will fill it with the
    % correct data in iso 8601 format
	%if isfield(struc.file_attr,'FILE_GENERATION_DATE')==1 & isempty(struc.file_attr.FILE_GENERATION_DATE)==0 & ischar(struc.file_attr.FILE_GENERATION_DATE)==1
    if isfield(struc.file_attr,'FILE_GENERATION_DATE')==1 & ischar(struc.file_attr.FILE_GENERATION_DATE)==1
		fprintf(mdatfid,'FILE_GENERATION_DATE=%s\n',struc.file_attr.FILE_GENERATION_DATE);
	else
		disp('Warning: invalid FILE_GENERATION_DATE');
	end
	if isfield(struc.file_attr,'FILE_ACCESS')==1 & isempty(struc.file_attr.FILE_ACCESS)==0 & ischar(struc.file_attr.FILE_ACCESS)==1
		fprintf(mdatfid,'FILE_ACCESS=%s\n',struc.file_attr.FILE_ACCESS);
	else
		disp('Warning: invalid FILE_ACCESS');
	end
	if isfield(struc.file_attr,'FILE_PROJECT_ID')==1 & isempty(struc.file_attr.FILE_PROJECT_ID)==0 & ischar(struc.file_attr.FILE_PROJECT_ID)==1
		fprintf(mdatfid,'FILE_PROJECT_ID=%s\n',struc.file_attr.FILE_PROJECT_ID);
	else
		disp('Warning: invalid FILE_PROJECT_ID');
	end
	%OPTIONAL FILE_ASSOCIATION
	if isfield(struc.file_attr,'FILE_ASSOCIATION')==1 & isempty(struc.file_attr.FILE_ASSOCIATION)==0 & ischar(struc.file_attr.FILE_ASSOCIATION)==1
		fprintf(mdatfid,'FILE_ASSOCIATION=%s\n',struc.file_attr.FILE_ASSOCIATION);
	else
		%disp('Warning: invalid FILE_ASSOCIATION');
		fprintf(mdatfid,'FILE_ASSOCIATION=\n');
	end
	%FILE_META_VERSION IS ADDED AUTOMATICALLY BY ASC2HDF, not by idlcr8hdf: IT MAY or MAY NOT BE SPECIFIED/ADDED TO THE METADATA OUTPUT FILE
	if isfield(struc.file_attr,'FILE_META_VERSION')==1 & isempty(struc.file_attr.FILE_META_VERSION)==0 & ischar(struc.file_attr.FILE_META_VERSION)==1
		fprintf(mdatfid,'FILE_META_VERSION=%s\n',struc.file_attr.FILE_META_VERSION);%is filled in by asc2hdf
	else
		disp('Warning: invalid FILE_META_VERSION');
	end

	fprintf(mdatfid,'!\n');
	fprintf(mdatfid,'! Section 5.1 & 5.2: Variable Attributes\n');
	%fprintf(mdatfid,'! Data output:	Variable values\n');
	fprintf(mdatfid,'! --------------------------------------\n');

	%GETEST: WERKT TOT HIER
	%struc.var has 1 element per data variable
	%each struc.var(l) contains attributes and data values (array)
	for l=1:length(struc.var)
		%write variable attributes to metadata output file
		fprintf(mdatfid,'!\n');
		%VAR_ attributes
		if isfield(struc.var(l),'VAR_NAME')==1 & isempty(struc.var(l).VAR_NAME)==0 & ischar(struc.var(l).VAR_NAME)==1
			%THIS TEST MUST BE PERFORMED HERE, BECAUSE YOU NEED A VALID VAR_NAME FOR THE DISP, AND BECAUSE YOU DO NOT WANT TO PRINT VAR_NAME IF THE TEST FAILS
			%if variable does not have VALUES specified => error + continue with next variable
			if isfield(struc.var(l),'VALUES')==0 | isempty(struc.var(l).VALUES)==1
				disp(['Error: variable ',struc.var(l).VAR_NAME,' does not have any VALUES. Variable is skipped.']);
				continue;
			end
			fprintf(mdatfid,'VAR_NAME=%s\n',struc.var(l).VAR_NAME);
		else
			disp(['Warning: invalid VAR_NAME for variable ',num2str(l),'. Variable is skipped.']);
			%proceed with next variable (because disp's below presume a valid VAR_NAME and would cause an error if VAR_NAME is invalid)
			%and because VAR_NAME is needed in data output file
			continue;
		end
		%VAR_NAME and VALUES are both valid (otherwise, a "continue" will have prevented you from arriving at this point in the code)
		
		%FORMAT DETECTION: done only once per variable!
		%format detection is done here because the format may also be needed for VALID_MIN/MAX SCALE_MIN/MAX
		%DETECTION: use user specified "FORMAT" field (if present and not empty, else use converted VIS_FORMAT (if present and not empty, else use data type default))

		if isfield(struc.var(l),'FORMAT')==1 & isempty(struc.var(l).FORMAT)==0 & ischar(struc.var(l).FORMAT)==1
			%Use FORMAT field
			fmt=struc.var(l).FORMAT;
			%fmt must end with '\n' - only checked here (user defined formats), VIS_FORMAT translation and default formats contain '\n'
			if strcmp(fmt(length(fmt)-1:length(fmt)),'\n')==0
				fmt=[fmt,'\n'];
			end
		else
			%FORMAT field is invalid => use VIS_FORMAT
			if isfield(struc.var(l),'VIS_FORMAT')==1 & isempty(struc.var(l).VIS_FORMAT)==0 & ischar(struc.var(l).VIS_FORMAT)==1
				%Use VIS_FORMAT

				%NOTE: the fprintf format strings and VIS_FORMAT mean the same thing, but are written differently
				%so a "translation" between the two is necessary
				%Translate VIS_FORMAT to fprintf format (only Ad,Fd.d,Ed.d, Id and Id.d are supported - see Metadata guidelines):

				%VIS_FORMAT MUST BE CHAR ARRAY (string), NOT CELL ARRAY - evt conversie??

				%VIS_FORMAT vs Matlab (C-like) formats
				%'Ad'          '%as' (char string, length a)
				%'Fa.b'        '%a.bf' ?? NAZIEN : Fa.b = fixed point <=> %f = floating point? beter: %d?
				%'Ea.b'        '%a.be' of '%a.bE' (exponential, min. a digits, fraction of b digits)
				%'Ia'          '%ad' (integer, min. a digits)
				%INCORRECT:
				%'Ia.b'        '%ad' (integer, min a digits, padded with leading zeroes) NEE! Ia.b = min a karakters, met min. b cijfers (b bepaalt leading 0's)
				%	        => %0ad geeft a digits waarbij a de leading 0's bepaalt!! => dubbele printf nodig?? '%ad' (BETER: %as!! sprintf geeft string!!) print van string=sprintf('%0b',value)!
				%CORRECT (see man fprintf)
				%'Ia.b'        '%a.bd' or '%a.bi' (integer, min a characters in total (space padding if necessary), min. b digits (leading 0's if necessary)

				c=upper(struc.var(l).VIS_FORMAT(1));

				switch c
					case 'A'
						%YOU SHOULD PUT THIS INSIDE A TRY-CATCH (sscanf can fail if VIS_FORMAT is incorrectly specified eg A4.3)
						%get nr of chars
						nr=sscanf(struc.var(l).VIS_FORMAT,'A%d');
						%testen of nr wel iets bevat??
						fmt=['%',num2str(nr),'s','\n'];
						%EVT: conversie via char() nodig of num2str??
					case 'F'
						%NOT NECESSARY: just replace Fa.b by %a.bf
						%get nr of digits (nr) and precision of fraction (nr of digits after the decimal separator)
						%[nr,p]=sscanf(struc.var(l).VIS_FORMAT,'F%d.%d');

						%can also:
						%str=sscanf(struc.var(l).VIS_FORMAT,'F%s');
						str=regexprep(struc.var(l).VIS_FORMAT,'F','','once');
						fmt=['%',str,'f','\n'];
					case 'E'
						%can also:
						%str=sscanf(struc.var(l).VIS_FORMAT,'F%s');
						str=regexprep(struc.var(l).VIS_FORMAT,'E','','once');
						fmt=['%',str,'e','\n'];
					case 'I'
						%2 possibilities: Id and Id.d!
						%YOU CANNOT DISTINGUISH THEM BY length() alone: cfr I10 does not have length 2 and should be recognized as Id, not Id.d!
						%=> SO: recognize them by checking for '.'!!
						%OR: do not distinguish them!! => Ia(.b) => %a(.b)d!!
						%if length(struc.var(l).VIS_FORMAT)==2
						%	%get number of characters
						%	nrchar=sscanf(struc.var(l).VIS_FORMAT,'I%d');
						%	fmt=['%',num2str(nrchar),'d','\n']
						%else
						%	if length(struc.var(l).VIS_FORMAT)==4
								%get nr of characters and minimal number of digits
								%[nrchar,dig]=sscanf(struc.var(l).VIS_FORMAT,'I%d.%d');
								%fmt=['%',num2str(nrchar),'.',num2str(dig),'d'];
								%BETTER: like 'E' conversion

						str=regexprep(struc.var(l).VIS_FORMAT,'I','','once');
						fmt=['%',str,'d','\n'];

						%	else
						%		%error: unrecognized VIS_FORMAT
						%		%display error and return
						%		disp (['Error: VIS_FORMAT for variable ',struc.var(l).VAR_NAME,' is not supported.']);
						%		fclose(mdatfid);
						%		fclose(datfid);
						%		return;
						%	end
						%end
					otherwise
						%display error and return
						disp (['Error: VIS_FORMAT for variable ',struc.var(l).VAR_NAME,' is not supported.']);
						%fclose(mdatfid);
						%fclose(datfid);
						%return;
						continue;
				end
			else
				%VIS_FORMAT is also invalid
				if isfield(struc.var(l),'VAR_DATA_TYPE')==1 & isempty(struc.var(l).VAR_DATA_TYPE)==0 & ischar(struc.var(l).VAR_DATA_TYPE)==1
					%use VAR_DATA_TYPE to calculate default
					%OTHER DEFAULTS MAY BE CHOSEN
					switch struc.var(l).VAR_DATA_TYPE
						case 'DOUBLE'
							%use C/Matlab's default format for floats
							fmt='%f\n';
						case 'REAL'
							fmt='%f\n';
						case 'STRING'
							fmt='%s\n';
						case 'LONG'
							fmt='%d\n';
						case 'INTEGER'
							fmt='%d\n';
						otherwise
							disp(['Error: variable ',struc.var(l).VAR_NAME,' should have a valid FORMAT, VIS_FORMAT or VAR_DATA_TYPE specified.']);
							continue;	
					end
				else
					%DATA TYPE is also invalid => ERROR
					disp(['Error: variable ',struc.var(l).VAR_NAME,' should have a valid FORMAT, VIS_FORMAT or VAR_DATA_TYPE specified.']);
					%proceed with next variable
					continue;
				end
			end
		end		

		%DEBUG
		%fmt
		
		if isfield(struc.var(l),'VAR_DESCRIPTION')==1 & isempty(struc.var(l).VAR_DESCRIPTION)==0 & ischar(struc.var(l).VAR_DESCRIPTION)==1
			fprintf(mdatfid,'VAR_DESCRIPTION=%s\n',struc.var(l).VAR_DESCRIPTION);
		else
			disp(['Warning: invalid VAR_DESCRIPTION for variable ',struc.var(l).VAR_NAME]);
		end
		%OPTIONAL VAR_NOTES
		if isfield(struc.var(l),'VAR_NOTES')==1 & isempty(struc.var(l).VAR_NOTES)==0 & ischar(struc.var(l).VAR_NOTES)==1
			fprintf(mdatfid,'VAR_NOTES=%s\n',struc.var(l).VAR_NOTES);
		else
			%disp(['Warning: invalid VAR_NOTES for variable ',struc.var(l).VAR_NAME]);
			fprintf(mdatfid,'VAR_NOTES=\n');
		end
		if isfield(struc.var(l),'VAR_DATA_TYPE')==1 & isempty(struc.var(l).VAR_DATA_TYPE)==0 & ischar(struc.var(l).VAR_DATA_TYPE)==1
			fprintf(mdatfid,'VAR_DATA_TYPE=%s\n',struc.var(l).VAR_DATA_TYPE); %SHOULD BE CALCULATED!!
		else
			disp(['Warning: invalid VAR_DATA_TYPE for variable ',struc.var(l).VAR_NAME]);
		end
		%NO ischar() test: VAR_DIMENSION CAN BE NUMERIC!
		if isfield(struc.var(l),'VAR_DIMENSION')==1 & isempty(struc.var(l).VAR_DIMENSION)==0
			if isnumeric(struc.var(l).VAR_DIMENSION)==1
				%auto-convert using %1.1d format (1 digit integer)
				struc.var(l).VAR_DIMENSION=sprintf('%1.1d',struc.var(l).VAR_DIMENSION);
			end
			%test if string value is between '1' and '8'?
			%(this is not tested by ASC2HDF)
			%we use >= and <= to test the ASCII value of the character(s) stored in VAR_DIMENSTION
			
			try
				numb2=str2num(struc.var(l).VAR_DIMENSION);
			catch
				disp(['Warning: VAR_DIMENSION for variable ',struc.var(l).VAR_NAME,' contains invalid characters.']);
				%this will force the next test to fail also => no fprintf is done! 
				numb2=0;
			end
			if length(struc.var(l).VAR_DIMENSION)==1 & numb2 >= 1 & numb2 <= 8
				fprintf(mdatfid,'VAR_DIMENSION=%s\n',struc.var(l).VAR_DIMENSION);
			else
				disp(['Warning: VAR_DIMENSION for variable ',struc.var(l).VAR_NAME,' must be between 1 and 8.']);
			end	
			
		else
			disp(['Warning: invalid VAR_DIMENSION for variable ',struc.var(l).VAR_NAME]);
		end
		if isfield(struc.var(l),'VAR_SIZE')==1 & isempty(struc.var(l).VAR_SIZE)==0 & ischar(struc.var(l).VAR_SIZE)==1
			fprintf(mdatfid,'VAR_SIZE=%s\n',struc.var(l).VAR_SIZE);
		else
			disp(['Warning: invalid VAR_SIZE for variable ',struc.var(l).VAR_NAME]);
		end
		if isfield(struc.var(l),'VAR_DEPEND')==1 & isempty(struc.var(l).VAR_DEPEND)==0 & ischar(struc.var(l).VAR_DEPEND)==1
			if(strcmpi(struc.var(l).VAR_DEPEND,'INDEPENDENT')==1 & str2num(struc.var(l).VAR_SIZE)==1)
                fprintf(mdatfid,'VAR_DEPEND=CONSTANT\n');
            else
                fprintf(mdatfid,'VAR_DEPEND=%s\n',struc.var(l).VAR_DEPEND);
            end
		else
			disp(['Warning: invalid VAR_DEPEND for variable ',struc.var(l).VAR_NAME]);
		end
		if isfield(struc.var(l),'VAR_UNITS')==1 & isempty(struc.var(l).VAR_UNITS)==0 & ischar(struc.var(l).VAR_UNITS)==1
			fprintf(mdatfid,'VAR_UNITS=%s\n',struc.var(l).VAR_UNITS);
		else
			disp(['Warning: invalid VAR_UNITS for variable ',struc.var(l).VAR_NAME]);
		end
		if isfield(struc.var(l),'VAR_SI_CONVERSION')==1 & isempty(struc.var(l).VAR_SI_CONVERSION)==0 & ischar(struc.var(l).VAR_SI_CONVERSION)==1
			fprintf(mdatfid,'VAR_SI_CONVERSION=%s\n',struc.var(l).VAR_SI_CONVERSION);
		else
			disp(['Warning: invalid VAR_SI_CONVERSION for variable ',struc.var(l).VAR_NAME]);
		end
		%VALID_MIN can be numeric
		if isfield(struc.var(l),'VAR_VALID_MIN')==1 & isempty(struc.var(l).VAR_VALID_MIN)==0
			if isnumeric(struc.var(l).VAR_VALID_MIN)==1
				%VALID_MIN is a number (float,int,...)
				%=> use same format as for "VALUES"
				formatstr=['VAR_VALID_MIN=',fmt];
				fprintf(mdatfid,formatstr,struc.var(l).VAR_VALID_MIN);
			else
				fprintf(mdatfid,'VAR_VALID_MIN=%s\n',struc.var(l).VAR_VALID_MIN);
			end
		else
			disp(['Warning: invalid VAR_VALID_MIN for variable ',struc.var(l).VAR_NAME]);
		end
		%VALID_MAX can be numeric
		if isfield(struc.var(l),'VAR_VALID_MAX')==1 & isempty(struc.var(l).VAR_VALID_MAX)==0
			if isnumeric(struc.var(l).VAR_VALID_MAX)==1
				%VALID_MAX is a number (float,int,...)
				%=> use same format as for "VALUES"
				formatstr=['VAR_VALID_MAX=',fmt];
				fprintf(mdatfid,formatstr,struc.var(l).VAR_VALID_MAX);
			else
				fprintf(mdatfid,'VAR_VALID_MAX=%s\n',struc.var(l).VAR_VALID_MAX);
			end
		else
			disp(['Warning: invalid VAR_VALID_MAX for variable ',struc.var(l).VAR_NAME]);
		end
		if isfield(struc.var(l),'VAR_MONOTONE')==1 & isempty(struc.var(l).VAR_MONOTONE)==0 & ischar(struc.var(l).VAR_MONOTONE)==1
			fprintf(mdatfid,'VAR_MONOTONE=%s\n',struc.var(l).VAR_MONOTONE);
		else
			disp(['Warning: invalid VAR_MONOTONE for variable ',struc.var(l).VAR_NAME]);
		end
		if isfield(struc.var(l),'VAR_AVG_TYPE')==1 & isempty(struc.var(l).VAR_AVG_TYPE)==0 & ischar(struc.var(l).VAR_AVG_TYPE)==1
			fprintf(mdatfid,'VAR_AVG_TYPE=%s\n',struc.var(l).VAR_AVG_TYPE);
		else
			disp(['Warning: invalid VAR_AVG_TYPE for variable ',struc.var(l).VAR_NAME]);
		end
		if isfield(struc.var(l),'VAR_FILL_VALUE')==1 & isempty(struc.var(l).VAR_FILL_VALUE)==0 & ischar(struc.var(l).VAR_FILL_VALUE)==1
			fprintf(mdatfid,'VAR_FILL_VALUE=%s\n',struc.var(l).VAR_FILL_VALUE);
		else
			disp(['Warning: invalid VAR_FILL_VALUE for variable ',struc.var(l).VAR_NAME]);
		end

		fprintf(mdatfid,'!\n');

		%VIS_ attributes
		if isfield(struc.var(l),'VIS_LABEL')==1 & isempty(struc.var(l).VIS_LABEL)==0 & ischar(struc.var(l).VIS_LABEL)==1
			fprintf(mdatfid,'VIS_LABEL=%s\n',struc.var(l).VIS_LABEL);
		else
			disp(['Warning: invalid VIS_LABEL for variable ',struc.var(l).VAR_NAME]);
		end
		if isfield(struc.var(l),'VIS_FORMAT')==1 & isempty(struc.var(l).VIS_FORMAT)==0 & ischar(struc.var(l).VIS_FORMAT)==1
			fprintf(mdatfid,'VIS_FORMAT=%s\n',struc.var(l).VIS_FORMAT);
		else
			disp(['Warning: invalid VIS_FORMAT for variable ',struc.var(l).VAR_NAME]);
		end
		if isfield(struc.var(l),'VIS_PLOT_TYPE')==1 & isempty(struc.var(l).VIS_PLOT_TYPE)==0 & ischar(struc.var(l).VIS_PLOT_TYPE)==1
			fprintf(mdatfid,'VIS_PLOT_TYPE=%s\n',struc.var(l).VIS_PLOT_TYPE);
		else
			disp(['Warning: invalid VIS_PLOT_TYPE for variable ',struc.var(l).VAR_NAME]);
		end
		if isfield(struc.var(l),'VIS_SCALE_TYPE')==1 & isempty(struc.var(l).VIS_SCALE_TYPE)==0 & ischar(struc.var(l).VIS_SCALE_TYPE)==1
			fprintf(mdatfid,'VIS_SCALE_TYPE=%s\n',struc.var(l).VIS_SCALE_TYPE);
		else
			disp(['Warning: invalid VIS_SCALE_TYPE for variable ',struc.var(l).VAR_NAME]);
		end
		%SCALE_MIN can be numeric
		if isfield(struc.var(l),'VIS_SCALE_MIN')==1 & isempty(struc.var(l).VIS_SCALE_MIN)==0
			if isnumeric(struc.var(l).VIS_SCALE_MIN)==1
				%SCALE_MIN is a number (float,int,...)
				%=> use same format as for "VALUES"
				formatstr=['VIS_SCALE_MIN=',fmt];
				fprintf(mdatfid,formatstr,struc.var(l).VIS_SCALE_MIN);
			else
				fprintf(mdatfid,'VIS_SCALE_MIN=%s\n',struc.var(l).VIS_SCALE_MIN);
			end
		else
			disp(['Warning: invalid VIS_SCALE_MIN for variable ',struc.var(l).VAR_NAME]);
		end
		%SCALE_MAX can be numeric
		if isfield(struc.var(l),'VIS_SCALE_MAX')==1 & isempty(struc.var(l).VIS_SCALE_MAX)==0
			if isnumeric(struc.var(l).VIS_SCALE_MAX)==1
				%SCALE_MAX is a number (float,int,...)
				%=> use same format as for "VALUES"
				formatstr=['VIS_SCALE_MAX=',fmt];
				fprintf(mdatfid,formatstr,struc.var(l).VIS_SCALE_MAX);
			else
				fprintf(mdatfid,'VIS_SCALE_MAX=%s\n',struc.var(l).VIS_SCALE_MAX);
			end
		else
			disp(['Warning: invalid VIS_SCALE_MAX for variable ',struc.var(l).VAR_NAME]);
		end


		%write variable values to data output file
		%print "header" (variable's name)
		fprintf(datfid,'%s\n',struc.var(l).VAR_NAME);
		%print values (1 value per line)

		%print values to data output file
		[rows,cols]=size(struc.var(l).VALUES);
		if ischar(struc.var(l).VALUES)
			%special case: char array => length==string length, not number of rows and VALUES(m)== m-th char, not m-th row
			%ASSUMPTION: 1 row = 1 string value! (in case of multiple strings), no more than 2 dimensions
			if length(size(struc.var(l).VALUES)) == 2
				for m=1:rows
					fprintf(datfid,fmt,struc.var(l).VALUES(m,:));
				end
			else
				disp(['Warning: Character array for variable must contain 2 dimensions (1 row = 1 string)']);
			end
		else
			%for m=1:length(struc.var(l).VALUES)
			%	if iscell(struc.var(l).VALUES)
			%		fprintf(datfid,fmt,struc.var(l).VALUES{m});
			%	else
			%		fprintf(datfid,fmt,struc.var(l).VALUES(m));
			%	end
			%end
			%Use "vectorized" fprintf (instead of writing the loop yourself => you need to compensate for multiple dimensions,...
			%THIS AUTOMATICALLY COMPENSATES FOR MULTIPLE DIMENSIONS (eg 2D matrix of Doubles => (:) looks at it on a column per column basis
			if iscell(struc.var(l).VALUES)==1
				fprintf(datfid,fmt,struc.var(l).VALUES{:}); %{:} is necessary
			else
				fprintf(datfid,fmt,struc.var(l).VALUES(:)); %... .VALUES) is also possible (Doubles)
			end
		end
	end

	%additionally print an empty comment line at the end (to prevent asc2hdf problems - see FAQ in ASC2HDF manual)
	fprintf(mdatfid,'!\n');
	fprintf(datfid,'!\n');
	
	fclose(datfid);
	fclose(mdatfid);
catch
	%Catch and display any errors to make sure that files are closed! - NOTE: you can also "rethrow" the error
	disp(['Error: ',lasterr]);
	fclose(datfid);
	fclose(mdatfid);
end

