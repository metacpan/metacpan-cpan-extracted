use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Unicode/Confuse.pm';
my $pod = 'lib/Unicode/Confuse.pod';
my $github = 'github.com/benkasminbullock/unicode-confuse';
my $repo = "https://$github";
WriteMakefile (
    NAME => 'Unicode::Confuse',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
	'File::Slurper' => '0.012',
	'JSON::Parse' => '0.61',
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
    MIN_PERL_VERSION => '5.010',
);
