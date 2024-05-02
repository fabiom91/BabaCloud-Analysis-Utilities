% Is correct ??

% John O' Toole, 11/2006.
function dstr = ReBRM2MatlabDate( time )

dstr = datestr( str2num(time) / (24*60*60) + datenum('1-Jan-1970'));
