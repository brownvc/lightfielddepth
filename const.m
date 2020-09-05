%%
%% Constants used by the algorithms
%% These should not be changed. Any run specific parameters can
%% be set in parameters.m
%%
classdef const
   properties (Constant = true)
     SegMinWidthMultiplier = 0.1;

     filtOutliersGradientDirectionThresh = 0.97;
     filtOutliersMinContigPixels = 4;

     visibilityMinViews = 3;
     visibilityAlignmentThreshold = 0.95 % this is a cos(theta) where theta is the alignment angle

     refineIterCount = 10;
     refineTempStart = 0.15;
     refineTempAnnealFactor = 0.88;

     trilatFiltWinSz = 10;

     sparsifyFactor = 0.9;

     diffusionScale = 2.0;

     planeSweepMaxViews = 8;
     planeSweepPatchSz = [5 5];
     planeSweepMaxDispOffset = 0.25;
     planeSweepNumDispOffset = 9; % This should be an odd number

   end
end
