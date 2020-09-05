%%
%% Detect edges by directional filtering with the filters provided
%% in F. The gradient of each filter is specified in gx, and gy
%%
function [E, Z] = epis2edges( EPI, F, m, gx, gy )
  szEpi = [size(EPI, 1) size(EPI, 2) size(EPI, 4)];
  E = zeros( szEpi );
  Z = zeros( szEpi );

  parfor i = 1:szEpi(3)
    [E(:, :, i), Z(:, :, i), ~] = findEdgesEPI( EPI(:, :, :, i), F, m, gx, gy);
  end

end
