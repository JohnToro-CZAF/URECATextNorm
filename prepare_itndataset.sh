GIZA_BIN_DIR="./giza-pp/GIZA++-v2"
MCKLS_BINARY="./giza-pp/mkcls-v2/mkcls"
GOOGLE_CORPUS_DIR="./data"

WORK_DIR = `pwd`
echo "Working directory:" ${WORK_DIR}

CORPUS_DIR=${WORK_DIR}/corpus
ALIGNMENT_DIR=${WORK_DIR}/alignment

mkdir ${CORPUS_DIR}
python ${WORK_DIR}/dataPreparation/data_split.py \
    --data_dir=${GOOGLE_CORPUS_DIR} \
    --output_dir=${CORPUS_DIR}

## This script extracts all unique ITN phrase-pairs from the Google TN dataset, tokenizes them and stores in separate folders for each semiotic class. In each folder we generate a bash script for running the alignment.

if [ -d ${ALIGNMENT_DIR} ]
then 
    echo "Cleaning ${ALIGNMENT_DIR}":
    rm -r ${ALIGNMENT_DIR}
fi 

mkdir ${ALIGNMENT_DIR}
python ${WORK_DIR}/dataPreparation/prepare_alignment.py \
    --data_dir=${CORPUS_DIR} \
    --out_dir=${ALIGNMENT_DIR} \
    --gizza_dir=${GIZA_BIN_DIR} \
    --mckls_binary=${MCKLS_BINARY} \

rm -r ${ALIGNMENT_DIR}/punct

## for better GIZA++ alignments mix in examples from other classes
## they will append to the tail of "src" and "dst" files and they will not have corresponding freqs in "freq" file
## all these appended lines will be skipped in the get_replacement_vocab step
for fn in "src" "dst"
do
    cat ${ALIGNMENT_DIR}/money/${fn} \
        ${ALIGNMENT_DIR}/cardinal/${fn} \
        ${ALIGNMENT_DIR}/decimal/${fn} \
        ${ALIGNMENT_DIR}/fraction/${fn} \
        ${ALIGNMENT_DIR}/measure/${fn} > ${ALIGNMENT_DIR}/money/${fn}.new

    cat ${ALIGNMENT_DIR}/measure/${fn} \
        ${ALIGNMENT_DIR}/cardinal/${fn} \
        ${ALIGNMENT_DIR}/decimal/${fn} \
        ${ALIGNMENT_DIR}/fraction/${fn} \
        ${ALIGNMENT_DIR}/money/${fn} > ${ALIGNMENT_DIR}/measure/${fn}.new

    cat ${ALIGNMENT_DIR}/fraction/${fn} \
        ${ALIGNMENT_DIR}/cardinal/${fn} \
        ${ALIGNMENT_DIR}/measure/${fn} \
        ${ALIGNMENT_DIR}/money/${fn} > ${ALIGNMENT_DIR}/fraction/${fn}.new

    cat ${ALIGNMENT_DIR}/decimal/${fn} \
        ${ALIGNMENT_DIR}/cardinal/${fn} \
        ${ALIGNMENT_DIR}/measure/${fn} \
        ${ALIGNMENT_DIR}/money/${fn} > ${ALIGNMENT_DIR}/decimal/${fn}.new

done

for c in "decimal" "fraction" "measure" "money"
do
    mv ${ALIGNMENT_DIR}/${c}/src.new ${ALIGNMENT_DIR}/${c}/src
    mv ${ALIGNMENT_DIR}/${c}/dst.new ${ALIGNMENT_DIR}/${c}/dst
done

for subfolder in ${ALIGNMENT_DIR}/*
do
    echo ${subfolder}
    chmod +x ${subfolder}/run.sh
done

## Run alignment using multiple processes
for subfolder in ${ALIGNMENT_DIR}/*
do
    cd ${subfolder}
    ./run.sh &
done
wait

## Extract final alignments for each semiotic class
for subfolder in ${ALIGNMENT_DIR}/*
do
    python ${WORK_DIR}/dataPreparation/extract_giza_alignments.py \
      --giza_dir=${subfolder} \
      --out_filename=itn.out \
      --giza_suffix=A3.final
done
wait

## add column with frequencies of phrase pairs as well the phrases in the corpus
for subfolder in ${ALIGNMENT_DIR}/*
do
    paste -d"\t" ${subfolder}/freq ${subfolder}/itn.out > ${subfolder}/itn.out2
done

