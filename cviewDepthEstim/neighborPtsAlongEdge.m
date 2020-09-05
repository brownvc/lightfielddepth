%
% Return the neighbors for a point p in the edge image E.
% An point q in E is considered a neighbor of another point r if it lies on an edge (E(q) == 1), and
% it lies along the tangent at r. The set N is constructed by adding neighbors recursively starting
% at p, upto a maximum of maxCount
%
function N = neighborPtsAlongEdge(E, gx, gy, p, maxCount)

  po = p;
  N = zeros(maxCount, 2);
  i = 1;
  
  for k = 1:floor(maxCount/2)

    % Move in the tangent direction
    tx = -gy(p(2), p(1));
    ty = gx(p(2), p(1));

    if abs(ty) < abs(tx)
      px1 = p(1) + round(tx);
      px2 = px1;
      py1 = p(2) + ceil(ty);
      py2 = p(2) + floor(ty);
    else
      px1 = p(1) + ceil(tx);
      px2 = p(1) + floor(tx);
      py1 = p(2) + round(ty);
      py2 = py1;
    end

    % If an edge point exists in the tangent direction, add it to the list of neighbors
    if py1 < size(E, 1) & py1 > 0 & px1 < size(E, 2) & px1 > 0 & E(py1, px1) == 1
      p = [px1 py1];
      N(i, :) = p;
      i = i + 1;
    elseif py2 < size(E, 1) & py2 > 0 & px2 < size(E, 2) & px2 > 0 & E(py2, px2) == 1
      p = [px2 py2];
      N(i, :) = p;
      i = i + 1;
    else
      break;
    end
  end

  p = po;
  for k = 1:floor(maxCount/2)

    % Move in the opposite direction of the tangent
    tx = gy(p(2), p(1));
    ty = -gx(p(2), p(1));

    if abs(ty) < abs(tx)
      px1 = p(1) + round(tx);
      px2 = px1;
      py1 = p(2) + ceil(ty);
      py2 = p(2) + floor(ty);
    else
      px1 = p(1) + ceil(tx);
      px2 = p(1) + floor(tx);
      py1 = p(2) + round(ty);
      py2 = py1;
    end
        
    if py1 < size(E, 1) & py1 > 0 & px1 < size(E, 2) & px1 > 0 & E(py1, px1) == 1
      p = [px1 py1];
      N(i, :) = p;
      i = i + 1;
    elseif py2 < size(E, 1) & py2 > 0 & px2 < size(E, 2) & px2 > 0 & E(py2, px2) == 1
      p = [px2 py2];
      N(i, :) = p;
      i = i + 1;
    else
      break;
    end
  end
  
  N = sub2ind( size(E), N(1:i-1, 2), N(1:i-1, 1) );
end
