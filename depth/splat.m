%
% Splat depth labels, weights, and point ids onto an image
%
function [M, S, Id] = splat(D, W, sz)
   [D, o] = sortrows(D, 3); % sort so that foreground points are drawn after
   
   D(:, [1 2]) = round(D(:, [1 2]));
   oIdx = D(:, 1) < 1 | D(:, 1) > sz(2) | D(:, 2) < 1 | D(:, 2) > sz(1);

   if size(D, 1) == size(W, 1)
     W = W(o);
     W(oIdx, :) = [];
   end
   D(oIdx, :) = [];
   sIdx = sub2ind( sz, D(:, 2), D(:, 1) );

   S = zeros(sz);
   S(sIdx) = D(:, 3);

   M = zeros(sz);
   M(sIdx) = W;

   Id = zeros(sz);
   Id(sIdx) = o(~oIdx);
 end 
