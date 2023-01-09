#!/bin/bash

vecs=("00_sv" "01_sv" "01_sv_short" "02_sv" "02_sv_short" "03_sv_short" "04_sv")

echo "HELLO"

for v in ${vecs[@]}; do
  infn="test-vectors/vec_271_${v}.dat"
  reffn="test-vectors/vec_271_${v}_ref.ppm"
  outfn="ppms/out_${v}.ppm"
  
  echo ${infn}
  ./rasterizer_gold ${outfn} ${infn}
  echo "======================"
  diff ${outfn} ${reffn} 
  echo "======================"
done
