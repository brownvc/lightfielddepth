function imgOut = weighted_median_filter_approx(imgIn, imgGuide, r, epsilon, nBins, sigmaHist)
%weighted_median_filter_approx - Approximated version of weighted median filter with guided filter weights for images
%
%   imgOut    = weighted_median_filter_approx(imgIn, imgGuide, r, epsilon, nBins, sigmaHist)
%
% INPUT:
%
%   imgIn     - Input image
%   imgGuide  - Input guidance image, should be 3-channel RGB
%   r         - Local window radius for guided filter weights
%   epsilon   - Regularization parameter for guided filter weights
%   nBins     - Number of bins for quantizing
%   sigmaHist - Sigma for Gaussian smoothed histogram
%
%
% Algorithm:
%
%   This approximated version is for filtering images (usually with 256 labels) only. It constructs a
%   Gaussian smoothed weighted histogram, then the median can be found via integrating this histogram.
%   This is done in our code as convolving each slice with the erf function, which is essentially a low-
%   pass filtering, hence downsampling in range space can be used.
%

if ~exist('epsilon', 'var')
    epsilon = 0.01;
end

if ~exist('nBins', 'var')
    nBins = 32;
end

if ~exist('sigmaHist', 'var')
    sigmaHist = 0.06;
end

imgIn = im2double(imgIn);
imgGuide = im2double(imgGuide);
imgOut = zeros( size(imgIn) );

vecDisps = linspace(0, 1, nBins);

gfObj = guidedfilter_color_precompute(imgGuide, r, epsilon);

hei = size(imgIn,1);
wid = size(imgIn,2);
weightedIntegralHist = zeros(hei, wid, nBins);

for c = 1 : size(imgIn,3)
    fprintf('Computing channel: %d\n', c);
    for d = 1 : nBins
        fprintf('%d of %d\n', d, nBins);
        
        % apply guided filter to the Gaussian integral slice
        weightedIntegralHist(:,:,d) = ...
            guidedfilter_color_runfilter(...
                gaussian_integral(vecDisps(d), imgIn(:,:,c), sigmaHist), gfObj);
    end
    
    % find the interpolated median
    
    targetVal = 0.49;
    
    imgOutc = zeros(hei, wid);
    
    for d = 1 : nBins-1
        imgBin1 = weightedIntegralHist(:,:,d);
        imgBin2 = weightedIntegralHist(:,:,d+1);
        
        bin1Val = vecDisps(d);
        bin2Val = vecDisps(d+1);
        
        frac = (targetVal-imgBin1) ./ (imgBin2-imgBin1);
        interpolated = bin1Val + frac * (bin2Val - bin1Val);
        
        idx = imgBin1<targetVal & imgBin2>=targetVal;
        imgOutc(idx) = interpolated(idx);
    end
    
    imgOut(:,:,c) = imgOutc;
end

end

%--------------------------------------------------------------------------------------
function y = gaussian_integral(x, mu, sigma)
y = 0.5 * ( 1 + erf((x-mu) / (sigma * 1.41421356237)) );
end
