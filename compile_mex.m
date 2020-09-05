filelist = dir('./ImageStack/src/');
filelist = filelist(~startsWith({filelist.name}, '.'));
filelist = filelist(~startsWith({filelist.name}, 'Func'));
filelist = filelist(endsWith({filelist.name}, '.cpp'));

filelist = cellfun(@(a) strcat('./ImageStack/src/', a), {filelist.name}, 'UniformOutput', false);
filelist = join(cellfun(@string, filelist));

eval(strcat("mex ./lahbpcg_mex.cpp ", filelist, " -DNO_SDL -DNO_OPENEXR -DNO_TIFF -DNO_JPEG -DNO_PNG -lfftw3f -ldl -R2018a"))
