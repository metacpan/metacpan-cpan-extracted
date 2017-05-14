
package Uplug::SV;


=head1 NAME

Uplug::SV - Uplug Language pack for Swedish

=head1 SYNOPSIS

 # prepare some data
 uplug pre/markup -in input.txt | uplug pre/sent -l sv > sentences.xml
 uplug pre/sv/basic -in input.txt -out tokenized.xml

 # tag tokenized text in XML
 uplug pre/sv/tagHunPos -in tokenized.xml -out tagged.xml

 # parse a tagged corpus using the MaltParser
 uplug pre/sv/malt -in tagged -out parsed.xml

 # run the entire pipeline
 uplug pre/sv-all -in input.txt -out output.xml

=head1 DESCRIPTION

Note that you need to install the main components of L<Uplug> first. Download the latest version of uplug-main from L<https://bitbucket.org/tiedemann/uplug> or from CPAN and install it on your system.

The Uplug::SV package includes configuration files for running annotation tools for Swedish. To install configuration files and models, simply run:

 perl Makefile.PL
 make
 make install

=head1 SEE ALSO

Project website: L<https://bitbucket.org/tiedemann/uplug>

CPAN: L<http://search.cpan.org/~tiedemann/uplug-main/>

=cut

1;
