# Testing  4 Prophage finding tools

I was searching for the best prophage finding tool for bacterial genomics.  After a literature review and recommendations from colleagues, I decided on 3 (updated: 4): Phispy, VirSorter, Phigaro, and ProphET.  I also throw in PHASTER, but as it is not open source, I decided against it.  Having code available to peer review (or in this case, to install locally) is important to me.  If the title of this post bothers you, just pretend I am using 0-indexed counting.

## Our test data
Erwinia carotovora subsp. atroseptica SCRI1043 [BX950851.1](https://www.ncbi.nlm.nih.gov/nuccore/BX950851.1), was chosen for a test bug, as one of the submitters confirmend that considerable human effort went into manually annotating the prophages. 

## PHASTER
We uploaded a fasta file of our test genome to PHASTER.  After about 5 minutes, we got a result


```
Region	Region Length	Completeness	Score	# Total Proteins	Region Position	Most Common Phage	GC %	Details
1	41.4Kb	intact	150	42	2926054-2967509 info_outline	PHAGE_Entero_P88_NC_026014(22)	50.58%	Show info_outline
2	40.6Kb	questionable	90	55	4140147-4180770 info_outline	PHAGE_Burkho_BcepMu_NC_005882(32)	52.22%	Show info_outline
```

This was, unsurprisingly, the easiest of the tools to use.

## ProphET

Next we tried [ProphET](https://github.com/jaumlrc/ProphET). Being a non-Broadie (single tear),  I installed it into a conda env I created:

```
conda create -n ProphET
source activate ProphET
conda install -c biocore blast-legacy
conda install bedtools
conda install  perl-bioperl 
```

NOTE:  There were a few more perl libraries that I needed to install, which they document well in their README.


After getting everything installed, I tried running it, but started running into GFF issues. For the uninitiated, the GFF file format is the leading cause of existential crises.  The author's insist on using one GFF spec, while other resources uses another.  For this reason, they  include a tool `rewrite_gff.pl` to fix this.  So, my workflow became (running from the root directory of ProphET):
```
    cd ./UTILS.dir/GFFLib/
    perl ./gff_rewrite.pl --input path/to/BX950851.1.gff --output ../../BX950851.1_new..gff --add_missing_features
    cd ../../
    ./ProphET_standalone.pl --fasta_in path/to/BX950851.1.fasta../../BX950851.1_new..gff --outdir Lys${i}_ProphET

```

This was cumbersome (especially when running with multiple genomes), and it is surprising and frustrating that this is not built in to the tool.

The results look like this:

```
BX950851.1      1       2932697 2967509
BX950851.1      2       3803975 3827465
BX950851.1      3       4144591 4180770
```

So ProphET has truncated the first hit from PHASTER, and added an aditional hit.  But overall, these results agree decently well.


## Phispy
The last release of Phispy was in 2014; the readme shows that the author was a PhD student, who has likely gone on to greater things now.  Dispite the tool's age, it came highly recommended.

I installed it from sourceforge:

```
# download from https://downloads.sourceforge.net/project/phispy/phiSpyNov11_v2.3.zip

unzip phiS*
conda create --name phispy python=2.7.15 biopython r-randomforests
source activate phispy
```

Ok, so it says that it needs a certain type of annotation. Lets give it a try with a vanilla annotation 

```
python ~/miniconda3/envs/phispy/bin/phiSpyNov11_v2.3/genbank_to_seed.py ./BX950851.1.gb ./BX950851_seed/ 

In the GenBank file, for a gene/RNA, locus_tag is missing. locus_tag is required for each gene/RNA.                                                                   
Please make sure that each gene/RNA has locus_tag and run the program again.       
```

It didnt work. I reannoated the genome with Prokka, and it subsequently worked.  I ran Phispy, and eventually got the following results:

```
CAIIPDDM_00pp.1 CAIIPDDM_1_1063490_1081325
CAIIPDDM_02pp.2 CAIIPDDM_1_2372933_2431115
CAIIPDDM_02pp.3 CAIIPDDM_1_2773681_2839971
CAIIPDDM_02pp.4 CAIIPDDM_1_2929563_2964448
CAIIPDDM_02pp.5 CAIIPDDM_1_3192250_3271834
CAIIPDDM_03pp.6 CAIIPDDM_1_4116963_4175637
```

Now, we have 1 that we have seen before, and 5 new ones.


##  Phigaro
Joe Healey recommended trying another tool, [Phigaro](https://github.com/lpenguin/phigaro).  why not? Its available on pip, how bad could it be?

```
conda create -n phigaro
source activate phigaro
pip install phigaro
phigaro-setup

```

I am working on an HPC, so I do not have sudo access.  Strike 1 for phigaro.  But they include instruction for semi-manual setup.  

I am stuck trying to get metagenemark.  Their licence page on their website isn't working.  I have emailed the authors. Strike 2.


[6 hours later]
The authors got it sorted out, and I now have it configured, after a bit of fiddling around with having the `.gm_key` in the right part of the filesystem.

I ran the program as `phigaro -f ./BX950851.fasta -o BX950851_phigaro.txt`, getting the following result:
```
scaffold        begin   end
BX950851.1 Erwinia carotovora subsp. atroseptica SCRI1043, complete genome      1356757 1376318
BX950851.1 Erwinia carotovora subsp. atroseptica SCRI1043, complete genome      2928085 3003543
BX950851.1 Erwinia carotovora subsp. atroseptica SCRI1043, complete genome      3106945 3119520
BX950851.1 Erwinia carotovora subsp. atroseptica SCRI1043, complete genome      3735875 3765347
BX950851.1 Erwinia carotovora subsp. atroseptica SCRI1043, complete genome      4143714 4184809
```
Compared to Phispy, we have 1, maybe two overlapping hits.  Both the PHASTER hits seem to be there, though.

## VirSorter

Lastly, we tried Virsorter.  You have to download a sizable database, but they give a nice walkthrough on how to get set up on their Github page.  I'll spare you the details of running it; it was pretty pain-free. Here are the results

Update: talked with the authors on how to find the coordinates.


## Summary


| Island no. | Putative phenotype(s)                                                  | start   | stop    | PHASTER | ProphET | phiSpy | phigaro | VirSorter |
|------------|------------------------------------------------------------------------|---------|---------|---------|---------|--------|---------|-----------|
| HAI1       | Capsular polysaccharide biosynthesis                                   | 574080  | 587651  |         |         |        |         |    X      |
| HAI2       | Polyketide phytotoxin biosynthesis (cfa)                               | 590844  | 688402  |         |         |        |         |    X      |
| HAI3       |                                                                        | 739283  | 750273  |         |         |        |         |           |
|            |                                                                        | 1063490 | 1081325 |         |         | X      |         |           |
|            |                                                                        | 1356757 | 1376318 |         |         |        | X       |           |
| HAI4       |                                                                        | 1180862 | 1196644 |         |         |        |         |           |
| HAI5       | Exopolysaccharide and O-antigen biosynthesis                           | 1606718 | 1638218 |         |         |        |         |           |
| HAI6       | Nonribosomal peptide phytotoxin                                        | 1666599 | 1727303 |         |         |        |         |           |
| HAI7       | Type IV secretion (virB) ; Integrated plasmid ;                        | 1855523 | 1926959 |         |         |        |         |    X      |
| HAI8       | Type III secretion (hrp);  (hecAB)                                     | 2324722 | 2486065 |         |         | X      |         |    X      |
| HAI9       | P2 family prophage                                                     | 2935461 | 2966671 | X       | o       | X      | X       |    X      |
| HAI10      | Phenazine antibiotic biosynthesis (ehp)                                | 3029319 | 3040751 |         |         |        |         |           |
| HAI11      |                                                                        | 3092131 | 3101182 |         |         |        |         |           |
|            |                                                                        | 3106945 | 3119520 |         |         |        | X       |           |
| HAI12      | Rhs and its accessory element VgrG                                     | 3194782 | 3227396 |         |         | X      |         |           |
| HAI13      | Putative integrated plasmid                                            | 3236381 | 3263492 |         |         |        |         |    X      |
| HAI14      | Nitrogen fixation (nif)                                                | 3280604 | 3355481 |         |         |        |         |           |
| HAI15      | Agglutination/adhesion (aggA)                                          | 3652523 | 3677516 |         |         |        |         |           |
|            |                                                                        | 3735875 | 3765347 |         |         |        | X       |           |
| HAI16      |                                                                        | 3794816 | 3880056 |         | X       |        |         |           |
| HAI17      | Prophage                                                               | 4144591 | 4180770 | X       | X       | o      | X       |    X      |

`X` = Hit 
`o` = partial hit
`?` = unknown    
This table adapted from table 1 of https://www.ncbi.nlm.nih.gov/pubmed/15263089

We do appear to detect the obvious phages (marked HAI11 and HAI17), but thats where the similarity ends.  We don't really know what to make of the other hits.  And this is sensible -- the longer a prophage is integrated into a genome, the more replication errors are going to occur, and the more that region is going to start blending in to the host region.  I think that we learn is that any of these softwares can detect obvious (read: recent) prophages, but for more ancestral ones, its anyones guess.



## Conclusion


This was not fun.

- I wish most of these were easier to install.
- I wish none of these were written in Perl.
- I wish all of these were open source.
- I wish Phispy was still maintained.
- I wish none of them were hosted on Sourceforge.
- I wish there weren't additional tools that I would need to compare to make this more complete.
- I wish these worked from raw reads rather than assemblies, as we know prophages are difficult to correcly assemble.
- I wish all the tools's publications had appropriate, benchmarked comparisons to existing tools.
- I wish I didn't get  5 different answers from  5 different tools.
- I wish none of these involved instalation licenses

