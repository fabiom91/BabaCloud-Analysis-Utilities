%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function fn2 = findZIPFiles(BABACloudFiles)
% List ZIP files in the folder
aa = dir(BABACloudFiles);
fn1 = {aa.name};
% dirn = aa.folder;
fn2 = {}; c1 = 1;

for ii = 1:length(fn1)
    dum = fn1{ii};
    sr = strfind(dum, '.zip');
    if isempty(sr)==0 & sr==length(dum)-3 & dum(1) ~= '.'
        fn2{c1}  = dum; c1 = c1+1';
    end
end
end