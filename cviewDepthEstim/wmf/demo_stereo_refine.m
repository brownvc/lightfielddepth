% demo_stereo_refine

close all;
clear all;

pair_name = 'tsukuba';
%pair_name = 'venus';

if strcmp(pair_name, 'tsukuba')
    num_disp = 15;
    disp_scale = 16; %% a constant scale for displaying only
elseif strcmp(pair_name, 'venus')
    num_disp = 32;
    disp_scale = 8;
end

imgGuide = imread(['img_stereo/',pair_name,'_left.png']);
dispMapInput  = imread(['img_stereo/',pair_name,'_boxagg.png']) / disp_scale;

eps = 0.01^2;
r = ceil(max(size(imgGuide, 1), size(imgGuide, 2)) / 40);

dispMapOutput = weighted_median_filter(dispMapInput, imgGuide, 1:num_disp, r, eps);
dispMapOutput = medfilt2(dispMapOutput,[3,3]);

figure; imshow(dispMapInput * disp_scale); title('Input disparity map');
figure; imshow(dispMapOutput * disp_scale); title('Output disparity map');
