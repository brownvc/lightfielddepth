%%
%% Merge horizontal and vertical EPI lines into a single set of 3D points. 
%% Points in the set P are represented by their spatial position in the central view,
%% along with their depth.
%%
function [P, puIdx, pvIdx] = merge(Lu, Lv, szLF)
  
  Lu = cellfun(@(l, i) [sum(l, 2) ./ 2, ...                        % x-coordinate
			repelem(i, size(l, 1), 1), ...             % y-coordinate
			(l(:, 2) - l(:, 1)) ./ (szLF(3) - 1)], ... % disparity
	       Lu, num2cell([1:length(Lu)]'), 'UniformOutput', false);

  Lv = cellfun(@(l, i) [repelem(i, size(l, 1), 1), ...             % x-coordinate
			sum(l, 2) ./ 2, ...                        % y-coordinate
			(l(:, 2) - l(:, 1)) ./ (szLF(3) - 1)], ... % disparity
	       Lv, num2cell([1:length(Lv)]'), 'UniformOutput', false);

  Lu = vertcat(Lu{:});
  Lv = vertcat(Lv{:});

  P = [Lu; Lv];
  puIdx = zeros(size(P, 1), 1, 'logical');
  pvIdx = zeros(size(P, 1), 1, 'logical');
  puIdx([1:size(Lu, 1)]) = 1;
  pvIdx([size(Lu, 1) + 1:size(Lu, 1) + size(Lv, 1)]) = 1;
end
