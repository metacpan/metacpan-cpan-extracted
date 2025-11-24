#!/usr/bin/env perl

use 5.016;

use ExtUtils::MakeMaker;

# Use command 'oodist' to produce your whole software release.
my $version = '3.00';
my $git      = "https://github.com/markov2/perl5-User-Identity";
my $publish  = "../public_html/user-identity";
my $homepage = "http://perl.overmeer.net/CPAN/";

my %oodist   = (
	oodoc_version => 3.05,
	first_year => 2003,
	email    => "markov\@cpan.org",

	include  => [
	],

	use      => [
	],

	parser   => {
		syntax         => 'markov',
		skip_links     => [
			'AddressBook',
		],
		pmhead         => undef,
	},

	tests    => {
	},

	release  => {
		publish        => "$publish/source",
	},

	raw      => {
		publish        => "$publish/raw",
	},

	generate => [ {
		format         => 'pod3',
		podtail        => undef,
	}, ],
);

my %prereq = (
	'Hash::Ordered' => 0.014,
);

my %optional = (
	'Geography::Countries' => 2009041301,
);

WriteMakefile
	NAME       => 'User::Identity',
	VERSION    => $version,
	ABSTRACT   => 'Collect information about a user',
	AUTHOR     => 'Mark Overmeer <markov@cpan.org>',
	LICENSE    => 'perl_5',

	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources   => {
			repository => {
				type => 'git',
				url  => "$git.git",
				web  => $git,
			},
			bugtracker => {
				web  => "$git/issues",
			},
			homepage => $homepage,
			license  => [ 'http//dev.perl.org/licenses/' ],
		},
		prereqs => {
			runtime => {
				requires => \%prereq,
			},
			develop => {
				requires => {
					'OODoc' => '3.00',
				},
			},
			test => {
				requires => {
					'Test::More' => 1.00,
					'Test::Pod'  => 1.00,
				},
			},
		},

		# You may use multiple set-ups, see "oodist --make"
		x_oodist => \%oodist,
	};
