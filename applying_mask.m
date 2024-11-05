% Parent directory containing all runs
parent_dir = 'C:\Users\sdabiri\OneDrive - Georgia Institute of Technology\BMED 8803 - Stat ML for Neural data\Project\preprocessed\s05';

% Directory containing the left and right EC masks
mask_dir = 'C:\Users\sdabiri\OneDrive - Georgia Institute of Technology\BMED 8803 - Stat ML for Neural data\Project\Small_Dataset\s05';

% File names for the left and right EC masks
left_mask = fullfile(mask_dir, 'LEC.nii');
right_mask = fullfile(mask_dir, 'REC.nii');

% Load the left and right EC masks
left_mask_vol = spm_vol(left_mask);
left_mask_data = spm_read_vols(left_mask_vol);

right_mask_vol = spm_vol(right_mask);
right_mask_data = spm_read_vols(right_mask_vol);

% Combine the left and right masks into one
combined_mask_data = (left_mask_data > 0) | (right_mask_data > 0); % Logical OR to combine
combined_mask_data = double(combined_mask_data); % Convert to double for compatibility

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
        
        % Apply the combined EC mask
        masked_data = smoothed_data .* combined_mask_data;
        
        % Save the masked image
        [~, filename, ext] = fileparts(smoothed_files{j});
        output_file = fullfile(run_output_dir, ['ECmasked_' filename ext]);
        
        masked_vol = smoothed_vol; % Copy metadata from original
        masked_vol.fname = output_file;
        spm_write_vol(masked_vol, masked_data);
    end
    
    disp(['Masking complete for ' run_dirs(i).name '. Output saved in ' run_output_dir]);
end

disp('All runs processed. Check each run folder for the masked_outputs directory.');
