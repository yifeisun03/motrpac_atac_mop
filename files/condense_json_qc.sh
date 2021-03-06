#!/bin/bash

# merge qc.json files (single replicate)
base=/path/to/cromwell-executions/atac
outdir=/path/to/output/directory
path_to_python_script=/path/to/cleanup.py

mkdir -p $outdir

if [[ "$base" == *"cromwell-executions/atac"* ]]; then
	# JSON reports are being collected from pipeline output 
	for dir in `ls $base`; do 
		if [ ! -d "$base/$dir" ]; then continue; fi 
		prefix=`ls $base/$dir/call-bowtie2/shard-0/execution | grep -E "trim.merged.bam$" | sed "s/_L001.*//"`
		cp $base/$dir/call-qc_report/execution/qc.json $outdir/$prefix.qc.json
	done
	indir=$outdir
else
	# "base" specifies an input directory with many JSON files 
	indir=$base
fi

# merge JSON files into one report 
# do some wonky formatting stuff since multiple subheaders makes it difficult to convert to a tsv file  
first=1
for json in `ls $indir | grep "json"`; do

	sed -e "s/[ \t]$//" -e "s/\"//g" -e "s/[{}]//g" -e "s/\]//g" -e "s/\[//g" -e "s/,//g" -e "s/: /,/g" -e "s/                /@/" -e "s/^[ \t]*//" -e "/^$/d" -e "s/@/,/g" $indir/$json > $outdir/tmp

	if [ "$first" == "1" ]; then
		cut -f1 -d',' $outdir/tmp > $outdir/merged.tmp.txt
		first=0
	fi
	cut -f2 -d',' $outdir/tmp > $outdir/tmp.info
	paste $outdir/merged.tmp.txt $outdir/tmp.info > $outdir/tmp.merged
	rm $outdir/merged.tmp.txt
	mv $outdir/tmp.merged $outdir/merged.tmp.txt
done

rm $outdir/tmp*
sed -i -e '2d' $outdir/merged.tmp.txt
rm $outdir/*qc.json 

# indicate headers in condensed report 
for header in flagstat_qc \
	dup_qc \
	pbc_qc \
	nodup_flagstat_qc \
	overlap_reproducibility_qc \
	idr_reproducibility_qc \
	frip_macs2_qc \
	overlap_frip_qc \
	idr_frip_qc \
	ataqc;do
		sed -i "s/^$header.*/$header -------------------------------------------------------------------/" $outdir/merged.tmp.txt
done

python2 ${path_to_python_script} $outdir/merged.tmp.txt $outdir/merged.qc.txt
rm $outdir/merged.tmp.txt
