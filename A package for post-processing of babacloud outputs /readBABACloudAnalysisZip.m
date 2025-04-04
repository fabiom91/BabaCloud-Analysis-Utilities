% Extracts information from CSV files within ZIP files of BabaCloud babyEEG analysis.
%
% This routine iterates through all ZIP files in the "BABACloudFiles" folder,
% extracts information from three CSV files in each ZIP, and saves the results
% in MAT files in the "saveto" folder.
%
% CSV Files in Each ZIP:
% 1. "SUBJECTID_Classifiers_result.csv": Provides raw output from all
%    classifiers. Each row with text signifies the algorithm used, such as
%    "BSN_info," indicating that the subsequent rows are from the BSN
%    algorithm. The row with "BSN overall" denotes the BSN calculated and
%    smoothed over all EEG channels. Values represent 2-second epochs of
%    EEG data, with the first column marking the start of the recording.
%
% 2. "SUBJECTID_Classifiers_result_ver10min.csv": Presents post-processed
%    BSN values smoothed over channels for every 10-minute epoch. Values
%    represent 10-minute epochs of EEG data, with the first column marking
%    the start of the recording.
%
% 3. "SUBJECTID_Classifiers_result_ver60min.csv": Displays post-processed
%    BSN values smoothed over channels for every 1-hour epoch. Values
%    represent 1-hour epochs of EEG data, with the first column marking
%    the start of the recording.
%
% Explanation of Rows in "SUBJECTID_Classifiers_result.csv":
% - "Seizures": Outputs from the seizure detector.
% - "Artefacts": Outputs from the artefact detector per channel.
% - "BSN_info": BSN overall and BSN per channel.
% - "LBSN" and "UBSN": Lower and upper confidence interval values for BSN
%    overall and per channel.
% - "BSN Colours": R, G, and B values for visualizing the BSN trend.
% - "SST_info": Sleep state trend, including overall, upper, and lower
%    confidence interval values.
%
% Author: Saeed Montazeri
% Affiliation: BabaCentre, University of Helsinki
% Date: 19.12.2023

% Note1: t=0 marks the start of the recording.
% Note2: BabaCloud outputs correspond to each 2-second non-overlapping window
% of EEG data.

clc; close all;clear all;

UtilPwd = 'Utils/';
addpath(UtilPwd)

% Fill this part
BABACloudFiles = './output/'; % BABACloud analysis outputs, zip files
tmpFolder = './tmp/'; % A folder to save temporary files
saveto = './ZIPcontent/'; % Save extracted data into
% SubjectID is extracted from the results files.
% This also allow multiple babyID in the same folder.
% SubjectID = 'Anonymous'; % Babacloud API default is Anonymous

% List ZIP files in the folder
ZIPFiles = findZIPFiles(BABACloudFiles);

% Main
for i = 1:length(ZIPFiles)
    disp(['Pocessing: ' ZIPFiles{i}])
    % Extracts data from the ZIP and retrieves the baby ID from the CSV filename.
    [analysesOuts, babyID] = readfromZIPfiles([BABACloudFiles ZIPFiles{i}], tmpFolder);

    % Use the zip file name (without extension) as the output file name.
    [~, zipBaseName, ~] = fileparts(ZIPFiles{i});
    outputFile = fullfile(saveto, [zipBaseName '.mat']);
    
    % Save the extracted data
    save(outputFile, 'analysesOuts')
end

rmpath(UtilPwd)

% What is next?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PUT YOUR CODE HERE
% Concatenate all the ZIPFiles from different recordings of one subject. 
% For each 'analysesOuts', concatenate the numeric arrays found within the
% structure. Remember to insert gaps (with NaN values) between the recordings 
% at the 2-second time resolution. 
% Example: for 60 min (=1 h) gap, the gap array is NaN(1,1800). 
% Remember the correct order.
% Example: 
% for i = 1:length(ZIPFiles)
%   for j = 1:length(ZIPFiles{i})
%       Concatenate = [array1 gap array2];
%   end
% end
% Save the concatenated data for further use in the "computeBSNres.m" 
