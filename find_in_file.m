function ind = find_in_file(infile,string)
%find_in_file find string in file read line by line as cell array
%
%   File must be read using 
%         fid = fopen('','r');
%         i = 1;
%         tline = fgetl(fid);
%         infile{i} = tline;
%         while ischar(tline)
%             i = i+1;
%             tline = fgetl(fid);
%             infile{i} = tline;
%         end
%         fclose(fid);
%
%   Input: cell array containing file, and string to find
%   Output: index of line string is found on


% placeholder value
ind=-99;

% look for exact match (in case string is part of longer strings as well)
for i=1:length(infile)-1
    
   if strcmp(infile{i},string)
       ind=i;
       break
   end
    
end

% if not found, use strfind
if ind==-99
    % finds all lines that contain the string
    tmp=strfind(infile(1:end-1),string);
    ind=find(not(cellfun('isempty', tmp)));
end

if isempty(ind), error('String not found'), end
    
end

