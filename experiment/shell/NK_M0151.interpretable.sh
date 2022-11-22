#!/bin/bash
#$ -S /bin/bash
#$ -N NK_M0151
#$ -cwd
#$ -o /home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0151/out
#$ -e /home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0151/err

source ${HOME}/.bashrc
source activate EvoPred

WD="/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0151"
ko_ko_file="/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0151/dataset/ko_ko.rn.Bacteria.txt"

mkdir ${WD}/prediction_interpretable &> /dev/null

i=1

for feature in ec12 md path ec12md mdpath ec12path ec12mdpath; do

    mkdir ${WD}/prediction_interpretable/${feature} &> /dev/null

    feature_file="/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0151/dataset/${feature}_rn.txt"   

    for treemethod in mlgtdb; do

        tree_file="/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0150/tree/bac120_msa_r89.faa.${treemethod}.representative.renamed.rooted.nwk"

        for acrmethod in MPPA; do

            mkdir ${WD}/prediction_interpretable/${feature}/${treemethod}_${acrmethod} &> /dev/null

            ko_gn_weight_file="/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0150/result/ko_gn_weight.${treemethod}_${acrmethod}.txt"

            rn_gn_weight_file="${WD}/dataset/rn_gn_weight.${treemethod}_${acrmethod}.txt"

            for ko in $(cat ${ko_ko_file} | cut -f1); do

                if [ $(( ${i} % 290 + 1)) -eq ${SGE_TASK_ID} ];then

                    mkdir ${WD}/prediction_interpretable/${feature}/${treemethod}_${acrmethod}/${ko} &> /dev/null

                    for target in gain loss; do

                            mkdir ${WD}/prediction_interpretable/${feature}/${treemethod}_${acrmethod}/${ko}/${target} &> /dev/null

                            cd    ${WD}/prediction_interpretable/${feature}/${treemethod}_${acrmethod}/${ko}/${target}

                            # Create dataset (X, y)
                            xygen --target ${ko} -X ${rn_gn_weight_file} -y ${ko_gn_weight_file} -t ${tree_file} --gl ${target} --predictor ${feature_file} > X_y.txt

                            for predmethod in LR RF; do

                                # 5-fold cross-validation
                                predevo -i X_y.txt -m ${predmethod} -c -k 5 --header -p -n skip -s none| awk -v ko=${ko} -v target=${target} -v pred=${predmethod} -v feature=${feature} '{print ko"\t"target"\t"pred"\t"$0"\t"feature}' > ${ko}_${predmethod}_auc_${feature}.txt

                                predevo -i X_y.txt -m ${predmethod} -c -k 5 --header -p -n skip -s none --scoring roc_auc_pvalue --permutation 100000 | awk -v ko=${ko} -v target=${target} -v pred=${predmethod} -v feature=${feature} '{print ko"\t"target"\t"pred"\t"$0"\t"feature}' > ${ko}_${predmethod}_pvalue_${feature}.txt

                                mv args.csv args.${predmethod}.csv

                            done

                        

                            rm X_y.txt

                            

                        done

                fi

                i=$(expr $i + 1)
                
                
            
            done
        
        done

    done

done