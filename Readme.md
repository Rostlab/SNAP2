# SNAP2

SNAP2 is a method that predicts the effects of single amino acid substitutions in a protein on the protein's function using neural networks.
The development started in November 2011 by Maximilian Hecht.
Perl is used as development language.

## 'git svn clone' HOWTO

* search for correct svn repository (https://rostlab.org/owiki/index.php/Packages)
* -> svn+ssh://rostlab.org/mnt/project/subversion/snap2
* check for sufficient user rights on repository host `$username` and `$password` (contact juanmi@jmcejuela.com)
* user rights only valid for student cluster, note the change of host server to i12k-biolab01.informatik.tu-muenchen.de
* create local folder, supposed to contain future local git repository `$localgit`
* create local folder, supposed to contain current svn repository `$localsvn`
* download svn repository to local folder with `svn co svn+ssh://$username@i12k-biolab01.informatik.tu-muenchen.de/mnt/project/subversion/snap2 $localsvn`
* move to svn `cd $localsvn`
* extract all users, who previously worked on that repository with `svn log --xml | grep author | sort -u | perl -pe 's/.*>(.*?)<.*/$1 = /'`
* write all users into a file `$userstxt` with the format `user1 = First Last Name <email@address.com>`
* clone from student cluster with correct project directory and correct user credentials like `git svn clone --prefix=origin/ --stdlayout --authors-file=$userstxt svn+ssh://$username@i12k-biolab01.informatik.tu-muenchen.de/mnt/project/subversion/snap2 $localgit`
* possible error on Mac OS X 10.10. 'Can't locate SVN/Core.pm ...' can be solved by using `/usr/bin/git`
* insert password and watch it cloning (for troubleshooting refer to https://github.com/Rostlab/PP2_CS_WS_2015-16/wiki/HOWTO-access-rostlab-svn-repos)
* move tags and references and clean them with
  * `cp -Rf .git/refs/remotes/origin/tags/* .git/refs/tags/`
  * `rm -Rf .git/refs/remotes/origin/tags`
  * `cp -Rf .git/refs/remotes/* .git/refs/heads/`
  * `rm -Rf .git/refs/remotes`
* add local git repository to remote repository with `git remote add origin git@github.com:Rostlab/SNAP2.git`
* push to remote by `git push origin --all`

## HOWTO Install

## HOWTO Run, Basics

* Input: Fasta Protein Sequence
* Output: Prediction Score between -100 (neutral) and 100 (effect) for every possible SNP at every position
* Expected Results
* ...

## Method Description

### Author
Maximilian Hecht

### Publications
* Hecht, M., Bromberg, Y., & Rost, B. (2015). Better prediction of functional effects for sequence variants. BMC Genomics, 16(Suppl 8), S1 [PubMed](http://www.ncbi.nlm.nih.gov/pubmed/26110438)
* Bromberg Y & Rost B. (2007). SNAP: predict effect of non-synonymous polymorphisms on function. Nucleic Acids Research, Vol. 35, No. 11 3823-3835 [PubMed](http://www.ncbi.nlm.nih.gov/pubmed/17526529) [Full PDF](http://rostlab.org/~hecht/snap.pdf)
* Hecht, M., Bromberg, Y., & Rost, B. (2013). News from the protein mutability landscape. Journal of molecular biology, 425(21), 3937-3948 [PubMed](http://www.ncbi.nlm.nih.gov/pubmed/23896297) [Full PDF](http://rostlab.org/~snap2web/snap2landscape.pdf)

### Description

* feature calculation (using predict protein pipeline)
* neural network with 650 input, 100 hidden and 2 output nodes
* all 10 models from 10-fold cross validation used to calculate results
* 10 results averaged in jury decision

### Training / Test data

* 100000 variants from OMIM, PMD and enzyme.expasy.org

### ...

## Evaluation

## TODO from Exercise 5.11.15

* remove svn structure trunk/branch/etc..
* 


How to obtain databases for snap2?

* swiss_dat:
        1: Download ftp://ftp.uniprot.org/pub/databases/uniprot/knowledgebase/uniprot_sprot.dat.gz
        2: gunzip uniprot_sprot.dat.gz

* db_swiss:
        1: Obtain swiss_dat (see above)
        2: Generate swiss_dat ID index file: assuming you now have uniprot_sprot.dat in /data/swissprot execute:
           $ /usr/share/librg-utils-perl/dbSwiss --datadir /data/swissprot --infile /data/swissprot/uniprot_sprot.dat --table dbswiss

           This generates /data/swissprot/dbSwiss, the process may take a hour.

	   Note: the generated index file may not be compatible with libdb versions other than the one present on the generating OS.

* uniref, uniref90, swiss:
        1: Download as appropriate:
            + ftp://ftp.uniprot.org/pub/databases/uniprot/uniref/uniref100/uniref100.fasta.gz
            + ftp://ftp.uniprot.org/pub/databases/uniprot/uniref/uniref90/uniref90.fasta.gz
            + ftp://ftp.uniprot.org/pub/databases/uniprot/knowledgebase/uniprot_sprot.fasta.gz
        2: gunzip downloaded file
        3: Use formatdb to format *.fasta file for BLAST

