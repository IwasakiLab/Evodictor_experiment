#!/bin/bash
#$ -S /bin/bash
#$ -N NK_M0151
#$ -cwd
#$ -o /home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0151/out
#$ -e /home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0151/err

source ${HOME}/.bashrc
source activate EvoPred
export OMP_NUM_THREADS=1

export PATH=/home/naoki-konno/Iwasakilab/code/MetabolicTrajectory/python/Pipeline/EvolutionPredictor/:${PATH}

WD="/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0151"
ko_ko_file="/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0151/dataset/ko_ko.rn.Bacteria.txt"

mkdir ${WD}/prediction_Nselected &> /dev/null

i=1

for feature in md ec12md ec12mdpath; do

    mkdir ${WD}/prediction_Nselected/${feature} &> /dev/null

    feature_file="/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0151/dataset/${feature}_rn.txt"   

    for treemethod in mlgtdb; do

        tree_file="/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0150/tree/bac120_msa_r89.faa.${treemethod}.representative.renamed.rooted.nwk"

        for acrmethod in MPPA; do

            mkdir ${WD}/prediction_Nselected/${feature}/${treemethod}_${acrmethod} &> /dev/null

            ko_gn_weight_file="/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0150/result/ko_gn_weight.${treemethod}_${acrmethod}.txt"

            rn_gn_weight_file="${WD}/dataset/rn_gn_weight.${treemethod}_${acrmethod}.txt"

            for ko in $(cat ${ko_ko_file} | cut -f1); do

                if [ $(( ${i} % 290 + 1)) -eq ${SGE_TASK_ID} ];then

                    mkdir ${WD}/prediction_Nselected/${feature}/${treemethod}_${acrmethod}/${ko} &> /dev/null

                    for target in gain loss; do

                            mkdir ${WD}/prediction_Nselected/${feature}/${treemethod}_${acrmethod}/${ko}/${target} &> /dev/null

                            cd    ${WD}/prediction_Nselected/${feature}/${treemethod}_${acrmethod}/${ko}/${target}

                            # Create dataset (X, y)
                            xygen --target ${ko} -X ${rn_gn_weight_file} -y ${ko_gn_weight_file} -t ${tree_file} --gl ${target} --predictor ${feature_file} > X_y.txt

                            for selectmethod in ANOVA RandomForest; do

                                selevo --max_depth 2 --n_estimators 500 -i X_y.txt -k 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50 -m ${selectmethod} --o1 ${ko}_${selectmethod}_${feature}.selection_scores.txt --o2 ${ko}_${selectmethod}_${feature}.selected_features.txt --o3 X_y.${ko}_${selectmethod}_${feature}.selected.txt --skip_header --signed &> /dev/null

                                for Nfeatures in $(seq 1 50); do

                                    if [ -e X_y.${ko}_${selectmethod}_${feature}.selected.${Nfeatures}.txt ]; then

                                        for predmethod in LR RF; do

                                            # 5-fold cross-validation
                                            predevo -i X_y.${ko}_${selectmethod}_${feature}.selected.${Nfeatures}.txt -m ${predmethod} -c -k 5 --header -p -n skip -s none| awk -v ko=${ko} -v target=${target} -v pred=${predmethod} -v feature=${feature} -v selectmethod=${selectmethod} -v Nfeatures=${Nfeatures} '{print ko"\t"target"\t"pred"\t"feature"\t"selectmethod"\t"Nfeatures"\t"$0}' > ${ko}_${selectmethod}_${predmethod}_auc_${feature}.${Nfeatures}.txt

                                            #predevo -i X_y.${ko}_${selectmethod}_${feature}.selected.${Nfeatures}.txt -m ${predmethod} -c -k 5 --header -p -n skip -s none --scoring roc_auc_pvalue --permutation 100000 | awk -v ko=${ko} -v target=${target} -v pred=${predmethod} -v feature=${feature} '{print ko"\t"target"\t"pred"\t"$0"\t"feature}' > ${ko}_${predmethod}_pvalue_${feature}.txt

                                            mv args.csv args.${selectmethod}_${predmethod}.${Nfeatures}.csv

                                        done
                                    
                                    fi

                                done
                            
                            done

                            rm X_y*.txt

                        done

                fi

                i=$(expr $i + 1)
                
                
            
            done
        
        done

    done

done