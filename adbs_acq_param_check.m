function adbs_acq_param_check(nifti_dir, dicom_dir, out_dir, dcm2niix_dir, acq_catg)
% Function to compile subject details and acquisition parametes (subj-ID,
% name, age, gender, TR, TE, image size, voxel size, and number of volumes
% in case of EPI) for different acqusiiton types, into a csv file
%% Inputs:
% nifti_dir:    directory with NIfTI data for each subject, organized into
%               folders (sub-xxxx); this directory is the output of
%               adbs_import_dicom
% dicom_dir:    directory having DICOM data for the same subjects as listed
%               in nifti_dir, organized into folders (sub-xxxx)
% out_dir:      output directory where acquisition specific NIfTI data will
%               be exported (subject folders would be automatically
%               created; see Notes)
% dcm2niix_dir: directory where dcm2niix is present
% acq_catg:     category of acquisition for which data is being compiled;
%               can be one of the following:
%               'T1' or 'T1w'
%               'rsf' or 'rest'
%
%% Output:
% Given a kind of acquisition category, the series ID for that acquisition
% is picked for each subject from the .json files; then that particular
% DICOM data is converted to NIfTI while additionally writing out the text
% file containig subject's private data from which name, age, gender, TR
% and TE is picked up; the image is then read using SPM and image and voxel
% size is calculated.
%
% Following files are created in the out_dir apart from the NIfTI images:
% (param_check_<acq_catg>_ddmmmyyyy_hhmmss.csv)
% (param_check_summary_<acq_catg>_ddmmmyyyy.txt)
%
%% Notes:
% Folder corresponding to each subject is automatically created in the
% out_dir, the name is the same as the name in nifti_dir and dicom_dir; if
% a particular subject's folder already exists in out_dir, that subject is
% skipped; this is useful if the same nifti_dir and dicom_dir have to be
% repeatedily subjected to conversion (such as the case when new subjects
% are added) but existing data should not be touched
%
% If out_dir does not exist, it will be created
%
% If any directory is not provided, user is prompted via GUI to select the
% appropriate directory; this can lead to a crash if remote session is
% being used
%
% If acq_catg is not provided, user is prompted on via GUI to enter the
% appropriate string; this can lead to a crash if remote session is
% being used
%
% If for any subject, the acq_catg is not found, it is mentioned in the csv
% file
%
% If subjects are skipped, no record is written in the csv file
%
% Can be used instead of adbs_dicom_sanity_check
%
%% Default:
% No defaults; all arguments need to be passed by the user
%
%% Command:
% dcm2niix is called with the following options:
% bids       = 1;
% gz         = 0;
% precise    = 0;
% outname    = %p;
% series_id  = <as determined from the .json file>;
% text_notes = 1;
%
%% Author(s)
% Parekh, Pravesh
% Bhalerao, Gaurav
% February 27, 2018
% ADBS

%% Evaluate inputs and set some values
% Check if nothing is input
if nargin == 0
    warning('NIfTI directory must be given');
    nifti_dir = uigetdir(pwd, 'Select NIfTI directory');
    warning('DICOM directory must be given');
    dicom_dir = uigetdir(pwd, 'Select DICOM directory');
    warning('Output directory not specified');
    out_dir = uigetdir(pwd, 'Select output directory');
    warning('Path to dcm2niix not provided');
    dcm2niix_dir = uigetdir(pwd, 'Select directory having dcm2niix');
    warning('Acquisition category must be provided');
    acq_catg = inputdlg('Enter acquisition category', 'Acqusition Category', 1);
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
    
    % Check if dicom_dir is provided; otherwise prompt
    if ~exist('dicom_dir', 'var')
        warning('DICOM directory must be given');
        dicom_dir = uigetdir(pwd, 'Select DICOM directory');
    else
        % Check if dicom_dir is empty; if yes, prompt
        if isempty(dicom_dir)
            warning('DICOM directory must be given');
            dicom_dir = uigetdir(pwd, 'Select DICOM directory');
        else
            % Check if dicom_dir exists
            if ~exist(dicom_dir, 'dir')
                error([dicom_dir, ' not found']);
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
    
    % Check if acq_catg is provided; otherwise prompt
    if ~exist('acq_catg', 'var')
        warning('Acquisition category must be provided');
        acq_catg = inputdlg('Enter acquisition category', 'Acqusition Category', 1);
    else
        % Check if acq_catg is empty; if yes, prompt
        if isempty(acq_catg)
            warning('Acquisition category must be provided');
            acq_catg = inputdlg('Enter acquisition category', 'Acqusition Category', 1);
        end
    end
    
    % Validate acq_catg
    if strcmpi(acq_catg, 'T1') || strcmpi(acq_catg, 'T1w')
        search_term = 'T1';
    else
        if strcmpi(acq_catg, 'rsf') || strcmpi(acq_catg, 'rest')
            search_term = 'rest';
        else
            error('Invalid acquisition category');
        end
    end
