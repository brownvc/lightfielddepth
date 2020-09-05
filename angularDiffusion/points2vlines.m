%
% Convert points to lines defined by their top and bottom intercepts on 
% vertical (v) EPIs.
% 
function [L, O] = points2vlines(P, szEPI)

  % Group points into lines by rounded x-coordinate
  [P, o] = sortrows(P, 1);
  idx = P(:, 1) < 1 | P(:, 1) > szEPI(3);
  P(idx, :) = [];
  o(idx, :) = [];
  
  [~, ~, X] = unique( round(P(:, 1)) );
  A = accumarray(X, 1:size(P, 1), [], @(r){[P(r, :) o(r, :)]});

  L = cell(szEPI(3), 1);
  for i = 1:size(A, 1)
    a = A{i};
    x = round(a(1, 1));
    L(x) = {[a(:, 2) - floor(szEPI(1) ./ 2) .* a(:, 3) ...
	     a(:, 2) + floor(szEPI(1) ./ 2) .* a(:, 3)]};
    O(x) = {a(:, 4)};
  end

end
