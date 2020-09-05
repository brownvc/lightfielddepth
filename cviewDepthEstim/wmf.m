%%
%% Perform weighted median filtering of the input depth image using the method
%% described in 'Constant Time Weighted Median Filtering for Stereo Matching and Beyond.'
%% The code for filtering in ./wmf was downloaded from Kaiming He's homepage:
%% http://kaiminghe.com/iccv13wmf/matlab_wmf_release_v1.rar
%%
function D = wmf(D, I, q, epsilon, r)
  mn = min(min(D));
  mx = max(max(D));
  D = (D - mn) ./ (mx - mn);
  D = round(D .* (q - 1));
  D = weighted_median_filter(D, I, [0:q], r, epsilon);
  D = medfilt2(D, [3 3]);
  D = D ./ q .* (mx - mn) + mn;
end
