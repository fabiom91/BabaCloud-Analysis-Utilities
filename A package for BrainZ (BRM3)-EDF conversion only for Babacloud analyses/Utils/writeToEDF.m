%--------------------------------------------------------------------------
function writeToEDF(Data, channel_labels, filename, saveTo)
% READ IN FILE
recDate = []; recTime = []; fs = [];

fs = Data(1).SampleHz;
redt = datevec(datetime(Data(1).StartTime));
recDate = redt(1:3);
recTime = redt(4:end);
data_mont = []; sc = [];
for i = 1: length(channel_labels)
    data_mont = [data_mont; Data(i).Data'];
    sc = [sc 0.3];
end
data_mont = data_mont./sc(1);
dc = mean(data_mont,2);

digitalMin = -(32768);
digitalMax = (32768)-1;

if length(data_mont) > 60*fs(1) % at least 1min of recording must exist in the file

    % clear fs
    len = length(data_mont)/fs(1);
    if floor(len) ~= len
        error('Wrong length of data')
    end
    % Write the EDF header
    hdrf = cell(1,11);
    hdrf{1} = ['0'; char(32*ones(167,1));...
        [sprintf('%02d',recDate(1,3)),'.',sprintf('%02d',recDate(1,2)),'.',sprintf('%02d',recDate(1,1)-2000)]';...
        [sprintf('%02d',recTime(1,1)),'.',sprintf('%02d',recTime(1,2)),'.',sprintf('%02d',recTime(1,3))]';['1792    ']';...
        char(32*ones(44,1)); num2str(len)' ; char(32*ones(8-length(num2str(len)),1)); '1'; char(32*ones(7,1));...
        num2str(length(channel_labels))'; char(32*ones(4-length(num2str(length(channel_labels))),1))];

    for ich = 1 : length(channel_labels)
        hdrf{2} = [hdrf{2};channel_labels{ich}';char(32*ones(16-length(channel_labels{ich}),1))];
        hdrf{3} = [hdrf{3};char('AgAgCl')';char(32*ones(74,1))];
        hdrf{4} = [hdrf{4};char('uV')';char(32*ones(6,1))];

        val2 = dc(ich) + (sc(ich) * digitalMax);
        val1 = -((sc(ich) * (digitalMax - digitalMin)) - val2);

        switch floor(log10(abs(val1)))
            case 4
                hdrf{5} = [hdrf{5}; num2str(val1, '%5.1f')'];
            case 3
                hdrf{5} = [hdrf{5}; num2str(val1, '%4.2f')'];
            case 2
                hdrf{5} = [hdrf{5}; num2str(val1, '%3.3f')'];
            case 1
                hdrf{5} = [hdrf{5}; num2str(val1, '%2.4f')'];
        end

        switch floor(log10(abs(val2)))
            case 4
                hdrf{6} = [hdrf{6}; num2str(val2, '%5.1f')'; char(32)];
            case 3
                hdrf{6} = [hdrf{6}; num2str(val2, '%4.2f')'; char(32)];
            case 2
                hdrf{6} = [hdrf{6}; num2str(val2, '%3.3f')'; char(32)];
            case 1
                hdrf{6} = [hdrf{6}; num2str(val2, '%2.4f')'; char(32)];
        end

        hdrf{7} = [hdrf{7}; num2str(digitalMin)';char(32*ones(2,1))];
        hdrf{8} = [hdrf{8}; num2str(digitalMax)';char(32*ones(3,1))];
        hdrf{9} = [hdrf{9}; char(32*ones(80,1))];
        hdrf{10} = [hdrf{10}; num2str(fs(1))';char(32*ones(8-length(num2str(fs(1))),1))];
        hdrf{11} = [hdrf{11}; char(32*ones(32,1))];
    end
    lenHdr = length(hdrf{1})+length(hdrf{2})+length(hdrf{3})+length(hdrf{4})+length(hdrf{5})+...
        length(hdrf{6})+length(hdrf{7})+length(hdrf{8})+length(hdrf{9})+length(hdrf{10})+length(hdrf{11});
    hdrf{1}(185:192) = [num2str(lenHdr)' ; char(32*ones(8-length(num2str(lenHdr)),1))];

    % Write file
    disp('Writing EDF .../')
    exportFileName = [filename '_' sprintf('%04d%02d%02d%02d%02d%02d', redt) '_' num2str(len) '.edf'];
    dum1 = write_edf([saveTo exportFileName], int16(data_mont), hdrf, size(data_mont,1), fs(1));
    clear hdrf selectChs

    clear  fs2 scx fs qq0 qq1 qq2 label
end
end
%--------------------------------------------------------------------------