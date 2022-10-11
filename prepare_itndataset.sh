#!/bin/bash

GIZA_BIN_DIR="/home/ubuntu/hoang.pn200243/UrecaTextNorm/giza-pp/GIZA++-v2"
MCKLS_BINARY="/home/ubuntu/hoang.pn200243/UrecaTextNorm/giza-pp/mkcls-v2/mkcls"
GOOGLE_CORPUS_DIR="./data"

WORK_DIR=`pwd`
echo "Working directory:" ${WORK_DIR}

CORPUS_DIR=${WORK_DIR}/corpus
ALIGNMENT_DIR=${WORK_DIR}/alignment

if [ -d ${CORPUS_DIR} ]
then 
    echo "Cleaning ${CORPUS_DIR}":
    rm -r ${CORPUS_DIR}
fi 

mkdir ${CORPUS_DIR}
python ${WORK_DIR}/dataPreparation/data_split.py \
    --data_dir=${GOOGLE_CORPUS_DIR} \
    --output_dir=${CORPUS_DIR}

if [ -d ${ALIGNMENT_DIR} ]
then 
    echo "Cleaning ${ALIGNMENT_DIR}":
    rm -r ${ALIGNMENT_DIR}
fi 

mkdir ${ALIGNMENT_DIR}
python ${WORK_DIR}/dataPreparation/prepare_alignment.py \
    --data_dir=${CORPUS_DIR} \
    --out_dir=${ALIGNMENT_DIR} \
    --giza_dir=${GIZA_BIN_DIR} \
    --mckls_binary=${MCKLS_BINARY} \

rm -r ${ALIGNMENT_DIR}/punct

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

# ## loop through the obtained alignments and collect vocabularies (for each semiotic class)
# ## of all possible replacement fragments (aka tags)
REP_DIR=${WORK_DIR}/replacement
if [ -d ${REP_DIR} ]
then 
    echo "Cleaning ${REP_DIR}":
    rm -r ${REP_DIR}
fi 
mkdir ${REP_DIR}

python ${WORK_DIR}/dataPreparation/prepare_after_alignment.py \
  --mode=get_replacement_vocab \
  --giza_dir=${ALIGNMENT_DIR} \
  --alignment_filename=itn.out2 \
  --data_dir="" \
  --vocab_filename=${REP_DIR}/replacement_vocab_full.txt \
  --out_filename=""

echo ${REP_DIR}

grep -v "0__" ${REP_DIR}/replacement_vocab_full.txt.verbatim | head -n 108 > ${REP_DIR}/replacement_vocab_verbatim.txt
grep -v "0__" ${REP_DIR}/replacement_vocab_full.txt.time | head -n 148 > ${REP_DIR}/replacement_vocab_time.txt
grep -v "0__" ${REP_DIR}/replacement_vocab_full.txt.telephone | head -n 52 > ${REP_DIR}/replacement_vocab_telephone.txt
head -n 0 ${REP_DIR}/replacement_vocab_full.txt.plain > ${REP_DIR}/replacement_vocab_plain.txt
grep -v "0__" ${REP_DIR}/replacement_vocab_full.txt.ordinal | head -n 251 > ${REP_DIR}/replacement_vocab_ordinal.txt
grep -v "0__" ${REP_DIR}/replacement_vocab_full.txt.money | grep -v "a__" | head -n 532 > ${REP_DIR}/replacement_vocab_money.txt
grep -v "0__" ${REP_DIR}/replacement_vocab_full.txt.measure | head -n 488 > ${REP_DIR}/replacement_vocab_measure.txt
head -n 257 ${REP_DIR}/replacement_vocab_full.txt.letters > ${REP_DIR}/replacement_vocab_letters.txt
grep -v "0__" ${REP_DIR}/replacement_vocab_full.txt.fraction | head -n 169 > ${REP_DIR}/replacement_vocab_fraction.txt
head -n 276 ${REP_DIR}/replacement_vocab_full.txt.electronic > ${REP_DIR}/replacement_vocab_electronic.txt
head -n 73 ${REP_DIR}/replacement_vocab_full.txt.digit > ${REP_DIR}/replacement_vocab_digit.txt
grep -v "0__" ${REP_DIR}/replacement_vocab_full.txt.decimal | head -n 149 > ${REP_DIR}/replacement_vocab_decimal.txt
grep -v "0__" ${REP_DIR}/replacement_vocab_full.txt.date | grep -v "[0-9]-[0-9]" | grep -v "[0-9]\,[0-9]" | grep -v "[0-9]\.[0-9]" | grep -v "[0-9]\/[0-9]" | head -n 554 > ${REP_DIR}/replacement_vocab_date.txt
grep -v "0__" ${REP_DIR}/replacement_vocab_full.txt.cardinal | head -n 402 > ${REP_DIR}/replacement_vocab_cardinal.txt
head -n 137 ${REP_DIR}/replacement_vocab_full.txt.address > ${REP_DIR}/replacement_vocab_address.txt

