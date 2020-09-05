%%
%% Fit a line to each non-zero pixel in c according to the slope map z
%% The lines are specified by their top and bottom intercepts on the EPI
%%
function l = fitLinesEPI(c, z, m, EPI)
  
  l = [];

  while sum(sum(c)) > 0
    
    % We start by fitting the most confident lines
    [~, maxIdx] = max(c(:));
    [i, j] = ind2sub( size(c), maxIdx );

    % Disregard values along the top and bottom edges of the EPI as 
    % these are usually noisy
    if(i == 1 | i == size(c, 1)) | (j == 1 | j == size(c, 2))
      c(i, j) = 0;
      continue;
    end
    p = [i, j];

    %
    % Fit a line at point p.
    % A line template is fit according to the slope at point p in the slope map z.
    tIdx = z( p(1), p(2) );

    %
    % Clear all pixels in the edge map around the fit line. 
    % To do this, we calculate the perpendicular distance of each non-zero pixel in 
    % c from the line with slope m(tIdx) passing through p.
    
    % A point on the line, in addition to p
    q = [0; p(2) + p(1) ./ m(tIdx)]; 
  
    % The pixels for which we want to calculate the distance from the line
    [Y, X] = find(c > 0);

    % Calculate perpendical distance from our fit line
    D = abs(X .* (q(1) - p(1)) - Y .* (q(2) - p(2)) + q(2) * p(1) - q(1) * p(2)) ./ ...
	sqrt( (q(1) - p(1)) .^ 2 + (q(2) - p(2)) .^ 2 );

    % Select pixels with distance less than desired threshold
    D = D < round((const.SegMinWidthMultiplier * size(c, 1)));
    idx = sub2ind(size(c), Y, X);
    proximalPtsIdx = D .* idx;
    proximalPtsIdx = proximalPtsIdx( proximalPtsIdx > 0);

    l = cat(1, l, [tIdx i j]);

    c(i, j) = 0;
    c(proximalPtsIdx) = 0;
  end

  if ~isempty(l)
    % Get the intercepts of the templates on the top and bottom of the EPI
    m = m(l(:, 1))';
    xt = l(:, 3) + (l(:, 2) - 1) ./ m;
    xb = l(:, 3) + (l(:, 2) - size(c, 1)) ./ m;
    l = [xt xb];
  end
end
