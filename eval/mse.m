%%
%% Mean squared error times 100
%%
function e = mse(dmap, dgt)
  e = mean((dmap - dgt).^2, 'all') * 100;
end
