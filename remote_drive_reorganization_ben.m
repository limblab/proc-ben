function remote_drive_reorganization_ben(base_dir,target_dir)
%% remote_drive_reorganization(base_dir, target_dir)
%
% Rearranges directories in the limblab/data directory to fit the
% "monkey/date/*.xyz" data structure. 
% 
% -- Inputs --
%  dd : base directory for the scan. 
%
%

if ~exist('base_dir')
    base_dir = pwd;
end

if ~exist('target_dir')
    target_dir = pwd;
end

f_ext = {'.nev','.ns1','.ns2','.ns3','.ns4','.ns5','.ns6','.plx','.mat','.ccf','.png','.fig','.jpg', '.rhd'};

dd = [];


%% get a list of files
for ii = 1:length(f_ext)
    if isempty(dd)
        dd = dir([base_dir,filesep,'**',filesep,'*',f_ext{ii}]);
    else
        dd = [dd;dir([base_dir,filesep,'**',filesep,'*',f_ext{ii}])];
    end
    
end

[dd, filesToMoveManually] = fixDirectoryDates(dd); %fill in dates for symlinks, get files that need to be moved manually because the windows dir call can't find them
%% create necessary directories and move all files
moved_files = {'Filename','name matches creation date'};
duplicate_files = {'Filename', 'name matches creation date'};

for ii = 1:length(dd)
    fn_split = strsplit(dd(ii).name,'_');
%     
%     rec_date_ind = cellfun(@str2num, fn_split, 'UniformOutput',false);
%     rec_date_ind = ~cell2mat(cellfun(@isempty, rec_date_ind, 'UniformOutput', false));
%     rec_date = fn_split{rec_date_ind};
%     
    create_date = datestr(dd(ii).date,'yyyymmdd');
    new_dir = [target_dir,filesep,create_date];
    
    % want to see if we have consistency in named date v putative creation
    % date
    rec_date_cmp = any(strcmpi(fn_split,create_date)) | any(strcmpi(fn_split,datestr(dd(ii).date,'mmddyy')));
    
    
    
    if ~exist(new_dir,'dir')
        mkdir(new_dir)
    end
    
    try
        if exist([new_dir, filesep, dd(ii).name], 'file') == 2
            duplicate_files(end+1, :) = {[dd(ii).folder, filesep, dd(ii).name], rec_date_cmp};
        else
            movefile([dd(ii).folder,filesep,dd(ii).name],new_dir);
            moved_files(end+1,:) = {[dd(ii).folder,filesep,dd(ii).name],rec_date_cmp};
        end
    end
    
end

%% Clean up empty directories

log_file = [base_dir,filesep,'log.xlsx'];

rem_dirs = {};
untouch_file = {};

scanned_dirs = unique({dd.folder});

for ii = 1:numel(scanned_dirs)
    sd_info = dir(scanned_dirs{ii});
    sd_info = sd_info(3:end);
    if isempty(sd_info)
        rem_dirs{end+1} = scanned_dirs{ii};
        rmdir(scanned_dirs{ii})
    else
        sd_info = sd_info(~[sd_info.isdir]);
        untouch_file(end+1:end+numel(sd_info)) = {sd_info.name};
    end
    
end



try
    xlswrite(log_file,rem_dirs,'Removed Directories')
catch
    disp('No directories removed')
end

try
    xlswrite(log_file,untouch_file,'Untouched Files')
catch
    disp('No files untouched')
end

try 
    xlswrite(log_file, duplicate_files, 'Duplicate files')
catch
    disp('No duplicate files detected')
end


try
    xlswrite(log_file,moved_files,'Moved Files')
catch
    disp('No files moved')
end
    
try
    xlswrite(log_file, filesToMoveManually, 'These need to be moved manually')
catch
    disp('No files need to be moved manually')
end

end


function [fixedDirectory, filesToMoveManually] = fixDirectoryDates(dd)
goodRows = [];
filesToMoveManually = {'Filepath'};
for i = 1:length(dd)
    if isempty(dd(i).date)
        [~, longString] = system(['dir ' dd(i).folder filesep dd(i).name]);
        if length(longString) ~= 43 %longString with length 43 is 'the system cannot find the file specified'
            splitString = split(longString);
            if all(~strcmpi(splitString{16}, {'Date', 'File'})) %'Date' exception is thrown when it recognizes the file but can't get the date, 'File' exception is thrown when an improper character is used (I think)
                dd(i).date = splitString{16};
                goodRows(end+1) = i;
            else
                filesToMoveManually{end+1, 1} = [dd(i).folder filesep dd(i).name];
            end
        else
            filesToMoveManually{end+1, 1} = [dd(i).folder filesep dd(i).name];
        end
    else
        goodRows(end+1) = i;
    end
end
fixedDirectory = dd(goodRows);

end

            