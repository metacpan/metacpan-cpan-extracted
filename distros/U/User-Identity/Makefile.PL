#!/usr/bin/env perl

use 5.016;

use ExtUtils::MakeMaker;

# Use command 'oodist' to produce your whole software release.
my $version = '1.03';
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

	generate => [
	  {
		# Add real pod to the releases
		format         => 'pod3',
		podtail        => undef,
	  },
 	  # You may add HTML formatters here.
 		  # You may add exporter configurations here.
	],
);

# The following is needed, because User::Identity does gracefully handle
# a missing Geography::Countries, but is incompatible with older releases.
my %prereq =
(   'Hash::Ordered' => 0.014,
);

my ($gc, $gc_version) = ('Geography::Countries' => 2009041301);
eval "require $gc";

if($@ =~ m/^Can't locate/)
{   # Not installed, but it is optional...
}
elsif($@)
{   # Other error message
    warn "Found problems compiling $gc:\n$@";
    $prereq{$gc} = $gc_version;
}
elsif($gc->VERSION < $gc_version)
{   warn "$gc is too old (",$gc->VERSION,"), and needs to be reinstalled\n";
    $prereq{$gc} = $gc_version;
}

WriteMakefile
	NAME       => 'User::Identity',
	VERSION    => $version,
	PREREQ_PM  => \%prereq,
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
			homepage => $homepage,
			license  => [ 'http//dev.perl.org/licenses/' ],
		},
		prereqs => {
			develop => {
				requires => {
					'OODoc' => '3.00',
				}
			},
			test => {
				requires => {
					'Test::More' => 1.00,
					'Test::Pod'  => 1.00,
				}
			},
		},

		# You may use multiple set-ups, see "oodist --make"
		x_oodist => \%oodist,
	};
