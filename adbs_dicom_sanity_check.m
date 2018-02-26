function adbs_dicom_sanity_check(in_dir, out_dir, dcm2niix_dir, series_id)
% Function to convert a specific DICOM series, save patient details, and
% then convert all the information into a csv file; this can be used to
% ensure that the subject name, age, and gender stored in the DICOM header
% are the same as the record
%% Inputs:
% in_dir:       input directory having subject folders (all subject folders
%               must follow the convention "sub-xxxx"; see Notes)
% out_dir:      output directory where NIfTI data should be exported
%               (subject folders would be automatically created; see Notes)
% dcm2niix_dir: directory where dcm2niix is present
% series_id:    which series number to convert
% 
%% Output:
% If default choices are used, each subject's data would be converted to
% NIfTI and output to the out_dir location. The subejct folders would be
% automatically created while conversion logs would be written to the log
% folder (sub-xxxx_log.txt); additionally a summary file is created in the
% out_dir (summary_ddmmmyyyy.txt)
%
% A csv file (subject_details_ddmmmyyyy_hhmmss.csv) is also created which
% has subject specific details
% 
%% Notes:
% The in_dir should have a folder for each subject; it is assumed that the
% folders are organized as "sub-xxxx"; each subject folder has one DICOM
% folder and the DICOMDIR file (though these are not explicitly checked).
% 
% Folder corresponding to each subject is automatically created in the
% out_dir, the naame is the same as the name in in_dir; if a particular
% subject's folder already exists in out_dir, that subject is skipped; this
% is useful if the same in_dir has to be repeatedily subjected to
% conversion (such as the case when new subjects are added) but existing
% data should not be touched
% 
% If out_dir does not exist, it will be created
%
% If in_dir is not provided, user is prompted via GUI to select input
% directory; this can lead to potential crashes if remote sessions are in
% use
%
% If dcm2niix_dir is not provided, user is prompted via GUI to select input
% directory; this can lead to potential crashes if remote sessions are in
% use
%
% If no inputs are given, user is prompted vua GUI to select relevant
% direcrtories; this can lead to potential crashes if remote sessions are
% in use
%
% If any particular DICOM info is not found for whatever reason, it is
% recorded in the csv file
% 
% If subjects are skipped, no record is written in the csv file
% 
%% Default:
% series_id = 101;
%
%% Command:
% dcm2niix is called with the following options:
% bids       = 1;
% gz         = 0;
% precise    = 0;
% outname    = %n;
% series_id  = 101;
% text_notes = 1;
% 
%% Author(s)
% Parekh, Pravesh
% Bhalerao, Gaurav
% February 26, 2018
% ADBS

%% Check inputs and assign defaults
% Check if nothing is input
if nargin == 0
    warning('Input directory must be given');
    in_dir = uigetdir(pwd, 'Select input directory');
    warning('Output directory not specified');
    out_dir = uigetdir(pwd, 'Select output directory');
    warning('Path to dcm2niix not provided');
    dcm2niix_dir = uigetdir(pwd, 'Select directory having dcm2niix');
else
    
    % Check if in_dir is provided; otherwise prompt
    if ~exist('in_dir', 'var')
        warning('Input directory must be given');
        in_dir = uigetdir(pwd, 'Select input directory');
    else
        % Check if in_dir is empty; if yes, prompt
        if isempty(in_dir)
            warning('Input directory must be given');
            in_dir = uigetdir(pwd, 'Select input directory');
        else
            % Check if in_dir exists
            if ~exist(in_dir, 'dir')
                error([in_dir, ' not found']);
            end
        end
    end
    
    % Check if out_dir is provided; otherwise prompt
    if ~exist('out_dir', 'var')
        warning('Output directory not specified');
        out_dir = uigetdir(pwd, 'Select output directory');
    else
        % Check if out_dir is empty; if yes, set to pwd
        if isempty(out_dir)
            warning('Output directory not specified');
            out_dir = uigetdir(pwd, 'Select output directory');
        else
            % Check if out_dir exists; if not, create it
            if ~exist(out_dir, 'dir')
                mkdir(out_dir);
            end
        end
    end
    
    % Check if dcm2niix_dir is provided; otherwise prompt
    if ~exist('dcm2niix_dir', 'var')
        warning('Path to dcm2niix not provided');
        dcm2niix_dir = uigetdir(pwd, 'Select directory having dcm2niix');
    else
        % Check if dcm2niix_dir is empty; if yes, prompt
        if isempty(dcm2niix_dir)
            warning('Path to dcm2niix not provided');
            dcm2niix_dir = uigetdir(pwd, 'Select directory having dcm2niix');
        else
            % Check if directory exists; if not, prompt again
            if ~exist(dcm2niix_dir, 'dir')
                warning([dcm2nix_dir, ' not found']);
                dcm2niix_dir = uigetdir(pwd, 'Select directory having dcm2niix');
            end
        end
    end
end

% Check if series_id is provided; otherwise set to default
if ~exist('series_id', 'var')
    series_id = 101;
end

% Set dcm2niix command options
bids        = 'y';
gz          = 'n';
precise     = 'n';
text_notes  = 'y';
outname     = '%n';

%% Create subject list
cd(in_dir);
list_subjs = dir('sub-*');
num_subjs  = length(list_subjs);
disp([num2str(num_subjs), ' subjects found']);

%% Prepare summary file
fid_summary_name = fullfile(out_dir, ['summary_', ...
                   datestr(now, 'ddmmmyyyy'), '.txt']);
