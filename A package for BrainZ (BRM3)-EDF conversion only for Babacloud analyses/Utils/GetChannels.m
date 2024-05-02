%--------------------------------------------------------------------------
function [channel_labels, FileIndex] = GetChannels(Index)
nFiles = length(Index.FileDescription);
EEGChannels = {};
for i = 1:nFiles
    AllFileNames{i} = Index.FileDescription{i}{2,2};
    AllFileIndex(i) = i;
    if strncmp(Index.FileDescription{i}{2,2},'DATA_RAW_EEG_',13)
        str = Index.FileDescription{i}{2,2}(14:end);
        idcs = strfind(str,'_');
        if ~isempty(idcs)
            EEGChannels{length(EEGChannels) + 1} = str(1:idcs-1);
        else
            EEGChannels{length(EEGChannels) + 1} = str(1:end-4);
        end
    end
end

channels = unique(EEGChannels);
channel_labels = {};
for i = 1:length(channels)
    if strncmp(channels{i},'LEFT',4)
        channel_labels{length(channel_labels) + 1} = channels{i};
    elseif strncmp(channels{i},'RIGHT',5)
        channel_labels{length(channel_labels) + 1} = channels{i};
    elseif strncmp(channels{i},'CROSSHEAD',9)
        channel_labels{length(channel_labels) + 1} = channels{i};
    end
end

FileIndex = [];
for j = 1:length(channel_labels)
    labelTOFind = ['DATA_RAW_EEG_' channel_labels{j}];
    inIndex = [];
    for i = 1:nFiles
        if strncmp(AllFileNames{i},labelTOFind,length(labelTOFind))
            inIndex = [inIndex i];
        end
    end
    FileIndex = [FileIndex; inIndex];
end
end
%--------------------------------------------------------------------------