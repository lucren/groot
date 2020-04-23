#!/bin/env bash
#
# This test checks the seeding and alignment accuracy of GROOT.
#
# The reads were generated using randomreads.sh (bbmap) with the command:
# randomreads.sh ref=../../../../db/full-ARG-databases/arg-annot-db/argannot-args.fna out=${NUM_READS}-test-reads.fq length=$READ_LEN  reads=$NUM_READS maxsnps=0 maxinss=0 maxdels=0 maxsubs=0 adderrors=false
#
set -e

# test parameters
TESTDIR=tmp-for-groot-accuracy
READS=../data/argannot-150bp-10000-reads.fq.gz
THREADS=8
READ_LEN=150
K_SIZE=31
SIG_SIZE=50
NUM_PART=4
MAX_K=4
CT=0.97
NUM_READS=10000 #the number of reads generated by randomreads.sh

mkdir $TESTDIR && cd $TESTDIR

# build the progs
go build -o groot ../../
go build -o acc ../groot-accuracy.go

# get the db
./groot get -d arg-annot

# index the ARGannot database
echo "indexing the ARG-annot database..."
gtime -f "\tmax. resident set size (kb): %M\n\tCPU usage: %P\n\ttime (wall clock): %E\n\ttime (CPU seconds): %S\n"\
 ./groot index -m arg-annot.90 -i index -w $READ_LEN -k $K_SIZE -s $SIG_SIZE -x $NUM_PART -y $MAX_K -p $THREADS

# align the test reads
echo "aligning reads..."
gtime -f "\tmax. resident set size (kb): %M\n\tCPU usage: %P\n\ttime (wall clock): %E\n\ttime (CPU seconds): %S\n"\
 ./groot align -i index -f $READS -t $CT -p $THREADS > groot.bam

# evaluate accuracy
./acc --bam groot.bam --numReads $NUM_READS > ../accuracy-for-${NUM_READS}-reads.txt

# clean up
cd ..
rm -r $TESTDIR

