# DCE2PE

This script calculates the percentage enhancement maps from DCE MRI pre- and post-contrast images

For this script to work, you will need:

 1) OsiriX or Horos (Mac OS X)

 2) Pre and post contrast DCE MRI data

 3) minc-tools along with mni-autoreg

 4) 'Nifti To DICOM' Database plugin in OsiriX installed


 This is how it works:

 1) export data from osirix 
 		t1_dyn_pre and post
 	- Add DICOMDIR 
 	- Hierarchical
 	- Don't modify the files
 
 2) use this script:

 ./dce2pe.sh 'Patient's directory made by Osirix'

 there is an option to register the data with:

 ./dce2pe.sh 'Patient's directory made by Osirix' linear

 or if you want to use non-linear registration:

 ./dce2pe.sh 'Patient's directory made by Osirix' nonlin

 
 3) be sure to have only the two datasets with pre and post 
  contrast Dicoms
