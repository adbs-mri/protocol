function adbs_import_dicom(in_dir, out_dir, log_dir, dcm2niix_dir, precise, gz, outname)
% Function to convert DICOM data to NIfTI using dcm2niix
%% Inputs:
% in_dir:       input directory having subject folders (all subject folders
%               must follow the convention "sub-xxxx"; see Notes)
% out_dir:      output directory where NIfTI data should be exported
%               (subject folders would be automatically created; see Notes)
% log_dir:      directory where conversion logs are written as text files
%               (see Notes for other possibilities)
% dcm2niix_dir: directory where dcm2niix is present
% precise:      whether Philips precise values are to be used or display
%               values (1/0)
% gz:           set to 1 if compressed NIfTI files are needed (1/0)
% outname:      argument for -f part of the command which decides how
%               converted files are named
% 
%% Output:
% If default choices are used, each subject's data would be converted to
% NIfTI and output to the out_dir location. The subejct folders would be
% automatically created while conversion logs would be written to the log
% folder (sub-xxxx_log.txt)
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
%% Defaults:
% precise   = 0;
% gz        = 0;
% outname   = %p;
% 
%% Author(s)
% Parekh, Pravesh
% Bhalerao, Gaurav
% February 22, 2018
% ADBS

%% Check input
