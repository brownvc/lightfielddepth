%%
%% Reproject depth to a non-crosshair view (which can be a novel view)
%% using the depth of the cross hair views provided in U and V
%%
function [D, M] = reproj2offcenter(V, U, vo, uo, param)

  uIdx = min(max(1, round(uo)), param.szLF(4));
  vIdx = min(max(1, round(vo)), param.szLF(3));

  [ur, um] = reproj(U(:, :, uIdx), param.cviewIdx - vo, 0);
  [vr, vm] = reproj(V(:, :, vIdx), 0, param.cviewIdx - uo);

  vm = medfilt2(vm, [3 3]);
  um = medfilt2(um, [3 3]);

  M = cat(3, um, vm);
  R = cat(3, ur, vr);
  R(isnan(R)) = 0;
  mc = num2cell(M, 3);
  rc = num2cell(R, 3);

  D = cellfun(@(ri, mi) mean(ri(mi ~= 0)), rc, mc);
  D(isnan(D)) = 0;
  M  = sum(M, 3);
end

