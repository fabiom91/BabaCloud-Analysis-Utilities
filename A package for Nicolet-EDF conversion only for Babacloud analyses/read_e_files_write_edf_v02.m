%% read_e_files_write_edf_v02.m
% This script reads EEG signal from e file, makes bipolar montages,
% and saves the results in EDF
%
%
% Saeed Montazeri M.
% Jan 16, 2023
% Last update : Feb 14, 2023
% Copyright © 2022, BABA Centre, University of Helsinki, Finland
% (https://www.babacenter.fi)

clc; close all;clear all;

% Paths to the EEG recordings, e files
EEGFile = '../EEG in e/';

% Export the EDF file into
saveTo = '../EEG in EDF/';

% Save the gap info between pauses
saveGaps = '../Gaps extracted form e files/';

% Initialization
Lead = {'F3','F4','F3','P3'};
Ref = {'P3','P4','F4','P4'};
channel_labels = {'F3-P3','F4-P4','F3-F4','P3-P4'};

% FIND .e files in current directory
aa = dir(EEGFile);
fn1 = {aa.name};
dirn = aa.folder;
fn2 = {}; c1 = 1;
for ii = 1:length(fn1)
    dum = fn1{ii};
    sr = strfind(dum, '.e');
    if isempty(sr)==0 & sr==length(dum)-1
        fn2{c1}  = dum; c1 = c1+1';
    end
end

% do for all valid e files
for ii = 1:length(fn2)

    disp(fn2{ii})
    % Process starts
    % READ IN FILE
    obj=NicoletFile([EEGFile fn2{ii}]);
    obj.fileName = [EEGFile fn2{ii}];
    slen = length(obj.segments);

    recDate = []; recTime = [];
    lab = {}; fdum = []; tstart = zeros(1,slen); tduration = tstart;
    for s = 1:slen
        tstart(s) = datenum(obj.segments(s).dateStr); % days since 0 AD
        tduration(s) = obj.segments(s).duration; % in seconds
        lab = [lab obj.segments(s).chName];
        fdum = [fdum obj.segments(s).samplingRate];
        recDate = [recDate; obj.segments(s).startDate];
        recTime = [recTime; obj.segments(s).startTime];
    end
    str = unique(lab(fdum>100), 'stable');
    disp(str)

    t0 = datetime([],[],[],[],[],[]);
    for s = 1:slen
        t0(s) = datetime([recDate(s,:) recTime(s,:)],'Format','dd.MM.yy HH:mm:ss');
    end
    [~, idx] = sort(t0);
    for kk = 1 : slen-1
        lenOfRec = tduration(idx(kk));
        gapvec = datevec(round((t0(idx(kk+1))-(t0(idx(kk))+seconds(lenOfRec)))));
        gap(kk,:) = gapvec;
        clear gapvec lenOfRec
    end
    dt = t0(idx(1));
    dates = recDate(idx,:);
    times = recTime(idx,:);
    recduration = tduration(idx);
    datetimes = t0;
    ids = idx;
    fnx = [saveGaps fn2{ii}(1:end-2) '.mat'];
    if slen ~= 1
        save(fnx,'gap','dt','dates','times','datetimes','ids','recduration')
    else
        save(fnx,'dt','dates','times','datetimes','ids','recduration')
    end
    clear gap dt datetimes ids

    % GET DATA
    for s = 1:slen

        location = [];
        for ijstr = 1:length(str)
            if ~isempty(str{ijstr})
                if length(str{ijstr}) <= 3 && (str{ijstr}(1) == 'F' || str{ijstr}(1) == 'P' || ...
                        str{ijstr}(1) == 'C' || str{ijstr}(1) == 'T' || str{ijstr}(1) == 'O')
                    location = [location ijstr];
                else
                    str{ijstr} = [];
                end
            end
        end
        scx = zeros(1,length(str)); % better selection of scale to fix scaling problem
        a=getNrSamples(obj, s);
        data = cell(1,length(a));
        for jj = 1:length(a)
            data{jj}=getdata(obj, s, [1 a(jj)], jj);
        end
        fs = obj.segments(s).samplingRate;
        label=obj.segments(s).chName;
        fref = find(fs<=100); for zz = 1:length(fref); label{fref(zz)} = ' '; end
        data_mont = int16(zeros(length(str), length(data{1})));
        sc = obj.segments(s).scale;
        % read in channels as per outlined in str variable above
        for jj = 1:length(str)
            qq1 = zeros(1, length(label));
            for kk = 1:length(label)
                qq1(kk) = strcmp(label{kk}, str{jj});
            end
            %qq1 = contains(label, str{jj}); use strcmp instead
            qq2 = fs>100;
            qq0 = qq1 & qq2;
            if sum(qq0)==1
                scx(jj) = sc(qq0==1); % fix scaling problem
                data_mont(jj,:) = data{qq0==1}./sc(qq0==1);
                fs2(jj) = fs(qq0==1);
            end
        end
        clear data

        if size(data_mont,2) > 60*fs2(1) % at least 1min of recording exist in the file

            selectChs = [];
            for ich = 1 : length(channel_labels)
                Ch1 = find(strncmp(Lead{ich},str,length(Lead{ich})));
                Ch2 = find(strncmp(Ref{ich},str,length(Ref{ich})));

                if fs2(Ch1) ~= fs2(Ch2)
                    error('Recordings pause-start with different fs')
                end
                if scx(Ch1) ~= scx(Ch2)
                    error('Recordings pause-start with different scale')
                end

                scxn = scx(Ch1);
                selectChs(ich,:) = ((double(data_mont(Ch1,:))*scx(Ch1)) - (double(data_mont(Ch2,:))*scx(Ch2)))./scxn;
            end
            clear data_mont

            % clear fs
            len = length(selectChs)/fs2(Ch1);
            if floor(len) ~= len
                error('Wrong length of data')
            end
            % Write the EDF header
            hdrf = cell(1,11);
            hdrf{1} = ['0'; char(32*ones(167,1));...
                [sprintf('%02d',recDate(s,3)),'.',sprintf('%02d',recDate(s,2)),'.',sprintf('%02d',recDate(s,1)-2000)]';...
                [sprintf('%02d',recTime(s,1)),'.',sprintf('%02d',recTime(s,2)),'.',sprintf('%02d',recTime(s,3))]';['1792    ']';...
                char(32*ones(44,1)); num2str(len)' ; char(32*ones(8-length(num2str(len)),1)); '1'; char(32*ones(7,1));...
                num2str(length(channel_labels))'; char(32*ones(4-length(num2str(length(channel_labels))),1))];

            digitalMin = -(32768);
            digitalMax = (32768)-1;

            for ich = 1 : length(channel_labels)
                val2 = digitalMax*(scxn);
                val1 = digitalMin*(scxn);

                hdrf{2} = [hdrf{2};channel_labels{ich}';char(32*ones(16-length(channel_labels{ich}),1))];
                hdrf{3} = [hdrf{3};char('AgAgCl')';char(32*ones(74,1))];
                hdrf{4} = [hdrf{4};char('uV')';char(32*ones(6,1))];

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
                hdrf{10} = [hdrf{10}; num2str(fs2(Ch1))';char(32*ones(8-length(num2str(fs2(Ch1))),1))];
                hdrf{11} = [hdrf{11}; char(32*ones(32,1))];
            end
            lenHdr = length(hdrf{1})+length(hdrf{2})+length(hdrf{3})+length(hdrf{4})+length(hdrf{5})+...
                length(hdrf{6})+length(hdrf{7})+length(hdrf{8})+length(hdrf{9})+length(hdrf{10})+length(hdrf{11});
            hdrf{1}(185:192) = [num2str(lenHdr)' ; char(32*ones(8-length(num2str(lenHdr)),1))];

            % Write file
            disp('Writing EDF .../')
            dum1 = write_edf([saveTo fn2{ii}(1:end-2) '_' num2str(s) '.edf'], int16(selectChs), hdrf, size(selectChs,1), fs2(Ch1));
            clear hdrf selectChs

            clear  fs2 scx fs qq0 qq1 qq2 label
        end
    end
end
