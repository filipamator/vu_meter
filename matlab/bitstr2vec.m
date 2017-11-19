function bitvec = bitstr2vec(bitstr)
#This function converts a bit string to a vector of 0s and 1s.
%
%Input: bitstr - string of "0"s and "1"s in IEEE 754 floating point format
%Output: bitvec - vector of 0s and 1s
%
%Floating Point Binary Formats
%Single: 1 sign bit, 8 exponent bits, 23 significand bits
%Double: 1 sign bit, 11 exponent bits, 52 significand bits
%
%Programmer: Eric Verner
%Organization: Matlab Geeks
%Website: matlabgeeks.com
%Email: everner@matlabgeeks.com
%Date: 22 Oct 2012

if ~ischar(bitstr)
  disp("Input must be a character string.")
  return;
end

bitvec = bitstr - "0";
