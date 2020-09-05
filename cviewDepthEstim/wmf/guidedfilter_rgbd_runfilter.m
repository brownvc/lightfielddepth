function q = guidedfilter_rgbd_runfilter(p, gfobj)
%   guidedfilter_color_runfilter   Run O(1) time implementation of guided filter
%
%   NOTE: you must call guidedfilter_color_precompute first!
%
%   - filtering input image: p (should be a gray-scale/single channel image)

%global gfobj;

r = gfobj.r;

[hei, wid] = size(p);

mean_p = boxfilter(p, r) ./ gfobj.N;

mean_Ip_r = boxfilter(gfobj.I(:, :, 1).*p, r) ./ gfobj.N;
mean_Ip_g = boxfilter(gfobj.I(:, :, 2).*p, r) ./ gfobj.N;
mean_Ip_b = boxfilter(gfobj.I(:, :, 3).*p, r) ./ gfobj.N;
mean_Ip_d = boxfilter(gfobj.I(:, :, 4).*p, r) ./ gfobj.N;

% covariance of (I, p) in each local patch.
cov_Ip_r = mean_Ip_r - gfobj.mean_I_r .* mean_p;
cov_Ip_g = mean_Ip_g - gfobj.mean_I_g .* mean_p;
cov_Ip_b = mean_Ip_b - gfobj.mean_I_b .* mean_p;
cov_Ip_d = mean_Ip_d - gfobj.mean_I_d .* mean_p;

a = zeros(hei, wid, 4);
for y=1:hei
    for x=1:wid
        cov_Ip = [cov_Ip_r(y, x), cov_Ip_g(y, x), cov_Ip_b(y, x) cov_Ip_d(y, x)];
        a(y, x, :) = cov_Ip * gfobj.invSigma{y, x}; % Eqn. (14) in the paper;
    end
end

b = mean_p - a(:, :, 1) .* gfobj.mean_I_r - a(:, :, 2) .* gfobj.mean_I_g - a(:, :, 3) .* gfobj.mean_I_b - a(:, :, 4) .* gfobj.mean_I_d; % Eqn. (15) in the paper;

q = (boxfilter(a(:, :, 1), r).* gfobj.I(:, :, 1)...
   + boxfilter(a(:, :, 2), r).* gfobj.I(:, :, 2)...
   + boxfilter(a(:, :, 3), r).* gfobj.I(:, :, 3)...
   + boxfilter(a(:, :, 4), r).* gfobj.I(:, :, 4)...
   + boxfilter(b, r)) ./ gfobj.N;  % Eqn. (16) in the paper;
