#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

my $module = 'Test::GreaterVersion';

use_ok($module) or exit;
can_ok( $module, '_get_installed_version' );

# module doesn't exist
{
	my $expected = undef;
	my $got      =
	  Test::GreaterVersion::_get_installed_version('A::IDontExist'); 
	is( $got, $expected, 'module doesn\'t exist' );
}

# look in the test directory
no warnings 'once';
use Cwd;
my $cwd=getcwd();
use File::Spec;
my $dir=File::Spec->catfile($cwd, 't', 'lib');
push @INC, $dir;
use warnings 'once';

# doesn't have version
{
	my $expected = 'undef';    # this is MakeMakers idea
	my $got = Test::GreaterVersion::_get_installed_version('A::NoVersion');
	is( $got, $expected, 'no version' );
}

# has version
{
	my $expected = 1.234;
	my $got      = Test::GreaterVersion::_get_installed_version('A::Version');
	is( $got, $expected, 'has version' );
}

=head2 AUTOR

Gregor Goldbach <glauschwuffel@nomaden.org>

=cut

