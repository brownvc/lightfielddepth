%%
%% Dense depth diffusion in the spatial domain
%%
function o = diffuseSpatial(P, W, I, dheuristic, param)

  P(:, [1 2]) = P(:, [1 2]) * const.diffusionScale;

  % Gradients of the depth heuristic
  [gxd, gyd] = imgradientxy( imresize( dheuristic, const.diffusionScale) );
  gd = sqrt( gxd.^2 + gyd.^2 );
  gd(:, [1 end]) = max(max(gd));
  gd([1 end], :) = max(max(gd));

  gd = imgaussfilt(gd, 1);

  % Gradients of the guidance image
  [gx, gy] = imgradientxy( imresize( I, const.diffusionScale) );
  g = sqrt( gx.^2 + gy.^2 );
  g(:, [1 end]) = max(max(g));
  g([1 end], :) = max(max(g));

  [w, d] = splat(P, W, param.szLF([1 2]) * const.diffusionScale);

  % Weights are determined empirically and work for all light fields
  wg = 100./255 ./ sqrt(0.01);
  g = wg .* g .* gd;
  g = double(1 ./ (10 * g.^2 + 0.0001));
  w = w .* 1500;
  
  o = lahbpcg_mex(d, w, g, g, 20, 0.00001);
  o = imresize(o, param.szLF([1 2]));
end
