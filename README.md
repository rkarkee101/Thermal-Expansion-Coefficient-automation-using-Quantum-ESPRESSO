# Instructions on how to use.

## File types
There are preprocess.bash, postprocess.bash, scf.in, header.in, job_scf, job_phon, mesh.conf files. The scf.in has only atomic position (in crystal coordinates). Put Atomic positions in crystal coordinate which will be easier for applying strain.


## Files to Edit
### preprocess.bash 
Line 4: Goto preprocess.bash and edit your desired strain list for calculation.

Line 7: Update the cell parameters from scf.in in cell_params.

Line 26: Update your desired strain. For example, uniaxial along x would be ([[E, 0, 0], [0, 1, 0], [0, 0, 1]]) 

Line 121: Update desired phonopy supercell dimension.

### job_phon
You can edit the name of .in and .out file (in this example, it is wse2) as per your project of interest. 
For example:
wse2-$i.in can be changed to  your_file_name-$i.in

wse2-$i.in &> wse2-$i.out  can be changed to  your_file_name-$i.in &> your_file_name-$i.out


### postprocess.bash
Line 29: If you changed the name of files in job_phon, you can edit it here. For example, wse2-$i.out changes to your_file_name-$i.out


## Running the code
If you're running your job on HPC, use job_preprocess as job script reference. This depends on your HPC. Then, submit job_preprocess. You can see the progress on results_preprocess.log

Once job_preprocess completes successfully, then you can run

```bash postprocess.bash```

After postprocess.bash runs successfully, you can go to thermal_properties folder and run
```phonopy-qha e-v.dat thermal_properties.yaml-{-{3..1},{0..3}}``` You can edit numbers based on your results.


