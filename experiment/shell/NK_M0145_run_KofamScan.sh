#!/bin/bash
#$ -S /bin/bash
#$ -N NK_M0145
#$ -cwd
#$ -o /home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0145/out
#$ -e /home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0145/err


exp_dir="/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0145"
downloaded_proteome_dir=${exp_dir}/download
result_dir=${exp_dir}/kofamscan

i=1

for taxid in $(cat ${exp_dir}/list/sptaxid.morethan15genomes.txt);do

    for faapath in $(ls ${exp_dir}/download/sp${taxid}/refseq/bacteria/*/*.faa.gz); do

        if [ $i -eq ${SGE_TASK_ID} ]; then

            gunzipped_faapath=$(echo $faapath | sed 's/.gz//g')
            faafile=$(basename $gunzipped_faapath)
            outdir="${result_dir}/ID${i}-${taxid}-${faafile}"
            mkdir $outdir
            cd    $outdir
            cat $faapath | gunzip > $outdir/$faafile
            kofamscan -f detail-tsv $outdir/$faafile | gzip > $outdir/${faafile}.kofamscan.txt.gz
            cat $outdir/tmp/tabular/tabular.txt   | gzip > $outdir/tabular.txt.gz
            rm -r $outdir/tmp
            rm $outdir/$faafile
        
        fi

        i=$(expr $i + 1)
    
    done

done