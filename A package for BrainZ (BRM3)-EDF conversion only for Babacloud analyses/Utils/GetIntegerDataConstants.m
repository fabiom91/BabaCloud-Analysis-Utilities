% John O' Toole, 11/2006.
function [integerRange, NominalGain, doubleRange] = ...
    GetIntegerDataConstants(File, Device);

integerRange=[]; NominalGain=[]; doubleRange=[];
iLeft = 1; iRight=2;

if( ~isempty(Device) )
  if( strcmpi(GetParameterValue( Device.Channel{2},'ID' ), 'Left') )
    iLeft = 2; iRight = 1;
  end


  % Get Gain value for Device.xml file...
  if( strcmpi( GetParameterValue(File, 'ChannelTitle'), 'Left' ) )
    NominalGain = GetParameterValue(Device.Channel{iLeft}, 'Gain');
  else
    NominalGain = GetParameterValue(Device.Channel{iRight}, 'Gain');
  end
  NominalGain = str2num( NominalGain );


  integerRange = 2^15-1;
  doubleRange  = 5e6/NominalGain/2;
end


