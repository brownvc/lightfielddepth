%%
%% Run the depth estimation code on multiple lightfields, 
%% saving results to file. 
%%
function runOnLightfields (D)
  addpath('./util', './lines', './depth', './cviewDepthEstim', './cviewDepthEstim/wmf', ...
	  './angularDiffusion');
  if isempty(D{1})
    disp('Error! No input specified. Please see README.md for help.');
    return;
  end
  
  % Results are saved in a a folder with the current timestamp as the name
  %
  tstamp = datestr(datetime, 'dd-mmm-yyyy HHMM');
  tstamp( isspace(tstamp) ) = '_';
  folder = ['./results/' tstamp 'hrs'];
  mkdir(folder);

  % The output file the name is the name of the light field
  fout = {};
  for i = 1:length(D)
    [filepath, name, ext] = fileparts( D{i} );
    if isempty(ext)
      str = D{i};
      if str(end) == '/'
        str(end) = [];
      end
      s = strsplit(str, '/');
      fout{i} = s{end};
    else
      disp('Input Error! Please provide a path to the folder containing light field images');
    end
  end

  % Run parameters
  % Change these to evaluate the output with different settings for different light fields
  param = parameters;

  % Initialize Matlab's parpool
  cluster = parcluster('local');
  cluster.NumWorkers = param.nWorkers;
  saveProfile(cluster);
  delete(gcp('nocreate'));
  parpool(param.nWorkers);

  % Run...
  for i = 1:length(D)
    VCLFD( D{i}, [folder '/' fout{i}], param);
  end
end
