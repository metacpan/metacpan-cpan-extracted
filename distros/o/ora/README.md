[![Build Status](https://travis-ci.org/pseudogene/ora.svg?branch=master)](https://travis-ci.org/pseudogene/ora)

# Bio::ORA

Olfactory Receptor family Assigner (ORA) [bioperl module].

## Description
Bio::ORA is a featherweight object for identifying mammalian olfactory receptor genes. The sequences should not be longer than 40kb. The returned array include location, sequence and statistic for the putative olfactory receptor gene. Fully functional with DNA and EST sequence, no intron supported.

##Associated publication

>**A cluster of olfactory receptor genes linked to frugivory in bats**
>
>Hayden S, Bekaert M, Goodbla A, Murphy WJ, Dávalos LM, Teeling EC.
>
>_Mol Biol Evol_. 2014 Apr;31(4):917-27. [doi: [10.1093/molbev/msu043](http://dx.doi.org/10.1093/molbev/msu043)].

##How to use this repository?

This repository host both the scripts and tools developed by this study. Feel free to adapt the scripts and tools, but remember to cite their authors!

To look at our scripts and raw results, **browse** through this repository. If you want to reproduce our results you will need to **clone** this repository, build the docker, and the run all the scripts. If you want to use our data for our own research, **fork** this repository and **cite** the authors.


##Requiements
To use this module you may need:

 *  [Bioperl](http://bioperl.org/) modules,
 *  [HMMER v3+](http://hmmer.org/) distribution and
 *  [FASTA 36+](ftp://ftp.ebi.ac.uk/pub/software/unix/fasta/) distribution.


## Installation

You can install the Bio::ORA module directly via [CPAN](http://search.cpan.org/~ceratites/ora/) or via [GitHub](https://github.com/pseudogene/ora):

#### CPAN (easiest way)

```
perl -MCPAN -e 'install Bio::ORA'
```


#### GitHub (most recent version)

```
git clone https://github.com/pseudogene/ora.git
cd ora
perl Makefile.pl
make
make test
sudo make install
```

## Usage

```
..:: Olfactory Receptor Assigner (ORA) ::..

Usage: or.pl [-options] --sequence=<sequence fasta file>

Options
 -a
    Force the use of alternative start codons, according to the current genetic code.
    Otherwise, ATG is the only initiation codon allow.
 --expect
    Set the E-value threshold. This setting specifies the statistical significance
    threshold for reporting matches against database sequences. [Default 1e-10].
 --format
    Available output format [Default fasta]:
      fasta (FASTA format)
      csv (Comma-separated values)
      genbank (GenBank format)
      tsv (Direct output for R)
      tbl (GenBank TBL format)
 -c
    When using a large number of contigs (e.g. newly sequenced genome), proceed to an
    initial FASTA search to identify the contigs where to run the actual ORA search.
 --filter
    Show ONLY the selected family number.
 --sub
    Extract the sequences of the Fasta hits.
 --name
    Overwrite the sequence name by the provided one. Otherwise the program will use the
    sequence name from as input.
 --table
    Force a genetic code to be used for the translation of the query. [Default 1]
 --size
    Filter fragments over the specified size as functional.
 -d
    Print all sequence details.

Advance options
 --resume
    Resume the search from given sequence name.
 --hmmfile
    Provide alternative HMM profiles.
    [Default /root/or.hmm]
 --fastafile
    Provide alternative reference OR sequences (fasta format).
    [Default /root/or.fasta]
 -v
    Print more possibly useful stuff, such as the individual scores for each sequence.
```


## Synopsis

Take a sequence object from, say, an inputstream, and find an Olfactory Receptor gene. HMM profiles are used in order to identify location, frame and orientation of such gene.

Creating the ORA object, _e.g._:

```
my $inputstream = Bio::SeqIO->new( -file => 'seqfile', -format => 'fasta' );
my $seqobj = $inputstream->next_seq();
my $ORA_obj = Bio::ORA->new( $seqobj );
```

Obtain an array holding the start point, the stop point, the DNA sequence and amino-acid sequence, _e.g._:

```
my $array_ref = $ORA_obj->{'_result'} if ( $ORA_obj->find() );
```

Display result in genbank format, _e.g._:

```
$ORA_obj->show( 'genbank' );
```

### Driver script

```
#!/usr/bin/perl
use strict;
use warnings;
use Bio::Seq;
use Bio::ORA;

my $inseq = Bio::SeqIO->new( '-file' => q{<} . $ARGV[0], -format => 'fasta' );
while (my $seq = $inseq->next_seq) {
  my $ORA_obj = Bio::ORA->new( $seq );
  if ( $ORA_obj->find() ) {
    $ORA_obj->show( 'genbank' );
  } else {
    print "  no hit!\n";
  }
}
```

###Local adaptations
This module uses three softwares. If HMMER or FASTA are updated make sure that HMMER's hmmscan and FASTA's tfastx36 and fastx36 still exists under same name. You change the call my editing the "Default softwares" section of `or.pm`.

```
# Default softwares
my $hmmscan = 'hmmscan';
my $tfastx = 'tfastx36';
my $fastx = 'fastx36';
```

Similarly, updates of HMMER may require to update the HMM indexes. Run `hmmpress`:

```
hmmpress -f /usr/local/bin/or.hmm
```

##Issues

If you have any problems with or questions about the scripts, please contact us through a [GitHub issue](https://github.com/pseudogene/ora/issues).
Any issue related to the scientific results themselves must be done directly with the authors.


## Contributing

You are invited to contribute new features, fixes, or updates, large or small; we are always thrilled to receive pull requests, and do our best to process them as fast as we can.


## License and distribution

This code is distributed under the GNU [GPLv3 license](http://www.gnu.org/licenses/gpl-3.0.html). The documentation, raw data and work are licensed under a [Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/).​

