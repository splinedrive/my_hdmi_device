#!/usr/bin/env bash
export PROJ=$1
source ${XRAY_DIR}/utils/environment.sh
${XRAY_UTILS_DIR}/fasm2frames.py --part xc7a100tcsg324-1 --db-root ${XRAY_UTILS_DIR}/../database/artix7 ${PROJ}.fasm > ${PROJ}.frames
${XRAY_TOOLS_DIR}/xc7frames2bit --part_file ${XRAY_UTILS_DIR}/../database/artix7/xc7a100tcsg324-1/part.yaml --part_name xc7a100tcsg324-1  --frm_file ${PROJ}.frames --output_file ${PROJ}.bit

