use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService::Instagram',
    AUTHOR              => q{Daya Sagar Nune <dayanune@cpan.org>},
    VERSION_FROM        => 'lib/WebService/Instagram.pm',
    ABSTRACT_FROM       => 'lib/WebService/Instagram.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'JSON'	     => 0,
	'LWP::UserAgent' => 0,
	'URI'	     => 0,
	'Carp' 	     => 0,
	'Data::Dumper' => 0,
	'HTTP::Request' => 0,
	 'Safe::Isa'     => 1.000005,
	'strict' 	=> 0,
	'warnings'	=> 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebService-Instagram-*' },
    META_MERGE => {
        resources  => {
            homepage => 'https://github.com/odem5442/WebService-Instagram',
            repository => 'git://github.com/odem5442/WebService-Instagram.git',
        }
    },
);
