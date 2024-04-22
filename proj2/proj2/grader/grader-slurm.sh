#!/bin/bash
#
#SBATCH --mail-user=katherinezh@cs.uchicago.edu
#SBATCH --mail-type=ALL
#SBATCH --job-name=proj2_grade 
#SBATCH --output=./slurm/out/%j.%N.stdout
#SBATCH --error=./slurm/out/%j.%N.stderr
#SBATCH --chdir=/home/katherinezh/project-2-yaodan-zhang/proj2/grader/
#SBATCH --partition=debug
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=900
#SBATCH --exclusive
#SBATCH --time=10:00

module load golang/1.19
go run proj2/grader proj2
