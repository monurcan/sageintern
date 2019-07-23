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
%display(strcat('00000000000000000000000000000000',fixed2bin(x1(i))));
%end
%disp('outputs: matlab');
%for i=1:L
%display(strcat( fixed2bin(imag(Y(i))), fixed2bin(real(Y(i))) ));
%end

%disp('outputs: sim');

for i=1:L
%disp(fft_res(i,:));
fft_res_fixed(i,1) =(bin2fixed(fft_res(i,1:8))) + 1i*bin2fixed(fft_res(i,9:16));
end

subplot(5,1,3)
P3 = abs(fft_res_fixed);
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


function b = fixed2bin(f)
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

function f = bin2fixed(b)
    if(b=='01111111')
        f = 1;
    elseif(b(1)=='1')
        f = bin2dec(b(2:8))/2^7-1;
    else
        f = bin2dec(b(2:8))/2^7;
    end
end

