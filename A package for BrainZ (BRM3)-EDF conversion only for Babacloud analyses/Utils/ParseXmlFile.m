%Brainz Matlab m file end user licence agreement

%Copyright 2005 by Brainz
%You are licensed to use and modify the BRM file matlab files with the following %restrictions

%This end user agreement must remain in all files
%The files and any files derived may be used for research only
%Brainz Instruments is not responsible for decision based on the use of these files.


function Index = ParseXmlFile(FileName, FilePath)

% OldPath = pwd;
% 
% if nargin == 0
%     [FileName, FilePath] = uigetfile({'*.xml', 'XML Files'}, 'Select File');
% elseif nargin == 1
%     FilePath = pwd;
% else
%     cd(FilePath);
% end

try
    Document    = xmlread([FileName]);
    DocTitle    = Document.getFirstChild;
    PreNode     = DocTitle.getFirstChild;
    ThisNode    = PreNode.getNextSibling;
catch
    Index = [];
    return;
end

i = 0;
k = 0;

while 1
    i = i + 1;
    Name{i}   = char(ThisNode.getNodeName);
    Value{i}  = char(ThisNode.getTextContent);

    try
        TestNode = ThisNode.getFirstChild;
        TestNode = TestNode.getNextSibling;
        TestNode = TestNode.getNextSibling;
        k = k + 1;        
        NodeDetails = GetSubNode(ThisNode);         
        Index.(Name{i}){k} = NodeDetails;        
    catch     
        Index.(Name{i}) = Value{i};
    end
    


    try
        PreNode = ThisNode.getNextSibling;
    catch
        return;
    end;
  
    try
        ThisNode = PreNode.getNextSibling;
        
        if isempty(ThisNode)
            return;
        end
    catch
        return;
    end
end

% cd(OldPath);
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
function NodeDetails = GetSubNode(SubDocument)

PreNode     = SubDocument.getFirstChild;
ThisNode    = PreNode.getNextSibling;

i = 0;

while 1
    i = i + 1;
    NodeDetails{i, 1} = char(ThisNode.getNodeName);
    NodeDetails{i, 2} = char(ThisNode.getTextContent);
    
    try
        PreNode = ThisNode.getNextSibling;
    catch
        return;
    end
    
    try
        ThisNode = PreNode.getNextSibling;
        
        if isempty(ThisNode)
            return;
        end
    catch
        return;
    end
end
%--------------------------------------------------------------------------