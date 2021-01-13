%%
%% Remove outliers from the set of EPI lines L.
%% An outlier is a line whos gradient doesn't match the gradient of the corresponding EPI
%% at a minimum specified number of sample points
%%
function L = filterOutliers(L, EPI, gxEPI, gyEPI, param)

  szEPI = size(EPI);

  for i = 1:length(L)
    lines = L{i};
    if isempty(lines)
      continue;
    end

    %
    % Remove lines who's gradients don't match EPI gradients over a minimum number of views

    % Get EPI gradients 
    imgx = gxEPI(:, :, i);
    imgy = gyEPI(:, :, i);

    % Calculate line gradients
    gx = szEPI(1);
    gy = lines(:, 1) - lines(:, 2);
    gm = 1 ./ sqrt(gx.^2 + gy.^2);
    gx = gx .* gm;
    gy = gy .* gm;

    idx = ones(size(lines, 1), 1, 'logical');

    for j = 1:size(lines, 1)
      x = [lines(j, 1) lines(j, 2)];  
      y = [1 szEPI(1)];                  

      nPoints = szEPI(1);
      rIndex = [y(1):y(2)];
      cIndex = max(1, min(round(linspace(x(1), x(2), nPoints)), szEPI(2)));
      index = sub2ind([szEPI(1) szEPI(2)], rIndex, cIndex);

      c = abs(gx(j) .* imgx(index) + gy(j) .* imgy(index));

      c = c > const.filtOutliersGradientDirectionThresh;
      if max(accumarray( [cumsum(diff([0 c]) == 1) .* c + 1]', c)) < const.filtOutliersMinContigPixels
	idx(j) = 0;
      end

    end
    L(i) = {lines(idx, :)};
  end

end 
