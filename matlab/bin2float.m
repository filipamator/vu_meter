function f = bin2float(b)
%This function converts a binary number to a floating point number.
%Because hex2num only converts from hex to double, this function will only
%work with double-precision numbers.
%
%Input: b - string of "0"s and "1"s in IEEE 754 floating point format
%Output: f - floating point double-precision number
%
%Floating Point Binary Format
%Double: 1 sign bit, 11 exponent bits, 52 significand bits
%
%Programmer: Eric Verner
%Organization: Matlab Geeks
%Website: matlabgeeks.com
%Email: everner@matlabgeeks.com
%Date: 22 Oct 2012
%
%I allow the use and modification of this code for any purpose.

%Input checking
if ~ischar(b)
  disp('Input must be a character string.');
  return;
end

hex = '0123456789abcdef'; %Hex characters

bins = reshape(b,4,numel(b)/4).'; %Reshape into 4x(L/4) character array

nums = bin2dec(bins); %Convert to numbers in range of (0-15)

hc = hex(nums + 1); %Convert to hex characters

f = hex2num(hc); %Convert from hex to float
