%%
%% Return n exponentially spaced points between v0 and v1
%%
function v = expspace(v0, v1, d, n)
  v = exp(d .* linspace(0, 1, n));
  v = v - min(v);
  v = (v ./ max(v)) .* (v0 - v1);
  v = v + v1;
end
