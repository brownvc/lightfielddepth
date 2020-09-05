%% 
%% Xiaolin Wu's antialiased line drawing algorithm.
%% Code downloaded from Wikipedia
%%

function I = wu(I, x0, y0, x1, y1)

  idx = [];

  ipart = @(x) floor(x); % integer part of x
  fpart = @(x) x - floor(x); % fractional part of x
  rfpart = @(x) 1 - fpart(x); 

  steep = abs(y1 - y0) > abs(x1 - x0);

  if steep
    [x0, y0] = deal(y0, x0); 
    [x1, y1] = deal(y1, x1);
  end
  if x0 > x1
    [x0, x1] = deal(x1, x0);
    [y0, y1] = deal(y1, y0); 
  end
    
  dx = x1 - x0;
  dy = y1 - y0;
  gradient = dy / dx;

  if dx == 0.0 
    gradient = 1.0
  end

  % first endpoint
  xend1 = round(x0);
  yend1 = y0 + gradient * (xend1 - x0);
  xgap1 = rfpart(x0 + 0.5);
  xpxl1 = xend1; % this will be used in the main loop
  ypxl1 = ipart(yend1);

  % second endpoint
  xend2 = round(x1);
  yend2 = y1 + gradient * (xend2 - x1);
  xgap2 = fpart(x1 + 0.5);
  xpxl2 = xend2; %this will be used in the main loop
  ypxl2 = ipart(yend2);

  idx = ones( xpxl2 - 1 - xpxl1, 3);
  n = 1;

  if steep
	      idx(n, :) = [xpxl1, ypxl1, rfpart(yend1) * xgap1];
	      idx(n + 1, :) = [xpxl1, ypxl1 + 1, fpart(yend1) * xgap1];
	      else
	      idx(n, :) = [ypxl1, xpxl1, rfpart(yend1) * xgap1];
	      idx(n + 1, :) = [ypxl1 + 1, xpxl1, fpart(yend1) * xgap1];
  end 
  n = n + 2;
  intery = yend1 + gradient; % first y-intersection for the main loop

  if steep
	      idx(n, :) = [xpxl2, ypxl2, rfpart(yend2) * xgap2];
	      idx(n + 1, :) = [xpxl2, ypxl2 + 1, fpart(yend2) * xgap2];
	      else
	      idx(n, :) =  [ypxl2, xpxl2, rfpart(yend2) * xgap2];
	      idx(n + 1, :) = [ypxl2 + 1, xpxl2, fpart(yend2) * xgap2];
  end
  n = n + 2;

  % main loop
  if steep
	      for x = xpxl1+1:xpxl2-1
	      idx(n, :) = [x, ipart(intery), rfpart(intery)];
	      idx(n + 1, :) = [x, ipart(intery) + 1, fpart(intery)];
      n = n + 2;
      intery = intery + gradient;
    end
	      else
	      for x = xpxl1+1:xpxl2-1
	      idx(n, :) = [ipart(intery), x, rfpart(intery)];
	      idx(n + 1, :) = [ipart(intery) + 1, x, fpart(intery)];
      n = n + 2;
      intery = intery + gradient;
    end
  end 

	      idx = idx(  (idx(:, 1) > 0 & idx(:, 1) <= size(I, 1)) & ...
	      (idx(:, 2) > 0 & idx(:, 2) <= size(I, 2)), :);
	      f = sub2ind( size(I), idx(:, 1), idx(:, 2));
	      I(f) = idx(:, 3);
end
