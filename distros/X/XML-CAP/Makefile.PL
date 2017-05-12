use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'XML::CAP',
    AUTHOR              => 'Ian Kluft <ikluft@cpan.org>',
    VERSION_FROM        => 'lib/XML/CAP.pm',
    ABSTRACT_FROM       => 'lib/XML/CAP.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
	'XML::LibXML' => 1.54,
	'Exception::Class' => 0,
        'Encode' => 0,
        'Exporter' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'XML-CAP-*' },
);
