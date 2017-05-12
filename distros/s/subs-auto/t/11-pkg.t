#!perl -T

use strict;
use warnings;

use Test::More tests => 16;

our $foo;

{
 eval q{
  use subs::auto in => 'subs::auto::Test::Pkg';
  subs::auto::Test::Pkg::foo 1
 };
 my $err = $@;
 is($err, '', 'compiled to subs::auto::Test::Pkg::foo(1)');
 is($foo, 3,  'subs::auto::Test::Pkg::foo was really called');
}

{
 eval q{
  use subs::auto in => 'subs::auto::Test::Pkg';
  {
   use subs::auto;
   foo 2
  }
 };
 my $err = $@;
 no warnings 'uninitialized';
 is($err, '', 'compiled to foo(2)');
 is($foo, 4,  'main::foo was really called');
}

{
 eval q{
  use subs::auto in => 'subs::auto::Test::Pkg';
  {
   use subs::auto;
   subs::auto::Test::Pkg::foo 3;
  }
 };
 my $err = $@;
 no warnings 'uninitialized';
 is($err, '', 'compiled to subs::auto::Test::Pkg::foo(3)');
 is($foo, 9,  'subs::auto::Test::Pkg::foo was really called');
}

{
 eval q{
  use subs::auto in => 'subs::auto::Test::Pkg';
  {
   use subs::auto;
   {
    package subs::auto::Test::Pkg;
    foo 4
   }
  }
 };
 my $err = $@;
 no warnings 'uninitialized';
 Test::More::is($err, '', 'compiled to foo(4)');
 Test::More::is($foo, 12, 'subs::auto::Test::Pkg::foo was really called');
}

{
 eval q{
  use subs::auto in => 'subs::auto::Test::Pkg';
  {
   use subs::auto;
   {
    package subs::auto::Test::Pkg;
    main::foo 5
   }
  }
 };
 my $err = $@;
 no warnings 'uninitialized';
 Test::More::is($err, '', 'compiled to main::foo(5)');
 Test::More::is($foo, 10, 'main::foo was really called');
}

{
 package subs::auto::Test::Pkg;

 eval q{
  use subs::auto;
  foo 6
 };
 my $err = $@;
 no warnings 'uninitialized';
 Test::More::is($err, '', 'compiled to foo(6)');
 Test::More::is($foo, 18, 'subs::auto::Test::Pkg::foo was really called');
}

{
 eval q{
  use subs::auto in => '::';
  foo 7
 };
 my $err = $@;
 no warnings 'uninitialized';
 is($err, '', 'compiled to foo(7)');
 is($foo, 14, 'main::foo was really called');
}

{
 package subs::auto::Test;

 eval q{
  use subs::auto in => '::Pkg';
  {
   package subs::auto::Test::Pkg;
   foo 8;
  }
 };
 my $err = $@;
 no warnings 'uninitialized';
 Test::More::is($err, '', 'compiled to foo(8)');
 Test::More::is($foo, 24, 'subs::auto::Test::Pkg::foo was really called');
}

sub foo {
 $main::foo = 2 * $_[0];
}

sub subs::auto::Test::Pkg::foo {
 $main::foo = 3 * $_[0];
}
