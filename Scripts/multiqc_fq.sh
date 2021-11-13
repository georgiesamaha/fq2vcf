#!/bin/bash

# to run: bash multiqc.sh from Scripts directory

module load singularity/3.7.0

Project=
fastq=/scratch/${Project}/Fastq

#### DON'T EDIT BELOW THIS LINE ####

singularity exec -B ${fastq}:$HOME \
        /project/${Project}/Apps/multiqc_1.9--py_1.sif \
        multiqc . ----filename ${Project}_multiqc_fastqc \
        -o ${fastq}
