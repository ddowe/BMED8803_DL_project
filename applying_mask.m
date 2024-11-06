clear;

% Parent directory containing all runs
parent_dir = 'C:\Users\sdabiri\OneDrive - Georgia Institute of Technology\BMED 8803 - Stat ML for Neural data\Project\preprocessed\s05';

% Directory containing the left and right EC masks
mask_dir = 'C:\Users\sdabiri\OneDrive - Georgia Institute of Technology\BMED 8803 - Stat ML for Neural data\Project\Small_Dataset\s05';

% File names for the left and right EC masks
left_mask = fullfile(mask_dir, 'r_LEC.nii');
right_mask = fullfile(mask_dir, 'r_REC.nii');

% Load the left and right EC masks
left_mask_vol = spm_vol(left_mask);
left_mask_data = spm_read_vols(left_mask_vol);

right_mask_vol = spm_vol(right_mask);
right_mask_data = spm_read_vols(right_mask_vol);

% Combine the left and right masks into one
combined_mask_data = (left_mask_data > 0) | (right_mask_data > 0); % Logical OR to combine
combined_mask_data = double(combined_mask_data); % Convert to double for compatibility

% Save the combined mask temporarily as a NIfTI file for resampling
combined_mask_vol = left_mask_vol; % Copy metadata from one of the mask volumes
combined_mask_vol.fname = fullfile(mask_dir, 'combined_mask.nii');
spm_write_vol(combined_mask_vol, combined_mask_data);

% Resample the combined mask to match the dimensions of a single smoothed image
% Identify one sample smoothed image file for resampling
sample_smooth_dir = fullfile(parent_dir, 'run001_8', 'smooth');
sample_smooth_file = dir(fullfile(sample_smooth_dir, 's*.nii')); % Assuming there is at least one file
sample_smooth_vol = spm_vol(fullfile(sample_smooth_dir, sample_smooth_file(1).name));

% Reslice the combined mask to match this sample smoothed image
flags = struct('mean', false, 'which', 1, 'interp', 0);
spm_reslice({sample_smooth_vol.fname, combined_mask_vol.fname}, flags);

% Load the resliced mask for use in all subsequent masking operations
resliced_mask_file = fullfile(mask_dir, 'combined_mask.nii');
resliced_mask_data = spm_read_vols(spm_vol(resliced_mask_file));

% Get a list of all run subdirectories
run_dirs = dir(fullfile(parent_dir, 'run*'));

% Loop over each run directory
for i = 1:length(run_dirs)
    % Define the path to the current run’s smooth folder
    smooth_dir = fullfile(parent_dir, run_dirs(i).name, 'smooth');
    
    % Check if the smooth directory exists
    if ~exist(smooth_dir, 'dir')
        warning('Smooth directory not found for %s. Skipping...', run_dirs(i).name);
        continue;
    end
    
    % Define an output directory within the current run's folder
    run_output_dir = fullfile(parent_dir, run_dirs(i).name, 'masked_outputs');
    if ~exist(run_output_dir, 'dir')
        mkdir(run_output_dir);
    end
    
    % Get a list of all smoothed images in the smooth folder
    smoothed_files = dir(fullfile(smooth_dir, 's*.nii')); % Update prefix if necessary
    smoothed_files = fullfile(smooth_dir, {smoothed_files.name});
    
    % Process each smoothed file in the current run
    for j = 1:length(smoothed_files)
        % Load the smoothed image
        smoothed_vol = spm_vol(smoothed_files{j});
        smoothed_data = spm_read_vols(smoothed_vol);
        
        % Debugging step: Check dimensions of the resliced mask and smoothed image
        disp('Dimensions of smoothed image:');
        disp(size(smoothed_data));
        
        disp('Dimensions of resliced mask:');
        disp(size(resliced_mask_data));
        
        % Apply the mask if dimensions match, otherwise display an error message
        if all(size(smoothed_data) == size(resliced_mask_data))
            masked_data = smoothed_data .* resliced_mask_data;
        else
            error('Dimension mismatch: Smoothed image and resliced mask have incompatible sizes.');
        end
        
        % Save the masked image
        [~, filename, ext] = fileparts(smoothed_files{j});
        output_file = fullfile(run_output_dir, ['ECmasked_' filename ext]);
        
        masked_vol = smoothed_vol; % Copy metadata from original
        masked_vol.fname = output_file;
        spm_write_vol(masked_vol, masked_data);
    end
    
    disp(['Masking complete for ' run_dirs(i).name '. Output saved in ' run_output_dir]);
end

% Delete the temporary combined mask file
delete(combined_mask_vol.fname);

disp('All runs processed. Check each run folder for the masked_outputs directory.');
