# SNAP2

SNAP2 is a method that predicts the effects of single amino acid substitutions in a protein on the protein's function using neural networks. A webservice is currently provided by the Rostlab (https://rostlab.org/services/snap/ and https://rostlab.org/services/snap2web/).
The implementation started in November 2011 by Maximilian Hecht. Perl is the programming language.

## License

The software is licensed under an [Academic Software License Agreement](https://rostlab.org/owiki/index.php/Academic_Software_License_Agreement).

## HOWTO Install

The recommended and tested environment is **Debian Wheezy (7)**. See [the wiki](https://github.com/Rostlab/SNAP2/wiki/Installation-and-Environments) for instructions on other environments and more details about the installation process and dependencies.

Install essentials and add rostlab repository:

```
cd ~
sudo apt-get update
sudo apt-get install csh vim wget build-essential devscripts debhelper devscripts python-software-properties
sudo apt-add-repository "deb http://rostlab.org/debian/ stable main contrib non-free"
sudo apt-get update
sudo apt-get install rostlab-debian-keyring
sudo apt-get update
```

Install blimps the hard way:

```shell
wget https://launchpad.net/debian/+archive/primary/+files/blimps_3.9-1.dsc
wget https://launchpad.net/debian/+archive/primary/+files/blimps_3.9.orig.tar.gz
wget https://launchpad.net/debian/+archive/primary/+files/blimps_3.9-1.debian.tar.gz
tar xzvf blimps_3.9.orig.tar.gz
tar xzvf blimps_3.9-1.debian.tar.gz
mv debian blimps-3.9/
mv blimps_3.9-1.dsc  blimps-3.9/
cd blimps-3.9
dpkg-source --commit
# -> add a patch name -> ctrl+o -> return -> ctrl+x
debuild -us -uc
cd ..
sudo dpkg -i \*blimps\*.deb
```

Install sift the hard way:

```shell
wget http://rostlab.org/debian/pool/non-free/s/sift/sift_4.0.3b-4.debian.tar.gz
wget http://rostlab.org/debian/pool/non-free/s/sift/sift_4.0.3b-4.dsc
wget http://rostlab.org/debian/pool/non-free/s/sift/sift_4.0.3b.orig.tar.gz
tar xzvf sift_4.0.3b.orig.tar.gz
mv sift_4.0.3b-4.dsc sift4.0.3b/
tar xzvf sift_4.0.3b-4.debian.tar.gz
mv debian sift4.0.3b/
cd sift4.0.3b/
dpkg-source --commit
# -> add a patch name -> ctrl+o -> return -> ctrl+x
debuild -us -uc
cd ..
sudo dpkg -i sift*.deb
```

Install snap2 via aptitude:

```shell
sudo apt-get install snap2
```


## HOWTO get and configure databases

Complete these steps after installing SNAP2 (on your VM). Ensure that there is enough space on your (virtual) machine. Depending on the type of database you want to use, you will need up to 110 GB disk space. If you initialized a vagrant box with default settings, you might want to use an external hard drive and forward it to the virtual machine. On the tested System (Mac OS X 10.10 and debain/wheezy64 in box), USB port forwarding was disabled and not possible to be used. To use the hard drive as shared folder, configure the virtualmachine in `Vagrantfile` (on your local machine) as follows, whereas `$host_folder_path` and `$guest_folder_path` are the folders on the local and virtual system, respectively:

```
Vagrant.configure(2) do |config|
	config.vm.synced_folder "$host_folder_path", "$guest_folder_path"
end
```

Then download and unzip the single databases to the folder of your choice on your local machine (`cd $host_folder_path`):

swiss_dat
```
wget ftp://ftp.uniprot.org/pub/databases/uniprot/knowledgebase/uniprot_sprot.dat.gz
gunzip uniprot_sprot.dat.gz
```

uniref100, uniref90, swissprot
```
wget ftp://ftp.uniprot.org/pub/databases/uniprot/uniref/uniref100/uniref100.fasta.gz
gunzip uniref100.fasta.gz
wget ftp://ftp.uniprot.org/pub/databases/uniprot/uniref/uniref90/uniref90.fasta.gz
gunzip uniref90.fasta.gz
wget ftp://ftp.uniprot.org/pub/databases/uniprot/knowledgebase/uniprot_sprot.fasta.gz
gunzip uniprot_sprot.fasta.gz
```

generate db_swiss:
```
/usr/share/librg-utils-perl/dbSwiss --datadir ./ --infile ./uniprot_sprot.dat --table dbswiss
```

format fasta databases for use with blast on the virtual machine if used (`formatdb`was already installed as a dependency of SNAP2)
```
formatdb -i uniref100.fasta
formatdb -i uniref90.fasta
formatdb -i uniprot_sprot.fasta
```

## HOWTO configure the tool
There is a config file, containing all necessary data in `/usr/share/snap2/snap2rc.default`. Copy that file to your homefolder and change its contents to adjust the settings.

```
cp /usr/share/snap2/snap2rc.default ~/.snap2rc
vim ~/.snap2rc
```

Most default settings are ok, but check the last paragraphs. They should state the locations of the recently downloaded databases. Edit the file to your needs, e.g.


## HOWTO run the tool


## HOWTO Use the webservice

The service can be accessed via https://rostlab.org/services/snap/ and https://rostlab.org/services/snap2web/.
(Exactly) One protein sequence in the Fasta format can be pasted into the textfield. Upon submission via `Run Prediction`, a popup shows up, presenting an adress, which leads to the result page, once the calculations are done.

The result page shows a heatmap with the input sequence along the x-axis and all 20 possible amino acid exchanges along the y-axis. Below the heatmap, the color code for the heatmap is presented. Red indicates an effect of the respective amino acid exchange, whereas blue predicts the exchange to be neutral with respect to the proteins function.

A sliding window enables the user to zoom into the heatmap. The zoom area is shown below the interpretation scale. Further down, a table presents all possible amiono acid exchanges at every position with the exact numerical scores and estimated accuracy.

For detailed information about the method, its results, and interpretations, refer to the method description below.

## HOWTO Run, Basics

* Input: Fasta Protein Sequence
* Output: Prediction Score between -100 (neutral) and 100 (effect) for every possible SNP at every position
* Expected Results
* ...

## Method Description

* Author: Maximilian Hecht
* Description
  * feature calculation (using predict protein pipeline)
  * neural network with 650 input, 100 hidden and 2 output nodes
  * all 10 models from 10-fold cross validation used to calculate results
  * 10 results averaged in jury decision


### Training / Test data

* 100000 variants from OMIM, PMD and enzyme.expasy.org


### Publications and other Resources
* Hecht, M., Bromberg, Y., & Rost, B. (2015). Better prediction of functional effects for sequence variants. BMC Genomics, 16(Suppl 8), S1 [PubMed](http://www.ncbi.nlm.nih.gov/pubmed/26110438)
* Bromberg Y & Rost B. (2007). SNAP: predict effect of non-synonymous polymorphisms on function. Nucleic Acids Research, Vol. 35, No. 11 3823-3835 [PubMed](http://www.ncbi.nlm.nih.gov/pubmed/17526529) [Full PDF](http://rostlab.org/~hecht/snap.pdf)
* Hecht, M., Bromberg, Y., & Rost, B. (2013). News from the protein mutability landscape. Journal of molecular biology, 425(21), 3937-3948 [PubMed](http://www.ncbi.nlm.nih.gov/pubmed/23896297) [Full PDF](http://rostlab.org/~snap2web/snap2landscape.pdf)
* SNAP2 Wiki by Rostlab.org (https://rostlab.org/owiki/index.php/Snap2)

### Evaluation

**TODO missing**


## Testing on various platforms using VM

### Requirements (tested on Mac OS X 10.10.)

* Vagrant (tested with 1.7.4)
* VirtualBox ~~(tested with 4.3.2)~~ (not running with 4.3.2, tested with 5.0.8)
* local git repository directory called `$gitlocal` (so that the vagrant machines can be shared with co-developers)

### Procedure

* enforce requirements
* move to local git root `cd $gitlocal`
* create a `.gitignore` file if it does not exist already
* put the folder `.vagrant` in the `.gitignore` file to allow the usage by different users
* initialize vagrant
  * `vagrant init`
  * a `Vagrantfile` is initialized
  * a folder `.vagrant` is initialized:
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
