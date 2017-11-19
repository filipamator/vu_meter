H=single(hann(1024));


fileID = fopen('exp.txt','w');

for x = 1:length(H)
    float2bin(H(x));
    fprintf(fileID,'"%s" when %d,h\n',float2bin(H(x)),x-1);
end


fclose(fileID);
