#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

my $module = 'Test::GreaterVersion';

use_ok($module) or exit;
can_ok( $module, '_get_version_from_lib' );

# look in the test directory
no warnings 'once';
$Test::GreaterVersion::libdir = 't/lib';
use warnings 'once';

# file doesn't exist
{
	my $expected = undef;
	my $got      =
	  Test::GreaterVersion::_get_version_from_lib('A::IDontExist'); 
	is( $got, $expected, 'file doesn\'t exist' );
}

# doesn't have version
{
	my $expected = 'undef';    # this is MakeMakers idea
	my $got = Test::GreaterVersion::_get_version_from_lib('A::NoVersion');
	is( $got, $expected, 'no version' );
}

# has version
{
	my $expected = 1.234;
	my $got      = Test::GreaterVersion::_get_version_from_lib('A::Version');
	is( $got, $expected, 'has version' );
}

=head2 AUTOR

Gregor Goldbach <glauschwuffel@nomaden.org>

=cut

