%%
%% This method was adapted from Jiang et al.'s code for performing forward
%% projection of depth and color. We only use it to reproject depth.
%% Jiang et al.'s code can be found at:
%% http://clim.inria.fr/research/DepthEstim/DepthEstim.zip
%%
function [outputFW, maskFW] = reproj(disparity_ref, delY, delX)

  [h, w] = size(disparity_ref);
  [X, Y] = meshgrid(1:w, 1:h);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%      Forward propagation from disparity map of the knwon view       %%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  curX_forward = round(X - delX * disparity_ref);
  curY_forward = round(Y - delY * disparity_ref);

  maskFW = false(h,w);
				%DispFW = zeros(h, w);
  DispFW = ones(h, w)*(-1000);
  DispFwIdx = zeros(h, w);
  NonOverlapped = false(h,w);

  for H = 1:h
    for W = 1:w

      if curY_forward(H,W)<=h && curX_forward(H,W)<=w && curY_forward(H,W)>=1 && curX_forward(H,W)>=1
	if(~maskFW(curY_forward(H,W),curX_forward(H,W)) )
	  maskFW(curY_forward(H,W),curX_forward(H,W)) = true;
	  DispFW(curY_forward(H,W),curX_forward(H,W)) = disparity_ref(H,W);
	  DispFwIdx( curY_forward(H, W), curX_forward(H, W) ) = sub2ind( [h, w], H, W);
	  NonOverlapped(H, W) = true;
	  
	elseif (disparity_ref(H,W) > DispFW(curY_forward(H,W),curX_forward(H,W)) )
	  maskFW(curY_forward(H,W),curX_forward(H,W)) = true;
	  DispFW(curY_forward(H,W),curX_forward(H,W)) = disparity_ref(H,W);

	  if DispFwIdx( curY_forward(H, W), curX_forward(H, W) ) ~= 0
	    NonOverlapped( DispFwIdx( curY_forward(H, W), curX_forward(H, W) ) ) = false;
	  end
	  DispFwIdx( curY_forward(H, W), curX_forward(H, W) ) = sub2ind( [h, w], H, W);
	  NonOverlapped(H, W) = true;
        end
	
      end
    end
  end

  curX_forward = double(X - delX * disparity_ref);
  curY_forward = double(Y - delY * disparity_ref);
  curX_forward = curX_forward(NonOverlapped);
  curY_forward = curY_forward(NonOverlapped);

  outputFW = zeros(h,w);
  ImgRefVec = disparity_ref(NonOverlapped);
  outputFW = griddata(curX_forward, curY_forward, ImgRefVec, X, Y, 'linear');
  outputFW = reshape(outputFW,[h,w]);
  maskFW = maskFW & ~isnan(outputFW);
end
