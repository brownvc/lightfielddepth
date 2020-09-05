%%
%% Rasterize EPI lines
%%
function bw = drawVisibleLines(lines, c, v, emptyVal, epiSz)

  [~, o] = sort(lines(:, 2) - lines(:, 1));
  lines = lines(o, :);
  c = c(o, :);
  v = v(o, :);

  bw = ones(epiSz) .* emptyVal;
  for i = 1:size(lines, 1)

    x = [lines(i, 1) lines(i, 2)];  
    y = [1 epiSz(1)];                  

    nPoints = epiSz(1);
    rIndex = [y(1):y(2)]; 
    cIndex = max(1, min(round(linspace(x(1), x(2), nPoints)), epiSz(2)));
    index = sub2ind(epiSz, rIndex, cIndex);
    index = index(logical(v(i, :)));
    bw(index) = c(i, 1);
  end
end
