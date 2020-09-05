%%
%% Splat points as lines onto a vertical (v) EPI with visibility V and weight W
%% 
function [M, D, I] = splatEPIv(P, V, W, szEPI)

  [L, o] = points2vlines(P, szEPI);
  Lv = cellfun(@(i) V(i, :), o, 'UniformOutput', false);
  Lw = cellfun(@(i) W(i, :), o, 'UniformOutput', false);
  Ld = cellfun(@(i) P(i, 3), o, 'UniformOutput', false);
  
  M = zeros(szEPI);
  D = zeros(szEPI);
  I = zeros(szEPI);

  for i = 1:szEPI(3)
    if isempty(L{i})
      continue;
    end
    M(:, :, i) = drawVisibleLines(L{i}, Lw{i}, Lv{i}, 0, szEPI([1 2]));
    D(:, :, i) = drawVisibleLines(L{i}, Ld{i}, Lv{i}, 0, szEPI([1 2]));
    %I(:, :, i) = drawLines2(L{i}, o{i}, V{i}, 0, szEPI([1 2]));
  end

end 
