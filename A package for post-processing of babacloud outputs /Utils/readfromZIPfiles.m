%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ZIPcontent] = readfromZIPfiles(to_its_zip, tmp_folder, SubjectID)
% Extract information from ZIP file
extractFile(to_its_zip,tmp_folder, [SubjectID '_Classifiers_result.csv']);
M = readtable([tmp_folder SubjectID '_Classifiers_result.csv'],'Delimiter',{';'},'NumHeaderLines',0,'VariableNamingRule','preserve');
delete([tmp_folder SubjectID '_Classifiers_result.csv'])

f_seizure = find(strncmp(M{:,1},'Seizures',8));
f_artifact = find(strncmp(M{:,1},'Artefacts',9));
f_BSN = find(strcmp(M{:,1},'BSN overall'));
f_LBSN = find(strcmp(M{:,1},'LBSN overall'));
f_UBSN = find(strcmp(M{:,1},'UBSN overall'));
f_red = find(strcmp(M{:,1},'R'));
f_green = find(strcmp(M{:,1},'G'));
f_blue = find(strcmp(M{:,1},'B'));
f_SST = find(strncmp(M{:,1},'SST overall',11));
f_USST = find(strncmp(M{:,1},'USST',4));
f_LSST = find(strncmp(M{:,1},'LSST',4));

ZIPcontent.seizures = [str2num(M{f_seizure+1,1}{1}) table2array(M(f_seizure+1,2:end))];

artifacts_ch = [];
for N_CHs = 2:2:f_BSN - 1 - f_artifact
    artifacts_ch = [artifacts_ch; [str2num(M{f_artifact+N_CHs,1}{1}) table2array(M(f_artifact+N_CHs,2:end))]];
end
ZIPcontent.artifacts = [artifacts_ch];

ZIPcontent.BSNs = [str2num(M{f_BSN+1,1}{1}) table2array(M(f_BSN+1,2:end))];
BSNs_CH = [];
for N_CHs = 3:2:f_LBSN - f_BSN
    BSNs_CH = [BSNs_CH; [str2num(M{f_BSN+N_CHs,1}{1}) table2array(M(f_BSN+N_CHs,2:end))]];
end
ZIPcontent.BSNs_CH = [BSNs_CH];

ZIPcontent.LBSNs = [str2num(M{f_LBSN+1,1}{1}) table2array(M(f_LBSN+1,2:end))];
LBSNs_CH = [];
for N_CHs = 3:2:f_UBSN - f_LBSN
    LBSNs_CH = [LBSNs_CH; [str2num(M{f_LBSN+N_CHs,1}{1}) table2array(M(f_LBSN+N_CHs,2:end))]];
end
ZIPcontent.LBSNs_CH = [LBSNs_CH];

ZIPcontent.UBSNs = [str2num(M{f_UBSN+1,1}{1}) table2array(M(f_UBSN+1,2:end))];
UBSNs_CH = [];
for N_CHs = 3:2:f_red - f_UBSN - 1
    UBSNs_CH = [UBSNs_CH; [str2num(M{f_UBSN+N_CHs,1}{1}) table2array(M(f_UBSN+N_CHs,2:end))]];
end
ZIPcontent.UBSNs_CH = [UBSNs_CH];


ZIPcontent.BSNColor_r = [str2num(M{f_red+1,1}{1}) table2array(M(f_red+1,2:end))];
ZIPcontent.BSNColor_g = [str2num(M{f_green+1,1}{1}) table2array(M(f_green+1,2:end))];
ZIPcontent.BSNColor_b = [str2num(M{f_blue+1,1}{1}) table2array(M(f_blue+1,2:end))];
ZIPcontent.SSTs = [str2num(M{f_SST+1,1}{1}) table2array(M(f_SST+1,2:end))];
ZIPcontent.USSTs = [str2num(M{f_USST+1,1}{1}) table2array(M(f_USST+1,2:end))];
ZIPcontent.LSSTs = [str2num(M{f_LSST+1,1}{1}) table2array(M(f_LSST+1,2:end))];

