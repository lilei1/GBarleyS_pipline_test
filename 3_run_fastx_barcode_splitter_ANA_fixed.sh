#!/bin/bash

# Adapted from run_fastx_barcode_splitter.sh by Jeff Neyhart.
# Description
# This script demultiplexes a number of multiplexed fastq files based on the barcode sequences that 
## appears at the beginning of the read. This script calls on the FastX_Barcode_Splitter, 
## which only allows barcodes of a constant length. Therefore, this script will run n jobs where n 
## is the number of different barcode lengths.

# Version info
## FastX_Toolkit: 0.0.14

##### Make changes below this line #####

#The directory where the keyfiles are located
# The key file with columns: Flowcell Lane Barcode Sample PlateName Row Column
KEYFILE_DIR=/home/smithkp/agonzale/Shared/GBS_Projects/NAM_GBS_2_6row/NAM_2_6_fastq/KEYFILES_Six-row

# The directory where the multiplexed samples are located or where their symbolic links are located
INDIR=/home/smithkp/agonzale/Shared/GBS_Projects/NAM_GBS_2_6row/NAM_2_6_fastq/FASTQ

# The path to the file containing the location of the fastq files corresponding to lanes requested
INDIR_fastq=/home/smithkp/shared/GBS_Projects/NAM_GBS_2_6row/NAM_2_6_fastq/KEYFILES_Six-row/Path_fastq_Six-row.txt
# The directory to output the demultiplexed fastq files
OUTDIR=/scratch.global/agonzale/NAM_GBS_2_6row

# The name of the current project (e.g. 2row_TP)
PROJECT='NAM_GBS_6row'

# Email address for queue notification
EMAIL='llei@umn.edu'

# The path to the "GBarleyS" folder
VCPWD=/home/smithkp/agonzale/Shared/GBS_Projects/NAM_GBS_2_6row/Pipeline/GBarleyS

##### Program Settings #####
# Queue settings for MSI
QUEUE_SETTINGS='-l walltime=90:00:00,mem=62gb'

# Specify the computing node
NODE='small'

# FastX_barcode_splitter settings
# See http://hannonlab.cshl.edu/fastx_toolkit/commandline.html#fastx_barcode_splitter_usage for more information
# bol: match barcodes at the beginning of a read
# mismatches 1: 1 mismatch allowed when matching the barcodes
FASTX_SETTINGS='--bol --mismatches 1'



#######################################
##### DO NOT EDIT BELOW THIS LINE #####
#######################################

set -e
set -u
set -o pipefail

# Error reporting
# Check if variables are empty
if [[ -z $KEYFILE_DIR ]] || [[ -z $INDIR ]] || [[ -z $INDIR_fastq ]] || [[ -z $OUTDIR ]] || [[ -z $PROJECT ]] || [[ -z $VCPWD ]] || [[ -z $EMAIL ]] || [[ -z ${QUEUE_SETTINGS} ]] || [[ -z ${FASTX_SETTINGS} ]] || [[ -z $PROJECT ]]; then
	echo "One or more variables was not specified. Please check the script and re-run." && exit 1
fi

# Save inputs as an array
INPUTS=( INDIR:$INDIR INDIR_fastq:$INDIR_fastq OUTDIR:$OUTDIR VCPWD:$VCPWD KEYFILE:$KEYFILE_DIR QUEUE:${QUEUE_SETTINGS} FASTX:${FASTX_SETTINGS} PROJECT:$PROJECT )

# Create an array of the multiplexed fastq files (e.g. C631EAXX_1_fastq.gz)
FASTQLIST=( $(find $INDIR -name "*_fastq.gz") )
# Check to make sure there are files in the INDIR directory
if [[ ${#FASTQLIST[@]} == 0 ]]; then
        echo -e "\nERROR: No _fastq.gz files were found in the INDIR. Please make sure you have specified the correct directory." && exit 1
else
        echo -e "\nThere are ${#FASTQLIST[@]} _fastq.gz files in the INDIR."
fi


# Change working directory
cd $VCPWD/Pipeline/Demultiplex/Barcode_Splitter
# Create the output head directory

mkdir -p ${OUTDIR}/Barcode_Splitter_Output/${PROJECT} && echo "Output SUB_PROJECT directories created."


# This code will start qsub submissions, one for each unparsed sample (e.g. C631EAXX_1_fastq.gz). Each job iterates through the list of barcode files and runs the fastx_barcode_splitter.pl script

#Use the name in the keyfile to choose which lane to work with.
KEYFILE_DIR_LIST=( $(find $KEYFILE_DIR -name "*_keyfile.txt") )

# For each fastq file...
for fastq in `cat $INDIR_fastq`; do
	
	# Set a prefix variable to be placed in the beginning of each output fastq file name
	prefix=$(basename $fastq "_fastq.gz")
	
	#Look for the barcode directory and Create an array of the barcode files
	BCODEFILES=( $(find $(pwd)/Barcode_Files3/$prefix/ -name "*.txt") )

	# Set the output directory as a variable
	OUTDIR_FINAL=${OUTDIR}/Barcode_Splitter_Output/${PROJECT}

	# Determine the number of cores to use
	# We will use the number of unique barcode lengths as a proxy
	NCORES=$(cd $(pwd)/Barcode_Files3/$prefix; ls |wc -w)

	# Adjust the queue settings
	QUEUE_SETTINGS="${QUEUE_SETTINGS},nodes=1:ppn=${NCORES}"

	# Set date
	YMD=$(date +%m%d%y-%H%M%S)



	echo "mkdir -p ${OUTDIR_FINAL}/${prefix}; \
cd ${OUTDIR_FINAL}/${prefix}; \
module load parallel; \
module load fastx_toolkit/0.0.14; \
function barcode_split () { zcat $fastq | fastx_barcode_splitter.pl --bcfile "'"$1"'" ${FASTX_SETTINGS} --prefix ${prefix}_ --suffix "'".fastq"'" >> ${prefix}_log.txt; \
}; \
export -f barcode_split; \
parallel --no-notice -j ${NCORES} \"barcode_split {}\" ::: ${BCODEFILES[@]}" \
| qsub "${QUEUE_SETTINGS}" -M $EMAIL -N ${prefix}_Barcode_Splitting_$YMD -m abe -r n -q $NODE
     
    
done && echo "Jobs away!"

# Print a user log for records
echo -e "
Basic Info
Script: ${0}
Date: $(date)
User: $(whoami)
Project: $PROJECT

Inputs
$(echo ${INPUTS[@]} | tr ' ' '\n')

" > $(basename ${0} ".sh")_log_${YMD}.out
