%%
%% Return a symmetric num_views x num_views matrix representing the view consistency
%% between each pair of views in the light field
%%
function C = pairwiseconst(D)
  szLF = size(D);
  numViews = szLF(3) * szLF(4);

  C = zeros( numViews, numViews);
  Dc = reshape(num2cell(D, [1 2]), 1, numViews);
  
  for i = 1:numViews
    [vs, us] = ind2sub( szLF([3 4]), i); % source view indices
    di = D(:, :, vs, us);
    ci = zeros(1, numViews);
    
    parfor (j = 1:numViews, 24)

      if i >= j
	ci(j) = 0;
	continue;
      end
      
      [vt, ut] = ind2sub( [szLF(3) szLF(4)], j); % target view indices

      % Project target onto source
      [r, m] = reproj( Dc{j}, 0, vt - vs, ut - us);
      
      R = [r(:) di(:)];
      R(isnan(R)) = 0;
      R(~m(:), :) = 0; 
      vi = var(R, [], 2);
      vi(~m(:)) = 0; % ignore disoccluded pixels 
      
      ci(j) = mean(vi, 'all');
    end
    C(:, i) = ci;
  end

end
