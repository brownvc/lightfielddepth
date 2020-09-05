%%
%% Generate *View Consistent Light Field Depth* for the input light field using
%% the parameter settings in param
%%
function VCLFD (fin, fout, param)

  LF = loadLF( fin, param.uCamMovingRight, param.vCamMovingRight, 'lab');
  
  param.szLF = [size(LF, 1) size(LF, 2) size(LF, 4) size(LF, 5)]; % light field size in y, x, v, u
  param.szEPI = [param.szLF(4) param.szLF(2) param.szLF(1)]; % EPI size 
  param.cviewIdx = ceil(param.szLF(3)/2);

  LFrgb = single(loadLF( fin, param.uCamMovingRight, param.vCamMovingRight, 'rgb')) ./ 255;
  LFrgb = num2cell(cat(4, squeeze(LFrgb(:, :, :, :, param.cviewIdx)), squeeze(LFrgb(:, :, :, param.cviewIdx, :))), [1 2 3]);

  LFg = single(loadLF( fin, param.uCamMovingRight, param.vCamMovingRight, 'gray')) ./ 255;
  LFg = num2cell(cat(3, squeeze(LFg(:, :, 1, :, param.cviewIdx)), squeeze(LFg(:, :, 1, param.cviewIdx, :))), [1 2]);
  
  % Get the central row of LF images, and their EPIs
  LFuc = squeeze(LF(:, :, :, param.cviewIdx, :));
  
  % Filter the views to remove noise
  for i = 1:size(LFuc, 4)
    LFuc(:, :, :, i) = imgaussfilt( squeeze(LFuc(:, :, :, i)), 0.85);    
  end
  EPIuc = permute(LFuc, [4 2 3 1]);

  % Get the central column of LF images, and their EPIs
  LFvc = squeeze(LF(:, :, :, :, param.cviewIdx));
  LFvc = permute(LFvc, [2 1 3 4]);
  for i = 1:size(LFvc, 4) 
    LFvc(:, :, :, i) = imgaussfilt( squeeze(LFvc(:, :, :, i)), 0.85);
  end
  EPIvc = permute(LFvc, [4 2 3 1]);

  t0 = tic;

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
  % EDGE DETECTION & LINE FITTING  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % Get 4D edges
  %
  tic
  [P, V] = lf2edges4d(EPIuc, EPIvc, param);
  [P, ~] = trilatFilt(P, V, LFrgb, param);
  t = toc;
  disp(['4D edge detection completed in ' num2str(t) 's']);

  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % CENTRAL VIEW DEPTH ESTIMATION %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  tic
  [O, W, dheuristic] = movePts2Surface(P, V, LFg, param);
  P(:, [1 2]) = P(:, [1 2]) + O;
  t = toc;
  disp(['Point offset completed in ' num2str(t) 's']);

  [P, urIdx] = trilatFilt(P, V, LFrgb, param);
  idx = isnan(W) | urIdx;
  P(idx, :) = [];
  V(idx, :) = [];
  W(idx, :) = [];
  O(idx, :) = [];
  
  % Select a specified percentage of highest-confidence points
  [W, o] = sort(W, 'descend');
  W = W(1:round(size(o, 1) * const.sparsifyFactor), :);
  P = P(o(1:round(size(o, 1) * const.sparsifyFactor)), :);
  V = V(o(1:round(size(o, 1) * const.sparsifyFactor)), :);
  O = O(o(1:round(size(o, 1) * const.sparsifyFactor)), :);

  % Improve depth at remaining points by performing a plane sweep in a small
  % oriented window around each point, and discard points with low alignment confidence
  tic
  [P, ~, lowConfIdx] = planeSweep(P, O, V, LFg, param);
  P(lowConfIdx, :) = [];
  V(lowConfIdx, :) = [];
  W(lowConfIdx) = [];
  t = toc;
  disp(['Plane sweep completed in ' num2str(t) 's']);

  tic
  dheuristic = wmf(dheuristic, lab2rgb(LF(:, :, :, param.cviewIdx, param.cviewIdx)), 256, 0.01^2, 5);
  t = toc;
  disp(['Weighted median filtering completed in ' num2str(t) 's']);

  tic
  o = diffuseSpatial(P(V(:, param.cviewIdx), :), W(V(:, param.cviewIdx)), LFg{param.cviewIdx}, dheuristic, param);
  t = toc;
  disp(['Diffusion completed in ' num2str(t) 's']);

  % Remove outliers and sharpen edges
  tic
  om = medfilt2(o, [3 3]);
  mn = min(min(om));
  mx = max(max(om));
  o(o > mx) = mx;
  o(o < mn) = mn;
  o = wmf(o, lab2rgb(LF(:, :, :, param.cviewIdx, param.cviewIdx)), 256, 0.001^2, 7);
  t = toc;
  disp(['Weighted median filtering completed in ' num2str(t) 's']);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % CROSS-HAIR VIEW PROJECTION %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  v = [1:param.szLF(3) repelem(param.cviewIdx, 1, param.szLF(4))];
  u = [repelem(param.cviewIdx, 1, param.szLF(3)) 1:param.szLF(4)];
  R = zeros(param.szLF(1), param.szLF(2), length(u));
  M = zeros(param.szLF(1), param.szLF(2), length(u));

  tic;
  parfor (i = 1:length(u), 18)
    [R(:, :, i), M(:, :, i)] = reproj(o,  param.cviewIdx - v(i), param.cviewIdx - u(i));
  end
  t = toc;
  disp(['Crosshair views projection completed in ' num2str(t) 's']);

  %%%%%%%%%%%%%%%%%%%%%%
  %  Angular Diffusion %
  %%%%%%%%%%%%%%%%%%%%%%

  % In U...
  tic;

  dEPIu = permute(R(:, :, param.szLF(3) + 1:end), [3 2 1]);
  dEPIu(isnan(dEPIu)) = 0;
  mEPIu = permute(M(:, :, param.szLF(3) + 1:end), [3 2 1]);

  % Select points occluded in the central view
  idx = ~V(:, param.cviewIdx);
  [wEPIu, lEPIu, ~] = splatEPIu(P(idx, :), V(idx, param.szLF(3) + 1:end), W(idx, :), param.szEPI);

  % Diffuse along horizontal EPIs
  U = diffuseAngular(dEPIu, mEPIu, lEPIu, wEPIu, o', EPIuc, param);
		     
  dEPIv = permute(permute(R(:, :, 1:param.szLF(3)), [2 1 3]), [3 2 1]);
  dEPIv(isnan(dEPIv)) = 0;
  mEPIv = permute(permute(M(:, :, 1:param.szLF(3)), [2 1 3]), [3 2 1]);
  
  idx = ~V(:, param.cviewIdx);
  [wEPIv, lEPIv, ~] = splatEPIv(P(idx, :), V(idx, 1:param.szLF(3)), W(idx, :), param.szEPI);

  % Diffuse along vertical EPIs
  V = diffuseAngular(dEPIv, mEPIv, lEPIv, wEPIv, o, EPIvc, param);
  V = permute(V, [2 1 3]);
  
  t = toc;
  disp(['EPI propagation completed in ' num2str(t) 's']);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %  Non-Cross Hair View Projection %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  tic;
  D = [];
  jv = [1:param.cviewIdx-1 param.cviewIdx + 1:param.szLF(3)];
  for i = [1:param.cviewIdx-1 param.cviewIdx + 1:param.szLF(3)]
    parfor (j = 1:length(jv), 12)
      [di, m] = reproj2offcenter(V, U, i, j, param);

      g = imgradient(LF(:, :, 1, i, j));
      g = 1./(1000 .* g.^2 + 0.0001);
      o = lahbpcg_mex(di, m  .* 15000, g, g, 10, 0.00001);

      o(o < min(min(di))) = min(min(di));
      o(o > max(max(di))) = max(max(di));
      Dt(:, :, j) = o;
    end
    D(:, :, i, jv) = Dt;
  end

  D(:, :, param.cviewIdx, :) = U;
  D(:, :, :, param.cviewIdx) = V;

  t = toc;
  disp(['All views projection completed in ' num2str(t) 's']);
  disp(['Depth estimation for ' num2str(param.szLF(3) * param.szLF(4)) ' views completed in ' num2str(toc(t0)) 's']);
  disp(['Output saved in ' fout '.mat']);
  
  save([fout '.mat'], 'D');
end
