# fq2vcf   WORK IN PROGRESS... 

This repo contains bash scripts for fastq to vcf pipeline, written for USyd Artemis HPC. This pipeline follows GATK/BROAD best practice recommendations for alignment and germline variant calling. Workflow requires users to download and prepare reference assembly and then run a series of scripts to align raw reads to the reference assembly, perform base quality score recalibration and perform variant calling with GATK.    

Instructions on how to install this repo, prepare, and run scripts follow below. 


## Installation  
  
Before you begin clone this repo to your `/project/<Project>` directory: 

```
module load git
git clone https://github.com/georgiesamaha/fq2vcf.git
```
* All Scritps can be found in and should be run from `/project/<Project>/Scripts`  
* All logs will be output into `/project/<Project>/Scripts/Logs`  

### Software 
All tools run in this pipeline are globally installed on Artemis, with the exception of MultiQC. Globally installed tools used in these scripts and their version are:  

 * fastqc/0.11.8
 * samtools/1.10
 * bwa/0.7.17
 * samblaster/0.1.24
 * singularity/3.7.0
 * gatk/4.2.1.0

Running MultiQC step is optional as it is used in this pipeline to create aggregate quality reports for fastqs and bams. To download multiQC/1.9 singularity container run the following from the Scripts directory:    
```
bash prepmultiqc.sh
``` 

## User guide   

### 1. Prepare /project and /scratch working directories 

These scripts assume you will be running your scripts from `/project/<Project>` and outputting files to `/scratch/<Project>`. You can edit variables in each script to output use a different directory structure.   

Upon cloning this repo from github you will have the following directory structure in `/project/<Project>`:  


```
/project/<Project>/
├── Apps
├── Reference
└── Scripts
  └── Logs
  
```

`Apps` should be used to house the MultiQC singularity image file (.sif) you download (instructions below) and any other tools you choose to install for downstream analyses.   
`Reference` should house any reference assembly files including .fasta (and its indexes), .dict, .gtf and population .vcf files. 
`Scripts` houses all scripts to be run as well as PBS and tool output logs. Run all scripts from `project/<Project>/Scripts`. If you run into any issues with failed runs, look at corresponding log file for source of error.   

These scripts expect the following directory structure in `/scratch/<Project>`:   
 
  ```
  /scratch/<Project>/
├── Bams
├── Fastq
└── VCFs
```
 
- `Fastq`: copy your fastq files here before you begin. FastQC will output quality reports.   
- `Bams` will house all BAM files including split, discordant, and final BAMs and bam summary stats
- `VCFs` will house all g.vcf files and cohort VCF file   


### 2. Download and prepare reference assembly   

Download reference genome from Ensembl's FTP site using wget. Can also use this opportunity to download population VCF file and GTF file for downstream analyses. For example:

```
wget http://ftp.ensembl.org/pub/release-104/fasta/felis_catus/dna/Felis_catus.Felis_catus_9.0.dna.toplevel.fa.gz
wget http://ftp.ensembl.org/pub/release-104/variation/vcf/felis_catus/felis_catus.vcf.gz
wget http://ftp.ensembl.org/pub/release-104/gtf/felis_catus/Felis_catus.Felis_catus_9.0.104.gtf.gz
```

Index the reference assembly for samtools, GATK and BWA by running `prepare_reference.pbs`. Edit ref variable before running.   

```
bash prepare_reference.pbs 
```

### 3. Check quality of fastq files with FastQC 

### 4. Aggregate fastQC reports with MultiQC 

### 5. Align raw reads to reference with bwa-mem

### 6. Perform base quality score recalibration 

### 7. Collect alignment summary stats 

### 8. Call variants with GATK's HaplotypeCaller 

### 9. Joint call variants 

### 10. Collect VCF summary stats 
