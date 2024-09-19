#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

BEGIN {
   $^V ge v5.18 or
      plan skip_all => "Lexical subroutines are not supported on Perl version $^V";
}

use lib "t";
use testcase "t::func";

BEGIN { $^H{"t::func/func"}++ }

# lexical func
{
   my func example { return 123; }

   is( example(), 123, 'lexical named func is callable' );
   ok( !main->can( "example" ), 'lexical func is not visible in package' );
}

# lexical funcs are lexical closures
{
   my @subs;
   foreach my $value ( 1 .. 3 ) {
      my func the_value { return $value };
      push @subs, \&the_value;
   }

   is( [ map { $_->() } @subs ], [ 1, 2, 3 ],
      'lexical named funcs are closures' );
}

# `my sub ...` parsing doesn't affect typed lexical variables
{
   my $e = defined eval <<'EOF' ? undef : $@;
   package Some::Class {}
   my Some::Class $var;
   1;
EOF
   ok( !$e, 'Successfully parsed `my TYPE $SCALAR`' )
      or diag( $e );
}

done_testing;
