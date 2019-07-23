
Fs = 1000;                    % Sampling frequency
T = 1/Fs;                     % Sampling period
L = 1024;                     % Length of signal
t = single((0:L-1)*T);                % Time vector

x1 = 0.5*sin(2*pi*300*t);

fileID = fopen('C:\questasim64_10.4c\examples\sin_data.txt','w');

%disp('inputs:');
for i=1:L
%display(strcat('0000',fixedtobin(x1(i))));
fprintf(fileID,'%s\n',strcat('00000000',fixedtobin(x1(i))));
end

fclose(fileID);

function b = fixedtobin(f)
    if(f==1)
        b = '01111111';
    elseif((f>0 && f<10^-7) || (f<0 && f>-10^-7))
        b = '00000000';
    elseif(f<0)
        b = strcat('1', dec2bin((f+1)*2^7, 7));
    else
        b = strcat('0', dec2bin(f*2^7, 7));
    end
end