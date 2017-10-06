use 5.013002;
use strict;
use ExtUtils::MakeMaker;
use warnings FATAL => 'all';
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Unicode::Peek',
    AUTHOR            => q{Athanasios Garyfalos <garyfalos@cpan.org>},
    VERSION_FROM      => 'lib/Unicode/Peek.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    MIN_PERL_VERSION  => "5.013002",
    VERSION_FROM      => 'lib/Unicode/Peek.pm', # retrieve version from module
    ABSTRACT_FROM     => 'lib/Unicode/Peek.pm', # retrieve abstract from module
    PREREQ_PM => {
        # your module's runtime dependencies
    },
    TEST_REQUIRES => {
        'Test::Fatal' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Unicode-Peek-*' },
    META_MERGE => {
        'meta-spec' => { version => 8 },
	    resources => {
		repository => {
		    type => 'git',
		    url  => 'git@github.com:thanos1983/Perl5-Unicode-Peek.git',
		    web  => 'https://github.com/thanos1983/Perl5-Unicode-Peek',
		},
	},
    },
);
