use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/WWW/LinkRot.pm';
my $pod = 'lib/WWW/LinkRot.pod';
my $github = 'github.com/benkasminbullock/www-linkrot';
my $repo = "https://$github";
WriteMakefile (
    NAME => 'WWW::LinkRot',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
	'LWP::UserAgent' => '6.53',
	'HTML::Make' => '0.05',
	'HTML::Make::Page' => '0.01',
	'File::Slurper' => '0.012',
	'JSON::Create' => '0.32',
	'JSON::Parse' => '0.61',
	'Convert::Moji' => '0.10',
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
