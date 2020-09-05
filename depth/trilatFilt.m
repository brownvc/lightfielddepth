%
% Perform trilateral filtering of points in color, depth, and spatial domains
%
function [Q, urIdx] = trilatFilt(P, V, LF, param) 

  % Get the color of each point from a view it is visible in.
  %
  
  % We select the visible view closest to the center
  [~, v] = min(abs(V .* [1:param.szLF(3) 1:param.szLF(4)] - 5), [], 2);

  % Group points by their visible view
  [U, ~, X] = unique(v);
  A = accumarray(X, 1:size(P,1), [], @(r) {P(r, :)});
  O = accumarray(X, 1:size(P,1), [], @(r) {r} ); % This is used to unsort A later
  C = {};

  % Calculate color by interpolating at any subpixel locations
  for i = 1:length(U)
    ui = (U(i) > param.szLF(3)) * (U(i) - param.szLF(3)) + (U(i) <= param.szLF(3)) * (param.cviewIdx);
    vi = (U(i) > param.szLF(3)) * (param.cviewIdx) + (U(i) <= param.szLF(3)) * U(i);
    
    % project points to current view
    pi = A{i};
    pi(:, [1 2]) = [ pi(:, 1) + pi(:, 3) .* (ui - param.cviewIdx) ...
		     pi(:, 2) + pi(:, 3) .* (vi - param.cviewIdx) ];
    lf = LF{U(i)};

    ci1 = interp2( lf(:, :, 1), pi(:, 1), pi(:, 2) );
    ci2 = interp2( lf(:, :, 2), pi(:, 1), pi(:, 2) );
    ci3 = interp2( lf(:, :, 3), pi(:, 1), pi(:, 2) );
    C(i) = {[ci1 ci2 ci3]};
  end

  Q = vertcat(A{:});
  C = vertcat(C{:});
  X = Q;

  % Rescale the spatial coordinates to accomodate points that overflow the center view
  viewportSz = [max(X(:, 2)) - min(X(:, 2)) max(X(:, 1)) - min(X(:, 1))] + 1;
  X(:, 1) = X(:, 1) - min(X(:, 1)) + 1;
  X(:, 2) = X(:, 2) - min(X(:, 2)) + 1;

  upscaleFactor = 2;
  sigmas = const.trilatFiltWinSz ./ 1;
  sigmad = param.maxAbsDisparity / 20;
  sigmac = 0.5;
  winSz = ceil(const.trilatFiltWinSz / 2) * upscaleFactor;

  sz = param.szLF([1 2]) .* upscaleFactor;
  X(:, 1) = X(:, 1) .* upscaleFactor;
  X(:, 2) = X(:, 2) .* upscaleFactor;
  [~, ~,  idx] = splat(X, 1, sz);

  d = X(:, 3);
  urIdx = zeros(size(d), 'logical');

  parfor (i = 1:size(X, 1), 6)
    pi = X(i, :);
    pc = C(i, :);

    win = idx( max(1, round(pi(2)) - winSz): min(sz(1), round(pi(2)) + winSz), ...
	       max(1, round(pi(1)) - winSz): min(sz(2), round(pi(1)) + winSz) );
    nidx = win(find(win));
    nidx = nidx(nidx ~= i); % Exclude the current point

    if sum(sum(nidx > 0)) < 5 %(isempty(nidx)) 
      urIdx(i) = true;
      continue;
    end
    
    pn = X(nidx, :);
    nd = pn(:, 3); % The neighbors' depth
    ns = pn(:, [1 2]); % The neighbors' spatial position
    nc = C(nidx, :); % The neighbors' (interpolated) color

    wd = normpdf( nd - pi(3), 0, sigmad );
    ws = normpdf( sqrt(sum((ns - pi([1 2])).^2, 2)), 0, sigmas);
    wc = normpdf( sqrt(sum((nc - pc).^2, 2)), 0, sigmac);

    w = max(wd .* ws .* wc, eps);

    d(i) = sum(w .* nd) ./ sum(w);
  end

  Q(:, 3) = d;
  O = vertcat(O{:});
  [~, S] = sort(O);
  Q = Q(S, :);
  urIdx = urIdx(S, :);
end
