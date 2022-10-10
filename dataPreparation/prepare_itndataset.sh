GIZA_BIN_DIR="/home/ubuntu/hoang.pn200243/URECA/giza-pp/GIZA++-v2"
MCKLS_BINARY="/home/ubuntu/hoang.pn200243/URECA/giza-pp/mkcls-v2/mkcls"
GOOGLE_CORPUS_DIR="/home/ubuntu/hoang.pn200243/URECA/data"

WORK_DIR = `pwd`
echo "Working directory:" ${WORK_DIR}

CORPUS_DIR=${WORK_DIR}/corpus
ALIGNMENT_DIR=${WORK_DIR}/alignment

python ${NEMO_PATH}/examples/