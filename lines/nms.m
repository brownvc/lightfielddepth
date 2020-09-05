%%
%% Non-Maximal Suppression
%% 
function s = nms(im, g)
  h = size(im, 1);
  w = size(im, 2);

  g(:, 2) = -g(:, 2);

  % Get the direction of the two closest pixels in the gradient
  % direction on an integer grid. 
  a = ceil(abs(g)) .* sign(g + eps);
  b = (abs(g(:, 1)) > abs(g(:, 2))) .* repmat([1 0], size(g, 1), 1) .* sign(g(:, 1) + eps) + ...
      (abs(g(:, 1)) <= abs(g(:, 2))) .* repmat([0 1], size(g, 1), 1) .* sign(g(:, 2) + eps); 
  theta = atan( abs(g(:, 2)) ./ abs(g(:, 1)) );

  [X, Y] = meshgrid(1:w, 1:h);
  A = sub2ind( size(im), min( h, max(1, Y(:) + a(:, 2))), min( w, max(1, X(:) + a(:, 1))) );
  B = sub2ind( size(im), min( h, max(1, Y(:) + b(:, 2))), min( w, max(1, X(:) + b(:, 1))) );
  
  l1 = abs(pi/2 - theta)/ (pi/2);
  v = (1 - l1) .* im(A)  + l1 .* im(B);

  % The closest pixels to the negative of the gradient
  c = -a;
  d = -b;
  C = sub2ind( size(im), min( h, max(1, Y(:) + c(:, 2))), min( w, max(1, X(:) + c(:, 1))) );
  D = sub2ind( size(im), min( h, max(1, Y(:) + d(:, 2))), min( w, max(1, X(:) + d(:, 1))) );
  w = (1 - l1) .* im(C) + l1 .* im(D);

  s = reshape( (im(:) > v) & (im(:) > w) , size(im, 1), size(im, 2) );
end
