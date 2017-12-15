#!/bin/bash

# exit immediately if there's an error
set -e # fail if any command (not counting non-last steps in a pipe) fail
set -x # see the commands which are executed
#set -o
set -o pipefail

#Load the module
source .start_lmod
ml picard/2.13.2-Java-1.8.0_92

#Define Scratch location
# scratch=/scratch


curl -LO https://s3-us-west-2.amazonaws.com/fredhutch-aws-batch-tools/linux-build-of-s3uploader/s3uploader

chmod +x s3uploader

# add current directory to path
export PATH=$PATH:.


# don't hardcode SAMPLE_NAME!
# export SAMPLE_NAME=PAXGES-09A-01R_withJunctionsOnGenome_dupsFlagged

#BAM file to be processed.
sampleName=${SAMPLE_NAME}
bam="${SAMPLE_NAME}.bam"

#Fastq file names
r1="${sampleName}_r1.fq.gz"
r2="${sampleName}_r2.fq.gz"
out="${sampleName}_picard.stderr"

# required for s3uploader
AWS_REGION=us-west-2
export AWS_REGION=us-west-2

# set up named pipes

rm -f $bam $r1 $r2 $out


mkfifo $bam
mkfifo $r1
mkfifo $r2
mkfifo $out

# hook up one end of the pipes....

# download bam file, set download to NOT time out
aws s3 cp --cli-read-timeout 0 --sse AES256 s3://fh-pi-meshinchi-s/SR/$bam - > $bam &

AWS_REGION=us-west-2 s3uploader -b fh-pi-meshinchi-s -k SR/picard_fq2/$r1 < $r1 &

AWS_REGION=us-west-2 s3uploader -b fh-pi-meshinchi-s -k SR/picard_fq2/$r2 < $r2 &

AWS_REGION=us-west-2 s3uploader -b fh-pi-meshinchi-s -k SR/picard_fq2/$out < $out &




#download bam
# aws s3 cp --sse AES256 s3://fh-pi-meshinchi-s/SR/$bam /$scratch/$bam


#Convert BAM to fastq
#filenames with suffix .gz are automatically gzipped by Picard tools.
#Include all reads, whether pass filter (PF) or not. changing flag does not improve or take away from psuedoalignemnt performance.
java -Xmx6g -Xms2g -jar ${EBROOTPICARD}/picard.jar SamToFastq QUIET=true INCLUDE_NON_PF_READS=true VALIDATION_STRINGENCY=SILENT MAX_RECORDS_IN_RAM=250000 I="$bam" F="$r1" F2="$r2" |& tee "$out"

#Fail if Java failes in the pipe above.
#echo ${PIPESTATUS[@]} | grep -qE '^[0 ]+$' # exit if any command in the above pipe failed

#upload step
# aws s3 cp --sse AES256 "/$scratch/$out" s3://fh-pi-meshinchi-s/SR/picard_fq2/$out
# aws s3 cp --sse AES256 "/$scratch/$r1" s3://fh-pi-meshinchi-s/SR/picard_fq2/$r1
# aws s3 cp --sse AES256 "/$scratch/$r2" s3://fh-pi-meshinchi-s/SR/picard_fq2/$r2
