use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/XS/Check.pm';
my $pod = 'lib/XS/Check.pod';
my $github = 'github.com/benkasminbullock/xs-check';
my $repo = "https://$github";
WriteMakefile (
    NAME => 'XS::Check',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
	'Text::LineNumber' => '0.02',
	'C::Tokenize' => '0.14',
	'File::Slurper' => '0.009',
	'Carp' => '0',
    },
    META_MERGE => {
	'meta-spec' => {
	    version => 2,
	},
        resources => {
            repository => {
		type => 'git',
		url => "git://$github.git",
		web => $repo,
	    },
            bugtracker => {
		web => "$repo/issues",
	    },
#	    homepage => 'http://',
        },
    },
    MIN_PERL_VERSION => '5.006001',
    EXE_FILES => ['./script/checkxs',],
);
