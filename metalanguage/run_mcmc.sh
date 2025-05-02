#!/bin/bash

repeats=$1
iters=$2
step=$3
test_name=$4
num_outer_loop_iters=$((iters/step))

echo "repeats=$repeats"
echo "iters=$iters" 
echo "step=$step"

for ((i=0; i<$num_outer_loop_iters; i++))
do
    echo "outer loop iter $i out of $num_outer_loop_iters"
    if [[ $i == 0 ]]; then
        julia metalanguage/run_mcmc_with_intermediates.jl $repeats $step "$4.txt" true
    else
        julia metalanguage/run_mcmc_with_intermediates.jl $repeats $step "$4.txt" false
    fi
done