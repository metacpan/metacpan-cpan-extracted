#!perl -T

use strict;
use warnings;

use Variable::Temp 'set_temp';

use Test::More tests => (9 + 2 * 19) * 2 + 6 * 3;

sub describe {
 my $h = $_[0];
 return join ', ', map "$_:$h->{$_}", sort keys %$h;
}

my $aelem_delete_msg = 'Localized extraneous array elements do not reset array length at scope end before perl 5.12';
my $aelem_delete_ok  = ("$]" >= 5.012);

# Lexicals

{
 my $x = 1;
 is $x, 1;
 {
  set_temp $x => 2;
  is $x, 2;
  $x = 3;
  is $x, 3;
 }
 is $x, 1;
 {
  set_temp $x => 4;
  is $x, 4;
  set_temp $x => 5;
  is $x, 5;
 }
 is $x, 1;
 {
  set_temp $x;
  is $x, undef;
 }
 is $x, 1;
}

{
 my @y = (1, 2);
 is "@y", "1 2";
 {
  set_temp @y => [ 3 ];
  is "@y", '3';
  @y = (4, 5, 6);
  is "@y", '4 5 6';
  $y[3] = 7;
  is "@y", '4 5 6 7';
 }
 is "@y", "1 2";
 {
  set_temp @y => [ 8, 9, 10 ];
  is "@y", '8 9 10';
  $y[1] = 11;
  is "@y", '8 11 10';
 }
 is "@y", "1 2";
 {
  set_temp @y => [ 12, 13, 14 ];
  is "@y", '12 13 14';
  set_temp @y => [ 15, 16];
  is "@y", '15 16';
 }
 is "@y", '1 2';
 {
  set_temp @y;
  is "@y", '';
 }
 is "@y", '1 2';
 {
  set_temp @y => [ qw<a b c> ];
  is "@y", 'a b c';
  SKIP: {
   skip $aelem_delete_msg => 3 unless $aelem_delete_ok;
   local $y[1] = 'd';
   is "@y", 'a d c';
   {
    local @y[2, 3] = qw<e f>;
    is "@y", 'a d e f';
   }
   is "@y", 'a d c';
  }
  is "@y", 'a b c';
 }
 is "@y", '1 2';
}

{
 my %z = (a => 1);
 is describe(\%z), 'a:1';
 {
  set_temp %z => { b => 2 };
  is describe(\%z), 'b:2';
  %z = (c => 3);
  is describe(\%z), 'c:3';
  $z{d} = 4;
  is describe(\%z), 'c:3, d:4';
 }
 is describe(\%z), 'a:1';
 {
  set_temp %z => { a => 5 };
  is describe(\%z), 'a:5';
  $z{a} = 6;
  is describe(\%z), 'a:6';
 }
 is describe(\%z), 'a:1';
 {
  set_temp %z => { a => 7, d => 8 };
  is describe(\%z), 'a:7, d:8';
  set_temp %z => { d => 9, e => 10 };
  is describe(\%z), 'd:9, e:10';
 }
 is describe(\%z), 'a:1';
 {
  set_temp %z;
  is describe(\%z), '';
 }
 is describe(\%z), 'a:1';
 {
  set_temp %z => { a => 11, f => 12 };
  is describe(\%z), 'a:11, f:12';
  {
   local $z{a} = 13;
   is describe(\%z), 'a:13, f:12';
   {
    local @z{qw<f g>} = (14, 15);
    is describe(\%z), 'a:13, f:14, g:15';
   }
   is describe(\%z), 'a:13, f:12';
  }
  is describe(\%z), 'a:11, f:12';
 }
 is describe(\%z), 'a:1';
}

# Globals

{
 our $X = 1;
 is $X, 1;
 {
  set_temp $X => 2;
  is $X, 2;
  $X = 3;
  is $X, 3;
 }
 is $X, 1;
 {
  set_temp $X => 4;
  is $X, 4;
  set_temp $X => 5;
  is $X, 5;
 }
 is $X, 1;
 {
  set_temp $X;
  is $X, undef;
 }
 is $X, 1;
 {
  local $X = 6;
  is $X, 6;
 }
 is $X, 1;
 {
  local $X = 7;
  set_temp $X => 8;
  is $X, 8;
 }
 is $X, 1;
 {
  set_temp $X => 9;
  local $X = 10;
  is $X, 10;
 }
 is $X, 1;
}

