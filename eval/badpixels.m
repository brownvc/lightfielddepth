%%
%% Bad pixels is defined as the percentage of pixels with an error below
%% a specified threshold t
%%
function e = badpixels(dmap, dgt, t)
  e = sum(sum(abs(dmap - dgt) > t)) ./ (size(dmap, 1) * size(dmap, 2));
end
