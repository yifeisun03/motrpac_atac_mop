#!/bin/bash

# Write JSON files for ENCODE ATAC pipeline input
# Assumes that reads are paired-end

set -e

fastq_dir=/mnt/lab_data/montgomery/nicolerg/motrpac/atac/FASTQ/RUN8
json_dir=/mnt/lab_data/montgomery/nicolerg/motrpac/atac/json/RUN8
base_json=/mnt/lab_data/montgomery/nicolerg/motrpac/atac/json/base_json

#suffix of input fastq files
SUF_R1=_R1_001.fastq.gz
SUF_R2=_R2_001.fastq.gz
#suffix of output files
OUT1_SUF=merge_R1.fastq.gz
OUT2_SUF=merge_R2.fastq.gz

# path to genome reference
genome_ref=/mnt/lab_data/montgomery/nicolerg/motrpac/atac/rn6_masked/rn6_masked.tsv

indiv=$(ls -1 ${fastq_dir}/*_001.fastq.gz | awk '{ match($0, /([\-A-z0-9]+)_L[0-9]+/, arr); print arr[1]}' | sort | uniq)

for i in $indiv; do

    # skip "Undetermined" FASTQs generated by bcl2fastq
    if [ `echo "$i" | grep "Undetermined"` ]; then
        continue
    fi

	# name JSON file from FASTQ sample name 
    json_file=${json_dir}/${i}.json

    echo "{" > ${json_file}
    echo "    \"atac.title\" : \"${i}\"," >> ${json_file}
    echo "    \"atac.description\" : \"ATAC-seq on motrpac\"," >> ${json_file}
    echo "    \"atac.pipeline_type\" : \"atac\"," >> ${json_file}
    echo "    \"atac.genome_tsv\" : \"${genome_ref}\"," >> ${json_file}
    echo "    \"atac.keep_irregular_chr_in_bfilt_peak\" : true," >> ${json_file} # required when using Ensembl reference genome, which has non-standard chromosome names 
    echo >> ${json_file}

    echo "    \"atac.paired_end\" : true," >> ${json_file}
    echo "    \"atac.multimapping\" : 4," >> ${json_file}
    echo >> ${json_file}

    echo "    \"atac.auto_detect_adapter\" : true," >> ${json_file} 
    echo >> ${json_file}

    # allocate CPUs
    echo "    \"atac.trim_adapter_cpu\" : 4," >> ${json_file}
    echo "    \"atac.bowtie2_cpu\" : 4," >> ${json_file}
    echo "    \"atac.filter_cpu\" : 4," >> ${json_file}
    echo "    \"atac.bam2ta_cpu\" : 4," >> ${json_file}
    echo "    \"atac.xcor_cpu\" : 4," >> ${json_file}
    echo >> ${json_file}

    # allocate memory
    echo "    \"atac.bowtie2_mem_mb\" : 16000," >> ${json_file}
    echo "    \"atac.filter_mem_mb\" : 16000," >> ${json_file}
    echo "    \"atac.macs2_mem_mb\" : 16000," >> ${json_file}
    echo >> ${json_file}

    # optional. we can set this to false if we're only interested in the less stringent "optimal" peak sets
    echo "    \"atac.enable_idr\" : true," >> ${json_file}
    echo >> ${json_file}

	# one of the two following blocks must be commented out =================

	# =============================================================

	# 4 FASTQ files (4 lanes) per sample 

	echo "    \"atac.fastqs_rep1_R1\" : [" >> ${json_file}
	counter=1
	for j in $(ls ${fastq_dir}/${i}_*L00*${SUF_R1})
	do
		if [ "$counter" = 4 ]; then
			echo "        \"${j}\"" >> ${json_file}
		else
			echo "        \"${j}\"," >> ${json_file}
		fi
		counter=$((counter +1))
	done
	echo "    ]," >> ${json_file}
	echo >> ${json_file}

	
	echo "    \"atac.fastqs_rep1_R2\" : [" >> ${json_file}
	counter=1
	for k in $(ls ${fastq_dir}/${i}_*L00*${SUF_R2}); do
		if [ "$counter" = 4 ]; then
			echo "        \"${k}\"" >> ${json_file}
		else
			echo "        \"${k}\"," >> ${json_file}
		fi
		counter=$((counter +1))
	done
	echo "    ]" >> ${json_file}

	# =============================================================

	# # 1 FASTQ file per sample (no lane splitting) 

	# fastq_r1=`ls ${fastq_dir}/${i}_*${SUF_R1}`
	# fastq_r2=`ls ${fastq_dir}/${i}_*${SUF_R2}`
	# echo "    \"atac.fastqs_rep1_R1\" : \"${fastq_r1}\"," >> ${json_file}
	# echo "    \"atac.fastqs_rep1_R2\" : \"${fastq_r2}\"" >> ${json_file}

	# =============================================================

	# =======================================================================

	echo "}" >> ${json_file}

done
