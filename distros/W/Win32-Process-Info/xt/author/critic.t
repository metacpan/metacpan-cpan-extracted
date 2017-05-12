package main;

use strict;
use warnings;

use File::Spec;
use Test::More 0.88;

BEGIN {
    eval {
	require Test::Perl::Critic;
	Test::Perl::Critic->import(
	    -profile => File::Spec->catfile(qw{xt author perlcriticrc})
	);
	1;
    } or do {
	plan skip_all => 'Test::Perl::Critic required to criticize code.';
	exit;
    };
}

plan (tests => 3);
critic_ok(File::Spec->catfile(qw{lib Win32 Process Info.pm}));
critic_ok(File::Spec->catfile(qw{lib Win32 Process Info NT.pm}));
critic_ok(File::Spec->catfile(qw{lib Win32 Process Info PT.pm}));

# Can't do the following until NT.pm and WMI.pm are brought into compliance
# all_critic_ok('lib');
# all_critic_ok();

1;
