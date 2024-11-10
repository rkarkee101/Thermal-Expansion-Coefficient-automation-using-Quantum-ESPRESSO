#!/bin/bash

strain_values=(-0.03 -0.02 -0.01 0.00 0.01 0.02 0.03)

# Original cell parameters (replace with your actual parameters)
cell_params="   3.330908579  -0.000000000  -0.000000000
  -1.665454288   2.884651448   0.000000000
  -0.000000000  -0.000000000  12.768207697
"

# Loop through strain values
for k in "${strain_values[@]}"
do

    # Create folder and files
    folder_name=$(printf "strain_%.3f" $k)
    mkdir "$folder_name"
done
