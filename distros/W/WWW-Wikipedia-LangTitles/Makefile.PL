use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/WWW/Wikipedia/LangTitles.pm';
my $pod = 'lib/WWW/Wikipedia/LangTitles.pod';
my $github = 'github.com/benkasminbullock/www-wikipedia-langtitles';
my $repo = "https://$github";
WriteMakefile (
    NAME => 'WWW::Wikipedia::LangTitles',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
	'Carp' => '0',
	'JSON::Parse' => '0.49',
	'LWP::UserAgent' => '6.15',
	'URI::Escape' => '1.71',
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
);
