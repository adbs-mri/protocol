function adbs_import_dicom(in_dir, out_dir, log_dir, dcm2niix_dir, bids, gz, precise, outname)
% Function to convert DICOM data to NIfTI using dcm2niix
%% Inputs:
% in_dir:       input directory having subject folders (all subject folders
%               must follow the convention "sub-xxxx"; see Notes)
% out_dir:      output directory where NIfTI data should be exported
%               (subject folders would be automatically created; see Notes)
% log_dir:      directory where conversion logs are written as text files
%               (see Notes for other possibilities)
% dcm2niix_dir: directory where dcm2niix is present
% bids:         whether BIDS style output is required (1/0)
% gz:           set to 1 if compressed NIfTI files are needed (1/0)
% precise:      whether to use Philips precise values or display values (1/0)
% outname:      argument for -f part of the command which decides how
%               converted files are named
%
%% Output:
% If default choices are used, each subject's data would be converted to
% NIfTI and output to the out_dir location. The subejct folders would be
% automatically created while conversion logs would be written to the log
% folder (sub-xxxx_log.txt); additionally a summary file is created in the
% out_dir (summary_ddmmmyyyy.txt)
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
% A text file containing the log of conversion process is output to the
% log_dir folder, the filename being sub-xxxx_log.txt; do note that the
% first line of this log file is the actual command used to execute the
% code; the following other options are supported, instead of a path:
% 'skip':       log files are not created
% '':           same as 'skip'
% 'sub':        log files are created within each subject's folder
%
% If out_dir or log_dir folders are missing, they will be created
%
% If out_dir is not provided, user is prompted via GUI to select output
% directory; this can lead to potential crashes if remote sessions are in
% use
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
%% Defaults:
% log_dir   = output to log folder as sub-xxxx_log.txt
% bids      = 1;
% gz        = 0;
% precise   = 0;
% outname   = %p;
%
%% Author(s)
% Parekh, Pravesh
% Bhalerao, Gaurav
% February 22, 2018
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
    warning('Log directory location not provided');
    log_dir = uigetdir(pwd, 'Select log directory');
    logging = 1;
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
    
    % Check if log_dir is provided; otherwise skip
    if ~exist('log_dir', 'var')
        logging = 1;
    else
        % Check specifics of log_dir input
        if isempty(log_dir)
            logging = 0;
        else
            if strcmpi(log_dir, 'skip')
                logging = 0;
            else
                if strcmpi(log_dir, 'sub')
                    logging = 1;
                else
                    logging = 1;
                    % Check if log_dir exists; if not, create it
                    if ~exist(log_dir, 'dir')
                        mkdir(log_dir);
                    end
                end
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

% Check if BIDS format is required
if ~exist('bids', 'var')
    bids = 1;
end

% Check if user wants gz files
if ~exist('gz', 'var')
    gz = 0;
end

% Check if Philips precise is explicitly passed
if ~exist('precise', 'var')
    precise = 0;
end

% Check if outname is provided
if ~exist('outname','var')
    outname = '%p';
end

% Convert binary variables to y and n (bids)
if bids
    bids = 'y';
else
    bids = 'n';
end

% Convert binary variables to y and n (gz)
if gz
    gz = 'y';
else
    gz = 'n';
end

% Convert binary variables to y and n (precise)
if precise
    precise = 'y';
else
    precise = 'n';
end

%% Create subject list
cd(in_dir);
list_subjs = dir('sub-*');
num_subjs  = length(list_subjs);
disp([num2str(num_subjs), ' subjects found']);

%% Prepare summary file
fid_summary = fopen(fullfile(out_dir, ['summary_', datestr(now, 'ddmmmyyyy'), '.txt']), 'w');
fprintf(fid_summary, '%s\r\n', ['in_dir:       ', in_dir]);
fprintf(fid_summary, '%s\r\n', ['out_dir:      ', out_dir]);
fprintf(fid_summary, '%s\r\n', ['log_dir:      ', log_dir]);
fprintf(fid_summary, '%s\r\n', ['dcm2niix_dir: ', dcm2niix_dir]);
fprintf(fid_summary, '%s\r\n', ['BIDS:         ', bids]);
fprintf(fid_summary, '%s\r\n', ['Compressed:   ', gz]);
fprintf(fid_summary, '%s\r\n', ['Precise:      ', precise]);
fprintf(fid_summary, '%s\r\n', ['Outname:      ', outname]);
fprintf(fid_summary, '%s\r\n', [num2str(num_subjs), ' subjects found']);

%% Loop over each subject and convert
% Move to dcm2niix_dir
cd(dcm2niix_dir);

for subj = 1:num_subjs
    % Output path
    sub_out_dir = fullfile(out_dir, list_subjs(subj).name);
    
    % If output directory exists, skip the subject (lazy conversion)
    if exist(sub_out_dir, 'dir')
        disp([list_subjs(subj).name, '...skipped']);
        fprintf(fid_summary, '%s\r\n', [list_subjs(subj).name, '...skipped']);
        continue
    else
        % Create the framework of the command
        command = ['-b ', bids, ' -z ', gz, ' -p ', precise, ' -f ', outname];

        % Create subject output directory
        mkdir(sub_out_dir);
        
        % Input path
        sub_in_dir   = fullfile(in_dir, list_subjs(subj).name);
        
        % Adding output directory and input directory to command
        command = [command, ' -o ', sub_out_dir, ' ', sub_in_dir];
        
        % Check about log files and create path to log file
        if logging
            if strcmpi(log_dir, 'sub')
                sub_log_file = fullfile(out_dir, list_subjs(subj).name, ...
                               [list_subjs(subj).name, '_log.txt']);
            else
                sub_log_file = fullfile(log_dir, ...
                               [list_subjs(subj).name, '_log.txt']);
            end
            
            % Update command with logging path
            command = [command, ' >> ', sub_log_file];
        end
        
        % Check OS and add execution method
        if isunix
            command = ['./dcm2niix ', command];
        else
            command = ['dcm2niix.exe ', command];
        end
        
        % If logging is enabled, write the command to the text file
        if logging
            fid = fopen(sub_log_file, 'w');
            fprintf(fid, '%s\r\n', command);
            fclose(fid);
        end
        
        % Execute the command
        status = system(command);
        
        % Display summary
        if status
            disp([list_subjs(subj).name, '...error']);
            fprintf(fid_summary, '%s\r\n', [list_subjs(subj).name, '...error']);
        else
            disp([list_subjs(subj).name, '...finished']);
            fprintf(fid_summary, '%s\r\n', [list_subjs(subj).name, '...finished']);
        end
    end
end
fclose(fid_summary);

% Return to output folder
cd(out_dir);