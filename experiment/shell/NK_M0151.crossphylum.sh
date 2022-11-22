#!/bin/bash
#$ -S /bin/bash
#$ -N NK_M0151
#$ -cwd
#$ -o /home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0151/out
#$ -e /home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0151/err

source ${HOME}/.bashrc
source activate EvoPred

WD="/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0151"

mkdir ${WD}/prediction_crossphylum &> /dev/null

ko_ko_file="/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0151/dataset/ko_ko.rn.Bacteria.txt"

i=1

#for treemethod in mlgtdb; do
for treemethod in mlgtdb; do
    
    tree_file="/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0150/tree/bac120_msa_r89.faa.${treemethod}.representative.renamed.rooted.nwk"

    for acrmethod in MPPA; do

        mkdir ${WD}/prediction_crossphylum/${treemethod}_${acrmethod}_crossphylum &> /dev/null

        ko_gn_weight_file="/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0150/result/ko_gn_weight.${treemethod}_${acrmethod}.txt"

        for ko in $(cat ${ko_ko_file} | cut -f1); do

            if [ $(( ${i} % 290 + 1)) -eq ${SGE_TASK_ID} ];then

                mkdir ${WD}/prediction_crossphylum/${treemethod}_${acrmethod}_crossphylum/${ko} &> /dev/null
                for target in gain loss; do

                        mkdir ${WD}/prediction_crossphylum/${treemethod}_${acrmethod}_crossphylum/${ko}/${target} &> /dev/null

                        cd    ${WD}/prediction_crossphylum/${treemethod}_${acrmethod}_crossphylum/${ko}/${target}

                        # Create dataset (X, y)
                        xygen --target ${ko} -X ${ko_gn_weight_file} -y ${ko_gn_weight_file} -t ${tree_file} --gl ${target} --predictor ${ko_ko_file} > X_y.txt

                        branch2phylum_file="/home/naoki-konno/Iwasakilab/data/MetabolicTrajectory/data/NK_M0150/table/node_phylum.mlgtdb_MPPA.txt" 
                        csvjoin --no-inference --no-header-row -c1,1 -t X_y.txt $branch2phylum_file | tr ',' '\t' | tail -n +2> name_X_y_phylum.txt

                        for phylum in p__Proteobacteria p__Actinobacteriota p__Firmicutes p__Bacteroidota p__Firmicutes_A p__Cyanobacteria p__Campylobacterota p__Spirochaetota p__Firmicutes_I p__Deinococcota; do

                            cat name_X_y_phylum.txt | grep $phylum    | cut -f1,2,3                    > name_X_y.${phylum}.test.txt
                            cat name_X_y_phylum.txt | grep -v $phylum | grep -v upstream | cut -f1,2,3 > name_X_y.not_${phylum}.train.txt

                            for predmethod in LR RF; do

                                # 5-fold cross-validation
                                predevo -i name_X_y.not_${phylum}.train.txt -t name_X_y.${phylum}.test.txt -m ${predmethod} -p -n skip --scoring roc_auc       | awk -v ko=${ko} -v target=${target} -v pred=${predmethod} -v phy=${phylum} '{print ko"\t"target"\t"pred"_"phy"\t"$0}' > ${ko}_${predmethod}_${phylum}_auc.txt

                                predevo -i name_X_y.not_${phylum}.train.txt -t name_X_y.${phylum}.test.txt -m ${predmethod} -p -n skip --scoring roc_auc_pvalue| awk -v ko=${ko} -v target=${target} -v pred=${predmethod} -v phy=${phylum} '{print ko"\t"target"\t"pred"_"phy"\t"$0}' > ${ko}_${predmethod}_${phylum}_pvalue.txt

                                mv args.csv args.${predmethod}_${phylum}.csv

                            done
                        done

                        rm *X_y*.txt

                done

            fi

            i=$(expr $i + 1)
        
        done
    
    done

done