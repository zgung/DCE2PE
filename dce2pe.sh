#!/bin/bash
clear
set -e

# This code resides at https://github.com/zgung/DCE2PE
####################################################################
#########     Calculate percentage enhancement map from    #########
#########       pre- and post-contrast DCE MRI images      #########
####################################################################

# for this script to work, you will need:
# 1) OsiriX or Horos (Mac OS X)
# 2) Pre and post contrast DCE MRI data
# 3) minc-tools along with mni-autoreg
# 4) 'Nifti To DICOM' Database plugin in OsiriX installed

# This is how it works:
#
# 1) export data from osirix 
# 		t1_dyn_pre and post

# 	- Add DICOMDIR 
# 	- Hierarchical
# 	- Don't modify the files
# 
# 2) use this script:
#
# ./dce2pe.sh 'Patient's directory made by Osirix'
#
# there is an option to register the data with:
#
# ./dce2pe.sh 'Patient's directory made by Osirix' linear
#
# or
#
# ./dce2pe.sh 'Patient's directory made by Osirix' nonlin
# 
# 3) be sure to have only the two datasets with pre and post 
#  contrast Dicoms
####################################################################

# state your parameters
patdir=$1
reg=$2
thrs='200' # this filters some noise in the images

# check if the directory is existing
if [ ! -d "$patdir" ]; then
echo 'Error: Directory not found'
exit 1
fi

echo "Oh, yeah!"
echo

# go to the directory and find the full path
cd $patdir
patfol=$(pwd)
cd ..

# remove possible minc files in the directory:
find $patfol -maxdepth 1 -type f -name "*.mnc" -delete

# make minc files from dicoms:
fold1=${patfol}/*/*
dcm2mnc -dname '' -fname '%A' $fold1 $patfol

# go inside the patient's folder
cd $patfol

# check if there are more than two minc files
numfil=$(ls ${patfol}/*.mnc | wc -l)

if [ "$numfil" -ne 2 ]; then
	echo
	echo 'Error: The number of Dicom series is not equal to two!'
	echo 'I will not continue....'
	exit 1; else
	echo
	echo 'I hope you are using the right Dicom series,)'
fi

# allocate the files
pre=$(ls | grep .mnc | sort -n | head -1)
pea=$(ls | grep .mnc | sort -n | tail -1)
echo
echo 'The files created are: '$pre' and '$pea
echo

# register the images
# first check if you are going to register and how
if [ "$reg" == 'nonlin' ]; then
	echo 'Registering the images - nonlinear.....'
	echo
	minctracc -lsq9 $pre $pea transf.xfm # non-linear resistration
	mincresample -like $pea -transformation transf.xfm $pre pre_reg.mnc
elif [ "$reg" == 'linear' ]; then
	echo 'Registering the images - linear.....'
	echo
	minctracc -lsq6 $pre $pea transf.xfm
	mincresample -like $pea -transformation transf.xfm $pre pre_reg.mnc; else
	echo
	echo 'The image are not going to be registered!'
fi
# filter the noise from 125 to 10000 on both files:
if [ -f "${patfol}"/pre_reg.mnc ]; then
	echo 'Calculating the percentage enhancement maps using the registered files'
	mincmath -const2 $thrs 10000 -clamp pre_reg.mnc pre.mnc; else
	echo 'Calculating the percentage enhancement maps using original files'
	mincmath -const2 $thrs 10000 -clamp $pre pre.mnc
fi
mincmath -const2 $thrs 10000 -clamp $pea pea.mnc

# calculate the percentage enhancement and clamp it so there are no negative values:
# function description of mincmath -pd is: PE- = 100 * (pre - pea) / pre
mincmath -pd pre.mnc pea.mnc pe-.mnc
mincmath -abs pe-.mnc pe_.mnc
mincmath -const2 0 10000 -clamp pe_.mnc pe.mnc

# create nifti files from both the PE and the original enhanced images:
echo 'Creating nifti files.............'

# if there are some nifti files created delete them
find $patfol -maxdepth 1 -type f -name "pe.nii" -delete
find $patfol -maxdepth 1 -type f -name "pea.nii" -delete

# now convert minc files to nifti 
mnc2nii -nii -quiet -short pe.mnc pe.nii
mnc2nii -nii -quiet -short $pea pea.nii

echo
echo 'Cleaning.........................'
echo '.................................'

# we don't need these minc files anywhere ever
rm ${patfol}/*.mnc
rm ${patfol}/transf.xfm

# that's it!
echo
echo 'Import files one at a time to OsiriX using Plugins -> Database -> nifti to dicom'
echo




