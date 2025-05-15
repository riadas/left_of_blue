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
        /scratch/riadas/julia-1.9.4/bin/julia metalanguage/run_mcmc_with_intermediates_no_sym.jl $repeats $step "${test_name}_repeats_${repeats}.txt" true
    else
        /scratch/riadas/julia-1.9.4/bin/julia metalanguage/run_mcmc_with_intermediates_no_sym.jl $repeats $step "${test_name}_repeats_${repeats}.txt" false
    fi
done
