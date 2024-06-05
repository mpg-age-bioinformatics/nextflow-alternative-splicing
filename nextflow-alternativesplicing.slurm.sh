#!/bin/bash

#source alternativeSplicing.config

## usage:
## $1 : `release` for latest nextflow/git release; `checkout` for git clone followed by git checkout of a tag ; `clone` for latest repo commit
## $2 : profile

set -e

get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/'
}

wait_for(){
    PID=$(echo "$1" | cut -d ":" -f 1 )
    PRO=$(echo "$1" | cut -d ":" -f 2 )
    echo "$(date '+%Y-%m-%d %H:%M:%S'): waiting for ${PRO}"
    wait $PID
    CODE=$?
    
    if [[ "$CODE" != "0" ]] ; 
        then
            echo "$PRO failed"
            echo "$CODE"
            failed=true
            #exit $CODE
    fi
}

failed=false

PROFILE=$2
LOGS="work"
PARAMS="params.json"
project_folder="/nexus/posix0/MAGE-flaski/service/hpc/home/sjiang/nextflow_asplicing_test/"

mkdir -p ${LOGS}

if [[ "$1" == "release" ]] ; 
  then

    ORIGIN="mpg-age-bioinformatics/"
    
    FASTQC_RELEASE=$(get_latest_release ${ORIGIN}nf-fastqc)
    echo "${ORIGIN}nf-fastqc:${FASTQC_RELEASE}" >> ${LOGS}/software.txt
    FASTQC_RELEASE="-r ${FASTQC_RELEASE}"

    KALLISTO_RELEASE=$(get_latest_release ${ORIGIN}nf-kallisto)
    echo "${ORIGIN}nf-kallisto:${KALLISTO_RELEASE}" >> ${LOGS}/software.txt
    KALLISTO_RELEASE="-r ${KALLISTO_RELEASE}"

    STAR_RELEASE=$(get_latest_release ${ORIGIN}nf-star)
    echo "${ORIGIN}nf-star:${STAR_RELEASE}" >> ${LOGS}/software.txt
    STAR_RELEASE="-r ${STAR_RELEASE}"

    MULTIQC_RELEASE=$(get_latest_release ${ORIGIN}nf-multiqc)
    echo "${ORIGIN}nf-multiqc:${MULTIQC_RELEASE}" >> ${LOGS}/software.txt
    MULTIQC_RELEASE="-r ${MULTIQC_RELEASE}"

    BEDGRAPHTOBIGWIG_RELEASE=$(get_latest_release ${ORIGIN}nf-bedGraphToBigWig)
    echo "${ORIGIN}nf-bedGraphToBigWig:${BEDGRAPHTOBIGWIG_RELEASE}" >> ${LOGS}/software.txt
    BEDGRAPHTOBIGWIG_RELEASE="-r ${BEDGRAPHTOBIGWIG_RELEASE}"

    SAJR_RELEASE=$(get_latest_release ${ORIGIN}nf-sajr)
    echo "${ORIGIN}nf-sajr:${SAJR_RELEASE}" >> ${LOGS}/software.txt
    SAJR_RELEASE="-r ${SAJR_RELEASE}"
    
    uniq ${LOGS}/software.txt ${LOGS}/software.txt_
    mv ${LOGS}/software.txt_ ${LOGS}/software.txt
    
else

  for repo in nf-fastqc nf-star nf-kallisto nf-multiqc nf-bedGraphToBigWig nf-sajr ; 
    do

      if [[ ! -e ${repo} ]] ;
        then
          git clone git@github.com:mpg-age-bioinformatics/${repo}.git
      fi

      if [[ "$1" == "checkout" ]] ;
        then
          cd ${repo}
          git pull
          RELEASE=$(get_latest_release ${ORIGIN}${repo})
          git checkout ${RELEASE}
          cd ../
          echo "${ORIGIN}${repo}:${RELEASE}" >> ${LOGS}/software.txt
      else
        cd ${repo}
        COMMIT=$(git rev-parse --short HEAD)
        cd ../
        echo "${ORIGIN}${repo}:${COMMIT}" >> ${LOGS}/software.txt
      fi

  done

  uniq ${LOGS}/software.txt >> ${LOGS}/software.txt_ 
  mv ${LOGS}/software.txt_ ${LOGS}/software.txt

fi

