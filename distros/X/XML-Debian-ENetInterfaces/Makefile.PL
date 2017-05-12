use strict;
use warnings;
# no 5.13.11;
use ExtUtils::MakeMaker;

my $EUMMV = $ExtUtils::MakeMaker::VERSION;
$EUMMV =~ s/_//g;
WriteMakefile(
    NAME                => 'XML::Debian::ENetInterfaces',
    AUTHOR              => q{Michael Mestnik <cheako+cpan@mikemestnik.net>},
    VERSION_FROM        => 'lib/XML/Debian/ENetInterfaces.pm',
    ABSTRACT_FROM       => 'lib/XML/Debian/ENetInterfaces.pm',
    ($EUMMV >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    MIN_PERL_VERSION	=> '5.10.0',
    PREREQ_PM => {
        'Test::More' => 0,
        'XML::LibXML' => 0,		# For generating XML.
        'XML::Parser::PerlSAX' => 0,	# For parsing XML.
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'XML-Debian-ENetInterfaces-*' },
);
