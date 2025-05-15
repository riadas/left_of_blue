#!/bin/bash

repeats=$1
# step=$2
# test_name=$3
num_outer_loop_iters=1 # $((594/step))

echo "repeats=$repeats"
echo "step=$step"

for ((i=0; i<$num_outer_loop_iters; i++))
do
    start_index=$((i*step))
    echo "outer loop iter $i out of $num_outer_loop_iters"
    julia metalanguage/compute_posteriors.jl $repeats # $start_index $step "${test_name}"
done