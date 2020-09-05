% demo_jpeg.m

close all;
clear all;

imgInput  = imread('img_jpeg/20.jpg');
%imgInput  = imread('img_jpeg/28.jpg');
%imgInput  = imread('img_jpeg/31.jpg');


%--------------------------------------------------------------------------
% JPEG Artifact removal example (without downsampling)

% imgOutput = zeros(size(imgInput), class(imgInput));
% for c = 1 : size(imgInput,3)
%     imgOutput(:,:,c) = ...
%         weighted_median_filter(imgInput(:,:,c), imgInput, 0:255, 5, 0.01);
% end

%--------------------------------------------------------------------------
% JPEG Artifact removal example (with downsampling)

nBins = 16;
imgOutput = weighted_median_filter_approx(imgInput, imgInput, 5, 0.01, nBins);

figure; imshow(imgInput ); title('Input image:');
figure; imshow(imgOutput); title('Output image:');
