
# View-Consistent 4D Light Field Depth Estimation
 [Numair Khan](https://cs.brown.edu/~nkhan6)<sup>1</sup>, 
 [Min H. Kim](http://vclab.kaist.ac.kr/minhkim/)<sup>2</sup>,
 [James Tompkin](http://www.jamestompkin.com)<sup>1</sup><br>
 <sup>1</sup>Brown, <sup>2</sup>KAIST<br>
 BMVC 2020

### [Paper]() | [Presentation Video]() | [Supplemental Results Video]() 

## Citation
If you use this code in your work, please cite the following works:

```
@article{khan2019vclfd,
  title={View-consistent 4D Lightfield Depth Estimation},
  author={Numair Khan, Min H. Kim, James Tompkin},
  journal={British Machine Vision Conferfence},
  year={2020},
}

@techreport(khan2020falfd,
  title={Fast and Accurate {4D} Light Field Depth Estimation},
  author={Numari Khan, Min H. Kim, James Tompkin},
  year={2020},
  institution={Brown University},
  number={CS-20-01},
}
```

## Running the MATLAB Code
* [Installing ImageStack](#installing-imagestack)
* [Generating Depth](#generating-depth)
* [Troubleshooting](#troubleshooting)

### Installing ImageStack

### Generating Depth
To generate disparity estimates for all views of a light field, use `run.sh` followed by the path to the light field file:

``` sudo ./run.sh <path-to-light-field> ```

The light field is provided as a `.mat` file containing a 5D array. The dimensions of the 5D array should be ordered as (y, x, rgb, v, u) where "rgb" denotes the color channels. 

```
                 u              
       ---------------------------->
       |  ________    ________
       | |    x   |  |    x   |
       | |        |  |        |
     v | | y      |  | y      | ....
       | |        |  |   pp     |     
       | |________|  |________| 
       |           :
       |           :
       v
```

Alternatively, a path to a directory of images may be provided to `run.sh`. The directory should contain a file called `config.txt` with the dimensions of the light field on the first line in format `y, x, v, u`.

<bf>Make sure to set the camera movement direction for both u and v in `parameters.m`.</bf>

The depth estimation results are output to a 4D MATLAB array in `./results/<time-stamp>/`.

### Troubleshooting
- Code fails with error `Index exceeds the number of array elements`: Make sure you are following the correct dimensional
ordering; for light field images this should be `(y, x, rgb, v, u)` and for depth labels `(y, x, v, u)`.
- The output has very high error: Make sure you specify the direction in which the camera moves in u and v. This can be done by setting the boolean variables `uCamMovingRight` and `vCamMovingRight` in `parameters.m`. The camera movement direction determines the occlusion order of EPI lines, and is important for edge detection and depth ordering.
- The code has been run and tested in MATLAB 2019b. Older version of MATLAB may throw errors on some functions.

## Errata 

- In Figure 8 of the main paper, the central row of the EPFL light fields show view(4, 4), rather than view(5, 5).
- The manner in which labels are propagated has been updated in this codebase. Before, we began at the top-most view in the central column and moved down. In this code, we move out from the central view in a spiral. This leads to a slight improvement over the results reported in the ICCV published paper. The paper linked from this repository includes the new results which match the code repository.
- The supplemental material linked from this repository has additional analysis of hyperparameter variation for all techniques across our analysis metrics.
