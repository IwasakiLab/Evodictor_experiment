#!/bin/bash
#$ -S /bin/bash
#$ -N NK_M0153
#$ -cwd
#$ -o /home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0153/out
#$ -e /home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0153/err

source ${HOME}/.bashrc
source activate EvoPred
export OMP_NUM_THREADS=1

WD="/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0153"
ko_ko_file="/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0151/dataset/ko_ko.rn.Bacteria.txt"

mkdir ${WD}/prediction_Nselected &> /dev/null

i=1

for feature in md; do

    mkdir ${WD}/prediction_Nselected/${feature} &> /dev/null

    feature_file="/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0151/dataset/${feature}_rn.txt"   

    for treemethod in mlgtdb; do

        tree_file="/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0150/tree/bac120_msa_r89.faa.${treemethod}.representative.renamed.rooted.nwk"

        for acrmethod in MPPA; do

            mkdir ${WD}/prediction_Nselected/${feature}/${treemethod}_${acrmethod} &> /dev/null

            ko_gn_weight_file="/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0150/result/ko_gn_weight.${treemethod}_${acrmethod}.txt"

            rn_gn_weight_file="/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0151/dataset/rn_gn_weight.${treemethod}_${acrmethod}.txt"

            for ko in $(cat ${ko_ko_file} | cut -f1); do

                if [ $(( ${i} % 290 + 1)) -eq ${SGE_TASK_ID} ];then

                    mkdir /home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0153/prediction_Nselected/${feature}/${treemethod}_${acrmethod}/${ko} &> /dev/null

                    for target in gain loss; do

                            mkdir /home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0153/prediction_Nselected/${feature}/${treemethod}_${acrmethod}/${ko}/${target} &> /dev/null

                            cd    /home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0153/prediction_Nselected/${feature}/${treemethod}_${acrmethod}/${ko}/${target}

                            # Create dataset (X, y)
                            xygen --target ${ko} -X ${rn_gn_weight_file} -y ${ko_gn_weight_file} -t ${tree_file} --gl ${target} --predictor ${feature_file} > X_y.txt

                            for selectmethod in ANOVA RandomForest; do

                                for predmethod in LR RF; do

                                    optNfeatures_file="/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0151/tables/KO_target_optNfeatures.${target}_${predmethod}_${selectmethod}.txt"

                                    uniNopt=$(cat ${optNfeatures_file} | grep ${ko} | cut -f3)
                                    Nopt=$(cat ${optNfeatures_file} | grep ${ko} | cut -f4)



                                    selevo --max_depth 2 --n_estimators 500 -i X_y.txt -k ${uniNopt},${Nopt} -m ${selectmethod} --o1 ${ko}_${selectmethod}_${feature}.selection_scores.txt --o2 ${ko}_${selectmethod}_${feature}.selected_features.txt --o3 X_y.${ko}_${selectmethod}_${feature}.selected.txt --skip_header --signed

                                    Nopt_type="N_opt_for_median_AUC"

                                    for Nopt_type in "N_opt_for_median_AUC" "N_opt_for_AUC_of_the_OG"; do

                                        if   [ $Nopt_type = "N_opt_for_median_AUC" ]; then

                                            Nfeatures=${uniNopt}

                                        elif [ $Nopt_type = "N_opt_for_AUC_of_the_OG" ]; then

                                            Nfeatures=${Nopt}
                                        
                                        fi

                                        if [ -n "$Nfeatures" ]; then

                                            cat ${ko}_${selectmethod}_${feature}.selected_features.${Nfeatures}.txt | csvtranspose | awk '{if( $2 == 1 ){print $0}}'| cut -f1 > md.selected.${selectmethod}_${predmethod}.${Nfeatures}.txt

                                            csvjoin -c1,1 --no-header-row /home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0151/dataset/md_rn.txt md.selected.${selectmethod}_${predmethod}.${Nfeatures}.txt | tail -n +2 | tr ',' '\t' > md_rn.${selectmethod}_${predmethod}.${Nfeatures}.txt

                                            # Create training/test dataset
                                            xygen --target ${ko} -X ${rn_gn_weight_file} -y ${ko_gn_weight_file} -t ${tree_file} --gl ${target} --predictor md_rn.${selectmethod}_${predmethod}.${Nfeatures}.txt      > X_y.${selectmethod}_${predmethod}.${Nfeatures}.train.txt

                                            xygen --target ${ko} -X ${rn_gn_weight_file} -y ${ko_gn_weight_file} -t ${tree_file} --gl ${target} --predictor md_rn.${selectmethod}_${predmethod}.${Nfeatures}.txt --ex > X_y.${selectmethod}_${predmethod}.${Nfeatures}.test.txt

                                            # Future prediction
                                            predevo -i X_y.${selectmethod}_${predmethod}.${Nfeatures}.train.txt -t X_y.${selectmethod}_${predmethod}.${Nfeatures}.test.txt -m ${predmethod} --header -p -n skip -s none | awk -v ko=${ko} -v target=${target} -v pred=${predmethod} -v selec=${selectmethod} -v type=${Nopt_type} -v nfeatures=${Nfeatures} '{print ko"\t"target"\t"pred"\t"selec"\t"type"\t"nfeatures"\t"$0}' >> sp_prob.${ko}_${target}_${predmethod}_${selectmethod}.${Nfeatures}.test.txt

                                            mv args.csv args.${selectmethod}_${predmethod}.${Nfeatures}.csv
                                        
                                        fi
                                    done

                                done

                            done

                            #rm X_y*.txt

                        done

                fi

                i=$(expr $i + 1)
                
            done
        
        done

    done

done