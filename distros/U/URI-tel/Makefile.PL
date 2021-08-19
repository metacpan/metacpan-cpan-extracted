use ExtUtils::MakeMaker;
use strict;
use warnings;

# Call 'perldoc ExtUtils::MakeMaker' for details of how to influence
# the contents of the Makefile that is written.

my %WriteMakefileArgs = (
    NAME                => 'URI::tel',
    VERSION_FROM        => 'lib/URI/tel.pm',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    ABSTRACT            => 'Implementation of rfc3966 for tel URI',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
    	'overload'		=> 0,
    	'overloading'	=> 0,
    	'parent'		=> 0,
    	'strict'		=> 0,
        'URI' 			=> 0
    },
    TEST_REQUIRES =>
    {
        'Test::More' 	=> 0,
    },
    LICENSE				=> 'perl_5',
    MIN_PERL_VERSION	=> 5.6.0,
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@git.deguest.jp:jack/URI-tel.git',
                web         => 'https://git.deguest.jp/jack/URI-tel',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://git.deguest.jp/jack/URI-tel/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);
