#!/bin/bash
# Usage: bash ChIP-seq_run.sh input.fq chip.fq


adapter_1="AGATCGGAAGAGCACACGTCTGAAC"
adapter_2="AGATCGGAAGAGCGTCGTGTAGGGA"
notrim="--no-trim"
threads=24
index="/home/Resource/Genome/mm10/bwa_index_mm10/mm10.fa"
chr_size='/home/Resource/Genome/mm10/mm10.chrom.sizes'
peak_genome="mm"


input_file=$1
chip_file=$2

echo  "processing input $input_file"  "processing ChIP $chip_file"

mkdir Processed_${chip_file}
ln -s `pwd`/${input_file} ./Processed_${chip_file}
ln -s `pwd`/${chip_file} ./Processed_${chip_file}
cd Processed_${chip_file}

adapter_1="AGATCGGAAGAGCACACGTCTGAAC"
adapter_2="AGATCGGAAGAGCGTCGTGTAGGGA"
notrim="--no-trim"
threads=24

### cutadapt
echo 'triming files'
cutadapt $notrim -j $threads -a $adapter_1 --quality-cutoff=15,10 -o trimed_${input_file}  $input_file > step1_cutadapt.input.trimlog
cutadapt $notrim -j $threads -a $adapter_1 --quality-cutoff=15,10 -o trimed_${chip_file}  $chip_file > step1_cutadapt.chip.trimlog

### mapping
echo "aligning" $input_file $chip_file
bwa mem -t $threads $index trimed_${input_file} | samtools view  -bS - | samtools sort - -O 'bam' -o step2_${input_file}.bam -T temp_aln
bwa mem -t $threads $index trimed_${chip_file} | samtools view  -bS - | samtools sort - -O 'bam' -o step2_${chip_file}.bam -T temp_aln

### methylQA 
methylQA density -E 0 -o step3_methylQA_${input_file} $chr_size step2_${input_file}.bam
methylQA density -E 0 -o step3_methylQA_${chip_file} $chr_size step2_${chip_file}.bam


### peak call wait
echo "processing done"

## peakcall parameters:
macs2 callpeak -t "step3_methylQA_"$chip_file".extended.bed"   -c "step3_methylQA_"$input_file".extended.bed"  -g $peak_genome  -n $chip_file -q 0.01 

