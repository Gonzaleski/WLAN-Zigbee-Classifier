function labelStats = checkLabelStats(folderPath, classNames)
    % Initialize counts
    numClasses = numel(classNames);
    labelCounts = zeros(numClasses,1);

    % Find all label files recursively
    labelFiles = dir(fullfile(folderPath, '**', '*.hdf'));
    fprintf('Found %d label files inside %s (including subfolders)\n', length(labelFiles), folderPath);

    for k = 1:length(labelFiles)
        % Load label image data from .hdf file
        filePath = fullfile(labelFiles(k).folder, labelFiles(k).name);
        data = imread(filePath);
        
        % Count pixels per label (pixel values assumed to be uint8 labels scaled to class indices)
        for c = 1:numClasses
            % Map class index to pixel value
            pixelValue = floor((c-1)*255/(numClasses-1));
            labelCounts(c) = labelCounts(c) + sum(data(:) == pixelValue);
        end
    end

    % Display results
    fprintf('Label counts summary:\n');
    for c = 1:numClasses
        fprintf('%10s: %d pixels\n', classNames(c), labelCounts(c));
    end
    
    labelStats = labelCounts;
end
