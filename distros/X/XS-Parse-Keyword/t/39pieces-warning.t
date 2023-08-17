#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use lib "t";
use testcase "t::pieces";

BEGIN { $^H{"t::pieces/permit"} = 1; }

my @warnings;
BEGIN { $SIG{__WARN__} = sub { push @warnings, $_[0] }; }

{
   BEGIN { undef @warnings; }
   piecewarning;

   BEGIN { is( \@warnings, [ "A warning here\n" ], 'piecewarning emits warning' ) };
}

{
   BEGIN { undef @warnings; }
   piecewarndep;

   BEGIN { is( \@warnings, [ "A deprecated warning here\n" ], 'piecewarndep emits warning' ) };

   BEGIN { undef @warnings; }
   no warnings 'deprecated';
   piecewarndep;

   BEGIN { is( \@warnings, [], 'piecewarndep warning is conditional' ) };
}

done_testing;
