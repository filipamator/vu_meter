function bitstr = bitvec2str(bitvec)
%This function converts a bit vector to a string of "0"s and "1"s.
%
%Input: bitvec - vector of 0s and 1s
%Output: bitstr - string of "0"s and "1"s in IEEE 754 floating point format
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

bitstr = char(bitvec + 48);

