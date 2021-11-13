# fq2vcf   WORK IN PROGRESS... 

This repo contains bash scripts for fastq to vcf pipeline, written for USyd Artemis HPC. This pipeline follows GATK/BROAD best practice recommendations for alignment and germline variant calling. Workflow requires users to download and prepare reference assembly and then run a series of scripts to align raw reads to the reference assembly, perform base quality score recalibration and perform variant calling with GATK. These scripts have not been optimised for speed and are run as a vanilla implementation.  

Instructions on how to install this repo, prepare, and run scripts follow below. 


## Set up and installation  
  
Before you begin clone this repo to your `/project/<Project>` directory: 

```
module load git
git clone https://github.com/georgiesamaha/fq2vcf.git
```
* All Scritps can be found in and should be run from `/project/<Project>/Scripts`  
* All logs will be output into `/project/<Project>/Scripts/Logs`  

These scripts assume you will be running your scripts from `/project/<Project>` and outputting files to `/scratch/<Project>`. You will need to edit variables in each script before running based on your project. You will generally need to edit project, reference and config variables in all scripts. Any variable that needs to be edited before running sits at the top of the script, under the heading `# edit these to match your project (specify full path)`.
     

Upon cloning this repo from github you will have the following directory structure in `/project/<Project>`:  


```
/project/<Project>/
├── Apps
├── Reference
└── Scripts
  └── Logs
  └── Configs
  
```

- `Apps` should be used to house the MultiQC singularity image file (.sif) you download (instructions below) and any other tools you choose to install for downstream analyses. 
- `Reference` should house any reference assembly files including .fasta (and its indexes), .dict, .gtf and population .vcf files. 
- `Scripts` houses all scripts to be run as well as PBS and tool output logs. Run all scripts from `project/<Project>/Scripts`. If you run into any issues with failed runs, look at corresponding log file for source of error. Most scripts are written as PBS array jobs. To check their progress in the queue as they run, type `jobstat` into the commandline.   

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

### Software 
All tools run in this pipeline are globally installed on Artemis, with the exception of MultiQC. Tools used in these scripts and their version are:  

 * fastqc/0.11.8
 * multiqc/1.9  
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

### 1. Prepare config file 

The config file must have one row per unique sample, matching the format:

|ArrayID|SampleID|Breed |Platform|SeqCentre |
|-------|--------|------|--------|----------|
|1      |Sample1 |Breed1|Illumina|Ramaciotti|
|2      |Sample2 |Breed1|Illumina|Ramaciotti|

   - ArrayID: job number for PBS job scheduler. Sample 1 will be run as 
   - SampleID: the unique identifier enabling one to recognise which FASTQs belong to the same sample.
   - Platform: type of sequencing platform 
   - SeqCentre: where the samples were sequenced, this will be stored in the final BAM files

Save the config file to the /project/<Project>/Scripts/Configs directory. It will be used to run a single job array for each sample, where applicable to run script parallel by sample.  

### 2. Download and prepare reference assembly   

Download reference genome from Ensembl's FTP site using wget. Can also use this opportunity to download population VCF file and GTF file for downstream analyses. For example:

```
wget http://ftp.ensembl.org/pub/release-104/fasta/felis_catus/dna/Felis_catus.Felis_catus_9.0.dna.toplevel.fa.gz
wget http://ftp.ensembl.org/pub/release-104/variation/vcf/felis_catus/felis_catus.vcf.gz
wget http://ftp.ensembl.org/pub/release-104/gtf/felis_catus/Felis_catus.Felis_catus_9.0.104.gtf.gz
```

Index the reference assembly for samtools, GATK and BWA by running `prepare_reference.pbs`. Edit ref variable before running.   

```
qsub prepare_reference.pbs 
```

### 3. Check quality of fastq files with FastQC 
  
This step will produce quality reports for all fastq files. Each fastq file will be run as a separate task and each task is processed in parallel. For an explanation of reports, see the [FastQC documentation](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/Help/).   

 To run fastQC in parallel create a `fastq.config` file and save in /project/<Project>/Scripts/Configs. Should have the following format, with no header:  
 |#ArrayID|Fastq|
|---|-----------------------------|
|1  |Sample1_R1_001.fastq.gz|
|2  |Sample1_L001_R2_001.fastq.gz|
|3  |Sample2_L001_R1_001.fastq.gz|
|4  |Sample2_L001_R2_001.fastq.gz|
|5  |Sample3_L001_R1_001.fastq.gz|
|6  |Sample3_L001_R2_001.fastq.gz|
  
 Edit variables in the script according to the needs of your project and run fastQC for each fastq file in parallel with: 
  ```
  qsub fastqc.pbs
  ```
FastQC reports are output to `/scratch/<Project>/Fastq/FastQC`. 

### 4. Aggregate fastQC reports with MultiQC 
  
Aggregate reports of FastQC results can also be produced for all FASTQ files using [MultiQC](https://multiqc.info/docs/), if desired. Edit the variables in the script according to the needs of your project and run script as: 
  
```
bash multiqc_fq.sh
```

MultiQC aggregate report for fastq files are output to `/scratch/<Project>/Fastq`. 
  
### 5. Align raw reads to reference with bwa-mem
  
Align raw reads to the reference assembly with bwa-mem for each sample in parallel. Duplicate and split reads will be extracted from the final alignment file and saved as .sam files. These files can later be used for structural variant calling if necessary. This process will take approximately 24 hours. If job fails because it excedes walltime, edit the #PBS -l walltime=HH:MM:SS variable to give the job more time. This may occur for higher coverage samples. Edit relevant variables in the script and run script with: 
  
```
qsub align.pbs
```
  
Indexed final.bam files as well as split.sam and disc.sam files are output to `/scratch/<Project>/Bams`  
  
### 6. Perform base quality score recalibration 

This step is optional and requires a set of known population-level variants to be run. It is a data pre-processing step that detects systematic errors made by the sequencing machine when it estimates the accuracy of each base call. Base quality score recalibration is performed in two steps. See [GATK's BQSR documentation](https://gatk.broadinstitute.org/hc/en-us/articles/360035890531-Base-Quality-Score-Recalibration-BQSR-) for more information. This step should take ~3-4 hours. Edit relevant variables in the script and run script with: 

```
qsub bqsr.pbs
```
  
### 7. Collect alignment summary stats 

Collect summary metrics for final.bam files with [Samtools flagstat](http://www.htslib.org/doc/samtools-flagstat.html). This step also includes running multiQC to create an aggregate report for all final.bam files. If you do not want to run MultiQC, hash out the singularity-multiqc command in the script. Edit relevant variables in the script and run script with: 

```
qsub bamstats.pbs
```
  
### 8. Call variants with GATK's HaplotypeCaller 

### 9. Joint call variants 

### 10. Collect VCF summary stats 
  
## Notes  
  
 
## Resources 
[Artemis user guide]() 
[Artemis job queues]()
[GATK bqsr]() 
[GATK parallelism]() 
[VCF file format]() 
[BAM file format[() 
[Fastq file format]()
  
