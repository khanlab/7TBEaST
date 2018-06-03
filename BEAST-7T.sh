#!/bin/bash

# This file records the processing parameters for 7T DBS dataset
# Put absolute path of the files for processing
# Author: Yiming Xiao - May 30, 2018

function usage {

echo "
Usage:
  BEAST-7T.sh <T1w_image.nii> <output_path> <output_basename>
  Obtain initial brain masks usnig Beast brain extraction.
  All images should be distortion corrected.
"

}

set -e

T1="$1"
output_path="$2"
work_dir="$3"
basename="$4"
template_PATH="$5"
BEAST_PATH="$6"

if [ $# -ne 6 ]
then
  usage;
  exit 1;
fi

execpath=`dirname $0`
execpath=`realpath $execpath`

cd $work_dir

# Step 1. remove negative voxels due to interpolation
echo "Step 1. remove negative voxels due to potential previous interpolation"
fslmaths $T1 -thr 0 ${basename}_thr0_T1w.nii.gz
ImageMath 3 ${basename}_nonNeg_T1w.nii.gz InPaint ${basename}_thr0_T1w.nii.gz 3

# Step 2. Image inhomogeneity correction
echo "Step 2. Image inhomogeneity correction"
N4BiasFieldCorrection -d 3 -v -b [200] -s 4 -r 0 -c [600x500x500x400x200,0] -i ${basename}_nonNeg_T1w.nii.gz -o ${basename}_rough-N4_T1w.nii.gz
nii2mnc ${basename}_rough-N4_T1w.nii.gz ${basename}_rough-N4_T1w.mnc

# Step 3. Transform to Talariach space
# The script path needs to be in $PATH
echo "Step 3. Transform to Talariach space"
${execpath}/bin/beast_normalize2.sh ${basename}_rough-N4_T1w.mnc ${basename}_icbm_T1w.mnc ${basename}_T1w-to-icbm_affine.xfm -modeldir $template_PATH

# Step 4. Skull stripping
echo "Step 4. Skull stripping"
mincbeast -fill -median -conf $BEAST_PATH/default.1mm.conf $BEAST_PATH ${basename}_icbm_T1w.mnc ${basename}_BEAST-icbm_brainmask.mnc

# Step 5. resample the masks back to native space
echo "Step 5. resample the masks back to native space"
itk_resample ${basename}_BEAST-icbm_brainmask.mnc ${basename}_BEAST-native_brainmask.mnc --labels --clobber --like ${basename}_rough-N4_T1w.mnc --transform ${basename}_T1w-to-icbm_affine.xfm --invert_transform --short
mnc2nii -short -nii ${basename}_BEAST-native_brainmask.mnc ${basename}_BEAST-native_brainmask.nii
gzip ${basename}_BEAST-native_brainmask.nii

# Step 6. convert back to .nii format
echo "Step 6. Convert to NiFTI format"
mincreshape -short -signed ${basename}_BEAST-icbm_brainmask.mnc ${basename}_BEAST-icbm_ss_brainmask.mnc
mnc2nii -short -nii ${basename}_BEAST-icbm_ss_brainmask.mnc ${basename}_BEAST-icbm_brainmask.nii
gzip ${basename}_BEAST-icbm_brainmask.nii
rm ${basename}_BEAST-icbm_ss_brainmask.mnc

mincreshape -short -signed ${basename}_icbm_T1w.mnc ${basename}_icbm_ss_T1w.mnc
mnc2nii -short -nii ${basename}_icbm_ss_T1w.mnc ${basename}_icbm_T1w.nii
gzip ${basename}_icbm_T1w.nii
rm ${basename}_icbm_ss_T1w.mnc


# Step 7. Refine N4 correction with obained mask
echo "Step 7. Refine N4 correction with obained mask"
N4BiasFieldCorrection -d 3 -i ${basename}_nonNeg_T1w.nii.gz -o [${basename}_nonNeg_N4_T1w.nii.gz,${basename}_T1w_biasfield.nii.gz] -b [250] -r 0 -s 4 -c [600x500x500x400x200,1e-5] -v -x ${basename}_BEAST-native_brainmask.nii.gz
ImageMath 3 ${basename}_N4_T1w.nii.gz / ${basename}_nonNeg_T1w.nii.gz ${basename}_T1w_biasfield.nii.gz

# Step 8. Apply the brain mask to the native T1w scan
echo "Step 8. Apply the brain mask to the native N4-corrected T1w scan"
ImageMath 3 ${basename}_N4_brain-T1w.nii.gz m ${basename}_N4_T1w.nii.gz ${basename}_BEAST-native_brainmask.nii.gz

# Step 8. Clean up and rename/copy the files for output
echo "Step 9. Clean up and rename/copy the files for output"
yes | cp -rf ${basename}_icbm_T1w.nii.gz $output_path/${basename}_icbm_T1w.nii.gz
yes | cp -rf ${basename}_BEAST-icbm_brainmask.nii.gz $output_path/${basename}_BEAST-icbm_brainmask.nii.gz
yes | cp -rf ${basename}_T1w-to-icbm_affine.xfm $output_path/${basename}_T1w-to-icbm_affine.xfm
yes | cp -rf ${basename}_BEAST-native_brainmask.nii.gz $output_path/${basename}_BEAST-native_brainmask.nii.gz
yes | cp -rf ${basename}_N4_T1w.nii.gz $output_path/${basename}_N4_T1w.nii.gz
yes | cp -rf ${basename}_N4_brain-T1w.nii.gz $output_path/${basename}_N4_brain-T1w.nii.gz

cd -
exit 0
