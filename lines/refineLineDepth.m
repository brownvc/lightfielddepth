%%
%% Refine the depth of each EPI line by minimizing the entropy of a set of points
%% sampled along the line. 
%%
function [L, C] = refineLineDepth(L, gxEPI, gyEPI, EPI) 

  for k = 1:length(L)

    lk = L{k};

    epigx = gxEPI(:, :, k);
    epigy = gyEPI(:, :, k);

    cprev = linesCost(lk, EPI(:, :, :, k));

    for j = 1:const.refineIterCount
      ti = const.refineTempStart * (const.refineTempAnnealFactor .^ (j - 1));
      dxt = rand(size(lk, 1), 1) * 2 * ti - ti;
      dxb = rand(size(lk, 1), 1) * 2 * ti - ti;

      lines = [lk(:, 1) + dxt lk(:, 2) + dxb];
      %c = refineCost(lines, epigx, epigy);
      c = linesCost(lines, EPI(:, :, :, k));
      % Update lines for which cost has reduced
      idx = c < cprev;

      lk(idx, :) = lines(idx, :);
      cprev(idx) = c(idx);
    end
    L(k) = {lk};
    C(k) = {cprev};
  end

end

%%
%% The entropy-based cost of a given line depth assignment
%%
function c = linesCost(lines, epi)
  szEpi = [size(epi, 1) size(epi, 2)];
  c = zeros(size(lines, 1), 1);
  nSamples = 15;

  % The fractional x values of each line at integer y coordinates
  %
  m = (lines(:, 1) - lines(:, 2)) ./ (szEpi(1) - 1);
  x = min(max(1, lines(:, 1) - m * linspace(0, szEpi(1) - 1, nSamples)) , szEpi(2));

  xf = floor(x);
  xc = ceil(x);
  y = repelem(linspace(1, szEpi(1), nSamples), size(lines,1), 1);
  w = x - xf; % linear interpolation weights

  % cubic interpolation
  [p, q] = meshgrid([1:szEpi(2)], [1:szEpi(1)]);
  li = interp2(p, q, epi(:, :, 1), x, y, 'cubic');

  % Linearly interpolate the luminance value of the line
  li = li ./ max(li, [], 2);
  c = entropy(li);
end
