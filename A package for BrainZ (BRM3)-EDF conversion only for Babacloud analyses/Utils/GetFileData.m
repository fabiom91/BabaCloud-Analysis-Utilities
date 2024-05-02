%--------------------------------------------------------------------------
function Data = GetFileData(File,Device)
DAUSampleHz         = 512;

Data.FileType       = GetParameterValue(File, 'FileType');
Data.FileName       = GetParameterValue(File, 'FileName');
Data.DataName       = GetParameterValue(File, 'DataName');
Data.ChannelTitle   = GetParameterValue(File, 'ChannelTitle');
Data.DataTitle      = GetParameterValue(File, 'DataTitle');
Data.StartTime      = GetParameterValue(File, 'StartTime');
Data.SampleHz       = DAUSampleHz / str2num(GetParameterValue(File, 'SamplePeriod512thSeconds'));
Data.Units          = GetParameterValue(File, 'Units');
Data.ArchiveLevel   = GetParameterValue(File, 'ArchiveLevel');

Data.Data           = GetNumericalData(File,Device);

if ~isempty(Data.StartTime)
    Data.StartTime = datestr(ReBRM2MatlabDate(Data.StartTime));
else
    Data.StartTime = '';
end

end
%--------------------------------------------------------------------------