{
 our @Y = (1, 2);
 is "@Y", "1 2";
 {
  set_temp @Y => [ 3 ];
  is "@Y", '3';
  @Y = (4, 5, 6);
  is "@Y", '4 5 6';
  $Y[3] = 7;
  is "@Y", '4 5 6 7';
 }
 is "@Y", "1 2";
 {
  set_temp @Y => [ 8, 9, 10 ];
  is "@Y", '8 9 10';
  $Y[1] = 11;
  is "@Y", '8 11 10';
 }
 is "@Y", "1 2";
 {
  set_temp @Y => [ 12, 13, 14 ];
  is "@Y", '12 13 14';
  set_temp @Y => [ 15, 16];
  is "@Y", '15 16';
 }
 is "@Y", '1 2';
 {
  set_temp @Y;
  is "@Y", '';
 }
 is "@Y", '1 2';
 {
  set_temp @Y => [ qw<a b c> ];
  is "@Y", 'a b c';
  SKIP: {
   skip $aelem_delete_msg => 3 unless $aelem_delete_ok;
   local $Y[1] = 'd';
   is "@Y", 'a d c';
   {
    local @Y[2, 3] = qw<e f>;
    is "@Y", 'a d e f';
   }
   is "@Y", 'a d c';
  }
  is "@Y", 'a b c';
 }
 is "@Y", '1 2';
 {
  local @Y = qw<A B>;
  is "@Y", 'A B';
 }
 is "@Y", '1 2';
 {
  local @Y = qw<C D E>;
  set_temp @Y => [ qw<F> ];
  is "@Y", 'F';
 }
 is "@Y", '1 2';
 {
  set_temp @Y => [ qw<G H I> ];
  local @Y = qw<J>;
  is "@Y", 'J';
 }
 is "@Y", '1 2';
}

{
 our %Z = (a => 1);
 is describe(\%Z), 'a:1';
 {
  set_temp %Z => { b => 2 };
  is describe(\%Z), 'b:2';
  %Z = (c => 3);
  is describe(\%Z), 'c:3';
  $Z{d} = 4;
  is describe(\%Z), 'c:3, d:4';
 }
 is describe(\%Z), 'a:1';
 {
  set_temp %Z => { a => 5 };
  is describe(\%Z), 'a:5';
  $Z{a} = 6;
  is describe(\%Z), 'a:6';
 }
 is describe(\%Z), 'a:1';
 {
  set_temp %Z => { a => 7, d => 8 };
  is describe(\%Z), 'a:7, d:8';
  set_temp %Z => { d => 9, e => 10 };
  is describe(\%Z), 'd:9, e:10';
 }
 is describe(\%Z), 'a:1';
 {
  set_temp %Z;
  is describe(\%Z), '';
 }
 is describe(\%Z), 'a:1';
 {
  set_temp %Z => { a => 11, f => 12 };
  is describe(\%Z), 'a:11, f:12';
  {
   local $Z{a} = 13;
   is describe(\%Z), 'a:13, f:12';
   {
    local @Z{qw<f g>} = (14, 15);
    is describe(\%Z), 'a:13, f:14, g:15';
   }
   is describe(\%Z), 'a:13, f:12';
  }
  is describe(\%Z), 'a:11, f:12';
 }
 is describe(\%Z), 'a:1';
 {
  local %Z = (A => 1, B => 2);
  is describe(\%Z), 'A:1, B:2';
 }
 is describe(\%Z), 'a:1';
 {
  local %Z = (A => 3, C => 4);
  set_temp %Z => { A => 5, D => 6 };
  is describe(\%Z), 'A:5, D:6';
 }
 is describe(\%Z), 'a:1';
 {
  set_temp %Z => { A => 7, E => 8 };
  local %Z = (A => 9, F => 10);
  is describe(\%Z), 'A:9, F:10';
 }
 is describe(\%Z), 'a:1';
}
