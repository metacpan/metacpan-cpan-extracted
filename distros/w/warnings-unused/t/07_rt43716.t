#!perl -w
# to resolve RT #43716

use strict;

use Test::More tests => 1;

use warnings;
use warnings::unused;

our $warns;
BEGIN{
	$warns = '';
	$SIG{__WARN__} = sub{ $warns .= "@_" };
}

sub foo{}

my $x = "foo";
{
  foo();
}
$x++;

is $warns, '';
