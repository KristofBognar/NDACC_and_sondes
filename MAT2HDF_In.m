function [struc]=MAT2HDF_In(infile,mode);

%-----------------------------------------------------------------
%DESCRIPTION
%-----------------------------------------------------------------
%
%General
%
%This function reads files containing a MAT2HDF configuration and
%stores the configuration information in a structure that can
%then be used in the MAT2HDF_Out function to create the files
%that are needed by ASC2HDF to make the HDF files. This function
%only reads in a predefined configuration file. The user can 
%alter the configuration to fit his/her application between the
%calling of this function (the processing of the "default" or
%"template" configuration) and the calling of the output 
%function MAT2HDF_Out.
%
%This function supports only ASCII files, either in the format
%defined by ASC2HDF (format for the metadata file, with the 
%addition of the "LITERAL=", "VALUES=" and "FORMAT=" statements)
%or in an XML format. Both formats are extensively described in
%the MAT2HDF Manual document.
%
%NOTE: unlike ASC2HDF, the whitespace (blanks, tabs,...) in the
%values (after the "=") are not deleted from each line before
%processing it. Leading spaces (in the beginning of each line)
%are ignored. Whitespace in the attribute name (before the "="
%or in the name="..." attribute of the tags) is ignored in 
%both text and XML input.
%
%Format of statements (briefly described)
%
%The statements in the ASC2HDF input format are case 
%insensitive, but the XML format is not. Comment lines are
%always ignored. The sequence of the text statements is random,
%with the exception that the VAR_NAME line must be the first
%line in each variable (like in the ASC2HDF defined format).
%All configuration lines for VAR_*, VIS_*, FORMAT and VALUES
%after the i-th VAR_NAME (and before the i+1-th) are regarded
%as configuration parameters of the i-th variable.
%Literal mode must also be set PREVIOUS to the VALUES line.
%Format may be specified anywere, but specifying it after a
%literally interpreted VALUES will overwrite the default
%'%s\n' format.
%Likewise for XML, the sequence of tags is unimportant, but
%the XML logic must be followed (<tag>...<endtag><tag2>...
%<endtag2>...). All tags must be within the <MAT2HDF> and
%</MAT2HDF> tags. All tags about VAR_*, VIS_*, VALUES and
%FORMAT between the i-th pair of <VAR></VAR> tags are regarded
%as the configuration parameters of the i-th variable. Format
%can be specified anywhere inside <VAR></VAR>, but specifying
%it after the VALUES tag may overwrite the '%s\n' format in
%case of a literal VALUES string.
%
%Note that this function does not check the presence nor the
%validity of the configuration (except for a few simple checks).
%If parts of the configuration are missing, they have to be
%added prior to calling the output function (if the configuration
%parameter is defined as "mandatory" by the Metadata Guidelines
%document from NILU). Parameters can be left undefined or empty
%only if the parameters are optional. The presence of variables
%is checked by ASC2HDF_Out and the validity of the parameters is
%checked extensively by ASC2HDF. This implies that all lines in
%the configuration or all tags (except the outer most "MAT2HDF"
%tag and the "VAR" tags per variable) are optional.
%
%Multiple lines that configure the same parameter will overwrite
%each other in such a way that only the last line will count.
%Example:
%LITERAL=1  => sets the literal mode to true
%statements... statements are interpreted with literal mode=true
%LITERAL=0  => false
%statements... statements are interpreted with literal mode=false
%LITERAL=1  => true again
%The result of these 3 lines will be that the literal mode is
%set to true (the last line overwrites all previous lines).
%
%Parameter data type
%
%All parameters are read and stored as strings, even numerical
%parameters like VAR_DIMENSION. This is done to prevent any
%loss in data precision like in the following example.
%The only exception is the data specified by a VALUES expres-
%sion (literal mode=false). Such an expression may result in
%a char array, a numerical or logical array or a cell array of 
%strings.
%Example:
%Let's say that MAT2HDF_In would read in a floating point
%number "12.3456789" and would convert it to a number. This
%would require a conversion to a Matlab Double. When
%MAT2HDF_Out detects the presence of this Double in the
%struct (=output of MAT2HDF_In = input to MAT2HDF_Out), it
%needs to print it in ASCII in the Metadata file that is
%needed for ASC2HDF. But in which format does it need to
%print it? Well, MAT2HDF_Out could try to "detect" the
%format, but this can be very hard (many possibilities).
%MAT2HDF_Out could also use some "default" format, let's say
%'%10.4f' for floating point numbers, but this may result
%in loss of significant digits. Printing "12.3456789" in the
%'%10.4f' format will result in "12.3457" (with a round off
%error!). ASC2HDF will read "12.3457" and convert it to a
%number, which is equal to "12.3457000000...", but this is
%not the value that we wanted! Using another default format
%might help, but it will without doubt be unsufficient in
%other situations.
%
%Please note that, for typically numerical parameters, the
%user may use numerical or string values (when adapting the
%structure between the call of MAT2HDF_In and MAT2HDF_Out).
%MAT2HDF_Out will detect the numerical value and use a
%predefined format (if there is one) or the same format as
%for VALUES to print it. See MAT2HDF_Out for more information.
%But please be aware that this might result in loss of 
%precision. The user is STRONGLY advised to use preformatted
%strings (he/she can select the appropriate format) instead 
%of numerical values.
%
%A side-effect of this is, that the parameters can contain
%ANY string, even if the string is absolutely nonsense. For
%example, you can specify VAR_DIMENSION to be "n", even while
%it should be a numerical value. (See also in the examples
%below).
%
%Adding values and Autosize/Autodimension:
%
%When a VALUES tag (XML) or a "VALUES=" line is present for a
%certain variable, then the VAR_SIZE and VAR_DIMENSION 
%parameters are filled in automatically. Note however that
%only char arrays, numerical arrays, logical arrays and cell 
%arrays of strings are accepted. Other data types will require
%the user to set his own configuration directly in the 
%output structure (VALUES, FORMAT, VAR_SIZE, 
%VAR_DIMENSION,...) of MAT2HDF_In.
%
%When literal mode is set to true (by using LITERAL=yes,
%LITERAL=1 when using plain text input or by using the
%LITERAL="yes" or LITERAL="1" attribute of the VALUES tag in
%XML), then the VALUES value is interpreted as a literal string,
%the FORMAT is set to '%s\n' (string format) and the VAR_DATA_TYPE
%is set to STRING. VAR_SIZE is set to "<string length>;1" and 
%VAR_DIMENSION is set to 2.
%
%If literal mode is false, then the VALUES value is interpreted
%as an expression, calculated in the function caller's workspace.
%This means that the expression can contain any variables/matrices
%that are known to Matlab on the moment (e.g. on the command
%prompt or in the function that is calling MAT2HDF_In) that 
%MAT2HDF_In is called. This overcomes the limitation that normal
%expressions inside a function can only use Matlab variables 
%that are defined within that function. VAR_SIZE and VAR_DIMENSION
%are calculated based on the size() function in Matlab.
%
%Please note that FORMAT, VAR_DATA_TYPE, VAR_SIZE,
%VAR_DIMENSION and any other parameter can still be overwritten 
%by the user by specifying the necessary configuration line/tag
%AFTER the "VALUES=" line or the VALUES tag. But this is usually
%not wanted (e.g. the automatically calculated VAR_SIZE and VAR_
%DIMENSION should be correct).
%
%NOTE: by default, literal mode is false. When a literal mode is
%set by the user, it applies to all following VALUES lines or tags,
%until the user changes the literal mode again.
%
%An example:
%Say that you don't want to calculate the VAR_SIZE and VAR_
%DIMENSION parameters, but instead you want to use the automa-
%tically calculated values. How would you do it? Let's say that
%the (numerical) values you want to store in the HDF file (under
%the variable "O3.COLUMN_VERTICAL.SOLAR" for instance) are stored
%in the Matlab (Double) array A (A contains the Vertical Column
%Density values for O3). This means that you set LITERAL to "no"
%and you specify A as the value in the VALUES= line or in the
%VALUES tag like so (TEXT INPUT):
%VAR_NAME=O3.COLUMN_VERTICAL.SOLAR
%...
%VAR_DIMENSION=m
%VAR_SIZE=n
%...
%LITERAL=no (or 0)
%VALUES=A
%
%Or in XML INPUT:
%<VAR>
%	<ATTR name="VAR_NAME">O3.COLUMN_VERTICAL.SOLAR</ATTR>
%	...
%	<ATTR name="VAR_DIMENSION">m</ATTR>
%	<ATTR name="VAR_SIZE">n</ATTR>
%	...
%	<VALUES LITERAL="no">A</VALUES>
%
%</VAR>
%
%Note that you can use any string (instead of "m" and "n") for
%VAR_DIMENSION and VAR_SIZE (both are interpreted as literal
%strings as discussed above).
%
%When MAT2HDF_In reaches the VALUES= line (or the VALUES tag),
%it will not only store the values from A in the structure, but
%it will also calculate VAR_SIZE and VAR_DIMENSION automatically,
%overwriting the "m" and "n" values that were already stored. You
%could also have omitted the VAR_SIZE and VAR_DIMENSION settings,
%because the processing of VALUES will fill them in anyway.
%
%No consistency checking between FORMAT, VIS_FORMAT and VALUES is
%done, so that maximum flexibility is provided. So, even if the
%VALUES contains a non-literal string (literal mode=0) and the
%format is specified as '%d\n', then the string will be printed
%out numerically (showing the ASCII values of the characters in
%the string).
%
%When adding DATETIME values, the START_DATE is NOT automatically
%adjusted. This is because DATETIME can be in 2 formats 
%(MJD-Double or ISO-String) and checking for these formats (when
%calculating the lowest date) is not so easy. Besides, ASC2HDF
% compensates and adjusts START_DATE automatically if it is not
% equal to the first DATETIME value.
% 2009: NO longer true that 2 formats are accepted for DATA_START_DATE: only
% ISO-string format is accepted.
% Same holds true for DATA_STOP_DATE that has been added in 2009, and for FILE_GENERATION_DATE.
%
%-----------------------------------------------------------------
%SYNTAX
%-----------------------------------------------------------------
%struc=output structure, usable as input structure to Output function
%[struc]=MAT2HDF_In(inputfile,mode);
%
%"struc" is the output memory structure containing the necessary
%configuation parameters. The structure can then be adapted by
%the user if necessary and used as input structure in MAT2HDF_Out.
%
%"inputfile" is the name (with path if necessary) of the ASCII
%input file. It can be in either ASC2HDF's format for the Meta-
%data file (with the VALUES, FORMAT and LITERAL extensions) or in
%XML format, as defined in the MAT2HDF Manual document.
%
%"mode" is the operational mode of the input function and
%and specifies if the input file needs to be read as plain text or
%as XML. Possible values are "-text", "text", "-xml", "xml" or
%their respective uppercase equivalents.
%
%-----------------------------------------------------------------
%MORE INFORMATION
%-----------------------------------------------------------------
%
%For more information, please consult the Manual document,
%available on the internal Envisat server website, in the 
%Documents site.

