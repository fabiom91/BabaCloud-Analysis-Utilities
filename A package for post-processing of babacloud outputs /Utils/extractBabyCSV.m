function [extractedCSV, babyID] = extractBabyCSV(zipFilename, tmp_folder)
% extractBabyCSV extracts a CSV file matching the pattern
%   '^\d+_Classifiers_result\.csv$'
% from the given zip file, and returns the full path to the extracted file 
% along with the baby ID (the digits at the start of the file name).
%
% Inputs:
%   zipFilename - Full path to the ZIP file.
%   tmp_folder  - Folder where the file will be extracted.
%
% Outputs:
%   extractedCSV - Full path to the extracted CSV file.
%   babyID       - Baby ID extracted from the file name.
    
    % Create Java File and ZipFile objects.
    zipJavaFile = java.io.File(zipFilename);
    zipFile = org.apache.tools.zip.ZipFile(zipJavaFile);

    entryFound = false;
    entries = zipFile.getEntries;
    while entries.hasMoreElements()
        entry = entries.nextElement();
        entryName = char(entry.getName());
        % Get only the file name (ignore any subdirectory paths).
        [~, name, ext] = fileparts(entryName);
        fileName = [name, ext];
        % Match pattern: one or more digits followed by _Classifiers_result.csv
        tokens = regexp(fileName, '^(\d+)_Classifiers_result\.csv$', 'tokens');
        if ~isempty(tokens)
            babyID = tokens{1}{1};
            extractedCSV = fullfile(tmp_folder, fileName);
            % Create the output directory if it does not exist.
            parentDir = fileparts(extractedCSV);
            if ~exist(parentDir, 'dir')
                mkdir(parentDir);
            end
            % Extract the file using Java streams.
            fileOutputStream = java.io.FileOutputStream(java.io.File(extractedCSV));
            fileInputStream = zipFile.getInputStream(entry);
            streamCopier = com.mathworks.mlwidgets.io.InterruptibleStreamCopier.getInterruptibleStreamCopier;
            streamCopier.copyStream(fileInputStream, fileOutputStream);
            fileOutputStream.close;
            entryFound = true;
            break;
        end
    end
    zipFile.close;
