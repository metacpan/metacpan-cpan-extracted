#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'XML::SAX::ExpatNB',
	VERSION_FROM  => 'lib/XML/SAX/ExpatNB.pm',
	SIGN          => 1,
    AUTHOR        => 'Yuval Kogman',
    ABSTRACT      => 'really non-blocking SAX Driver for Expat',
    PREREQ_PM     => {
                        "XML::SAX::Expat::Incremental" => '0',
						"Test::Exception" => '0',
						"Test::More"      => '0',
                     },
);


## add ourselves to the list of installed parsers
sub MY::install {
    package MY;
    my $script = shift->SUPER::install(@_);
    $script =~ s/install :: (.*)$/install :: $1 install_sax_expat_nb/m;
    $script .= <<"INSTALL";

install_sax_expat_nb :
\t\@\$(PERL) -MXML::SAX -e "XML::SAX->add_parser(q(XML::SAX::ExpatNB))->save_parsers()"

INSTALL

    return $script;
}

