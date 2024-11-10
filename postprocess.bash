#!/bin/bash

# Post-processing script to collect energy and volume and run phonopy calculations

# Create directory for thermal properties
mkdir -p thermal_properties

# Strain values (dynamically retrieved from the folder names)
strain_folders=$(ls -d strain_* | sort -t_ -k2,2n)

# Initialize a counter for the integer mapping
counter=-$(($(echo "$strain_folders" | wc -l) / 2))

# Loop over the sorted directories for each strain
for folder_name in $strain_folders
do
    cd $folder_name

    # Check if scf job completed by searching for "JOB DONE" in scf.out
    if grep -q "JOB DONE" scf.out; then
        echo "Processing folder: $folder_name"

        # Find the maximum supercell index (N)
        N=$(ls supercell-*.in | sed 's/[^0-9]//g' | sort -n | tail -1)

        # Construct file names for wse2-*.out dynamically
        files=""
        for i in $(seq -f "%03g" 1 $N); do
            files="$files wse2-$i.out"
        done

        # Run phonopy calculations using the constructed file names
        phonopy --qe -f $files
        phonopy --qe -c scf.in -t -p -s mesh.conf


        # Collect final energy and volume from scf.out
	energy=$(grep "Final energy" scf.out | awk '{print $4}')
        energy_in_eV=$(echo "$energy * 13.6" | bc -l)
        volume=$(grep "new unit-cell volume" scf.out | awk '{print $8}')


        # Append the collected energy and volume data to thermal_properties/e-v.dat
	echo " $volume  $energy_in_eV" >> ../thermal_properties/e-v.dat

        # Copy thermal_properties.yaml to the thermal_properties folder and rename the file with the integer value
        cp thermal_properties.yaml ../thermal_properties/thermal_properties.yaml-$counter
    else
        echo "SCF job not completed yet in $folder_name, skipping."
    fi

    # Increment the counter for the next strain folder
    ((counter++))

    # Return to the parent directory
    cd ..
done

echo "Post-processing completed. Check the thermal_properties directory for results."