%-----------------------------------------------------------------
%INPUT PARAMETERS
%-----------------------------------------------------------------

if nargin ~=2
	disp('Inputfile and operation mode must be given as parameters.');
	return;
end

if exist(infile,'file')==0
	disp('Inputfile must exist.');
	return;
end

%supported modes: 'text', '-text', 'xml', '-xml', 'xls', '-xls', 'excel', '-excel'
%EXCEL: only old excel versions (95, possibly 98) are supported => inconvenient
% (new Excel files need to be saved under old versions,...)
% new Excel versions require ActiveX server (Windows), installing it just for
% this application is too much work
%using excel (was only used to have a nice overview, instead of a plain ascii
% file) causes conversion problems...
% DECISION: Excel format is NOT supported, INSTEAD: Excel templates are (only
% once) converted manually to XML/ASCII input format (for practical use)

if mode(1)=='-'
	%eliminate starting '-'
	mode=regexprep(mode,'-','','once');
end

%supmodes={'text','xml','xls','excel'};
supmodes={'text','xml'};

found=0;
for k=1:length(supmodes)
	if strcmpi(mode,supmodes{k})==1
		found=1;
		%store mode number
		opmode=k;
	end
end

if found==0
	%disp('Mode must be ''text'', ''-text'', ''xml'', ''-xml'', ''xls'', ''-xls'', ''excel'' or ''-excel''.');
	disp('Mode must be ''text'', ''-text'', ''xml'' or ''-xml''.');
	return;
end

%opmode contains 1 for text files, 2 for XML files %NOT SUPPORTED:%and 3 or 4 for Excel files

%-----------------------------------------------------------------
%MAIN CODE
%-----------------------------------------------------------------

