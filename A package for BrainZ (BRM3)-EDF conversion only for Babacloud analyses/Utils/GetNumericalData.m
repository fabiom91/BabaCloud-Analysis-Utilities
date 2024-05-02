%--------------------------------------------------------------------------
function Data = GetNumericalData(File,Device)

fp = fopen(File{2,2}, 'rb');
% File

switch File{1,2}
    case 'FloatMappedToInt16'
        [integerRange, NominalGain, doubleRange] = ...
            GetIntegerDataConstants(File,Device);

        if( isempty(integerRange) )
            integerRange = 2^15-1;
            NominalGain = 2365;
            doubleRange  = 5e6/NominalGain/2;
        end

        Data = fread(fp, [1, inf], 'int16')' * doubleRange / integerRange;
    case 'Int16'
        Data = fread(fp, [1, inf], 'int16')';
    case 'Float32'
        Data = fread(fp, [1, inf], 'float32')';
    otherwise
        error('Unrecognized file format %s', File{1,2});
end

fclose(fp);
end
%--------------------------------------------------------------------------
