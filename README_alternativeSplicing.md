# Nextflow-alternative-splicing pipeline
adopted and modified from [bit_pipe_alternative_splicing](https://github.molgen.mpg.de/mpg-age-bioinformatics/bit_pipe_alternative_splicing/blob/master/README_alternativeSplicing.md)

SAJR pipeline based on the following instructions:  

  - http://storage.bioinf.fbb.msu.ru/~mazin/index.html  (not available)
  - https://protocolexchange.researchsquare.com/article/nprot-6093/v1  
      
### Requirements
  - normal RNAseq, preferably long paired end reads, to capture splicing events
  - if possible poly-A data would be better to rule out false pre-mRNA intron retention
      
### Pipeline
  - map Reads with STAR
  - merge, sort, and index replicate bamfiles using Samtools
  - run SAJR in de novo annotation mode to find novel splice-forms
  - run SAJR in annotation comparison mode to compare the novel annotation with the known annotation 
  - run SAJR in count mode for each sample
  - run SAJR differential splicing analysis
  
  
### Outputs
  - the output will be located in `${workdir}/sajr_output/count_files/`
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
      
### References
  - [STAR](https://pubmed.ncbi.nlm.nih.gov/23104886/)
  - [samtools](https://pubmed.ncbi.nlm.nih.gov/19505943/)
  - [SAJR](https://pubmed.ncbi.nlm.nih.gov/23340839/)

