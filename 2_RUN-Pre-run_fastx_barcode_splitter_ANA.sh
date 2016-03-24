#!/bin/bash

#PBS -l walltime=06:00:00,mem=15g,nodes=1:ppn=8
#PBS -N keyfile_creation
#PBS -M llei
#PBS -m abe
#PBS -r n
#PBS -q small

cd /home/morrellp/llei/Deleterious_mutation_project/Big_NAM/GBarleyS/Pipeline_Scripts

module load R

R CMD BATCH 1_Pre-run_fastx_barcode_splitter_ANA.R
