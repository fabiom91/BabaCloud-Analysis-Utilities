%% read_BRM3_files_write_edf_v01.m
% This script reads EEG signal from BRM version 3 file, makes bipolar montages,
% and saves the results in EDF
%
%
% Saeed Montazeri M.
% Jan 16, 2024
% Last update : Feb 14, 2024
% Copyright © 2022, BABA Centre, University of Helsinki, Finland
% (https://www.babacenter.fi)

clc; close all;clear all;

UtilPwd = 'Utils/';
addpath(UtilPwd)

% Paths to the EEG recordings, BRM files
FilePath = './';

% Export the EDF file into
saveTo = './';

% FIND .brm files in current directory
aa = dir(FilePath);
fn1 = {aa.name};
dirn = aa.folder;
fn2 = {}; c1 = 1;
for ii = 1:length(fn1)
    dum = fn1{ii};
    sr = strfind(dum, '.brm');
    if isempty(sr)==0 & sr==length(dum)-3
        fn2{c1}  = dum; c1 = c1+1';
    end
end

OldPath = pwd;

% do for all valid e files
for ii = 1:length(fn2)

    % Process starts
    FileName = fn2{ii};

    % Create temporary directory for uncompressing file
    disp('Creating temporary directory.');

    if( isunix )
        AbsTemporaryDirectory = strcat(OldPath, '/tmp/', FileName(1:end-4));
    else
        AbsTemporaryDirectory = strcat(OldPath, '\tmp', FileName(1:end-4));
    end

    % Uncompress selected file into temporary directory
    disp(strcat(['Extracting ' FileName ' to temporary directory.']));

    if( isunix ) eChar = '/'; else eChar = '\'; end
    if strcmp(FilePath(end), eChar)
        unzip(strcat(FilePath, FileName), AbsTemporaryDirectory);
    else
        unzip(strcat(FilePath, eChar, FileName), AbsTemporaryDirectory);
    end
    addpath(AbsTemporaryDirectory);

    try

        %     disp('Reading Patient.xml.');
        %     Patient = ParseXmlFile('Patient.xml');
        disp('Reading Device.xml.');
        Device = ParseXmlFile('Device.xml');
        %
        %     try
        %         disp('Reading DATA_EVENTS.xml.');
        %         Events = ParseXmlFile('DATA_EVENTS.xml');
        %         %Events.SessionStartTime = Patient.SessionStartTime;
        %     catch
        %         disp('No Data Events');
        %         Events = [];
        %     end


        % Obtain directory information
        disp('Reading BRM_Index.xml.');
        Index   = ParseXmlFile('BRM_Index.xml');

        [channel_labels, FileIndex] = GetChannels(Index);

        for irecst = 1:size(FileIndex,2)
            for jrecst = 1:size(FileIndex,1)
                Data(jrecst) = GetFileData(Index.FileDescription{FileIndex(jrecst,irecst)},Device);
            end

            filename_part1 = [fn2{ii}(1:end-4) '_' num2str(irecst)];
            writeToEDF(Data, channel_labels, filename_part1, saveTo);

            clear Data
        end

        clear  Events Patient Device Index FileName
    catch
        disp('***ERROR***. ReadBRM3Files operation cancelled.');
        disp(lasterr);

        Data = []; Events = []; Patient = []; Index = []; FileName = [];
        return;
    end
end

close all; clearvars -except fn2 OldPath eChar
rmpath(UtilPwd)

% Delete temporary directory and all temporary files
for ii = 1:length(fn2)
    
    FileName = fn2{ii};
    if( isunix )
        AbsTemporaryDirectory = strcat(OldPath, '/tmp/', FileName(1:end-4));
    else
        AbsTemporaryDirectory = strcat(OldPath, '\tmp', FileName(1:end-4));
    end
    rmpath(AbsTemporaryDirectory)

    disp('Removing temporary files and directory.');
    disp([' ']);
    delete([AbsTemporaryDirectory eChar '*.*']);
    if exist([AbsTemporaryDirectory eChar 'config']) == 7
        removeFolderWithContent([AbsTemporaryDirectory eChar 'config'], eChar);
        rmdir([AbsTemporaryDirectory eChar 'config']);
        rehash()
    end
    rmdir(AbsTemporaryDirectory);
end







