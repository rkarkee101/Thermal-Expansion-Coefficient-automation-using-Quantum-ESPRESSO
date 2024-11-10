#!/bin/bash

# Initial setup: define strain values and original cell parameters
strain_values=(-0.03 -0.02 -0.01 0.00 0.01 0.02 0.03)

# Original cell parameters (replace with your actual parameters)
cell_params="   3.330908579  -0.000000000  -0.000000000
  -1.665454288   2.884651448   0.000000000
  -0.000000000  -0.000000000  12.768207697
"

# Loop through strain values
for k in "${strain_values[@]}"
do
    # Create strain matrix E
    E=$(echo "scale=10; 1+$k" | bc)

    # Apply strain to cell parameters (matrix multiplication)
    strained_cell_params=$(python3 -c "
import numpy as np

E = float('$E')
cell_params = '''$cell_params'''.strip().split()
# Convert cell parameters into a numpy array
cell = np.array([list(map(float, cell_params[i:i+3])) for i in range(0, len(cell_params), 3)])
strain_matrix = np.array([[E, 0, 0], [0, E, 0], [0, 0, E]])
# Perform matrix multiplication
new_cell = np.dot(strain_matrix, cell.T).T
# Print the new cell parameters
for row in new_cell:
    print('   '.join(map(str, row)))
")

    # Check if strained cell parameters were generated successfully
    if [ -z "$strained_cell_params" ]; then
        echo "Error: Failed to generate strained cell parameters"
        exit 1
    fi

    # Debugging output for strained cell parameters
    echo "Strained Cell Parameters for strain $k:"
    echo "$strained_cell_params"

    # Create folder and files
    folder_name=$(printf "strain_%.3f" $k)
    mkdir "$folder_name"

    # Check if the folder was created successfully
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create directory $folder_name"
        exit 1
    fi

    cp scf.in job_scf job_phon header.in mesh.conf "$folder_name/"

    # Append the new cell parameters directly to scf.in
    {
        echo "CELL_PARAMETERS (angstrom)"
        echo "$strained_cell_params"
    } >> "$folder_name/scf.in"

    # Debugging: Show the contents of the updated scf.in file
    echo "Contents of $folder_name/scf.in after update:"
    cat "$folder_name/scf.in"

    echo "Submitting relax calculation"
    cd $folder_name
    sbatch job_scf
    cd ..
    echo "---------------------"




done



# Post-processing section after SCF job completion
for folder in $(ls -d */); do
    cd $folder

    # Wait for the SCF job to finish by checking "JOB DONE" in scf.out
    while ! grep -q "JOB DONE" scf.out; do
        echo "Waiting for SCF job to finish in folder $folder..."
        sleep 60  # Check every 60 seconds (can adjust the wait time as needed)
    done

    echo "SCF job finished in folder $folder"

    # Extract new atomic positions (final set) from scf.out
    new_atomic_positions=$(awk '/ATOMIC_POSITIONS/ {block_start=NR} /End final coordinates/ {block_end=NR-1} END {for (i=block_start; i<=block_end; i++) print lines[i]} {lines[NR]=$0}' scf.out)

    # Check if new atomic positions were successfully extracted
    if [ -z "$new_atomic_positions" ]; then
        echo "Error: Failed to extract new atomic positions from scf.out in $folder"
        exit 1
    fi

    # Backup the original scf.in file
    cp scf.in scf.in.bak

    # Find the number of atoms (nat) from scf.in
    nat=$(grep "nat" scf.in | awk -F'=' '{print $2}' | tr -d '[:space:],')


    echo "Number of atoms (nat) found: $nat"

    # Delete from ATOMIC_POSITIONS and the next $nat lines
    sed -i "/ATOMIC_POSITIONS/,+$((nat + 1))d" scf.in

    # Append the new atomic positions after the ATOMIC_POSITIONS line
    echo "$new_atomic_positions" >> scf.in

    # Debugging output: Show the updated scf.in file (optional)
    echo "Updated scf.in content for $folder:"
    cat scf.in
    echo "---------------------"

    # Generate the supercell using phonopy
    phonopy --qe -d --dim="3 3 1" -c scf.in

    # Find the maximum supercell index (N)
    N=$(ls supercell-*.in | sed 's/[^0-9]//g' | sort -n | tail -1)

    # Update the range in job_phon script based on N
    sed -i "s/{001..003}/{001..$N}/" job_phon

    # Submit the phonon calculation job
    sbatch job_phon

    # Go back to the parent directory before processing the next folder
    cd ..
done
