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

