
classdef parameters
   properties 
     % Multithreading
     nWorkers = 3;

     szLF = [];
     szEPI = [];
     cviewIdx = 0;
     
     % The code requires the camera to move towards the RIGHT in both the horizontal (u) 
     % and vertical (v) directions. This ensures a uniform occlusion order for lines
     % in an EPI based on slope. 
     % Set the following parameters to ensure the light field is loaded in the 
     % correct order.
     uCamMovingRight = false; 
     vCamMovingRight = true;

     % The maximum absolute disparity between two adjacent light field views
     maxAbsDisparity = 2.0; 
     nDisparity = 60;
   end
end
