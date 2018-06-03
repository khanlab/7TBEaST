#!/bin/bash
#SBATCH --reservation coss-wr_cpu
#SBATCH --account coss-wa
#SBATCH –-mem-per-cpu=4G
#SBATCH –-time=0-00:10
#SBATCH –-cpus-per-task=4
time python euler39_multiprocess.py
