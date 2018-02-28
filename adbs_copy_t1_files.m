function adbs_copy_t1_files(nifti_dir, out_dir)
% Function to copy T1w files from the NIfTI folder (output from
% adbs_import_dicom) to an output directory; the files are named as
% sub-xxxx_T1w.nii; .json file is also copied and renamed accordingly
%% Inputs:
% nifti_dir:    directory with NIfTI data for each subject, organized into
%               folders (sub-xxxx); this directory is the output of
%               adbs_import_dicom
% out_dir:      output directory where NIfTI and json files will be copied 
%               and renamed to sub-xxxx_T1w.nii style
%
%% Output:
% All structural files are copied out to out_dir in the format
% sub-xxxx_T1w.nii; the corrresponding .json file is also copied out and
% renamed; additionally, a summary text file is also created in the out_dir
% with the name summary_copy_t1_ddmmmyyyy.txt
% 
%% Notes:
% If out_dir does not exist, it will be created
% 
% If multiple T1 files exist (except PSIR files), data will not be copied
% 
% If nifti_dir or out_dir is not specified, user is prompted via GUI to
% select the appropriate folders; this can lead to a crash if, for example,
% remote session is being used
% 
% If file already exists in the out_dir, copying is skipped
% 
%% Default:
% No defaults; all arguments need to be passed by the user
%
%% Author(s)
% Parekh, Pravesh
% Bhalerao, Gaurav
% February 28, 2018
% ADBS

%% Evaluate inputs
% Check if nothing is input
if nargin == 0
    warning('NIfTI directory must be given');
    nifti_dir = uigetdir(pwd, 'Select NIfTI directory');
    warning('Output directory not specified');
    out_dir = uigetdir(pwd, 'Select output directory');
else
    
    % Check if nifti_dir is provided; otherwise prompt
    if ~exist('nifti_dir', 'var')
        warning('NIfTI directory must be given');
        nifti_dir = uigetdir(pwd, 'Select NIfTI directory');
    else
        % Check if nifti_dir is empty; if yes, prompt
        if isempty(nifti_dir)
            warning('NIfTI directory must be given');
            nifti_dir = uigetdir(pwd, 'Select NIfTI directory');
        else
            % Check if nifti_dir exists
            if ~exist(nifti_dir, 'dir')
                error([nifti_dir, ' not found']);
            end
        end
    end
    
    % Check if out_dir is provided; otherwise prompt
    if ~exist('out_dir', 'var')
        warning('Output directory not specified');
        out_dir = uigetdir(pwd, 'Select output directory');
    else
        % Check if out_dir is empty; if yes, prompt user
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
end

%% Create subject list
cd(nifti_dir);
list_subjs = dir('sub-*');
num_subjs  = length(list_subjs);
disp([num2str(num_subjs), ' subjects found']);

%% Prepare summary file
fid_summary_name = fullfile(out_dir, ['summary_copy_t1_', ...
                   datestr(now, 'ddmmmyyyy'), '.txt']);
if exist(fid_summary_name, 'file')
    fid_summary = fopen(fid_summary_name, 'a');
else
    fid_summary = fopen(fid_summary_name, 'w');
end
fprintf(fid_summary, '%s\r\n', ['Date:         ', datestr(now, 'ddmmmyyyy')]);
fprintf(fid_summary, '%s\r\n', ['Time:         ', datestr(now, 'HH:MM:SS PM')]);
fprintf(fid_summary, '%s\r\n', ['nifti_dir:    ', nifti_dir]);
fprintf(fid_summary, '%s\r\n', ['out_dir:      ', out_dir]);
fprintf(fid_summary, '%s\r\n', [num2str(num_subjs), ' subjects found']);

%% Loop over subjects and copy files out
for subj = 1:num_subjs
    
    % Go to subject specific NIfTI folder and find T1 file
    cd(fullfile(nifti_dir, list_subjs(subj).name));
    list_files = dir('*T1*.nii');
    
    % Attempt to remove any PSIR files that might have been selected
    count = 1;
    loc = [];
    for i = 1:length(list_files)
        if strfind(list_files(i).name, 'PSIR')
            loc(count) = i;
            count = count + 1;
        end
    end
    if ~isempty(loc)
        list_files(loc) = [];
    end
    
    if isempty(list_files)
        % Display summary and move on
        disp([list_subjs(subj).name, '...T1w file not found']);
        fprintf(fid_summary, '%s\r\n', ...
            [list_subjs(subj).name, '...T1w file not found']);
        continue;
    else
        % If multiple files are present, update summary, and move on
        if length(list_files) > 1
            disp([list_subjs(subj).name, '...multiple T1 images; skipping']);
            fprintf(fid_summary, '%s\r\n', [list_subjs(subj).name, '...multiple T1 images; skipping']);
            continue
        else
            % Update summary
            disp([list_subjs(subj).name, '...copying ', list_files.name]);
            fprintf(fid_summary, '%s',  [list_subjs(subj).name, '...copying ', list_files.name]);
            
            % Get just the file name (without extension)
            [~, fname, ~] = fileparts(list_files.name);
            
            % Create destination name
            dest_name = [list_subjs(subj).name, '_T1w'];
           
            % Copy NIfTI file
            copyfile(fullfile(nifti_dir, list_subjs(subj).name, [fname, '.nii']), ...
                     fullfile(out_dir, [dest_name, '.nii']));
                 
            % Copy json file
            copyfile(fullfile(nifti_dir, list_subjs(subj).name, [fname, '.json']), ...
                     fullfile(out_dir, [dest_name, '.json']));
                 
            % Update summary
            disp([list_subjs(subj).name,   '...done!']);
            fprintf(fid_summary, '%s\r\n', '...done!');
        end
    end
end

% Close summary file
fclose(fid_summary);