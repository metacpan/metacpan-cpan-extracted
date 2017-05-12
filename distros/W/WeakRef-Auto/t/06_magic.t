#!perl -wT

use strict;
use Test::More tests => 5;

use WeakRef::Auto;
use Devel::Peek;

use Tie::Scalar;
use Tie::Hash;

use warnings FATAL => 'misc';

my $tainted = $^X;
$tainted = [];

autoweaken $tainted;
is $tainted, undef, 'taint magic';
{
	my $ref = [];
	$tainted = $ref;
	is $tainted, $ref;
}
is $tainted, undef;

my $ts;
tie $ts, 'Tie::StdScalar';

eval{
	autoweaken $ts;
};
like $@, qr/does not work/;

my %th;
tie %th, 'Tie::StdHash';

eval{
	autoweaken $th{foo};
};
like $@, qr/does not work/;
