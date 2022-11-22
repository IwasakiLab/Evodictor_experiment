#!/bin/bash
#$ -S /bin/bash
#$ -N pastml
#$ -cwd
#$ -o /home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0150/ancestral/out
#$ -e /home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0150/ancestral/err

# required file

source activate pastmlenv

i=1

RESULT_DIR=/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0150/ancestral


INPUTCSV="/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0150/table/gn_ko.intree.Bacteria.table.csv"

for treemethod in mlgtdb nj; do

    INPUTNWK="/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0150/tree/bac120_msa_r89.faa."${treemethod}".representative.renamed.rooted.nwk"

    for acrmethod in MPPA DOWNPASS; do # MPPA: Posterior probability-based, DOWNPASS: Parsimony-based

        mkdir ${RESULT_DIR}/${treemethod}_${acrmethod} &> /dev/null

        for ko in $(head -n1 ${INPUTCSV} | sed 's/,/ /g' | sed 's/key//g'); do
            if [ $i -eq ${SGE_TASK_ID} ];then
                OUT_DIR=${RESULT_DIR}/${treemethod}_${acrmethod}/out_bacteria_${ko}
                mkdir ${OUT_DIR}
                echo "TASK_ID:${SGE_TASK_ID}\tDOMAIN:$DOMAIN\tKO:${ko}" > ${OUT_DIR}/info.txt
                cat $INPUTNWK                                           > ${OUT_DIR}/copied_tree.nwk
                cat $INPUTCSV | sed "s/gn://g"                          > ${OUT_DIR}/copied_table.csv
                cd ${OUT_DIR}
                pastml --prediction_method ${acrmethod} --tree ${OUT_DIR}/copied_tree.nwk  --data ${OUT_DIR}/copied_table.csv  --columns $ko -o ${ko}_ancestral_state.txt --data_sep , --tip_size_threshold 10000000000

                tar -cvf copied_tree_pastml.tar.gz copied_tree_pastml

                rm -r ${OUT_DIR}/copied_tree_pastml

                rm ${OUT_DIR}/copied_table.csv

                exit

            fi
            i=`expr $i + 1`

        done

    done

done

