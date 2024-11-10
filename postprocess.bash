#!/bin/bash

# Post-processing script to collect energy and volume and run phonopy calculations

# Create directory for thermal properties
mkdir -p thermal_properties

# Strain values
strain_values=(-0.03 -0.02 -0.01 0.00 0.01 0.02 0.03)


# Loop over the directories for each strain
for k in "${strain_values[@]}"
do
    folder_name=$(printf "strain_%.3f" $k)
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

	# Append the collected energy (converted to eV) and volume data to thermal_properties/e-v.dat
	echo " $volume  $energy_in_eV" >> ../thermal_properties/e-v.dat

        # Copy thermal_properties.yaml to the thermal_properties folder and rename the file
        cp thermal_properties.yaml ../thermal_properties/thermal_properties.yaml-$folder_name
    else
        echo "SCF job not completed yet in $folder_name, skipping."
    fi

    

    # Return to the parent directory
    cd ..
done

cd thermal_properties

thermal_files=$(ls thermal_properties.yaml-strain_* | sort -t "_"  -k3,3g)

phonopy-qha -p -s $thermal_files


echo "Post-processing completed. Check the thermal_properties directory for results."