end

% Set dcm2niix command options
bids        = 'y';
gz          = 'n';
precise     = 'n';
text_notes  = 'y';
outname     = '%p';

%% Create subject list
cd(nifti_dir);
list_subjs = dir('sub-*');
num_subjs  = length(list_subjs);
disp([num2str(num_subjs), ' subjects found']);

%% Prepare summary file
fid_summary_name = fullfile(out_dir, ['param_check_summary_', acq_catg, '_', ...
    datestr(now, 'ddmmmyyyy'), '.txt']);
if exist(fid_summary_name, 'file')
    fid_summary = fopen(fid_summary_name, 'a');
else
    fid_summary = fopen(fid_summary_name, 'w');
end
fprintf(fid_summary, '%s\r\n', ['Date:         ', datestr(now, 'ddmmmyyyy')]);
fprintf(fid_summary, '%s\r\n', ['Time:         ', datestr(now, 'HH:MM:SS PM')]);
fprintf(fid_summary, '%s\r\n', ['nifti_dir:    ', nifti_dir]);
fprintf(fid_summary, '%s\r\n', ['ficom_dir:    ', dicom_dir]);
fprintf(fid_summary, '%s\r\n', ['out_dir:      ', out_dir]);
fprintf(fid_summary, '%s\r\n', ['dcm2niix_dir: ', dcm2niix_dir]);
fprintf(fid_summary, '%s\r\n', ['acq_catg:     ', acq_catg]);
fprintf(fid_summary, '%s\r\n', [num2str(num_subjs), ' subjects found']);

%% Initialize table for pooling subject information
if strcmpi(search_term, 'rest')
    subj_info = cell2table(cell(num_subjs, 9));
    subj_info.Properties.VariableNames = ...
        {'subj_ID', 'DICOM_Name', 'DICOM_Age', 'DICOM_Gender', 'TR', 'TE', ...
        'image_dim', 'voxel_dim', 'num_vols'};
else
    if strcmpi(search_term, 'T1')
        subj_info = cell2table(cell(num_subjs, 8));
        subj_info.Properties.VariableNames = ...
            {'subj_ID', 'DICOM_Name', 'DICOM_Age', 'DICOM_Gender', 'TR', 'TE', ...
            'image_dim', 'voxel_dim'};
    end
end

