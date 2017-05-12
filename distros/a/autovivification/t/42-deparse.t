#!perl -T

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use VPIT::TestHelpers;

load_or_skip_all('B::Deparse', undef, [ ]);

plan tests => 2;

my $bd = B::Deparse->new;

{
 no autovivification qw<fetch strict>;

 sub blech { my $key = $_[0]->{key} }
}

{
 my $undef;
 eval 'blech($undef)';
 like $@, qr/Reference vivification forbidden/, 'Original blech() works';
}

{
 my $code = $bd->coderef2text(\&blech);
 my $undef;
 eval "$code; blech(\$undef)";
 like $@, qr/Reference vivification forbidden/, 'Deparsed blech() works';
}
