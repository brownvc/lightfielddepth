%
% Convert points to lines defined by their top and bottom intercepts on 
% horizontal (u) EPIs.
% 
function [L, O] = points2ulines(P, szEPI)

  % Group points into lines by rounded y-coordinate
  [P, o] = sortrows(P, 2);
  idx = P(:, 2) < 1 | P(:, 2) > szEPI(3);
  P(idx, :) = [];
  o(idx, :) = [];

  [~, ~, X] = unique( round(P(:, 2)) );
  A = accumarray(X, 1:size(P, 1), [], @(r){[P(r, :) o(r, :)]});

  L = cell(szEPI(3), 1);
  for i = 1:size(A, 1)
    a = A{i};
    y = round(a(1, 2));
    L(y) = {[a(:, 1) - floor(szEPI(1) ./ 2) .* a(:, 3) ...
	     a(:, 1) + floor(szEPI(1) ./ 2) .* a(:, 3)]};
    O(y) = {a(:, 4)};
  end

end
