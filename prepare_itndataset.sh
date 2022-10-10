GIZA_BIN_DIR="./giza-pp/GIZA++-v2"
MCKLS_BINARY="./giza-pp/mkcls-v2/mkcls"
GOOGLE_CORPUS_DIR="./data"

WORK_DIR = `pwd`
echo "Working directory:" ${WORK_DIR}

CORPUS_DIR=${WORK_DIR}/corpus
ALIGNMENT_DIR=${WORK_DIR}/alignment

mkdir ${CORPUS_DIR}
python ${WORK_DIR}/data_split.py \
    --data_dir=${GOOGLE_CORPUS_DIR} \
    --output_dir=${CORPUS_DIR}

## This script extracts all unique ITN phrase-pairs from the Google TN dataset, tokenizes them and stores in separate folders for each semiotic class. In each folder we generate a bash script for running the alignment.

mkdir ${ALIGNMENT_DIR}
python 