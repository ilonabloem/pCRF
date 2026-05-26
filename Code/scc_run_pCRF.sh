#!/bin/bash -l
#$ -j y
#$ -m ae
#$ -N run_pCRF # Name the job
#$ -t 1-8 # set up as an array job - submit independent job for each subject
#$ -l h_rt=12:00:00 # Request enough time
#$ -pe omp 4 # Request parallel environment
#$ -l mem_per_core=8G
#$ -P vision
#$ -cwd #run in current working directory
#$ -o /usr2/postdoc/ibloem/Git/pCRF/logs/out_$JOB_NAME_$JOB_ID-$TASK_ID.log
#$ -e /usr2/postdoc/ibloem/Git/pCRF/logs/error_$JOB_NAME_$JOB_ID-$TASK_ID.log


echo "Job started ..."

module load matlab/2020b
module load freesurfer/6.0
module load spm
module load fsl

	
matlab -nodisplay -r "run_pCRF_scc($NSLOTS, $SGE_TASK_ID); exit"

echo "DONE ..."

