pkg('load', 'image');

data = load('fpga-2d-filter.sim/sim_1/behav/xsim/Lena128x128g_8bits_r_filter.dat');

w = 128;
h = 128;

d = mat2gray(bin2dec(num2str(data)));
im = reshape(d, w,h)';
imwrite(im, 'output.bmp');

