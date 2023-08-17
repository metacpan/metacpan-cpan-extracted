#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use lib "t";
use testcase "t::stages";

sub stages { return $_[0] }

# not permitted
{
   my $ret = stages { one => "one" };

   is( $ret, { one => "one" },
      'not permitted keyword falls through to regular symbol lookup' );
}

# denied by func
{
   BEGIN { $^H{"t::stages/permitkey"} = 1; }

   my $ret = stages { two => "two" };

   is( $ret, { two => "two" },
      'keyword permitted by key but denied by func' );
}

# permitted
{
   BEGIN { $^H{"t::stages/permitkey"} = 1; }
   BEGIN { $^H{"t::stages/permitfunc"} = 1; }

   my $ret = stages { three => "three" };

   is( $ret, "STAGE",
      'keyword permitted by .permit func' );
}

done_testing;
