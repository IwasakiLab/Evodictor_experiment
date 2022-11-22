#!/bin/bash
#$ -S /bin/bash
#$ -N NK_M0151
#$ -cwd
#$ -o /home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0151/out
#$ -e /home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0151/err

#source activate EvoPred

source ${HOME}/.bashrc
source activate EvoPred

WD="/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0151"

mkdir ${WD}/prediction_roc &> /dev/null

ko_ko_file="/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0151/dataset/ko_ko.rn.Bacteria.txt"

i=1

#for treemethod in mlgtdb; do
for treemethod in nj mlgtdb; do
    
    tree_file="/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0150/tree/bac120_msa_r89.faa.${treemethod}.representative.renamed.rooted.nwk"

    for acrmethod in MPPA DOWNPASS; do

        mkdir ${WD}/prediction_roc/${treemethod}_${acrmethod} &> /dev/null

        ko_gn_weight_file="/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0150/result/ko_gn_weight.${treemethod}_${acrmethod}.txt"

        for ko in $(cat ${ko_ko_file} | cut -f1); do

                    
            if [ $(( ${i} % 290 + 1)) -eq ${SGE_TASK_ID} ];then

                    mkdir ${WD}/prediction_roc/${treemethod}_${acrmethod}/${ko} &> /dev/null

                    for target in gain loss; do

                        mkdir ${WD}/prediction_roc/${treemethod}_${acrmethod}/${ko}/${target} &> /dev/null

                        cd    ${WD}/prediction_roc/${treemethod}_${acrmethod}/${ko}/${target}

                        # Create dataset (X, y)
                        xygen --target ${ko} -X ${ko_gn_weight_file} -y ${ko_gn_weight_file} -t ${tree_file} --gl ${target} --predictor ${ko_ko_file} > X_y.txt

                        for predmethod in LR RF; do

                            # 5-fold cross-validation
                            predevo -i X_y.txt -m ${predmethod} -c -k 5 --header -p -n skip --scoring roc_curve | awk -v ko=${ko} -v target=${target} -v pred=${predmethod} '{print ko"\t"target"\t"pred"\t"$0}' > ${ko}_${predmethod}_curve.txt

                            #predevo -i X_y.txt -m ${predmethod} -c -k 5 --header -p -n skip --scoring roc_auc_pvalue --permutation 100000 | awk -v ko=${ko} -v target=${target} -v pred=${predmethod} '{print ko"\t"target"\t"pred"\t"$0}' > ${ko}_${predmethod}_pvalue.txt

                            mv args.csv args.${predmethod}.csv

                        done

                        rm X_y.txt

                    done

            fi

            i=$(expr $i + 1)
            
            
        
        done
    
    done

done