%% Loop over each subject and work!
for subj = 1:num_subjs
    
    % Output path
    sub_out_dir = fullfile(out_dir, list_subjs(subj).name);
    
    % If output directory exists, skip the subject
    if exist(sub_out_dir, 'dir')
        disp([list_subjs(subj).name, '...skipped']);
        fprintf(fid_summary, '%s\r\n', [list_subjs(subj).name, '...skipped']);
        continue
    else
        
        % Create subject output directory
        mkdir(sub_out_dir);
        
        % Go to subject specific NIfTI folder and find .json file
        cd(fullfile(nifti_dir, list_subjs(subj).name));
        
        switch(search_term)
            case 'T1'
                list_files = dir('*T1*.json');
                
                if isempty(list_files)
                    % Display summary, print into file, and move on
                    disp([list_subjs(subj).name, '...T1w json not found']);
                    fprintf(fid_summary, '%s\r\n', ...
                        [list_subjs(subj).name, '...T1w json not found']);
                else
                    % If multiple files are present, update summary, skip
                    % subject, update table, and move on
                    if length(list_files) > 1
                        disp([list_subjs(subj).name, '...multiple T1 images; skipping']);
                        fprintf(fid_summary, '%s\r\n', [list_subjs(subj).name, '...multiple T1 images; skipping']);
                        subj_info.subj_ID{subj}      = list_subjs(subj).name;
                        subj_info.DICOM_Name{subj}   = 'multiple T1; skipped';
                        subj_info.DICOM_Age{subj}    = 'multiple T1; skipped';
                        subj_info.DICOM_Gender{subj} = 'multiple T1; skipped';
                        subj_info.TR{subj}           = 'multiple T1; skipped';
                        subj_info.TE{subj}           = 'multiple T1; skipped';
                        subj_info.image_dim{subj}    = 'multiple T1; skipped';
                        subj_info.voxel_dim{subj}    = 'multiple T1; skipped';
                    else
                        
                        % Update summary
                        disp([list_subjs(subj).name, '...reading ', list_files.name]);
                        fprintf(fid_summary, '%s',  [list_subjs(subj).name, '...reading ', list_files.name]);
                        
                        % Read .json file
                        fid_json     = fopen(fullfile(nifti_dir, list_subjs(subj).name, list_files.name), 'r');
                        json_content = textscan(fid_json, '%s');
                        
                        % Figure out series number and remove comma at end
                        loc         = strcmpi(json_content{1,1}, '"SeriesNumber":');
                        series_num  = json_content{1,1}{find(loc)+1}(1:end-1);
                        
                        % Close .json file
                        fclose(fid_json);
                        
                        % Attempt to locate series in DICOM folder
                        cd(fullfile(dicom_dir, list_subjs(subj).name, 'DICOM'));
                        
                        % Get master series folder
                        tmp = dir('S*');
                        if length(tmp) > 1
                            
                            % Can't proceed; update summary and table, and move on
                            disp([list_subjs(subj).name,   '...multiple master series; cannot proceed']);
                            fprintf(fid_summary, '%s\r\n', '...multiple master series; cannot proceed');
                            subj_info.subj_ID{subj}      = list_subjs(subj).name;
                            subj_info.DICOM_Name{subj}   = 'multiple master series; skipped';
                            subj_info.DICOM_Age{subj}    = 'multiple master series; skipped';
                            subj_info.DICOM_Gender{subj} = 'multiple master series; skipped';
                            subj_info.TR{subj}           = 'multiple master series; skipped';
                            subj_info.TE{subj}           = 'multiple master series; skipped';
                            subj_info.image_dim{subj}    = 'multiple master series; skipped';
                            subj_info.voxel_dim{subj}    = 'multiple master series; skipped';
                            continue;
                        else
                            cd(tmp.name);
                            series_loc = dir(['*', series_num, '*']);
                            if isempty(series_loc)
                                
                                % Can't find series; update summary and table, and move on
                                disp([list_subjs(subj).name, '...cannot find series ', series_num]);
                                fprintf(fid_summary, '%s\r\n',  ['...cannot find series ', series_num]);
                                subj_info.subj_ID{subj}      = list_subjs(subj).name;
                                subj_info.DICOM_Name{subj}   = 'series not found; skipped';
                                subj_info.DICOM_Age{subj}    = 'series not found; skipped';
                                subj_info.DICOM_Gender{subj} = 'series not found; skipped';
                                subj_info.TR{subj}           = 'series not found; skipped';
                                subj_info.TE{subj}           = 'series not found; skipped';
                                subj_info.image_dim{subj}    = 'series not found; skipped';
                                subj_info.voxel_dim{subj}    = 'series not found; skipped';
                                continue;
                            else
                                % Check if multiple series match the name
                                if length(series_loc)>1
                                    
                                    % Can't proceed; update summary and table, and move on
                                    disp([list_subjs(subj).name, '...multiple series matching ', series_num, ' found; cannot proceed']);
                                    fprintf(fid_summary, '%s\r\n',  ['...multiple series matching ', series_num, ' found; cannot proceed']);
                                    subj_info.subj_ID{subj}      = list_subjs(subj).name;
                                    subj_info.DICOM_Name{subj}   = 'multiple matching series; skipped';
                                    subj_info.DICOM_Age{subj}    = 'multiple matching series; skipped';
                                    subj_info.DICOM_Gender{subj} = 'multiple matching series; skipped';
                                    subj_info.TR{subj}           = 'multiple matching series; skipped';
                                    subj_info.TE{subj}           = 'multiple matching series; skipped';
                                    subj_info.image_dim{subj}    = 'multiple matching series; skipped';
                                    subj_info.voxel_dim{subj}    = 'multiple matching series; skipped';
                                    continue;
                                else
                                    
                                    % Series found; update summary
                                    disp([list_subjs(subj).name, '...found series ', series_num]);
                                    fprintf(fid_summary, '%s', ['...found series ', series_num]);
                                    
                                    % Create the framework of the command
                                    command = ['-b ', bids, ...
                                        ' -z ', gz, ...
                                        ' -p ', precise, ...
                                        ' -t ', text_notes, ...
                                        ' -n ', series_num, ...
                                        ' -f ', outname];
                                    
                                    sub_in_dir = fullfile(dicom_dir, list_subjs(subj).name);
                                    
                                    % Adding output directory and input directory to command
                                    command = [command, ' -o ', sub_out_dir, ' ', sub_in_dir];
                                    
                                    % Check OS and add execution method
                                    if isunix
                                        command = ['./dcm2niix ', command];
                                    else
                                        command = ['dcm2niix.exe ', command];
                                    end
                                    
                                    % Execute the command
                                    cd(dcm2niix_dir);
                                    [status,~] = system(command);
                                    
                                    % Display summary
                                    if status
                                        disp([list_subjs(subj).name, '...conversion error']);
                                        fprintf(fid_summary, '%s',   '...conversion error');
                                        % Update table and move on
                                        subj_info.subj_ID{subj}      = list_subjs(subj).name;
                                        subj_info.DICOM_Name{subj}   = 'conversion error; skipped';
                                        subj_info.DICOM_Age{subj}    = 'conversion error; skipped';
                                        subj_info.DICOM_Gender{subj} = 'conversion error; skipped';
                                        subj_info.TR{subj}           = 'conversion error; skipped';
                                        subj_info.TE{subj}           = 'conversion error; skipped';
                                        subj_info.image_dim{subj}    = 'conversion error; skipped';
                                        subj_info.voxel_dim{subj}    = 'conversion error; skipped';
                                        continue
                                    else
                                        disp([list_subjs(subj).name, '...conversion finished']);
                                        fprintf(fid_summary, '%s',   '...conversion finished');
                                    end
                                    
                                    % Go to subject folder and find the text file(s) created
                                    cd(sub_out_dir);
                                    list_files = dir('*.txt');
                                    
                                    % If no files exist, update summary and
                                    % table variable
                                    if isempty(list_files)
                                        disp([list_subjs(subj).name, '...text file not created']);
                                        fprintf(fid_summary, '%s\r\n', '...text file not created');
                                        subj_info.subj_ID{subj}      = list_subjs(subj).name;
                                        subj_info.DICOM_Name{subj}   = 'text file not found';
                                        subj_info.DICOM_Age{subj}    = 'text file not found';
                                        subj_info.DICOM_Gender{subj} = 'text file not found';
                                        subj_info.TR{subj}           = 'text file not found';
                                        subj_info.TE{subj}           = 'text file not found';
                                        subj_info.image_dim{subj}    = 'text file not found';
                                        subj_info.voxel_dim{subj}    = 'text file not found';
                                        continue;
                                    else
                                        
                                        % If multiple files are present, select the first one
                                        if length(list_files) > 1
                                            list_files = list_files(1);
                                        end
                                        
                                        % Update summary
                                        disp([list_subjs(subj).name, '...reading ', list_files.name]);
                                        fprintf(fid_summary, '%s',  ['...reading ', list_files.name]);
                                        
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
                                        
                                        % Get TR
                                        loc = strcmpi(info{1,1}, 'TR:');
                                        if isempty(find(loc, 1))
                                            subj_info.TR{subj} = 'TR not found';
                                        else
                                            subj_info.TR{subj} = info{1,1}{find(loc)+1};
                                        end
                                        
                                        % Get TE
                                        loc = strcmpi(info{1,1}, 'TE:');
                                        if isempty(find(loc, 1))
                                            subj_info.TE{subj} = 'TE not found';
                                        else
                                            subj_info.TE{subj} = info{1,1}{find(loc)+1};
                                        end
                                        
                                        % Read same name NIfTI file using SPM
                                        [~, txt_name, ~] = fileparts(list_files.name);
                                        header = spm_vol(fullfile(out_dir, list_subjs(subj).name, [txt_name, '.nii']));
                                        data   = spm_read_vols(header);
                                        
                                        % Get image size
                                        img_size = size(data);
                                        subj_info.image_dim{subj} = [num2str(img_size(1)), ' x ', num2str(img_size(2)), ' x ', num2str(img_size(3))];
                                        
                                        % Get voxel size
                                        p = spm_imatrix(header.mat);
                                        vox_size = p(7:9);
                                        subj_info.voxel_dim{subj} = [num2str(vox_size(1)), ' x ', num2str(vox_size(2)), ' x ', num2str(vox_size(3))];
                                        
                                        % Close info file
                                        fclose(fid_info);
                                        
                                        % Update summary
                                        disp([list_subjs(subj).name, '...done!']);
                                        fprintf(fid_summary, '%s\r\n', '...done!');
                                    end
                                end
                            end
                        end
                    end
                end
        end
    end
end
    
    % Close summary file
    fclose(fid_summary);
    
    % Write csv file
    writetable(subj_info, fullfile(out_dir, ...
        ['param_check_', acq_catg, '_', datestr(now, 'ddmmmyyyy_HHMMSS'), '.csv']));