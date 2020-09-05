#!/bin/bash

lightfields="'$*'"
matlab -nodisplay -r "runOnLightfields(strsplit($lightfields, ','));exit"
