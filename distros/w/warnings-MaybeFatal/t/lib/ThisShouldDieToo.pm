package ThisShouldDieToo;

use strict;
use warnings;
use warnings::MaybeFatal;

{
	no warnings::MaybeFatal;
	sub yyy { 1 };
	sub yyy { 2 };
}

sub xxx { 1 };
sub xxx { 2 };

1;
