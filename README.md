# nextflow-alternative-splicing

This workflow is based on the following nextflow pipes:

- https://github.com/mpg-age-bioinformatics/nf-fastqc
- https://github.com/mpg-age-bioinformatics/nf-kallisto
- https://github.com/mpg-age-bioinformatics/nf-star
- https://github.com/mpg-age-bioinformatics/nf-bedGraphToBigWig
- https://github.com/mpg-age-bioinformatics/nf-sajr

## hpc - slurm test

Create the test directory:
```
mkdir -p /${HOME}/nextflow_asplicing_test
```

Download the demo data:
```
mkdir -p ~/nextflow_asplicing_test/raw_data
cd ~/nextflow_asplicing_test/raw_data

curl -J -O https://datashare.mpcdf.mpg.de/s/jcEaS5vqpJO0lOy/download
curl -J -O https://datashare.mpcdf.mpg.de/s/XHanbnjfvQ9rACD/download
curl -J -O https://datashare.mpcdf.mpg.de/s/sIebkRdMfMSweq2/download
curl -J -O https://datashare.mpcdf.mpg.de/s/zoNxS9vRI7jl77y/download
curl -J -O https://datashare.mpcdf.mpg.de/s/0WHGNIhjJC792lY/download
curl -J -O https://datashare.mpcdf.mpg.de/s/ZlM0lWKPh8KrP6B/download
curl -J -O https://datashare.mpcdf.mpg.de/s/o3O6BKaEXqB7TTo/download

```

Add the run script, paramaters file, and sample sheet to the project folder:
```
cd ~/nextflow_asplicing_test/

git clone git@github.com:mpg-age-bioinformatics/nextflow-alternative-splicing.git

# curl -J -O https://raw.githubusercontent.com/mpg-age-bioinformatics/nextflow-alternative-splicing/main/nextflow-alternativesplicing.slurm.sh
# curl -J -O https://raw.githubusercontent.com/mpg-age-bioinformatics/nextflow-alternative-splicing/main/params.json
# curl -J -O https://raw.githubusercontent.com/mpg-age-bioinformatics/nextflow-alternative-splicing/main/sample_sheet.xlsx
```

Run slurm test:
```
cd ~/nextflow_asplicing_test/nextflow-alternative-splicing
bash nextflow-alternativesplicing.slurm.sh -profile studio
```

Once run is complete you will find in the `work` folder the file `software.txt` with information on all the respective versions used for your run.

 
Outputs
  - the output will be located in `~/nextflow_asplicing_test/sajr_output/count_files/`
  - the file most researchers want is:
      - **results.xlsx**: list of significant alternative splicing events with with optional indication of novel splicing patterns.
      - contains: alternative TSS, alternative 5' and 3' splicing, alternative exon usage, intron retention; and alternative poly-A site

Here is a list of output columns and what they mean (to my best knowledge and personal mails, the documentation is not great):

```

GeneNames           : Ensemeb gene ID
gene_id             : SAJR defined gene ID
Class	            : SAJR defined class (ref: http://storage.bioinf.fbb.msu.ru/~mazin/sajr_comp.html "Overlap classes")
chr_id	            : chomosome coordinates of segment
start               : start coordinates of segment
stop	            : end coordinates of segment
strand	            : strand of segment
type	            : SAJR defined type (ref: http://storage.bioinf.fbb.msu.ru/~mazin/annotator.html possible types: EXT, INT, ALT)
position	    : SAJR defined position of segment in transcript (FIRST, INTERNAL or LAST)
sites               : description of the donor/acceptor sites (personal communication with the author: "The column gives types of splice that form the segments: acceptor, donor, transcription start and end and dot ('.') denotes rare cases when two sites coincides. This column can be used to define simple splicing types (but please take into account that these segments might be a parts of complex alternatives) - ad, aa, dd and da are cassette exon, alternative acceptor, donor and retained intron respectively")
pvalue	            : calculated by SAJR R-package function "calcSAPvalue()": Calculate p-value based on chisq distribution for each fit and factor could account for overdispersion
padj	            : p.value adjusted for multiple hypothesis testing (using Benjamini & Hochberg method)
psi.grp1	    : inclusion ratio (psi) averaged over all replicates in group 1 (ref: http://storage.bioinf.fbb.msu.ru/~mazin/counter_man.html "Inclusion ratio calculation")
psi.grp2	    : inclusion ratio (psi) averaged over all replicates in group 2	
grp1.sd	            : inclusion ratio (psi) standard deviation over all replicates in group 1 	
grp2.sd	            : inclusion ratio (psi) standard deviation over all replicates in group 2 		
psi.diff	    : psi.grp2 - psi.grp1
log2FC	            : log2((psi.grp2+0.01)/(psi.grp1+0.01))
ir.sample           : inclusion ratio of segment for each sample
i.sample            : # inclusion reads of each segment for each sample (ref: http://storage.bioinf.fbb.msu.ru/~mazin/counter_man.html "Segment read count" for exact definitions of inclusion and exclusion reads)
e.sample            : # exclusion reads of segement for each sample
segment	            : segment ID (randomly assigned)
Novelty	            : either "KnownSplice" if splice site was found in original annotation or "NovelSplice" if splice site has not been annotated before
external_gene_name  : gene name

```
