figure

subplot(5,1,1)
plot(t,x1)
title("time domain");
subplot(5,1,2)

Y = single(fft(x1));
P2 = abs(Y);
plot(P2)
title("matlab fft");

%disp('inputs:');
%for i=1:L
%display(strcat('00000000000000000000000000000000',float2bin(x1(i))));
%end
%disp('outputs: matlab');
%for i=1:L
%display(strcat( float2bin(imag(Y(i))), float2bin(real(Y(i))) ));
%end

%disp('outputs: sim');

for i=1:L
%disp(fft_res(i,:));
fft_res_float(i,1) =(bin2float(fft_res(i,1:32))) + 1i*bin2float(fft_res(i,33:64));
end

subplot(5,1,3)
P3 = abs(fft_res_float);
plot(P3) % max(P2)/max(P3)*
title("fft core ("+L+"-point)")

subplot(5,1,4)
plot(P2, "k-", 'LineWidth',2)
hold on
plot(max(P2)/max(P3)*P3, "r--", 'LineWidth',1.5)
legend('fft core(normalized)', 'matlab fft')
title("comparison")

subplot(5,1,5)
error = abs(P2'/max(P2)-1/max(P3)*P3)*100;

plot(error, "r--");
title("error %")

function b = float2bin(f)
%This function converts a floating point number to a binary string.
%
%Input: f - floating point number, either double or single
%Output: b - string of '0's and '1's in IEEE 754 floating point format
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
%
%I allow the use and modification of this code for any purpose.
%Input checking
if ~isfloat(f)
  disp('Input must be a floating point number.');
  return;
end
hex = '0123456789abcdef'; %Hex characters
h = num2hex(f);	%Convert from float to hex characters
hc = num2cell(h); %Convert to cell array of chars
nums =  cellfun(@(x) find(hex == x) - 1, hc); %Convert to array of numbers
bins = dec2bin(nums, 4); %Convert to array of binary number strings
b = reshape(bins.', 1, numel(bins)); %Reshape into horizontal vector
end

function f = bin2float(b)
%This function converts a binary number to a floating point number.
%Because hex2num only converts from hex to double, this function will only
%work with double-precision numbers.
%
%Input: b - string of '0's and '1's in IEEE 754 floating point format
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
end

