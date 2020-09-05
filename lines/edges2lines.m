%%
%% Given an edge confidence map E and a slope map Z, fit a line
%% to the edges. The slope of each line is provided in m.
%%
%% The function returns a line set L, where each line is defined by its
%% top and bottom intercept on an EPI. 
%%
function L = edges2lines( E, Z, m )
  szEpi = size(E);

  L = cell(szEpi(3), 1);

  parfor i = 1:szEpi(3)
    lines = fitLinesEPI( E(:, :, i), Z(:, :, i), m); 

    if isempty(lines)
      lines = [0 0];
    end
    L(i) = {lines};
  end

end
