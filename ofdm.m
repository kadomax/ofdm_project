clc;
close all;
%TRANSMITTER
%transmit pilot
x = randi([0 , 15] , 64 , 1)';
q = qammod(x , 16);
tx = ifft(q , 64);
cp_length = 16;
tx = [tx(: , end-cp_length+1:end) tx]; % cyclic prefix 

%transmit data
x_signal = randi([0 , 15] , 64 , 1)';
q_signal = qammod(x_signal , 16);
tx_signal = ifft(q_signal , 64);
tx_signal = [tx_signal(: , end-cp_length + 1 : end) tx_signal]; % cyclic prefix

%CHANNEL
% 3-tap channel
h = [1 , 0 , 0 , sqrt(10^(-17/10)) , sqrt(10^(-21 / 10))]; % power delay profile 
r = randn(1 , length(h)) + 1i*randn(1 , length(h)); % random complex numbers with rayleigh distributed amplitude
h = h .* r; % impulse response of channel

h_64 = [h zeros(1 , length(x) - length(h))];
H = fft(h_64 , 64);

% convolve with transmitted signal
tx_ray = conv(h , tx); 
tx_signal_ray = conv(h , tx_signal);

%add awgn
snr = 30;
tx_noisy = awgn(tx_ray , snr);
tx_signal_noisy = awgn(tx_signal_ray , snr);

figure();
subplot(2 , 1 , 1); plot((1 : length(tx_signal_noisy)) , abs(tx_signal_noisy)); title("tx signal amplitude with noise");
subplot(2 , 1 , 2); plot((1 : length(tx_signal_noisy)) , angle(tx_signal_noisy)); title("tx signal phase with noise");

%RECEIVER
%for pilot symbol
rx = tx_noisy(1 : 80);
rx = rx(cp_length + 1 : end);
q_r = fft(rx , 64);

%for data symbol
rx_signal = tx_signal_noisy(1 : 80);
rx_signal = rx_signal(cp_length + 1 : end);
q_r_signal = fft(rx_signal , 64);

%channel estimation
H_est = q_r ./ q;

figure();
subplot(2 , 1 , 1); plot((1 : 64) , abs(H)); title("actual frequency response of the channel");
subplot(2 , 1 , 2); plot((1 : 64) , abs(H_est)); title("estimated frequency response of the channel");

figure();
scatterplot(q_r_signal , 1 , 0 , 'g.'); title("scatter plot at the receiver before equalization"); set(gca,'Color','k');

% channel equalization
q_r_signal = q_r_signal ./ H_est;

figure();
scatterplot(q_r_signal , 1 , 0 , 'g.'); title("scatter plot at the receiver after equalization"); set(gca,'Color','k');

%ML estimation
points = (qammod((0 : 15) , 16)); % 16-QAM points
mindist = inf; % initially distance is infinity
minpt = 0;
q_r_signal_estimate = (zeros(1 , 64));
for k = 1 : length(q_r_signal)
    mindist = inf;
    for m = 1 : length(points)
        if norm(q_r_signal(k) - points(m)) < mindist
            mindist = norm(q_r_signal(k) - points(m));
            minpt = points(m);
        end
    end
    q_r_signal_estimate(k) = minpt;
end


rx_data = qamdemod(q_r_signal_estimate , 16);
figure();
subplot(2 , 1 , 1); stem((1 : 64) , x_signal); title("sent");
subplot(2 , 1 , 2); stem((1 : 64) , rx_data); title("received(SNR = 30 dB)");

disp(x_signal);
disp(rx_data);



