use strict;
use warnings;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME                => 'WebFetch',
    AUTHOR              => 'Ian Kluft <ikluft@cpan.org>',
    VERSION_FROM        => 'lib/WebFetch.pm',
    ABSTRACT_FROM       => 'lib/WebFetch.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    	'LWP::UserAgent' => 0,
    	'HTTP::Request' => 0,
	'Locale::Country' => 0,
	'Date::Calc' => 0,
	'Data::Dumper' => 0,
	'HTML::LinkExtor' => 0,
	'XML::Parser' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebFetch-*' },
);
