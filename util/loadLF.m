%%
%% Load the light field images into a 5D array: (y, x, rgb, v, u)
%% Indices of the returned array follow Matlab's convention of (row, column):
%%                 u
%%    ---------------------------->
%%    |  ________    ________
%%    | |    x   |  |    x   |
%%    | |        |  |        |
%%  v | | y      |  | y      | ....
%%    | |        |  |        |     
%%    | |________|  |________|
%%    |           :
%%    |           :
%%    v
%%
%% The input files may be in .mat, or
%% alternately, a folder with the light field images (PNGs) may be provided.

function [LF, dmin, dmax] = loadLF( fin, uCameraMovingRight, vCameraMovingRight, cspace)

  [folder, name, ext] = fileparts(fin);
  LF = [];

  if isempty(ext)
    % Read the light field from a directory of images.
    % Assumes the images in the directory are named in row-major order.
    % A file with the name config.txt  must be included in the image 
    % directory which lists the size of the light field as v, u, y, x

    config = fopen(fullfile(fin, 'config.txt'), 'r');
    assert( config > 0, ['Error: No config.txt found at ' fin]);
    pm = textscan(config, '%f %f %f %f %f %f', 1);
    sz = pm(1:4);
    dmin = pm(5);
    dmax = pm(6);
    fclose(config);

    v = sz{3}; u = sz{4}; y = sz{1}; x = sz{2}; 
    files = dir(fullfile(fin, '*.png'));
    assert( length(files) == u * v, 'Error: Lightfield size mismatch');

    if strcmp(cspace, 'lab')
      LF = zeros(y, x, 3, v, u);
    elseif strcmp(cspace, 'gray')
      %LF = zeros(y, x, 1, v, u, 'uint8');
      LF = zeros(y, x, 1, v, u);		  
    else
      LF = zeros(y, x, 3, v, u);
    end

    for i = 1:v
      for j = 1:u
        filename = fullfile(fin, files((i - 1) * u + j).name);

	if strcmp(cspace, 'lab')
	  LF(:, :, :, i, j) = rgb2lab(imread(filename));
	elseif strcmp(cspace, 'ycbcr')
	  LF(:, :, :, i, j) = rgb2ycbcr(imread(filename));
        elseif strcmp(cspace, 'gray')
          LF(:, :, 1, i, j) = rgb2gray(imread(filename));
	else 
	  LF(:, :, :, i, j) = (imread(filename));		  
	end  
      end
    end
  elseif strcmp(ext, '.mat')
    % Read light field from a .mat file
    LF = struct2cell(load(fin));
    LF = LF{1};
  else
    disp(['Error: Unrecognized light field file extension ' ext]);
    disp("Hint: Use utility function HCIloadLF in runOnLightfields.m to load HCI dataset light fields.");
    return;
  end

  % Flipping ensures a uniform occlusion order in EPIs
  if uCameraMovingRight
    LF = flip(LF, 5);
  end
  if vCameraMovingRight
    LF = flip(LF, 4);
  end

end