cat ${REP_DIR}/replacement_vocab_address.txt \
  ${REP_DIR}/replacement_vocab_cardinal.txt \
  ${REP_DIR}/replacement_vocab_date.txt \
  ${REP_DIR}/replacement_vocab_decimal.txt \
  ${REP_DIR}/replacement_vocab_digit.txt \
  ${REP_DIR}/replacement_vocab_electronic.txt \
  ${REP_DIR}/replacement_vocab_fraction.txt \
  ${REP_DIR}/replacement_vocab_letters.txt \
  ${REP_DIR}/replacement_vocab_measure.txt \
  ${REP_DIR}/replacement_vocab_money.txt \
  ${REP_DIR}/replacement_vocab_ordinal.txt \
  ${REP_DIR}/replacement_vocab_plain.txt \
  ${REP_DIR}/replacement_vocab_telephone.txt \
  ${REP_DIR}/replacement_vocab_time.txt \
  ${REP_DIR}/replacement_vocab_verbatim.txt > ${REP_DIR}/replacement_vocab.select.txt

python ${WORK_DIR}/dataPreparation/prepare_after_alignment.py \
  --mode=filter_by_vocab \
  --giza_dir=${ALIGNMENT_DIR} \
  --alignment_filename=itn.out2 \
  --data_dir="" \
  --vocab_filename=${REP_DIR}/replacement_vocab.select.txt \
  --out_filename=itn.select.out

for subset in "train" "dev"
do
    python ${WORK_DIR}/dataPreparation/prepare_after_alignment.py \
      --mode=get_labeled_corpus \
      --giza_dir=${ALIGNMENT_DIR} \
      --alignment_filename=itn.select.out \
      --data_dir=${CORPUS_DIR}/${subset} \
      --vocab_filename="" \
      --out_filename=${CORPUS_DIR}/${subset}.labeled
done

python ${WORK_DIR}/dataPreparation/get_label_vocab.py \
  --train_filename=${CORPUS_DIR}/train.labeled \
  --dev_filename=${CORPUS_DIR}/dev.labeled \
  --out_filename=${CORPUS_DIR}/label_map.txt

python  ${WORK_DIR}/dataPreparation/sample_each_label.py \
  --filename=${CORPUS_DIR}/dev.labeled \
  --max_count=10

python  ${WORK_DIR}/dataPreparation/sample_each_label.py \
  --filename=${CORPUS_DIR}/train.labeled \
  --max_count=500

if [ -d ${WORK_DIR}/datasets ]
then 
    echo "Cleaning ${WORK_DIR}/datasets":
    rm -r ${WORK_DIR}/datasets
fi 
mkdir ${WORK_DIR}/datasets

DATASET=${WORK_DIR}/datasets/itn_sample500k_rest1500k_select_vocab
if [ -d ${DATASET} ]
then 
    echo "Cleaning ${DATASET}/datasets":
    rm -r ${DATASET}
fi 
mkdir ${DATASET}

cat ${CORPUS_DIR}/train.labeled.sample_500 > ${DATASET}/train.tsv
head -n 1500000 ${CORPUS_DIR}/train.labeled.rest_500 >> ${DATASET}/train.tsv
cat ${CORPUS_DIR}/dev.labeled.sample_10 > ${DATASET}/valid.tsv
head -n 12000 ${CORPUS_DIR}/dev.labeled.rest_10 >> ${DATASET}/valid.tsv
cp ${DATASET}/valid.tsv ${DATASET}/test.tsv

echo "ADDRESS" > ${CORPUS_DIR}/semiotic_classes.txt
echo "CARDINAL" >> ${CORPUS_DIR}/semiotic_classes.txt
echo "DATE" >> ${CORPUS_DIR}/semiotic_classes.txt
echo "DECIMAL" >> ${CORPUS_DIR}/semiotic_classes.txt
echo "DIGIT" >> ${CORPUS_DIR}/semiotic_classes.txt
echo "ELECTRONIC" >> ${CORPUS_DIR}/semiotic_classes.txt
echo "FRACTION" >> ${CORPUS_DIR}/semiotic_classes.txt
echo "LETTERS" >> ${CORPUS_DIR}/semiotic_classes.txt
echo "MEASURE" >> ${CORPUS_DIR}/semiotic_classes.txt
echo "MONEY" >> ${CORPUS_DIR}/semiotic_classes.txt
echo "ORDINAL" >> ${CORPUS_DIR}/semiotic_classes.txt
echo "PLAIN" >> ${CORPUS_DIR}/semiotic_classes.txt
echo "PUNCT" >> ${CORPUS_DIR}/semiotic_classes.txt
echo "TELEPHONE" >> ${CORPUS_DIR}/semiotic_classes.txt
echo "TIME" >> ${CORPUS_DIR}/semiotic_classes.txt
echo "VERBATIM" >> ${CORPUS_DIR}/semiotic_classes.txt

cp ${CORPUS_DIR}/label_map.txt ${WORK_DIR}/datasets/label_map.txt
cp ${CORPUS_DIR}/semiotic_classes.txt ${WORK_DIR}/datasets/semiotic_classes.txt