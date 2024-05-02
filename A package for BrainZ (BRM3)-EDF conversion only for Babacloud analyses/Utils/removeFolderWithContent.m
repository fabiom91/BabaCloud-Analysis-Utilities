%--------------------------------------------------------------------------
function removeFolderWithContent(mypath, eChar)
% Remove folder and its complete content.
% All data of the folder has to be closed.
%
% path -> path to folder as string
% get folder content
content = dir(mypath);
for iContent = 3 : numel(content)
    if ~content(iContent).isdir
        % remove files of folder
        delete([mypath eChar content(iContent).name]);
%         delete(sprintf(['%s' eChar '%s'],path,content(iContent).name));
        rehash()
    else
        % remove subfolder
        removeFolderWithContent(sprintf(['%s' eChar '%s'],mypath,content(iContent).name), eChar);
        rmdir(sprintf(['%s' eChar '%s'],mypath,content(iContent).name));
        rehash()
    end
end
end
%--------------------------------------------------------------------------
