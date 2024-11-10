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

wse2-$i.in &> wse2-$i.out  can be changed to  your_file_name-$i.in &> your_file_name-$i.ou

### postprocess.bash



