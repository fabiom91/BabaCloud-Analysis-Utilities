% Reads the MAT files containing BabaCloud analysis outputs at a 2-second 
% resolution and adjusts the BSN resolution to longer intervals by 
% incorporating information from artifact classifier and seizure detector.
% This results in smoother BSN values. However, some NaN values may represent 
% BSNs affected by an excessive amount of artifacts or seizures in that segment.
%
% If there are multiple files for one subject, concatenate their BabaCloud 
% analysis outputs at a 2-second resolution by adding gaps with NaN values 
% before using this script.
%
% Author: Saeed Montazeri
% Affiliation: BabaCentre, University of Helsinki
% Date: 19.12.2023

% Note: t=0 marks the start of the recording.

clc; close all;clear all;

UtilPwd = 'Utils/';
addpath(UtilPwd)

% Fill this part
ZIPcontent = './ZIPcontent/'; %BABACloud analysis outputs, one file per subject
saveto = './BSNs/'; %Save extracted BSNs into

% List MAT files in the folder
files = findMATFiles(ZIPcontent);

% Main
for i = 1:length(files)
    disp(['Pocessing: ' files{i}])
    
    % This line reads and extracts all the results stored in the zip file
    load([ZIPcontent files{i}]);

    % Specify the time resolution for the new BSN (currently set to 1 hour)
    % BabaCloud outputs correspond to each 2-second non-overlapping window
    % of EEG data. The window length should be larger than 2 seconds.
    windowlength = 1800; % 60 (min) * 60 (second) * 0.5 (sample/second);

    selectedChannel = 'all'; % Set to 'all' for all channels or specify the 
    % raw index of specific channels. Example:
    % selectedChannel = [1,4];

    BSN_newRes = changeBSNres(analysesOuts, windowlength, selectedChannel);

    % Save the extracted information
    save([saveto files{i}(1:end-4) '_BSN.mat'], 'BSN_newRes')
end

rmpath(UtilPwd)
