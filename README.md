# SNAP2

SNAP2 is a method that predicts the effects of single amino acid substitutions in a protein on the protein's function using neural networks. A webservice is currently provided by the Rostlab (https://rostlab.org/services/snap/ and https://rostlab.org/services/snap2web/).
The development by Maximilian Hecht started in November 2011.
Perl is used as development language.

## License

The software is licensed under a Academic Software License Agreement (https://rostlab.org/owiki/index.php/Academic_Software_License_Agreement).

## Dependencies

### Software 
* blast2
* libai-fann-perl
* libfile-chdir-perl
* librg-utils-perl
* predictprotein
* reprof
* run-psic
* sift

### Databases
* CBlast80
* dbSwiss
* SwissBlast
* swiss_dat

## HOWTO Install
Installation routine according to https://rostlab.org/owiki/index.php/Debian_repository

* sudo apt-get install python-software-properties
* sudo apt-add-repository "deb http://rostlab.org/debian/ stable main contrib non-free"
* sudo apt-get update (ignore GPG error)
* sudo apt-get install rostlab-debian-keyring (without verification)
* sudo apt-get update
* sudo apt-get install <PACKAGE> where <PACKAGE> is the package you want to install (e.g. 'profphd')

### Debian Wheezy (7)

* sudo apt-get install python-software-properties
* sudo apt-add-repository "deb http://rostlab.org/debian/ stable main contrib non-free"
* sudo apt-get update
* sudo apt-get install rostlab-debian-keyring
* sudo apt-get update
* sudo apt-get install snap2

leads to missing dependency error
```
The following packages have unmet dependencies:
 snap2 : Depends: sift (>= 4.0.3b)
```

tried several workarounds, e.g:
* download from http://sift.jcvi.org/www/www/sift4.0.3b.tar.gz
* untar package with `tar -zxvf sift4.0.3b.tar.gz -C $sift` where `$sift` is an empty directory
* move the linux executables to the correct location `mv $sift/bin/linux/* $sift/bin/`
* csh missing -> install csh `sudo apt-get install csh`
all failed

### Ubuntu Precise (12.4)
Installation routine
* sudo apt-get update
* sudo apt-get install python-software-properties
* sudo apt-add-repository "deb http://rostlab.org/debian/ stable main contrib non-free"
* sudo apt-get update
* sudo apt-get install rostlab-debian-keyring
* sudo apt-get update
* sudo apt-get install snap2

leads to output
```
Reading package lists... Done
Building dependency tree
Reading state information... Done
Some packages could not be installed. This may mean that you have
requested an impossible situation or if you are using the unstable
distribution that some required packages have not yet been created
or been moved out of Incoming.
The following information may help to resolve the situation:

The following packages have unmet dependencies:
 snap2 : Depends: predictprotein but it is not going to be installed
         Depends: reprof but it is not installable
         Depends: sift (>= 4.0.3b) but it is not installable
E: Unable to correct problems, you have held broken packages.
```

Installing dependency packages also fails with the same error, fetching their source code (`sudo apt-get source reprof`) works in some cases, but does not improve anything (of course (just have been interested in)).

### Debian Squeeze (6)
Installation routine
* sudo apt-get update
* sudo apt-get install python-software-properties -> useless see below
* sudo apt-get install --fix-missing python-software-properties -> because of smaller errors
* sudo apt-add-repository "deb http://rostlab.org/debian/ stable main contrib non-free" -> apt-add-repo not known
* sudo echo "deb http://rostlab.org/debian/ stable main contrib non-free\ndeb http://rostlab.org/debian/ stable main contrib non-free" >> /etc/apt/sources.list
* sudo apt-get update
* sudo apt-get install rostlab-debian-keyring
* sudo apt-get update
* sudo apt-get install snap2

leads to 
```
Reading package lists... Done
Building dependency tree
Reading state information... Done
Some packages could not be installed. This may mean that you have
requested an impossible situation or if you are using the unstable
distribution that some required packages have not yet been created
or been moved out of Incoming.
The following information may help to resolve the situation:

The following packages have unmet dependencies:
 snap2 : Depends: libai-fann-perl but it is not installable
         Depends: predictprotein but it is not going to be installed
         Depends: reprof but it is not installable
         Depends: sift (>= 4.0.3b) but it is not installable
         Recommends: pp-popularity-contest but it is not installable
E: Broken packages
```

### Debian Wheezy (7) try 2

install essentials and add rostlab repository
* cd ~
* sudo apt-get update
* sudo apt-get install csh vim wget build-essential devscripts debhelper python-software-properties
* sudo apt-add-repository "deb http://rostlab.org/debian/ stable main contrib non-free"
* sudo apt-get update
* sudo apt-get install rostlab-debian-keyring
* sudo apt-get update

install blimps the hard way
* wget https://launchpad.net/debian/+archive/primary/+files/blimps_3.9-1.dsc
* wget https://launchpad.net/debian/+archive/primary/+files/blimps_3.9.orig.tar.gz
* wget https://launchpad.net/debian/+archive/primary/+files/blimps_3.9-1.debian.tar.gz
* tar xzvf blimps_3.9.orig.tar.gz
* tar xzvf blimps_3.9-1.debian.tar.gz
* mv debian blimps-3.9/
* mv blimps_3.9-1.dsc  blimps-3.9/
* cd blimps-3.9
* debuild -us -uc
* dpkg-source --commit
* -> add dsc -> ctrl+o -> return -> ctrl+x
* debuild -us -uc
* cd ..
* sudo dpkg -i \*blimps\*.deb

install sift the hard way
* wget http://rostlab.org/debian/pool/non-free/s/sift/sift_4.0.3b-4.debian.tar.gz
* wget http://rostlab.org/debian/pool/non-free/s/sift/sift_4.0.3b-4.dsc
* wget http://rostlab.org/debian/pool/non-free/s/sift/sift_4.0.3b.orig.tar.gz
* tar xzvf sift_4.0.3b.orig.tar.gz
* mv sift_4.0.3b-4.dsc sift4.0.3b/
* tar xzvf sift_4.0.3b-4.debian.tar.gz
* mv debian sift4.0.3b/
* cd sift4.0.3b/
* dpkg-source --commit
* -> add dsc -> ctrl+o -> return -> ctrl+x
* debuild -us -uc
* cd ..
* sudo dpkg -i sift*.deb

install snap2 via aptitude
* sudo apt-get install snap2

## HOWTO get databases

## HOWTO configure and run the tool

## HOWTO Use the webservice

The service can be accessed via https://rostlab.org/services/snap/ and https://rostlab.org/services/snap2web/.
(Exactly) One protein sequence in the Fasta format can be pasted into the textfield. Upon submission via `Run Prediction`, a popup shows up, presenting an adress, which leads to the result page, once the calculations are done.

The Results page shows a heatmap with the input sequence along the x-axis and all 20 possible amino acid exchanges at every position along the y-axis. Below the heatmap, the color code for the heatmap is presented. Red indicates an effect of the respective amino acid exchange, wheras blue predicts the exchange to be neutral with respect to the proteins function.

A sliding window enables the user to zoom into the heatmap. The zoom area is shown below the interpretation scale. Further down, a table presents all possible amiono acid exchanges at every position with the exact numerical scores and estimated accuracy.

For detailed informations about the method, its results and interpretations, refer to the method description below.

## HOWTO Run, Basics

* Input: Fasta Protein Sequence
* Output: Prediction Score between -100 (neutral) and 100 (effect) for every possible SNP at every position
* Expected Results
* ...

## Method Description

### Author
Maximilian Hecht

### Description

* feature calculation (using predict protein pipeline)
* neural network with 650 input, 100 hidden and 2 output nodes
* all 10 models from 10-fold cross validation used to calculate results
* 10 results averaged in jury decision


### Training / Test data

* 100000 variants from OMIM, PMD and enzyme.expasy.org

### ...

### Publications and other Resources
* Hecht, M., Bromberg, Y., & Rost, B. (2015). Better prediction of functional effects for sequence variants. BMC Genomics, 16(Suppl 8), S1 [PubMed](http://www.ncbi.nlm.nih.gov/pubmed/26110438)
* Bromberg Y & Rost B. (2007). SNAP: predict effect of non-synonymous polymorphisms on function. Nucleic Acids Research, Vol. 35, No. 11 3823-3835 [PubMed](http://www.ncbi.nlm.nih.gov/pubmed/17526529) [Full PDF](http://rostlab.org/~hecht/snap.pdf)
* Hecht, M., Bromberg, Y., & Rost, B. (2013). News from the protein mutability landscape. Journal of molecular biology, 425(21), 3937-3948 [PubMed](http://www.ncbi.nlm.nih.gov/pubmed/23896297) [Full PDF](http://rostlab.org/~snap2web/snap2landscape.pdf)
* SNAP2 Wiki by Rostlab.org (https://rostlab.org/owiki/index.php/Snap2)

## Evaluation

## 'git svn clone' HOWTO

The software was initially developed, using svn as versioning tool. In scope of the exercises of the course Protein Prediction II for Computer Scientists in October 2015, the svn repository was moved to github, checked for updates and inconsistencies and its documentation updated. In the following, all necessary steps to clone the svn repository to github are documented.

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

## Testing on various platforms using VM

### Requirements (tested on Mac OS X 10.10.)
* Vagrant (tested with 1.7.4)
* VirtualBox ~~(tested with 4.3.2)~~ (not running with 4.3.2, tested with 5.0.8)
* local git repository directory called `$gitlocal` (so that the vagrant machines can be shared with co-developers)

### Procedure
* enforce requirements
* move to local git root `cd $gitlocal`
* initialize vagrant
  * `vagrant init`
  * a `Vagrantfile` is initialized
* download the virtual machine image you want to use
  * https://atlas.hashicorp.com/ provides a great number of machines
  * the machines listed in the table below were tested
  * use `vagrant box add $image`, whereas `$image` is of the format `debian/wheezy64`
  * you will be asked for the provider of your choice. select yours (tested with virtualBox)
  * this may take a while ...
* setup the downloaded box as box to be used by the provider on startup, by editing `Vagrantfile` s.t. it contains
```
Vagrant.configure("2") do |config|
  config.vm.box = "debian/wheezy64"
end
```
* run the machine with `vagrant up`
* the content of the folder, vagrant was initialized in will be provided on the VM under `/vagrant`


### Virtual Machines

The following machines were tested with Vagrant and VirtualBox on MacOS X 10.10.
Installation and execution of SNAp2 was successfully tested on these machines.
For detailed installation and execution procedures, please refer to *HOWTO Install* and *HOWTO Run*.

| OS | Version | 32/64 bit | hashicorp name |
|----|---------|-----------|----------------|
|Debian|7 "wheezy"|64|debian/wheezy64|
|||||


## Old README from Maximilian Hecht

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

