%--------------------------------------------------------------------------
function Value = GetParameterValue(File, Parameter)

i = strmatch(Parameter, char(File{:,1}));

if ~isempty(i)
    Value = File{i,2};
else
    Value = [];
end
%--------------------------------------------------------------------------