if exist(fid_summary_name, 'file')
    fid_summary = fopen(fullfile(out_dir, ['summary_', ...
                  datestr(now, 'ddmmmyyyy'), '.txt']), 'a');
else
    fid_summary = fopen(fullfile(out_dir, ['summary_', ...
                  datestr(now, 'ddmmmyyyy'), '.txt']), 'w');
end
fprintf(fid_summary, '%s\r\n', ['Date:         ', datestr(now, 'ddmmmyyyy')]);
fprintf(fid_summary, '%s\r\n', ['Time:         ', datestr(now, 'HH:MM:SS PM')]);
fprintf(fid_summary, '%s\r\n', ['in_dir:       ', in_dir]);
fprintf(fid_summary, '%s\r\n', ['out_dir:      ', out_dir]);
fprintf(fid_summary, '%s\r\n', ['dcm2niix_dir: ', dcm2niix_dir]);
fprintf(fid_summary, '%s\r\n', ['series_id:    ', num2str(series_id)]);
fprintf(fid_summary, '%s\r\n', [num2str(num_subjs), ' subjects found']);

%% Initialize table for pooling subject information
subj_info = cell2table(cell(num_subjs, 4));
subj_info.Properties.VariableNames = ...
    {'subj_ID', 'DICOM_Name', 'DICOM_Age', 'DICOM_Gender'};

%% Loop over each subject and convert

for subj = 1:num_subjs
    % Move to dcm2niix_dir
    cd(dcm2niix_dir);
    
    % Output path
    sub_out_dir = fullfile(out_dir, list_subjs(subj).name);
    
    % If output directory exists, skip the subject (lazy conversion)
    if exist(sub_out_dir, 'dir')
        disp([list_subjs(subj).name, '...skipped']);
        fprintf(fid_summary, '%s\r\n', [list_subjs(subj).name, '...conversion skipped']);
        continue
    else
        % Create the framework of the command
        command = ['-b ', bids, ' -z ', gz, ' -p ', precise, ...
                  ' -t ', text_notes, ' -n ', num2str(series_id), ' -f ', outname];

        % Create subject output directory
        mkdir(sub_out_dir);
        
        % Input path
        sub_in_dir   = fullfile(in_dir, list_subjs(subj).name);
        
        % Adding output directory and input directory to command
        command = [command, ' -o ', sub_out_dir, ' ', sub_in_dir];
        
        % Check OS and add execution method
        if isunix
            command = ['./dcm2niix ', command];
        else
            command = ['dcm2niix.exe ', command];
        end
        
         % Execute the command
        [status,~] = system(command);
        
        % Display summary
        if status
            disp([list_subjs(subj).name, '...error']);
            fprintf(fid_summary, '%s', [list_subjs(subj).name, '...conversion error']);
        else
            disp([list_subjs(subj).name, '...finished']);
            fprintf(fid_summary, '%s', [list_subjs(subj).name, '...conversion finished']);
        end
        
        % Go to subject folder and find the text file(s) created
        cd(sub_out_dir);
        list_files = dir('*.txt');
        
        % If no files exist, update summary
        if isempty(list_files)
            disp([list_subjs(subj).name, '...series not found']);
            fprintf(fid_summary, '%s\r\n', '...series not found');
            subj_info.subj_ID{subj}       = list_subjs(subj).name;
            subj_info.DICOM_Name{subj}    = 'series not found';
            subj_info.DICOM_Age{subj}     = 'series not found';
            subj_info.DICOM_Gender{subj}  = 'series not found';
        else
            % If multiple files are present, select the first one
            if length(list_files) > 1
                list_files = list_files(1);
            end
            % Update summary
            disp([list_subjs(subj).name, '...reading ', list_files.name]);
            fprintf(fid_summary, '%s\r\n', ['...reading ', list_files.name]);
            
            % Read text file and get info
            fid_info = fopen(list_files.name, 'r');
            info     = textscan(fid_info, '%s');
            
            % Collect info and add to subj_info table
            
            % Get subj-ID
            subj_info.subj_ID{subj} = list_subjs(subj).name;
            
            % Get DICOM_Name
            loc = strcmpi(info{1,1}, 'Name:');
            if isempty(find(loc, 1))
                subj_info.DICOM_Name{subj} = 'Name not found';
            else
                subj_info.DICOM_Name{subj} = info{1,1}{find(loc)+1};
            end
            
            % Get DICOM_Age
            loc = strcmpi(info{1,1}, 'Age:');
            if isempty(find(loc, 1))
                subj_info.DICOM_Age{subj} = 'Age not found';
            else
                % Remove leading zero and trailing 'Y' from age
                subj_info.DICOM_Age{subj} = info{1,1}{find(loc)+1}(2:end-1);
            end
            
            % Get DICOM_Gender
            loc = strcmpi(info{1,1}, 'Gender:');
            if isempty(find(loc, 1))
                subj_info.DICOM_Gender{subj} = 'Gender not found';
            else
                % Remove leading zero and trailing 'Y' from age
                subj_info.DICOM_Gender{subj} = info{1,1}{find(loc)+1};
            end
            
            % Close info file
            fclose(fid_info);
        end
    end
end
fclose(fid_summary);

% Write csv file
writetable(subj_info, fullfile(out_dir, ...
    ['subject_details', datestr(now, 'ddmmmyyyy_HHMMSS'), '.csv']));