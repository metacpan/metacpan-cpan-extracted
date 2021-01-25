#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use lib "t";
use testcase "t::stages";

sub stages { return $_[0] }

# not permitted
{
   my $ret = stages { one => "one" };

   is_deeply( $ret, { one => "one" },
      'not permitted keyword falls through to regular symbol lookup' );
}

# permitted
{
   BEGIN { $^H{"t::stages/permit"} = 1; }

   my $ret = stages { two => "two" };

   is( ref $ret, "CODE",
      'permitted keyword becomes a CODE ref' );
}

# TODO: test that it can throw

done_testing;