% extractFile(to_its_zip,tmp_folder, [SubjectID  '_Classifiers_result_ver10min.csv']);
% M_m = readtable([tmp_folder SubjectID '_Classifiers_result_ver10min.csv'],'Delimiter',{';'},'NumHeaderLines',0,'VariableNamingRule','preserve');
% delete([tmp_folder SubjectID '_Classifiers_result_ver10min.csv'])
% 
% if length(M_m{:,1}) > 8
%     if size(M_m,2) >= 2
% 
%         f = find(strcmp(M_m{:,1},'BSN overall'));
%         ZIPcontent.BSNs_10min = [str2num(M_m{f+1,1}{1}) table2array(M_m(f+1,2:end))];
% 
%         f = find(strcmp(M_m{:,1},'UBSN overall'));
%         ZIPcontent.UBSNs_10min = [str2num(M_m{f+1,1}{1}) table2array(M_m(f+1,2:end))];
% 
%         f = find(strcmp(M_m{:,1},'LBSN overall'));
%         ZIPcontent.LBSNs_10min = [str2num(M_m{f+1,1}{1}) table2array(M_m(f+1,2:end))];
% 
%         f = find(strcmp(M_m{:,1},'R'));
%         ZIPcontent.BSNColor_10min_r = [str2num(M_m{f+1,1}{1}) table2array(M_m(f+1,2:end))];
% 
%         f = find(strcmp(M_m{:,1},'G'));
%         ZIPcontent.BSNColor_10min_g = [str2num(M_m{f+1,1}{1}) table2array(M_m(f+1,2:end))];
% 
%         f = find(strcmp(M_m{:,1},'B'));
%         ZIPcontent.BSNColor_10min_b = [str2num(M_m{f+1,1}{1}) table2array(M_m(f+1,2:end))];
%     else
%         ZIPcontent.BSNs_10min = [M_m{1,1}];
%         ZIPcontent.UBSNs_10min = [M_m{3,1}];
%         ZIPcontent.LBSNs_10min = [M_m{5,1}];
%         ZIPcontent.BSNColor_10min_r = [M_m{10,1}];
%         ZIPcontent.BSNColor_10min_g = [M_m{12,1}];
%         ZIPcontent.BSNColor_10min_b = [M_m{14,1}];
%     end
% else
% 
%     ZIPcontent.BSNs_10min = [NaN(1,1)];
%     ZIPcontent.UBSNs_10min = [NaN(1,1)];
%     ZIPcontent.LBSNs_10min = [NaN(1,1)];
%     ZIPcontent.BSNColor_10min_r = [NaN(1,1)];
%     ZIPcontent.BSNColor_10min_g = [NaN(1,1)];
%     ZIPcontent.BSNColor_10min_b = [NaN(1,1)];
% end
% 
% extractFile(to_its_zip,tmp_folder, [SubjectID '_Classifiers_result_ver60min.csv']);
% M_h = readtable([tmp_folder SubjectID '_Classifiers_result_ver60min.csv'],'Delimiter',{';'},'NumHeaderLines',0,'VariableNamingRule','preserve');
% delete([tmp_folder SubjectID '_Classifiers_result_ver60min.csv'])
% 
% if length(M_h{:,1}) > 8
%     if size(M_h,2) >= 2
%         f = find(strcmp(M_h{:,1},'BSN overall'));
%         ZIPcontent.BSNs_60min = [str2num(M_h{f+1,1}{1}) table2array(M_h(f+1,2:end))];
% 
%         f = find(strcmp(M_h{:,1},'UBSN overall'));
%         ZIPcontent.UBSNs_60min = [str2num(M_h{f+1,1}{1}) table2array(M_h(f+1,2:end))];
% 
%         f = find(strcmp(M_h{:,1},'LBSN overall'));
%         ZIPcontent.LBSNs_60min = [str2num(M_h{f+1,1}{1}) table2array(M_h(f+1,2:end))];
% 
%         f = find(strcmp(M_h{:,1},'R'));
%         ZIPcontent.BSNColor_60min_r = [str2num(M_h{f+1,1}{1}) table2array(M_h(f+1,2:end))];
% 
%         f = find(strcmp(M_h{:,1},'G'));
%         ZIPcontent.BSNColor_60min_g = [str2num(M_h{f+1,1}{1}) table2array(M_h(f+1,2:end))];
% 
%         f = find(strcmp(M_h{:,1},'B'));
%         ZIPcontent.BSNColor_60min_b = [str2num(M_h{f+1,1}{1}) table2array(M_h(f+1,2:end))];
%     else
%         ZIPcontent.BSNs_60min = [M_h{1,1}];
%         ZIPcontent.UBSNs_60min = [M_h{3,1}];
%         ZIPcontent.LBSNs_60min = [M_h{5,1}];
%         ZIPcontent.BSNColor_60min_r = [M_h{10,1}];
%         ZIPcontent.BSNColor_60min_g = [M_h{12,1}];
%         ZIPcontent.BSNColor_60min_b = [M_h{14,1}];
%     end
% else
% 
%     ZIPcontent.BSNs_60min = [NaN(1,1)];
%     ZIPcontent.UBSNs_60min = [NaN(1,1)];
%     ZIPcontent.LBSNs_60min = [NaN(1,1)];
%     ZIPcontent.BSNColor_60min_r = [NaN(1,1)];
%     ZIPcontent.BSNColor_60min_g = [NaN(1,1)];
%     ZIPcontent.BSNColor_60min_b = [NaN(1,1)];
% end
end
