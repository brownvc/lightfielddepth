function O = diffuseAngular(d, m, l, w, dmapc, EPI, param)

  szEPI = size(EPI);
  
  parfor i = 1:size(EPI, 4)
    e(:, :, i) = imgradient(EPI(:, :, 1, i));
    m(:, :, i) = medfilt2(m(:, :, i), [1 3]);
  end

  m = m .* 15;
  d(m == 0) = 10000;
  
  d(w > 0) = l(w > 0);
  m(w > 0) = w(w > 0);

  d(param.cviewIdx, :, :) = dmapc;
  m(param.cviewIdx, :, :) = 5;

  nWorkers = 12;
  uEpisPerWorker = ceil(szEPI(4) ./ nWorkers);

  M = accumarray( repelem([1:nWorkers]', uEpisPerWorker, 1), ...
		    1:nWorkers * uEpisPerWorker, [], @(r){m(:, :, min(r, szEPI(4)))}); 
  D = accumarray( repelem([1:nWorkers]', uEpisPerWorker, 1), ...
		    1:nWorkers * uEpisPerWorker, [], @(r){d(:, :, min(r, szEPI(4)))}); 
  E = accumarray( repelem([1:nWorkers]', uEpisPerWorker, 1), ...
		    1:nWorkers * uEpisPerWorker, [], @(r){e(:, :, min(r, szEPI(4)))}); 
    
  O = {};
  parfor (i = 1:size(M, 1), nWorkers)
    mi = M{i};
    di = D{i};
    ei = E{i};
    oi = zeros( szEPI(1), szEPI(2), uEpisPerWorker );
    
    for j = 1:uEpisPerWorker
      d = padarray(double(di(:, :, j)), [1 1], 0);
      w = padarray(double(mi(:, :, j)), [1 1], 0);
      m = max(max(ei(:, :, j)));
      g = padarray(ei(:, :, j), [1 1], m);
      g = 1 ./ (10 .* g.^2 + 0.0001);
      o = lahbpcg_mex(d, w, g, g, 1000, 0.00001);
      oi(:, :, j) = o( 2:end - 1, 2:end - 1);
    end
    O(i) = {oi};
  end

  O = cellfun(@(u) permute(u, [3 2 1]), O, 'UniformOutput', false);
  O = vertcat(O{:});
  O = O(1:size(EPI, 4), :, :);
end
