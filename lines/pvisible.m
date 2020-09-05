%%
%% Get the cross-hair view indices in which each point is visible
%%
function V = pvisible(P, gxEPIu, gyEPIu, gxEPIv, gyEPIv)

  % Group points into lines by rounded y-coordinate
  [P, o] = sortrows(P, 2);
  [~, ~, X] = unique( round(P(:, 2)) );
  A = accumarray(X, 1:size(P, 1), [], @(r){P(r, :)});

  U = cell(size(A, 1), 1);
  for i = 1:size(A, 1)
    a = A{i};
    y = round(a(1, 2));
    if y < 1 | y > size(gxEPIu, 3) 
      U(i) = {zeros( size(a, 1), size(gxEPIu, 1) )};
      continue;
    end

    lines = [a(:, 1) - floor(size(gxEPIu, 1) ./ 2) .* a(:, 3) ...
	a(:, 1) + floor(size(gxEPIu, 1) ./ 2) .* a(:, 3)];

    U(i) = {visibility(lines, gxEPIu(:, :, y), gyEPIu(:, :, y))};
  end

  % Reverse U to original point order
  [~, o] = sort(o);
  U = vertcat(U{:});
  P = P(o, :);
  U = U(o, :);

  % Group points into lines by rounded x-coordinate
  [P, o] = sortrows(P, 1);
  [~, ~, X] = unique( round(P(:, 1)) );
  A = accumarray(X, 1:size(P, 1), [], @(r){P(r, :)});

  V = cell(size(A, 1), 1);
  for i = 1:size(A, 1)
    a = A{i};
    x = round(a(1, 1));
    if x < 1 | x > size(gxEPIv, 3) 
      V(i) = {zeros( size(a, 1), size(gxEPIv, 1) )};
      continue;
    end
    
    lines = [a(:, 2) - floor(size(gxEPIv, 1) ./ 2) .* a(:, 3) ...
	     a(:, 2) + floor(size(gxEPIv, 1) ./ 2) .* a(:, 3)];
    
    V(i) = {visibility(lines, gxEPIv(:, :, x), gyEPIv(:, :, x))};
  end

  % Reverse V to original point order
  [~, o] = sort(o);
  V = vertcat(V{:});
  V = V(o, :);
  
  V = logical([V U]);
end
