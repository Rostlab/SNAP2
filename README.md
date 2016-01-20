# SNAP2

SNAP2 is a method that predicts the effects of single amino acid substitutions in a protein on the protein's function using neural networks. A webservice is currently provided by the Rostlab (https://rostlab.org/services/snap/ and https://rostlab.org/services/snap2web/).
The implementation started in November 2011 by Maximilian Hecht. Perl is the programming language.

## License

The software is licensed under an [Academic Software License Agreement](https://rostlab.org/owiki/index.php/Academic_Software_License_Agreement).

## HOWTO Install

The recommended and tested environment is **Debian Wheezy (7)**. See [the wiki](https://github.com/Rostlab/SNAP2/wiki/Installation-and-Environments) for instructions on other environments and more details about the installation process and dependencies. Furthermore, see [these wiki page](https://github.com/Rostlab/SNAP2/wiki/Testing-on-various-platforms-using-VM) for on instructions on how to set up a virtual machine if needed.

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


### HOWTO get and configure databases

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

### HOWTO configure the tool

There is a config file, containing all necessary data in `/usr/share/snap2/snap2rc.default`. Copy that file to your homefolder and change its contents to adjust the settings.

```
cp /usr/share/snap2/snap2rc.default ~/.snap2rc
vim ~/.snap2rc
```

Most default settings are ok, but check the last paragraphs. They should state the locations of the recently downloaded databases. Edit the file to your needs, e.g.

`TODO` example?


## HOWTO Run


### HOWTO Use the Web Service

The service can be accessed via https://rostlab.org/services/snap/ and https://rostlab.org/services/snap2web/.
(Exactly) One protein sequence in the Fasta format can be pasted into the textfield. Upon submission via `Run Prediction`, a popup shows up, presenting an adress, which leads to the result page, once the calculations are done.

The result page shows a heatmap with the input sequence along the x-axis and all 20 possible amino acid exchanges along the y-axis. Below the heatmap, the color code for the heatmap is presented. Red indicates an effect of the respective amino acid exchange, whereas blue predicts the exchange to be neutral with respect to the proteins function.

A sliding window enables the user to zoom into the heatmap. The zoom area is shown below the interpretation scale. Further down, a table presents all possible amiono acid exchanges at every position with the exact numerical scores and estimated accuracy.

For detailed information about the method, its results, and interpretations, refer to the method description below.

### HOWTO Use the CLI Tool

* Input: Fasta Protein Sequence
* Output: Prediction Score between -100 (neutral) and 100 (effect) for every possible SNP at every position
* Expected Results `TODO`
* ...

`TODO` missing more information and a full example for how to run the cli tool


## Method Description

* Author: Maximilian Hecht
* Description
  * feature calculation (using predict protein pipeline)
  * neural network with 650 input, 100 hidden and 2 output nodes
  * all 10 models from 10-fold cross validation used to calculate the results
  * 10 results averaged in jury decision


### Training / Test data

About 100,000 variants from the Protein Mutant Database (PMD), SwissProt, OMIM and HumVar are used for testing and training of SNAP2. The variants are either classified as 'neutral' or 'effect'.

If a variant is annotated with 'no change' in PMD, the variant is classified as neutral. If there is any change in its function independent of in- or decrease, it is classified as effect. The function of enzymes that are listed in SwissProt is descibed by the Enzyme Commission (EC) number. If two variants have the same EC number, they are classified as neutral. The databases OMIM and HumVar contain protein variants that are associated with diseases. Therefore, they provide variants with an effect.


### Publications and other Resources
* Hecht, M., Bromberg, Y., & Rost, B. (2015). Better prediction of functional effects for sequence variants. BMC Genomics, 16(Suppl 8), S1 [PubMed](http://www.ncbi.nlm.nih.gov/pubmed/26110438) [Full PDF](http://www.ncbi.nlm.nih.gov/pmc/articles/PMC4480835/pdf/1471-2164-16-S8-S1.pdf)
* Bromberg Y & Rost B. (2007). SNAP: predict effect of non-synonymous polymorphisms on function. Nucleic Acids Research, Vol. 35, No. 11 3823-3835 [PubMed](http://www.ncbi.nlm.nih.gov/pubmed/17526529) [Full PDF](http://rostlab.org/~hecht/snap.pdf)
* Hecht, M., Bromberg, Y., & Rost, B. (2013). News from the protein mutability landscape. Journal of molecular biology, 425(21), 3937-3948 [PubMed](http://www.ncbi.nlm.nih.gov/pubmed/23896297) [Full PDF](http://rostlab.org/~snap2web/snap2landscape.pdf)
* SNAP2 Wiki by Rostlab.org (https://rostlab.org/owiki/index.php/Snap2)

### Evaluation

SNAP2 was compared with the original version SNAP, SIFT, and PolyPhen-2

<img src="https://github.com/Rostlab/SNAP2/blob/develop/doc/ROC.png?raw=true" width="400"/>
