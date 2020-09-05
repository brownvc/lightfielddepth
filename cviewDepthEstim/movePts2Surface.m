%
% Move depth points from edges to surfaces.
%
% In theory, the depth at an edge is undefined -- it is a transition between two surfaces.
% In order to perform diffusion correctly, we want our depth labels to lie on surfaces,
% not edges. So we need to move our points by a small amount off edges. But since we only
% have a sparse set of depth labels, it is not trivial to determine which surface the edge
% depth label corresponds to.
%
% This function moves points off edges by performing diffusion in both surface directions,
% and then checking which direction generates the stronger gradient at the edge. It also
% returns a heuristic estimate of the final disparity.
%
function [O, W, dheuristic] = movePts2Surface(P, V, LFg, param)

  % For each point, get the index of a view in the central cross-hair in which it is visible. 
  % For points visible in multiple views, the one closest to the central view is selected
  [~, viewIdx] = min(abs(V .* [1:param.szLF(3) 1:param.szLF(4)] - param.cviewIdx), [], 2);

  % Get the unique set of views with visible points, ...
  [uniqueViewIdx, ~, X] = unique(viewIdx);
  % ... and the set of points for each of those views
  visiblePtsIdx = accumarray(X, 1:size(V, 1), [], @(r){r});

  O = zeros(size(P, 1), 1); % The offsets
  W = zeros(size(P, 1), 1); % The confidence
  Gx = zeros(size(P, 1), 1); % Gradient along x at each point..
  Gy = zeros(size(P, 1), 1); % Gradient along y.

  Oi = {};
  Wi = {};
  Gxi = {};
  Gyi = {};
  
  [m, d, idx] = splat(P, 1, [512 512]);

  parfor (i = 1:length(uniqueViewIdx), 18)
    view = uniqueViewIdx(i);
    ui = (view <= param.szLF(3)) * param.cviewIdx + (view > param.szLF(3)) * (view - param.szLF(3));
    vi = (view <= param.szLF(3)) * view + (view > param.szLF(3)) * param.cviewIdx;
    
    % Project visible points to current view
    vis = V(:, view);
    Pi = P;
    Pi(:, [1 2]) = [Pi(:, 1) + (ui - param.cviewIdx) .* Pi(:, 3) Pi(:, 2) + (vi - param.cviewIdx) .* Pi(:, 3)];

    % Find the gradient direction at each points
    [lfgx, lfgy] = imgradientxy( LFg{view} );
    pgx = interp2(lfgx, Pi(:, 1), Pi(:, 2));
    pgy = interp2(lfgy, Pi(:, 1), Pi(:, 2));
    pgm = 1 ./ sqrt( pgx.^2 + pgy.^2 );
    pgx = pgx .* pgm;
    pgy = pgy .* pgm;
    pgx(isnan(pgx)) = 0;
    pgy(isnan(pgy)) = 0;

    [g, ~, ~] = splat(Pi(vis, :), 1, [param.szLF(1) param.szLF(2)]);
    g = double(1 ./ (g.^2 + 0.0001));

    % 1. Offset points in gradient direction and diffuse
    Po = Pi;
    Po(:, [1 2]) = Po(:, [1 2]) + [pgx pgy];

    [w, d] = splat(Po(vis, :), 1, [param.szLF(1) param.szLF(2)]);
    w = double(w .* 100000);
    Duf(:, :, i) = lahbpcg_mex(d, w, g, g, 1000, 0.00001);
		       
    % 2. Offset points opposite to the gradient direction and diffuse
    Po(:, [1 2]) = Po(:, [1 2]) - 2 * [pgx pgy];
    
    [w, d] = splat(Po(vis, :), 1, [param.szLF(1) param.szLF(2)]);
    w = double(w .* 100000);
    Dub(:, :, i) = lahbpcg_mex(d, w, g, g, 1000, 0.00001);
    
    ptsIdx = visiblePtsIdx{i};

    %
    % Select the offset direction which generates the sharper gradient at the current edge point
    samplesRange = 3;
    samplesOffset = [-samplesRange:samplesRange];
    edgeSampleIdx = ceil(length(samplesOffset) ./ 2);
    ptsx = Pi(ptsIdx, 1) + pgx(ptsIdx) .* samplesOffset;
    ptsy = Pi(ptsIdx, 2) + pgy(ptsIdx) .* samplesOffset;

    df = interp2( Duf(:, :, i), ptsx, ptsy );
    db = interp2( Dub(:, :, i), ptsx, ptsy );

    idxf = abs(df(:, edgeSampleIdx ) - df(:, edgeSampleIdx - 1)) > abs(df(:, edgeSampleIdx) - df(:, edgeSampleIdx + 1));
    dfc = df(:, 2:end);
    dfc(idxf, :) = df(idxf, 1:end-1);

    idxb = abs(db(:, edgeSampleIdx ) - db(:, edgeSampleIdx - 1)) > abs(db(:, edgeSampleIdx) - db(:, edgeSampleIdx + 1));
    dbc = db(:, 2:end);
    dbc(idxf, :) = db(idxf, 1:end-1);
    
    df = dfc;
    db = dbc;

    ao = abs(df * [ linspace(-1, -2, samplesRange) linspace(2, 1, samplesRange) ]');
    bo = abs(db * [ linspace(-1, -2, samplesRange) linspace(2, 1, samplesRange) ]');
    Wi(i) = {exp(1.3 * abs(bo - ao))};
	
    % Normalize the response across the edge to the range [-1, 1]
    df(isnan(df)) = 0;
    db(isnan(db)) = 0;
    df = df - min(df, [], 2);
    df = (df ./ max(df, [], 2)) * 2 - 1;
    db = db - min(db, [], 2);
    db = (db ./ max(db, [], 2)) * 2 - 1;

    df = abs(df * [ linspace(-1, -2, samplesRange) linspace(2, 1, samplesRange) ]');
    db = abs(db * [ linspace(-1, -2, samplesRange) linspace(2, 1, samplesRange) ]');
    fidx = df > db;

    oi = zeros(size(ptsIdx, 1), 1);
    oi(fidx, :) = 1;   % Move these points along the gradient direction
    oi(~fidx, :) = -1; % Move these points opposite to the gradient direction

    Oi(i) = {oi};
    Gxi(i) = {pgx(ptsIdx)};
    Gyi(i) = {pgy(ptsIdx)};
  end

  cidx = find( uniqueViewIdx == param.cviewIdx);
  dheuristic = (Duf(:, :, cidx) + Dub(:, :, cidx));
  
  ptsIdx = vertcat(visiblePtsIdx{:});
  O(ptsIdx, :) = vertcat(Oi{:});
  W(ptsIdx, :) = vertcat(Wi{:});
  Gx(ptsIdx, :) = vertcat(Gxi{:});
  Gy(ptsIdx, :) = vertcat(Gyi{:});

  % Median filter the offsets of neighboring points along an edge
  [m, ~, idx] = splat(P, 1, param.szLF([1 2]));
  [gx, gy] = imgradientxy(LFg{param.cviewIdx});
  gm = sqrt(gx.^2 + gy.^2);
  gx = gx ./ gm;
  gy = gy ./ gm;

  O2 = O;
  for i = 1:size(P, 1)
    p = round(P(i, [1 2]));
    neighbors = neighborPtsAlongEdge(m, gx, gy, p, 60);
    if ~isempty(neighbors)
      O2(i) = median( [O(idx(neighbors))' O(i)] );
    else
      O2(i) = O(i);
    end
  end

  % Offset the points in the determined direction
  O = O2 .* [Gx Gy];
end
