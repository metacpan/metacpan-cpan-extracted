#!/usr/bin/perl

use strict;
use warnings;
use Test::Weaken;

# uncomment this to run the ### lines
use Smart::Comments;

use constant und => \undef;
my $global = 123;

{
  package MyOverload;
  use overload '&{}' => sub {
    return sub {
      print "hello\n";
      return [ \$global ];

      return [ \\\undef ];
      return main::und();
    }
  };
  sub new {
    return bless {}, shift;
  }
}

sub my_constructor {
  return [ \$global ];
}

my $obj = MyOverload->new;
&$obj();

my $tw = Test::Weaken::leaks
  ({ 
    constructor => 'main::my_constructor',
    # constructor => $obj,
   });
### $tw
exit 0;
