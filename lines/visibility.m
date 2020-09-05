%%
%% Get the view indices in which an EPI line is visible.
%%
function b = visibility(l, epigx, epigy)

  szEPI = [size(epigx, 1), size(epigx,2)];

  b = ones( size(l, 1), size(epigx, 1), 'logical');
  n = size(l, 1);

  % Find all pairs of intersecting lines...
  %
  u = repmat(l(:, 1), 1, n);
  v = repmat(l(:, 2), 1, n);
  s = repmat(l(:, 1)', n, 1);
  r = repmat(l(:, 2)', n, 1);

  % The foreground/background line is determined by slope
  N = ((r <= v & s >= u) | (r >= v & s <= u)); 
  [lb, lf] = find(N .*((r - s) > (v - u)) > 0); 

  % Also get lines that extend outside the visible EPI region
  lo = find((l(:, 1) < 1 | l(:, 1) > szEPI(2)) | (l(:, 2) < 1 | l(:, 2) > szEPI(2)));
  lb = unique([lb; lo]);

  % Get pixel positions to sample along each background line
  %
  lbu = l(lb, :);
  
  m = (lbu(:, 1) - lbu(:, 2)) ./ (szEPI(1) - 1);
  x = lbu(:, 1) - m * linspace(0, szEPI(1) - 1, szEPI(1));
  y = repelem(linspace(1, szEPI(1), szEPI(1)), size(lbu, 1), 1);

  % Calculate the gradient of each background line
  gx = szEPI(1) - 1;
  gy = lbu(:, 1) - lbu(:, 2);
  gm = 1 ./ sqrt(gx.^2 + gy.^2);
  gx = gx .* gm;
  gy = gy .* gm;

  imgx_interp = interp2(epigx, x, y, 'cubic');
  imgy_interp = interp2(epigy, x, y, 'cubic');

  img_m = 1 ./ sqrt(imgx_interp.^2 + imgy_interp.^2);
  imgx_interp = imgx_interp .* img_m;
  imgy_interp = imgy_interp .* img_m;

  a = imgx_interp .* gx + imgy_interp .* gy;
  b(unique(lb), :) = medfilt2(abs(imgx_interp .* gx + imgy_interp .* gy) > const.visibilityAlignmentThreshold, [1 3]);
end