if opmode==1

	%INIT
	%varcount starts at 0 (it is updated to 1 on the first "VAR_NAME" line (so for the first variable)
	%varcount counts all "variables" read
	varcount=0;
	
	%interpret next VALUES as literal string or as expression in eval
	literal=0;	 %DEFAULT: no literal interpretation

	%TEXT FILE (ASC2HDF template format)
	%just parse all lines, storing all values as strings
	%(no numerical data)
	
	%textread with delimiter \n to store 1 line per cell element (default: any whitespace = delimiter => all words are stored in separate cells)
	lines=textread(infile,'%s','delimiter','\n');
	
	%if there is no "VALUES=" line or "FORMAT=" line => parts of the code (the corresponding if-blocks) are just not executed)
	length(lines);
	%iterate over all lines
	for l=1:length(lines)
		%DEBUG
% 		l
		%lines{l}
		
		%first trim off the leading spaces - IS DONE BY USING %s FORMAT IN TEXTREAD!?
				
		%skip comment lines
		if strcmp(lines{l}(1),'!')==1 | strcmp(lines{l}(1),'#')==1
			continue;
		end
		
		%skip empty lines - lines containing only '\n' cannot occur (\n is delimiter of textread => \n's are not stored in cell array lines{})
		%length 0 is impossible normally (can't occur?)
		if length(lines{l})==0
			continue;
		end

		found=0;
		if strcmpi(lines{l}(1:3),'PI_')==1 | strcmpi(lines{l}(1:3),'DO_')==1 | strcmpi(lines{l}(1:3),'DS_')==1
			found=1;
			
			%PI_*, DO_* or DS_* attributes are all "originator attributes" => store them in struc.orig_attr.<attr_name>
			%[attr_name,str]=sscanf('%s=%s',lines{l});
			%string tokenise
			[attr_name,rem]=strtok(lines{l},'=');
			%delete the '='
			val=regexprep(rem,'=','','once');
			
			%remove spaces from attr_name
			attr_name=regexprep(attr_name,'[ 	]*','');
			
			%DEBUG
			%attr_name
			%str
			
			%BETTER SOLUTION: cfr PI_NAME => is stored as struc.orig_attr.PI_NAME
			%SO: instead of interpreting the line => just prepend "struc.orig_attr" to it
			%NO: part after '=' must be placed in single quotes for interpretation as string!?
			%';' at the end of evalline prevents eval from displaying the results
			evalline=['struc.orig_attr.',attr_name,'=''',val,'''',';'];
			%"evalline" should be put in an eval() statement!
		end
		if strcmpi(lines{l}(1:5),'DATA_')==1
			found=1;
			
			%DATA_* variables => struc.dset_attr.DATA_*
			%string tokenise
			[attr_name,rem]=strtok(lines{l},'=');
			%delete the '='
			val=regexprep(rem,'=','','once');
			
			%remove spaces from attr_name
			attr_name=regexprep(attr_name,'[ 	]*','');
			
			%evalline=['struc.dset_attr.',lines{l}]
			evalline=['struc.dset_attr.',attr_name,'=''',val,'''',';'];
		end
		if strcmpi(lines{l}(1:5),'FILE_')==1
			found=1;
			
			%string tokenise
			[attr_name,rem]=strtok(lines{l},'=');
			%delete the '='
			val=regexprep(rem,'=','','once');
			
			%evalline=['struc.dset_attr.',lines{l}]
			evalline=['struc.file_attr.',attr_name,'=''',val,'''',';'];

		end
		if strcmpi(lines{l}(1:4),'VAR_')==1
			found=1;
			
			%when a VAR_NAME is encountered => new variable! (see ASC2HDF manual: ASC2HDF also uses "VAR_NAME" line to detect a new variable)
			if strcmpi(lines{l}(1:8),'VAR_NAME')==1
				varcount=varcount+1;
			end

			%string tokenise
			[attr_name,rem]=strtok(lines{l},'=');

			%delete the '='
			val=regexprep(rem,'=','','once');
			
			%remove spaces from attr_name
			attr_name=regexprep(attr_name,'[ 	]*','');
			
			%evalline=['struc.var(',num2str(varcount),').',lines{l}]
			if varcount > 0
				evalline=['struc.var(',num2str(varcount),').',attr_name,'=''',val,'''',';'];
			else
				%if no "VAR_NAME" lines have passed => varcount==0 => cannot be eval()'ed (index 0 does not exist in Matlab)=> Warning
				disp(['Warning: VAR_NAME must be first line in each block that describes a Variable. Line ',num2str(l),' appeared before VAR_NAME line.']);
			end
		end
		if strcmpi(lines{l}(1:4),'VIS_')==1
			found=1;
						
			%VIS_*
			%string tokenise
			[attr_name,rem]=strtok(lines{l},'=');
			%delete the '='
			val=regexprep(rem,'=','','once');
			
			%remove spaces from attr_name
			attr_name=regexprep(attr_name,'[ 	]*','');
			
			%evalline=['struc.var(',num2str(varcount),').',lines{l}]
			evalline=['struc.var(',num2str(varcount),').',attr_name,'=''',val,'''',';'];

		end
		%SPECIAL TREATMENT OF "LITERAL", "VALUES" and "FORMAT"?
		%NO: VAR_FORMAT is just a normal format string => can be handled like other VAR_* variables
		%NO!! VAR_FORMAT must be stored as "FORMAT"
	
		%LITERAL lines are processed before VALUES lines (because they can and should appear before them)
	
		if strcmpi(lines{l}(1:7),'LITERAL')==1 
			found=1;
			%string tokenise
			[attr_name,rem]=strtok(lines{l},'=');
			%delete the '='
			val=regexprep(rem,'=','','once');
			
			%remove spaces from attr_name
			attr_name=regexprep(attr_name,'[ 	]*','');
			
			%values yes/no are also accepted
			if strcmp(val,'1')==1 | strcmp(val,'0')==1 |strcmpi(val,'yes')==1 | strcmpi(val,'no')==1
				%translate "yes" to '1' and "no" to '0'
				if strcmpi(val,'yes')==1
					val='1';
				end
				if strcmpi(val,'no')==1
				        val='0';
				end
				
				%DEBUG
				%val
				
				evalline=['literal=',val,';'];
			else
				disp(['Warning: illegal value in LITERAL line at line ',num2str(l),': only values 1, 0, yes and no are allowed.']);
			end
		end
		if strcmpi(lines{l}(1:6),'VALUES')==1
			found=1;
			if varcount>0
				%string tokenise
				[attr_name,rem]=strtok(lines{l},'=');
				%delete the '='
				val=regexprep(rem,'=','','once');
				
				%remove spaces from attr_name
				attr_name=regexprep(attr_name,'[ 	]*','');
				
				if literal==1
					%literal string => format must be "%s\n" for correct printing?!
					evalline=['struc.var(',num2str(varcount),').VALUES=''',val,''';'];
					%CAN BE OVERWRITTEN BY ADDITIONAL FORMAT= line AFTER THIS VALUES= line!
					struc.var(varcount).FORMAT='%s\n';
					struc.var(varcount).VAR_DATA_TYPE='STRING';
				else
					%evaluate the expression in the caller's workspace
					value=evalin('caller',val);
					%value must be inside the '' 
					%(so that it is part of the evalline-string and is not treated as a string itself nor as a literal ('' '') in the string)
					evalline=['struc.var(',num2str(varcount),').VALUES=value;'];
				end
			else
				%if no "VAR_NAME" lines have passed => varcount==0 => cannot be eval()'ed (index 0 does not exist in Matlab)=> Warning
				disp(['Warning: VAR_NAME must be first line in each block that describes a Variable. Line ',num2str(l),' appeared before VAR_NAME line.']);
			end
		end

		if strcmpi(lines{l}(1:6),'FORMAT')==1
			found=1;
			if varcount>0
				%if literal==0
					%string tokenise
					[attr_name,rem]=strtok(lines{l},'=');
					%delete the '='
					val=regexprep(rem,'=','','once');
					
					%remove spaces from attr_name
					attr_name=regexprep(attr_name,'[ 	]*','');
					
					evalline=['struc.var(',num2str(varcount),').FORMAT=''',val,''';'];
				%else
				%	%FIXED FORMAT: %s\n in case LITERAL=1 (literal string): NOT USED, USER SHOULD BE ABLE TO SPECIFY HIS OWN FORMAT (eg user defined
				%	%string format
				%	evalline=['struc.var(',num2str(varcount),').FORMAT=%s\n'];
				%end
			else
				%if no "VAR_NAME" lines have passed => varcount==0 => cannot be eval()'ed (index 0 does not exist in Matlab)=> Warning
				disp(['Warning: VAR_NAME must be first line in each block that describes a Variable. Line ',num2str(l),' appeared before VAR_NAME line.']);
			end	
		end
		
		if found==0
			disp(['Warning: unrecognized line at line ',num2str(l),'.']);
			continue;
		end
		
		try
			eval(evalline);
		catch
			disp(['Error when doing eval. Possibly incorrect input line at line ',num2str(l),': ',lasterr]);
		end
		
		%AUTOSIZE/AUTODIMENSION: eval() must have executed normally!
		%only calculate VAR_SIZE/VAR_DIMENSION if processed line is a "VALUES" line
		if strcmpi(lines{l}(1:6),'VALUES')==1
			%string tokenise - NOT NECESSARY (is done above)
			[attr_name,rem]=strtok(lines{l},'=');
			%delete the '='
			str=regexprep(rem,'=','','once');
			
			%remove spaces from attr_name
			attr_name=regexprep(attr_name,'[ 	]*','');
			
			if literal==1
				%AUTOSIZE/AUTODIMENSION: adjust VAR_SIZE and VAR_DIMENSION automatically (original VAR_SIZE and VAR_DIMENSION values are overwritten!)
				%LITERAL STRING => just 1 string => VAR_DIMENSION == 1 and VAR_SIZE only contains string length
				%CAN BE OVERWRITTEN BY ADDITIONAL <ATTR name="VAR_SIZE"> TAGS OR BY USER (inbetween input and output function)
				struc.var(varcount).VAR_SIZE=sprintf('%d;1',length(str));
				struc.var(varcount).VAR_DIMENSION=sprintf('%d',2);
			else
				%AUTOSIZE/AUTODIMENSION:
				%we need to calculate VAR_SIZE and VAR_DIMENSION, but this depends on the Matlab data type (eg string = special case,...)
				A=struc.var(varcount).VALUES;
      

				dimsizes=size(A);
				%dims=ndims(A);
				dims=length(dimsizes);

                                
				
				if iscell(struc.var(varcount).VALUES)==1

					%conversion to char array only succeeds if the cell array only contains character strings (cell array of strings)
					try
						A=char(struc.var(varcount).VALUES);
						%VALUES still remains cell array, only A is converted! => so Output function will see a iscell()==1!
						%if character conversion succeeds, following if-test is also executed!
					catch
						disp(['Warning: cell array of VALUES for variable ',num2str(l),' may only contain strings.']);
						struc.var(varcount).VALUES=[];
						continue;
					end
				end
				%if VALUES is a character array (or cell array of strings, already converted to char array)
				if isa(A,'char')==1

					%char array => first VAR_SIZE element must be the same as number of columns (=max string length)
					%dimsizes(2) is the number of columns (2nd dimension of a char array)
					%so, to arrive at VAR_SIZE, just switch dimsizes(1) and (2) and print all dimsizes in 1 string
					str=sprintf('%d;%d',dimsizes(2),dimsizes(1));
					%append other dimsizes (if necessary)
					if dims>2
						%dimensions 3 and up (first 2 dimensions are already covered)
						%for d=3:dims
						%	if d==dims
						%		str=[str,sprintf('%d',dimsizes(d))];
						%	else
						%		str=[str,sprintf('%d;'dimsizes(d))];
						%	end
						%end
				
						%vectorized
						%first sprintf prints all remaining dimensions (except last one), with a ";" after the number, the second sprintf
						%adds the last dimension (no following ";"!!)
						str=[str,';',sprintf('%d;',dimsizes(3:dims-1)),sprintf('%d',dimsizes(dims))];
					end
					struc.var(varcount).VAR_SIZE=str;
					struc.var(varcount).VAR_DIMENSION=sprintf('%d',dims);
                    if dims==2 %only 2D arrays can be row/column vectors (if number of rows or columns is "1")
						%special case: array contains only 1 value => both if-tests are performed, but both will result in DIMENSION=1 and SIZE=1
						if dimsizes(1)==1
							%1 row, multiple columns (in a 2D array) == row vector
							struc.var(varcount).VAR_SIZE=sprintf('%d',dimsizes(2));
							struc.var(varcount).VAR_DIMENSION='1';
                        elseif dimsizes(2)==1
                            struc.var(varcount).VAR_SIZE=sprintf('%d',dimsizes(1));
							struc.var(varcount).VAR_DIMENSION='1';
                        end                       
                    end
                    
                end
                
				if isnumeric(A)==1 | islogical(A)==1
					%normal, numeric array
					struc.var(varcount).VAR_SIZE=[sprintf('%d;',dimsizes(1:dims-1)),sprintf('%d',dimsizes(dims))];
					struc.var(varcount).VAR_DIMENSION=sprintf('%d',dims);
					%compensate for row/column vectors: do not use DIMENSION=2, use 1 instead and only specify the number of rows/cols as SIZE
					if dims==2 %only 2D arrays can be row/column vectors (if number of rows or columns is "1")
						%special case: array contains only 1 value => both if-tests are performed, but both will result in DIMENSION=1 and SIZE=1
						if dimsizes(1)==1
							%1 row, multiple columns (in a 2D array) == row vector
							struc.var(varcount).VAR_SIZE=sprintf('%d',dimsizes(2));
							struc.var(varcount).VAR_DIMENSION='1';
                            if isfield(struc.var(varcount),'VAR_DEPEND')==1 & isempty(struc.var(varcount).VAR_DEPEND)==0 & ischar(struc.var(varcount).VAR_DEPEND)==1
                                if(~isempty(strfind(struc.var(varcount).VAR_DEPEND,';')))
                                    struc.var(varcount).VAR_SIZE=sprintf('1;%d',dimsizes(2));
                                    struc.var(varcount).VAR_DIMENSION='2';
                                end
                            end
                        end
						if dimsizes(2)==1
							%multiple rows, 1 column (in a 2D array) == column vector
							struc.var(varcount).VAR_SIZE=sprintf('%d',dimsizes(1));
							struc.var(varcount).VAR_DIMENSION='1';
                            if isfield(struc.var(varcount),'VAR_DEPEND')==1 & isempty(struc.var(varcount).VAR_DEPEND)==0 & ischar(struc.var(varcount).VAR_DEPEND)==1
                                if(~isempty(strfind(struc.var(varcount).VAR_DEPEND,';')))
                                    struc.var(varcount).VAR_SIZE=sprintf('%d;1',dimsizes(1));
                                    struc.var(varcount).VAR_DIMENSION='2';
                                end
                            end
                        end
                        
					end
				end
			end
		end
	end
end
if opmode==2
	%XML file
	docNode=xmlread(infile);
	%getFirstChild or getChildNodes => item(0) is the same (document should only contain 1 child, the outer most tags "<MAT2HDF>")
	
	%XML file should contain only 1 outer tag, with tag name=='MAT2HDF'
	A=docNode.getElementsByTagName('MAT2HDF'); 
	% A now contains a "nodeList" of all tags found
	
	%if A's length ==0 => Error (no MAT2HDF tags)
	if A.getLength==0
		disp(['Error: No MAT2HDF tag found in the XML file ',inputfile,'. Nothing to process.']);
		return;
	end
	
	%if A's length is too large (more than 1 MAT2HDF node => Warning + only use the first)
	if A.getLength > 1
		disp('Warning: multiple MAT2HDF tags detected. Multiple configurations in one XML file is not allowed. Using first MAT2HDF tag.');
		%outTag=A.item(0) still selects only the first MAT2HDF tag (here, there are also other item(1,...) in the nodelist A, but they are ignored!)
	end	
	outTag=A.item(0);
	
	%outTag=docNode.getFirstChild; %by using this, you have to check manually to see if the first child is really an element node (tag) and that the tag is a "MAT2HDF"
	%tag
	
	%outTag has nodename "MAT2HDF" and value null (element node)
	%the next line gets all nodes (element nodes, attribute nodes,... all mixed) : you have to test nodeType like below (in comment) to see what kind of node you
	%are currently looking at (when iterating over all child nodes)
	%nodes=outTag.getChildNodes;
	%iterate over all nodes
	%for l=0:nodes.getLength-1
		%test NodeType: 
		%ELEMENT_NODE       = 1; - normal tags
  		%ATTRIBUTE_NODE     = 2; - attributes of tags
  		%TEXT_NODE          = 3; - text values of tags
  		%CDATA_SECTION_NODE = 4; - cdata -not used?
  		%ENTITY_REFERENCE_NODE = 5; - not used?
  		%ENTITY_NODE        = 6; - not used?
  		%PROCESSING_INSTRUCTION_NODE = 7; - not used?
  		%COMMENT_NODE       = 8; - not used?
  		%DOCUMENT_NODE      = 9; - not used?
  		%DOCUMENT_TYPE_NODE = 10; - not used?
  		%DOCUMENT_FRAGMENT_NODE = 11; - not used?
  		%NOTATION_NODE      = 12; - not used?
		%switch nodes.item(l).getNodeType
		%	case 1
		%		%tags (element nodes)
		%	case 2
		%		%attributes (attribute nodes)
		%	
		%	case 3
		%		%text contained inside the tags (text nodes)
		%	
		%	otherwise
		%end
	%end
	
	%BETTER WAY: get all element nodes (tags) you need, per tagname
	%ORIG tags
	tags=outTag.getElementsByTagName('ORIG');
	%tags now contains a nodeList of all ORIG element nodes (tags)
	%ALL ORIG ATTRIBUTES (PI_*, DO_* and DS_* are MANDATORY! => so length of tags should be 12 (4x PI, 4x DO, 4x DS) )- does not need to be tested here!
	%test if you have 4 PI's, 4 DO's, and 4 DS's - no: output function detects if some values are missing - does not need to be done here
	%(cfr text input: also no check if all lines are present!)
	%if tags.getLength ~=12
	%	disp('Error: there must be 12 ORIG tags, 1 for each originator attribute as specified in the Metadata Guidelines document.');
	%	return;
	%end
	
	%DEBUG
	%tags.getLength
	
	%iterate over all nodelist items (all tags found)
	for l=0:tags.getLength-1
		tag=tags.item(l);
		%test if the tag has a name attribute - || is faster (short-circuit?)
		if tag.hasAttributes==0
			disp('Warning: all ORIG tags must have a name attribute. Invalid ORIG tag is skipped.');
			continue;
		end
		%XML IS CASE SENSITIVE!!
		if tag.hasAttribute('name')==1
			%get name attribute's node
			namenode=tag.getAttributeNode('name');
			%namenode's NodeName is 'name', namenode's NodeValue is the value of the name attribute (eg 'PI_NAME')
		else
			if tag.hasAttribute('NAME')==1
				%get name attribute's node
				namenode=tag.getAttributeNode('NAME');
				%namenode's NodeName is 'name', namenode's NodeValue is the value of the name attribute (eg 'PI_NAME')
			else
				disp('Warning: all ORIG tags must have a name or NAME attribute. Invalid ORIG tag is skipped.');
				continue;
			end
		end
		
		%the child text node contains the value we want to assign to the originator attribute (eg the PI's name)
		%you can reach this text node either through getChildNodes => iterate over children and test if NodeType==3 (text node), there should be only 1 child text
		%node
		%OR: you can just call the getTextContent method
		%char() conversion IS NECESSARY to convert Java.lang.String object (a Java String) to a Matlab Character array!
		%SEE SITE: Calling Java From Matlab => data returned from Matlab (Java char array is automatically converted, but Java String is not!)
		str=char(tag.getTextContent);
		attr=char(namenode.getNodeValue);
		
		%remove spaces from attribute name (attr)
		attr=regexprep(attr,'[ 	]*','');
		
		%DEBUG
		%java1 & 2 give 1 (isa also gives 1) and ischar give 0 (false) if you omit the char() conversion (conversion of a Java String object to a Matlab char)
		%THIS IS LOGICAL: a Java String is a Java Object => isjava will give "true" (1) ('opaque' is the same as "external -non-matlab- type"?)
		%with char(), the String is converted to a Matlab object => isjava is now false (it's no longer a Java String) and ischar is now true
		%ischar(attr)
		%ischar(str)
		%methodsview(class(namenode))
		%isa(attr,'opaque')
		%java1=isjava(attr)
		%java2=isjava(str)
		
		%eval: use "literal" value, do not interpret as expression (str is placed inside two single quotes)
		evalline=['struc.orig_attr.',attr,'=''',str,'''',';'];
		try
			eval(evalline);
		catch
			disp(['Warning: eval failed when processing an ORIG tag. Tag number: ',num2str(l+1),': ',lasterr]);
		end
	end
	
	%DSET tags
	tags=outTag.getElementsByTagName('DSET');
	%tags now contains a nodeList of all DSET element nodes (tags)
		
	%DEBUG
	%tags.getLength
	
	%iterate over all nodelist items (all tags found)
	for l=0:tags.getLength-1
		tag=tags.item(l);
		%test if the tag has a name attribute - || is faster (short-circuit?)
		if tag.hasAttributes==0
			disp('Warning: all DSET tags must have a name attribute. Invalid DSET tag is skipped.');
			continue;
		end
		%XML IS CASE SENSITIVE!!
		if tag.hasAttribute('name')==1
			%get name attribute's node
			namenode=tag.getAttributeNode('name');
			%namenode's NodeName is 'name', namenode's NodeValue is the value of the name attribute (eg 'PI_NAME')
		else
			if tag.hasAttribute('NAME')==1
				%get name attribute's node
				namenode=tag.getAttributeNode('NAME');
				%namenode's NodeName is 'name', namenode's NodeValue is the value of the name attribute (eg 'PI_NAME')
			else
				disp('Warning: all DSET tags must have a name or NAME attribute. Invalid DSET tag is skipped.');
				continue;
			end
		end
		
		%the child text node contains the value we want to assign to the originator attribute (eg the PI's name)
		%you can reach this text node either through getChildNodes => iterate over children and test if NodeType==3 (text node), there should be only 1 child text
		%node
		%OR: you can just call the getTextContent method
		%char() conversion IS NECESSARY to convert Java.lang.String object (a Java String) to a Matlab Character array!
		%SEE SITE: Calling Java From Matlab => data returned from Matlab (Java char array is automatically converted, but Java String is not!)
		str=char(tag.getTextContent);
		attr=char(namenode.getNodeValue);
		
		%remove spaces from attribute name (attr)
		attr=regexprep(attr,'[ 	]*','');
				
		%DEBUG
		%java1 & 2 give 1 (isa also gives 1) and ischar give 0 (false) if you omit the char() conversion (conversion of a Java String object to a Matlab char)
		%THIS IS LOGICAL: a Java String is a Java Object => isjava will give "true" (1) ('opaque' is the same as "external -non-matlab- type"?)
		%with char(), the String is converted to a Matlab object => isjava is now false (it's no longer a Java String) and ischar is now true
		%ischar(attr)
		%ischar(str)
		%methodsview(class(namenode))
		%isa(attr,'opaque')
		%java1=isjava(attr)
		%java2=isjava(str)
		
		%eval: use "literal" value, do not interpret as expression (str is placed inside two single quotes)
		evalline=['struc.dset_attr.',attr,'=''',str,'''',';'];
		try
			eval(evalline);
		catch
			disp(['Warning: eval failed when processing a DSET tag. Tag number: ',num2str(l+1),': ',lasterr]);
		end
	end
	
	%FILE tags
	tags=outTag.getElementsByTagName('FILE');
	%tags now contains a nodeList of all FILE element nodes (tags)
		
	%DEBUG
	%tags.getLength
	
	%iterate over all nodelist items (all tags found)
	for l=0:tags.getLength-1
		tag=tags.item(l);
		%test if the tag has a name attribute - || is faster (short-circuit?)
		if tag.hasAttributes==0
			disp('Warning: all FILE tags must have a name attribute. Invalid FILE tag is skipped.');
			continue;
		end
		%XML IS CASE SENSITIVE!!
		if tag.hasAttribute('name')==1
			%get name attribute's node
			namenode=tag.getAttributeNode('name');
			%namenode's NodeName is 'name', namenode's NodeValue is the value of the name attribute (eg 'PI_NAME')
		else
			if tag.hasAttribute('NAME')==1
				%get name attribute's node
				namenode=tag.getAttributeNode('NAME');
				%namenode's NodeName is 'name', namenode's NodeValue is the value of the name attribute (eg 'PI_NAME')
			else
				disp('Warning: all FILE tags must have a name or NAME attribute. Invalid FILE tag is skipped.');
				continue;
			end
		end
		
		%the child text node contains the value we want to assign to the originator attribute (eg the PI's name)
		%you can reach this text node either through getChildNodes => iterate over children and test if NodeType==3 (text node), there should be only 1 child text
		%node
		%OR: you can just call the getTextContent method
		%char() conversion IS NECESSARY to convert Java.lang.String object (a Java String) to a Matlab Character array!
		%SEE SITE: Calling Java From Matlab => data returned from Matlab (Java char array is automatically converted, but Java String is not!)
		str=char(tag.getTextContent);
		attr=char(namenode.getNodeValue);
		
		%remove spaces from attribute name (attr)
		attr=regexprep(attr,'[ 	]*','');
		
		%DEBUG
		%java1 & 2 give 1 (isa also gives 1) and ischar give 0 (false) if you omit the char() conversion (conversion of a Java String object to a Matlab char)
		%THIS IS LOGICAL: a Java String is a Java Object => isjava will give "true" (1) ('opaque' is the same as "external -non-matlab- type"?)
		%with char(), the String is converted to a Matlab object => isjava is now false (it's no longer a Java String) and ischar is now true
		%ischar(attr)
		%ischar(str)
		%methodsview(class(namenode))
		%isa(attr,'opaque')
		%java1=isjava(attr)
		%java2=isjava(str)
		
		%eval: use "literal" value, do not interpret as expression (str is placed inside two single quotes)
		evalline=['struc.file_attr.',attr,'=''',str,'''',';'];
		try
			eval(evalline);
		catch
			disp(['Warning: eval failed when processing a FILE tag. Tag number: ',num2str(l+1),': ',lasterr]);
		end
	end

	%VAR tags - 1 for each variable!
	vartags=outTag.getElementsByTagName('VAR');
	%vartags now contains a nodeList of all VAR element nodes (tags)
	
	%DEBUG
	%vartags.getLength
	
	%iterate over all nodelist items (all tags found)
	for l=0:vartags.getLength-1
		%the current variable's number (varcount) is l+1 (Matlab indexing must start with index 1, not 0!)
		varcount=l+1;
		vartag=vartags.item(l);
		%DEFAULT (same default as in text mode above)
		literal=0;
		
		%ATTR tags for the variable attributes - all processed as literal strings
		
		attrtags=vartag.getElementsByTagName('ATTR');

		%DEBUG
		%attrtags.getLength		
		
		%iterate over all nodelist items (all tags found)
		for k=0:attrtags.getLength-1
			attrtag=attrtags.item(k);
			%test if the tag has a name attribute - || is faster (short-circuit?)
			if attrtag.hasAttributes==0
				disp(['Warning: all ATTR tags must have a name or NAME attribute. ATTR tag number ',num2str(k+1),' of variable ',num2str(varcount),' is skipped.']);
				continue;
			end
			%XML IS CASE SENSITIVE!!
			if attrtag.hasAttribute('name')==1
				%get name attribute's node
				namenode=attrtag.getAttributeNode('name');
				%namenode's NodeName is 'name', namenode's NodeValue is the value of the name attribute (eg 'PI_NAME')
			else
				if attrtag.hasAttribute('NAME')==1
					%get name attribute's node
					namenode=attrtag.getAttributeNode('NAME');
					%namenode's NodeName is 'name', namenode's NodeValue is the value of the name attribute (eg 'PI_NAME')
				else
					disp(['Warning: all ATTR tags must have a name or NAME attribute. ATTR tag number ',num2str(k+1),' of variable ',num2str(varcount),' is skipped.']);
					continue;
				end
			end
		
			str=char(attrtag.getTextContent);
			attr=char(namenode.getNodeValue);

			%remove spaces from attribute name (attr)
			attr=regexprep(attr,'[ 	]*','');

			%eval: use "literal" value, do not interpret as expression (str is placed inside two single quotes)
			evalline=['struc.var(',num2str(varcount),').',attr,'=''',str,'''',';'];
			try
				eval(evalline);
			catch
				disp(['Warning: eval failed when processing an ATTR tag. Variable ',num2str(l+1),': ',lasterr]);
			end
		end
		
		%VALUES tag(s) - normally just 1 tag - use the last one if multiple VALUES tags occur (last value counts)
		valtags=vartag.getElementsByTagName('VALUES');

		%DEBUG
		%valtags.getLength		
				
		if valtags.getLength > 1
			disp(['Warning: multiple VALUES tags for variable ',num2str(varcount),' have been detected. Only last VALUES tag will be processed.']);
		end
		
		if valtags.getLength>0
			%no iteration over all VALUES-tags is needed - just take the last one
			%last tag: item(valtags.getLength-1)
			%for k=0:attrtags.getLength-1
			valtag=valtags.item(valtags.getLength-1);
			%test if the tag has a LITERAL attribute
			if attrtag.hasAttributes==0
				disp(['Warning: all VALUES tags must have a literal or LITERAL attribute. Variable ', num2str(varcount),' has empty VALUES.']);
				struc.var(varcount).VALUES=[];
				continue;
			end
			%XML IS CASE SENSITIVE!!
			if valtag.hasAttribute('literal')==1
				%get attribute's node
				litnode=valtag.getAttributeNode('literal');
				%litnode's NodeName is "literal"; litnode's NodeValue is "yes/no/0/1" (the value of the literal attribute)
			else
				if valtag.hasAttribute('LITERAL')==1
					%get attribute's node
					litnode=valtag.getAttributeNode('LITERAL');
				else
					disp(['Warning: all VALUES tags must have a literal or LITERAL attribute. Variable ', num2str(varcount),' has empty VALUES.']);
					continue;
				end
			end

			attr=char(litnode.getNodeValue);

			%remove spaces from attribute name (attr)
			attr=regexprep(attr,'[ 	]*','');

			%translate 'yes' to '1' and 'no' to '0'
			if strcmpi(attr,'yes')==1
				attr='1';
			end
			if strcmpi(attr,'no')==1
		        	attr='0';
			end
			%eval will interpret '1' as 1... (could also be done by str2num...)
			evalline=['literal=',attr,';'];

			try
				%this sets the literal-variable to 0 or 1 (depending on the literal attribute of the VALUES tag)
				eval(evalline);
			catch
				disp(['Warning: eval failed when processing a VALUES tag. Variable ',num2str(l+1),': ',lasterr]);
			end
			%end

			%take text value of VALUES tag and process it (depending on literal-variable, it is either seen as an expression or as a literal string)

			str=char(valtag.getTextContent);		
			%str contains the string (expression or literal) contained in the VALUES tag

			if literal==1
				%literal string => format must be "%s\n" for correct printing?!
				evalline=['struc.var(',num2str(varcount),').VALUES=''',str,''';'];
				%CAN BE OVERWRITTEN BY ADDITIONAL FORMAT TAG(S) AFTER THIS VALUES TAG!
				struc.var(varcount).FORMAT='%s\n';
				struc.var(varcount).VAR_DATA_TYPE='STRING';
			else
				%str is taken as an expression
				%expression needs to be evaluated in the caller's workspace (eg expression may contain variables from the caller's workspace)
				value=evalin('caller',str);
				%value must be inside the '' 
				%(so that it is part of the evalline-string and is not treated as a string itself nor as a literal ('' '') in the string)
				evalline=['struc.var(',num2str(varcount),').VALUES=value;'];
			end
			try
				%this adds the VALUES to the output structure (possibly interpreting the str as Matlab expression)
				eval(evalline);
			catch
				disp(['Warning: eval failed when processing a VALUES tag. Variable ',num2str(l+1),': ',lasterr]);
			end

			%eval of VALUES must have executed normally for size/dimension calculation	
			if literal==1
				%AUTOSIZE/AUTODIMENSION: adjust VAR_SIZE and VAR_DIMENSION automatically (original VAR_SIZE and VAR_DIMENSION values are overwritten!)
				%LITERAL STRING => just 1 string => VAR_DIMENSION == 1 and VAR_SIZE only contains string length
				%CAN BE OVERWRITTEN BY ADDITIONAL <ATTR name="VAR_SIZE"> TAGS OR BY USER (inbetween input and output function)
				%NO: VAR_SIZE=strlength;1 (1 string of length=strlength) => VAR_DIMENSION=2!
				struc.var(varcount).VAR_SIZE=sprintf('%d;1',length(str));
				struc.var(varcount).VAR_DIMENSION=sprintf('%d',2);
			else
				%AUTOSIZE/AUTODIMENSION:
				%we need to calculate VAR_SIZE and VAR_DIMENSION, but this depends on the Matlab data type (eg string = special case,...)
				A=struc.var(varcount).VALUES;
				dimsizes=size(A);
				%dims=ndims(A);
				dims=length(dimsizes);

				if iscell(struc.var(varcount).VALUES)==1
					%conversion to char array only succeeds if the cell array only contains character strings (cell array of strings)
                    
					try
						A=char(struc.var(varcount).VALUES);
						%VALUES still remains cell array, only A is converted! => so Output function will see a iscell()==1!
						%if character conversion succeeds, following if-test is also executed!
					catch
						disp(['Warning: cell array of VALUES for variable ',num2str(l),' may only contain strings.']);
						struc.var(varcount).VALUES=[];
						continue;
					end
					%Recalculate - A is now a character array => new #rows/#cols
					dimsizes=size(A);
					%dims=ndims(A);
					dims=length(dimsizes);
				end
				%if VALUES is a character array (or cell array of strings, already converted to char array)
				if isa(A,'char')==1
                    
					%char array => first VAR_SIZE element must be the same as number of columns (=max string length)
					%dimsizes(2) is the number of columns (2nd dimension of a char array)
					%so, to arrive at VAR_SIZE, just switch dimsizes(1) and (2) and print all dimsizes in 1 string
					str=sprintf('%d;%d',dimsizes(2),dimsizes(1)); %no ';' after 2nd element (necessary in case dims==2)!
					%append other dimsizes (if necessary)
					if dims>2
						%dimensions 3 and up (first 2 dimensions are already covered)
						%for d=3:dims
						%	if d==dims
						%		str=[str,sprintf('%d',dimsizes(d))];
						%	else
						%		str=[str,sprintf('%d;'dimsizes(d))];
						%	end
						%end

						%vectorized
						%first sprintf prints all remaining dimensions (except last one), with a ";" after the number, the second sprintf
						%adds the last dimension (no following ";"!!)
						%additional ';' after 2nd element of VAR_SIZE is necessary
						str=[str,';',sprintf('%d;',dimsizes(3:dims-1)),sprintf('%d',dimsizes(dims))];
					end
					struc.var(varcount).VAR_SIZE=str;
					struc.var(varcount).VAR_DIMENSION=sprintf('%d',dims);
				end
				if isnumeric(A)==1 | islogical(A)==1
					%normal, numeric array
					struc.var(varcount).VAR_SIZE=[sprintf('%d;',dimsizes(1:dims-1)),sprintf('%d',dimsizes(dims))];
					struc.var(varcount).VAR_DIMENSION=sprintf('%d',dims);
					%compensate for row/column vectors: do not use DIMENSION=2, use 1 instead and only specify the number of rows/cols as SIZE
					if dims==2 %only 2D arrays can be row/column vectors (if number of rows or columns is "1")
						%special case: array contains only 1 value => both if-tests are performed, but both will result in DIMENSION=1 and SIZE=1
						if dimsizes(1)==1
							%1 row, multiple columns (in a 2D array) == row vector
							struc.var(varcount).VAR_SIZE=sprintf('%d',dimsizes(2));
							struc.var(varcount).VAR_DIMENSION='1';
						end
						if dimsizes(2)==1
							%multiple rows, 1 column (in a 2D array) == column vector
							struc.var(varcount).VAR_SIZE=sprintf('%d',dimsizes(1));
							struc.var(varcount).VAR_DIMENSION='1';
						end
					end
				end
			end			
		end
			
		%FORMAT tag(s) - normally just 1 tag - use the last one if multiple FORMAT tags occur or process all of them (has same result, but is slower)
		
		formtags=vartag.getElementsByTagName('FORMAT');

		%DEBUG
		%formtags.getLength		
		
		if formtags.getLength>0
			%iterate over all nodelist items (all tags found) - not needed: just use the last one
			%for k=0:formtags.getLength-1
			formtag=formtags.item(formtags.getLength-1);
			%test if the tag has a name attribute - || is faster (short-circuit?)
			if formtag.hasAttributes==1
				disp(['Warning: FORMAT tags do not require attributes. Attributes of FORMAT tag number ',num2str(k+1),' of variable ',num2str(varcount),' are ignored.']);
				continue;
			end

			str=char(formtag.getTextContent);
			%eval: use "literal" value, do not interpret as expression (str is placed inside two single quotes)
			evalline=['struc.var(',num2str(varcount),').FORMAT=''',str,'''',';'];
			try
				eval(evalline);
			catch
				disp(['Warning: eval failed when processing a FORMAT tag. Variable ',num2str(l+1),': ',lasterr]);
			end
			%end
		else
			struc.var(varcount).FORMAT='';
		end
	end
end	

%SEE ABOVE: Excel is not supported
%if opmode==3 | opmode==4
%	%Excel file
%	%No "values" attribute?? (has to be added to the template!)
%end



