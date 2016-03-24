####################################################################################################################################
# Author: Ana M. Poets
# Date: 26 Feb. 2016
# Description: This scrip will create independent Keyfiles for each sample in a master keyfile.
# This way we can demultiplex specific samples from a fastq.gz file.
# The script also creates a directory of barcode files for each sample.
####################################################################################################################################

rm(list=ls())

###INPUTS
#Identify the group (six or two rows) for which the Keyfile is being used
ROW<-"Six-row"
KEYFILE<-read.table("/home/morrellp/llei/Shared/shared/GBS_ABNAM/Six_row_keyfile.txt",header=T)

# The directory where the fastq.gz files are located
FASTQ_DIR<-"/home/morrellp/llei/Shared/shared/GBS_ABNAM/Fastq"

###PROCESS
#Combine flowcell and lane , use this column to create separated keyfiles for each lane
KEYFILE$COMBINE<-paste(KEYFILE[,1],KEYFILE[,2],sep="_")

UNIQUE_COMBINE<-as.data.frame(sort(unique(KEYFILE$COMBINE)))

#Create a directory where all the keyfiles will be stored
KEY_DIR<-paste("/home/morrellp/llei/Shared/shared/GBS_ABNAM/KEYFILES_",ROW,sep="")

dir.create(KEY_DIR)

#Create a directory where all the Barcode Files will go.
BARCODE_DIR<-"/home/morrellp/llei/Deleterious_mutation_project/Big_NAM/GBarleyS/Pipeline/Demultiplex/Barcode_Splitter/Barcode_Files3"

dir.create(BARCODE_DIR)

#Make a list of the location of the fastq.gz files for each lane here
FASTQ_DIR_PATH<-matrix(NA,ncol=1,nrow=(dim(UNIQUE_COMBINE)[1]))
for (i in 1:(dim(UNIQUE_COMBINE)[1])) {
	Line_key<-subset(KEYFILE,KEYFILE$COMBINE == UNIQUE_COMBINE[i,1] )
	BC<-paste(Line_key[,3], Line_key[,4],sep="_")
	Lane_bc<-cbind(Line_key[,-9],BC)
	write.table(Lane_bc, paste(KEY_DIR,"/", UNIQUE_COMBINE[i,1],"_keyfile.txt",sep=""),quote=F,row.names=F,col.names=T,sep="\t")

	##Separate samples by barcode length
	#Create Barcode directory to put the barcode files for each lane
	BAR_LANE_DIR<-paste(BARCODE_DIR,"/",UNIQUE_COMBINE[i,1],sep="")
	dir.create(BAR_LANE_DIR)
	
	#Make a list of unique barcodes
	BCODE_LENGTH <- NULL
	for (j in 1:(dim(Lane_bc)[1])) {
		BCODE_LENGTH[j] <-nchar(as.vector(Lane_bc[j,3]))
		}
	
	BCODE_LENGTH_UNIQ<-unique(sort(BCODE_LENGTH))
	
	for (len in 1:length(BCODE_LENGTH_UNIQ)){
		Barcode_file_length<-Lane_bc[which(BCODE_LENGTH == BCODE_LENGTH_UNIQ[len]),c(9,3)]
		write.table(Barcode_file_length,paste(BAR_LANE_DIR,"/","Barcode_file_length", BCODE_LENGTH_UNIQ[len],".txt",sep=""),quote=F,row.names=F,col.names=F,sep="\t")
	}
	
	#Create a list with  path to each fastq.gz file
	FASTQ_DIR_PATH[i,1]<-paste(FASTQ_DIR,"/", UNIQUE_COMBINE[i,1],"_fastq.gz",sep="")
}

write.table(FASTQ_DIR_PATH, paste(KEY_DIR, "/","Path_fastq_",ROW,".txt",sep=""),quote=F,row.names=F,col.names=F,sep="\t")



