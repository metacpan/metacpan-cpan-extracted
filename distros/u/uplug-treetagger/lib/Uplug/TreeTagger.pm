
package Uplug::TreeTagger;


=head1 NAME

Uplug::TreeTagger - Uplug add-on for using treetagger models for POS tagging

=head1 SYNOPSIS

 # prepare some data (for example, for English)
 uplug pre/markup   -in input.txt | uplug pre/sent -l en > sentences.xml
 uplug pre/en/basic -in input.txt -out tokenized.xml

 # tag text with marked sentence boundaries (using the TreeTagger tokenizer)
 uplug pre/en/toktag -in sentences.xml -out tagged.xml

 # tag a tokenized corpus
 uplug pre/en/tagTree -in tokenized.xml -out tagged.xml

 # run the entire pipeline (for English in this example)
 uplug pre/en/all-treetagger -in input.txt -out output.xml

=head1 DESCRIPTION

Note that you need to install the main components of L<Uplug> first. Download the latest version of uplug-main from L<https://bitbucket.org/tiedemann/uplug> or from CPAN and install it on your system.

The Uplug::TreeTagger package includes configuration files for running TreeTagger from Uplug. It doesn't add anything to the actual code. The installation of the TreeTagger and of relevant POS tagging modules is integrated in the installation routines. Simply run

 perl Makefile.PL
 make
 make install

to put binaries, model files and configurations into the global shared directory of Uplug. Note that downloading POS tagging models will take some time and that you need to agree with the terms and conditions of the TreeTagger (which will be printed on screen when running the first command).

Currently supported languages that have been integrated into Uplug are:
Bulgarian, German, English, Spanish, Estonian, French, Italian, Latin, Dutch, Swahili
(see share/systems/pre)

=head1 SEE ALSO

Project website: L<https://bitbucket.org/tiedemann/uplug>

CPAN: L<http://search.cpan.org/~tiedemann/uplug-main/>

=cut

1;
