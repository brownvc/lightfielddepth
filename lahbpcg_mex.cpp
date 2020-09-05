
#include <stdio.h>
#include "mex.h"
#include "./ImageStack/src/main.h"
#include "./ImageStack/src/Image.h"
#include "./ImageStack/src/LAHBPCG.h"

using namespace std;

void lahbpcg_mex(double *d, double *w, double *gx, double *gy, double *o, double niter, double merr, mwSize m, mwSize n) {
  ImageStack::Image data(n, m, 1, 1);
  ImageStack::Image grad(n, m, 1, 1);
  ImageStack::Image data_weight(n, m, 1, 1);
  ImageStack::Image gradx_weight(n, m, 1, 1);
  ImageStack::Image grady_weight(n, m, 1, 1);
  
  //cout << "[n, m] = [" << int(n) << ", " << int(m) << "]" <<endl;

  
  for (int x = 0; x < n; x++) {
    for (int y = 0; y < m; y++) {
      int idx = x * m + y;
      data(x, y) =  d[idx];
      grad(x, y) =  0;
      data_weight(x, y) =  w[idx];
      gradx_weight(x, y) =  gx[idx];
      grady_weight(x, y) =  gy[idx];
    }
  }

  ImageStack::LAHBPCG *oplahbpcg = new ImageStack::LAHBPCG();
  ImageStack::Image result = oplahbpcg->apply(data, grad, grad, data_weight, gradx_weight, grady_weight, niter, merr);

  for (int x = 0; x < n; x++) {
    for (int y = 0; y < m; y++) {
      int idx = x * m + y;
      o[idx] = result(x, y);
    }
  }
  
  delete oplahbpcg;
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  if(nrhs != 6)
    mexErrMsgIdAndTxt("MexLAHBPCG:nrhs", "Six inputs required.");

  if(nlhs != 1) {
    mexErrMsgIdAndTxt("MexLAHBPCG:nlhs", "One output required.");
  }

  double *d = mxGetDoubles(prhs[0]);
  double *w = mxGetDoubles(prhs[1]);
  double *gx = mxGetDoubles(prhs[2]);
  double *gy = mxGetDoubles(prhs[3]);
  double niter = mxGetScalar(prhs[4]);
  double merr = mxGetScalar(prhs[5]);
  plhs[0] = mxCreateDoubleMatrix(mxGetM(prhs[0]), mxGetN(prhs[0]), mxREAL);
  double *o = mxGetDoubles(plhs[0]);


  //cout << "Calling" << endl;
  lahbpcg_mex(d, w, gx, gy, o, niter, merr, mxGetM(prhs[0]), mxGetN(prhs[0]) );
}



