%%
%% Edge detection and line fitting
%%
function [P, V] = lf2edges4d(EPIuc, EPIvc, param)
  
  % Get EPI gradient images
  for i = 1:size(EPIvc, 4) 
    [gxEPIv(:, :, i) gyEPIv(:, :, i)] = imgradientxy(EPIvc(:, :, 1, i));
    gm = sqrt(gxEPIv(:, :, i).^2 + gyEPIv(:, :, i).^2);
    gxEPIv(:, :, i) = gxEPIv(:, :, i) ./ gm;
    gyEPIv(:, :, i) = gyEPIv(:, :, i) ./ gm;
  end

  for i = 1:size(EPIuc, 4)
    [gxEPIu(:, :, i) gyEPIu(:, :, i)] = imgradientxy(EPIuc(:, :, 1, i));
    gm = sqrt(gxEPIu(:, :, i).^2 + gyEPIu(:, :, i).^2);
    gxEPIu(:, :, i) = gxEPIu(:, :, i) ./ gm;
    gyEPIu(:, :, i) = gyEPIu(:, :, i) ./ gm;
  end

  % Generate the filters for edge detection, ...
  [F, m, gx, gy] = genFilters(param);

  % Calculate the edge confidence and slope maps
  [Eu, Zu] = epis2edges( EPIuc, F, m, gx, gy);
  [Ev, Zv] = epis2edges( EPIvc, F, m, gx, gy);

  % Fit lines to the edges
  Lu = edges2lines(Eu, Zu, m);
  Lv = edges2lines(Ev, Zv, m);

  % Remove outliers
  Lu = filterOutliers(Lu, EPIuc, gxEPIu, gyEPIu, param);
  Lv = filterOutliers(Lv, EPIvc, gxEPIv, gyEPIv, param);

  % Gradient-based line slope(depth)refinement
  Lu = refineLineDepth(Lu, gxEPIu, gyEPIu, EPIuc);
  Lv = refineLineDepth(Lv, gxEPIv, gyEPIv, EPIvc);

  % Merge lines from vertical and horizontal EPIs
  P = merge(Lu, Lv, param.szLF);

  % Determine the visibility of points/lines in each cross-hair view as a boolean matrix V.
  % The rows of V represents points/lines; the columns represent the cross-hair views (ordered linearly as vu)
  V = pvisible(P, gxEPIu, gyEPIu, gxEPIv, gyEPIv);

  % The central light field view is represented twice - once in the central column and once in the central row.
  % If an EPI line/point detected in the *central column* of views is  hidden in the central view,
  % it is set as hidden in the entire *central row*, and vice versa
  idxv = V(:, param.cviewIdx) == 0; 
  idxu = V(:, param.cviewIdx + param.szLF(3)) == 0;
  V(idxv, param.szLF(3) + 1 : end) = 0;
  V(idxu, 1:param.szLF(3)) = 0;

  % Remove points visible in less than a minimum number of views as outliers
  idx = sum(V, 2) < const.visibilityMinViews; 
  P(idx, :) = [];
  V(idx, :) = [];
end
