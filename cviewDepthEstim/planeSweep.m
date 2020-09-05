%%
%% Fine-tune the depth at points in P by performing a plane-sweep around each point  using a subset of views. 
%%
function [P, conf, pUnreliableIdx] = planeSweep(P, O, V, LFg, param)

  npoints = size(P, 1);
  doff = P(:, 3) + linspace(-const.planeSweepMaxDispOffset, const.planeSweepMaxDispOffset, const.planeSweepNumDispOffset);

  % For each point get at most const.planeSweepMaxViews views in which it is visible
  %
  fv = cellfun(@(vi) find(vi), num2cell(V, 2), 'UniformOutput', false);
  pviews = cellfun(@(f, i) uint32([repelem(i, min(const.planeSweepMaxViews, length(f)), 1) ...
				  f( randperm(length(f),  min(const.planeSweepMaxViews, length(f)) ))']), ...
		   fv, num2cell([1:npoints]'), 'UniformOutput', false);
  pviews = vertcat(pviews{:});
  Vc = zeros(size(V), 'logical');
  Vc( sub2ind(size(Vc), pviews(:, 1), pviews(:, 2)) ) = 1;

  C = zeros( [const.planeSweepPatchSz(1), const.planeSweepPatchSz(2), const.planeSweepNumDispOffset, npoints, const.planeSweepMaxViews], 'single');

  % Select the set of views from which we want to project onto our reference plane.
  vIdx = single(unique(pviews(:, 2)));
  pNextViewIdx = ones(npoints, 1, 'uint8');

  for i = 1:length(vIdx)
    u = (vIdx(i) <= param.szLF(3)) .* param.cviewIdx + (vIdx(i) > param.szLF(3)) .* (vIdx(i) - param.szLF(3));
    v = (vIdx(i) > param.szLF(3)) .* param.cviewIdx + (vIdx(i) <= param.szLF(3)) .* vIdx(i);
    s2t = [u - param.cviewIdx v - param.cviewIdx];

    pIdx = find(Vc(:, vIdx(i)));
    ci = costVolumeForImage( LFg{vIdx(i)}, P(pIdx, :), O(pIdx, :), ...
			     s2t, doff(pIdx,:), const.planeSweepPatchSz );
    for k = 1:length(pIdx)
      C(:, :, :, pIdx(k), pNextViewIdx(pIdx(k))) = ci(:, :, :, k);
    end
    pNextViewIdx(pIdx) = pNextViewIdx(pIdx) + 1;
  end

  C(isnan(C)) = 0; % A bit hacky; Does it affect the variance?
  
  Cvar = var(C, [], 5); % The variance along the views for each disparity estimate
  [conf, dmin] = min(Cvar, [], 3); % We use a winner-takes-all strategy for the best disparity
  dmin = squeeze(dmin);

  conf = squeeze(conf); % A const.planeSweepPatchSz x const.planeSweepPatchSz x npoints matrix of confidence at each patch pixel for a point
  
  % Normalize the confidence
  varsum = squeeze(sum(Cvar, 3));
  conf = 1 - conf ./ varsum;
  idx = conf > 0.99;
  didx = cellfun(@(d, i) mode(d(i)), num2cell(dmin, [1 2]), num2cell(idx, [1 2]) );
  didx = didx(:);

  conf = cellfun(@(cf, i) mean(cf(i)), num2cell(conf, [1 2]), num2cell(idx, [1 2]) );
  conf = conf(:);

  idx = sub2ind( size(doff), [1:npoints]', didx );
  pUnreliableIdx = isnan(idx); % These NaNs occur for patches where all pixels' confidence is lower than the threshold

  P(~pUnreliableIdx, 3) = doff( idx(~pUnreliableIdx) );
end

%%
%% Create a cost volume 
%%
function v = costVolumeForImage(I, ps, o, s2t, doff, patchSz)
  ndoff = size(doff, 2);

  % Generate oriented patches at each point
  px = ps(:, 1) + s2t(:, 1) .* doff;
  py = ps(:, 2) + s2t(:, 2) .* doff;
  px = px';
  py = py';
  px = px(:);
  py = py(:);

  [patchx, patchy] = orientedPatchAtPoint( [px, py], repelem(o, ndoff, 1), patchSz);
  
  % Interpolate image values at patch points 
  v = interp2(I, patchx, patchy);

  % Set NaN values to the mean.
  % NaNs occur when the patch exceeds the image bounds.
  % Note that even after the following steps we may have NaNs in cases where the
  % entire patch is zero.
  nanIdx = isnan(v);
  vprime = v;
  vprime(nanIdx) = 0;
  vmean = sum(vprime, 2) ./ sum(~nanIdx, 2);
  v = vprime + nanIdx .* vmean;
  v = reshape(v', patchSz(1), patchSz(2), ndoff, size(ps, 1));
end

%%
%% Return coordinates of a patch along point p oriented along the  direction o
%%
function [x, y] = orientedPatchAtPoint(p, o, patchSz)

  nSamplesu = patchSz(1);
  nSamplesv = patchSz(2);

  t = [o(:, 2) -o(:, 1)]; % The tangent at the point

  pux = repelem( linspace(-patchSz(1)/2, patchSz(1)/2, nSamplesu) .* t(:, 1), nSamplesv, 1);
  puy = repelem( linspace(-patchSz(2)/2, patchSz(2)/2, nSamplesu) .* t(:, 2), nSamplesv, 1);

  pvx = [linspace(0, patchSz(1), nSamplesv) .* o(:, 1)]';
  pvy = [linspace(0, patchSz(2), nSamplesv) .* o(:, 2)]';
  pvx = repelem( pvx(:), 1, nSamplesu);
  pvy = repelem( pvy(:), 1, nSamplesu);

  x = pvx + pux + repelem(p(:, 1), nSamplesv, nSamplesu);
  y = pvy + puy + repelem(p(:, 2), nSamplesv, nSamplesu);
  x = x';
  y = y';
  x = x(:);
  y = y(:);
  x = reshape(x, nSamplesu * nSamplesv, []);
  y = reshape(y, nSamplesu * nSamplesv, []);
  x = x';
  y = y';
end
