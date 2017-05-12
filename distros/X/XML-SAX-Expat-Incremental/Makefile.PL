#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'XML::SAX::Expat::Incremental',
	VERSION_FROM  => 'lib/XML/SAX/Expat/Incremental.pm',
	(eval { ExtUtils::MakeMaker->VERSION("6.18") } ? (SIGN          => 1) : ()),
    AUTHOR        => 'Yuval Kogman',
    ABSTRACT      => 'Incremental/non-blocking SAX Driver for Expat',
    PREREQ_PM     => {
                        "XML::SAX::Expat" => '0', # which implies
						"XML::Parser"     => '0',
						"Test::Exception" => '0',
						"Test::More"      => '0',
                     },
);

__END__
# according to: https://rt.cpan.org/Ticket/Display.html?id=13764 this is broken

## add ourselves to the list of installed parsers
sub MY::install {
    package MY;
    my $script = shift->SUPER::install(@_);
    $script =~ s/install :: (.*)$/install :: $1 install_sax_expat_inc/m;
    $script .= <<"INSTALL";

install_sax_expat_inc :
\t\@\$(PERL) -MXML::SAX -e "XML::SAX->add_parser(q(XML::SAX::Expat::Incremental))->save_parsers()"

INSTALL

    return $script;
}