get_images() {
  echo "- downloading images"
  nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1 && \
  nextflow run ${ORIGIN}nf-kallisto ${KALLISTO_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1 && \
  nextflow run ${ORIGIN}nf-star ${STAR_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1 && \
  nextflow run ${ORIGIN}nf-multiqc ${MULTIQC_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1 && \
  nextflow run ${ORIGIN}nf-bedGraphToBigWig ${BEDGRAPHTOBIGWIG_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1 && \
  nextflow run ${ORIGIN}nf-sajr ${SAJR_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1
  echo "- images downloaded"
}

run_fastqc() {
  echo "- running fastqc"
  nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file ${PARAMS} -profile ${PROFILE} >> ${LOGS}/nf-fastqc.log 2>&1 && \
  nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file ${PARAMS} -entry upload -profile ${PROFILE} >> ${LOGS}/nf-fastqc.log 2>&1
  echo "- fastqc done" 
}

run_kallisto_get_genome() {
  echo "- getting genome files"
  nextflow run ${ORIGIN}nf-kallisto ${KALLISTO_RELEASE} -params-file ${PARAMS} -entry get_genome -profile ${PROFILE} >> ${LOGS}/kallisto.log
  echo "- done downloading genome files"
}

run_star() {
  echo "- running star"
  nextflow run ${ORIGIN}nf-star ${STAR_RELEASE} -params-file ${PARAMS} -entry rename -profile ${PROFILE} >> ${LOGS}/star.log 2>&1 && \
  nextflow run ${ORIGIN}nf-star ${STAR_RELEASE} -params-file ${PARAMS} -entry index -profile ${PROFILE} >> ${LOGS}/star.log 2>&1 && \
  nextflow run ${ORIGIN}nf-star ${STAR_RELEASE} -params-file ${PARAMS} -entry map_reads -profile ${PROFILE} >> ${LOGS}/star.log 2>&1 && \
  nextflow run ${ORIGIN}nf-star ${STAR_RELEASE} -params-file ${PARAMS} -entry bam_index -profile ${PROFILE} >> ${LOGS}/star.log 2>&1 && \
  nextflow run ${ORIGIN}nf-star ${STAR_RELEASE} -params-file ${PARAMS} -entry merging -profile ${PROFILE} >> ${LOGS}/star.log 2>&1 

  echo "- star done"
}

run_multiqc() {
  echo "- running multiqc"
  nextflow run ${ORIGIN}nf-multiqc ${MULTIQC_RELEASE} -params-file ${PARAMS} -profile ${PROFILE} >> ${LOGS}/multiqc.log 2>&1 && \
  nextflow run ${ORIGIN}nf-multiqc ${MULTIQC_RELEASE} -params-file ${PARAMS} -entry upload -profile ${PROFILE} >> ${LOGS}/multiqc.log 2>&1
  echo "- multiqc done"
}

run_bedGraphToBigWig() {
  echo "- running bedGraphToBigWig_asplicing"  
  nextflow run ${ORIGIN}nf-bedGraphToBigWig ${BEDGRAPHTOBIGWIG_RELEASE} -params-file  ${PARAMS} -entry bedgraphtobigwig_ATACseq  -profile ${PROFILE}>> ${LOGS}/nf-bedGraphToBigWig.log 2>&1 && \
  nextflow run ${ORIGIN}nf-bedGraphToBigWig ${BEDGRAPHTOBIGWIG_RELEASE} -params-file  ${PARAMS} -entry upload  -profile ${PROFILE}>> ${LOGS}/nf-bedGraphToBigWig.log 2>&1


  echo "- bedGraphToBigWig done"  
}

run_sajr() {
  echo "- running sajr"
  nextflow run ${ORIGIN}nf-sajr ${SAJR_RELEASE} -params-file ${PARAMS} -entry config_template -profile ${PROFILE} >> ${LOGS}/sajr.log 2>&1 && \
  nextflow run ${ORIGIN}nf-sajr ${SAJR_RELEASE} -params-file ${PARAMS} -entry sajr_processing -profile ${PROFILE} >> ${LOGS}/sajr.log 2>&1 && \
  nextflow run ${ORIGIN}nf-sajr ${SAJR_RELEASE} -params-file ${PARAMS} -entry sajr_diff -profile ${PROFILE} >> ${LOGS}/sajr.log 2>&1 && \
  nextflow run ${ORIGIN}nf-sajr ${SAJR_RELEASE} -params-file ${PARAMS} -entry upload -profile ${PROFILE} >> ${LOGS}/sajr.log 2>&1 
  echo "- sajr done"
}

get_images & IMAGES_PID=$!
wait_for "${IMAGES_PID}:IMAGES"

run_fastqc & FASTQC_PID=$!
run_kallisto_get_genome & KALLISTO_PID=$!
wait_for "${KALLISTO_PID}:KALLISTO"

run_star & STAR_PID=$!
wait_for "${STAR_PID}:STAR"

run_multiqc & MULTIQC_PID=$!
wait_for "${MULTIQC_PID}:MULTIQC"

run_bedGraphToBigWig & RUN_bedGraphToBigWig_PID=$!
wait_for "${RUN_bedGraphToBigWig_PID}:bedGraphToBigWig"

run_sajr & SAJR_PID=$!
wait_for "${SAJR_PID}:SAJR"

rm -rf ${project_folder}upload.txt
cat $(find ${project_folder}/ -name upload.txt) > ${project_folder}/upload.txt
sort -u ${LOGS}/software.txt > ${LOGS}/software.txt_
mv ${LOGS}/software.txt_ ${LOGS}/software.txt
cp ${LOGS}/software.txt ${project_folder}/software.txt
cp README_alternativeSplicing.md ${project_folder}/README_alternativeSplicing.md
echo "main $(readlink -f ${project_folder}/software.txt)" >> ${project_folder}/upload.txt
echo "main $(readlink -f ${project_folder}/README_alternativeSplicing.md)" >> ${project_folder}/upload.txt
#${project_folder}/upload.txt ${upload_list}
echo "- done" && sleep 1

exit
