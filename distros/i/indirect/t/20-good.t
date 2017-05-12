#!perl -T

package NotEmpty;

sub new;

package main;

use strict;
use warnings;

use Test::More tests => 119 * 8 + 10;

BEGIN { delete $ENV{PERL_INDIRECT_PM_DISABLE} }

my ($obj, $pkg, $cb, $x, @a);
our ($y, $meth);
sub meh;
sub zap (&);

my @warns;

sub try {
 my ($code) = @_;

 @warns = ();
 {
  local $SIG{__WARN__} = sub { push @warns, @_ };
  eval $code;
 }
}

{
 local $/ = "####";
 while (<DATA>) {
  chomp;
  s/\s*$//;
  s/(.*?)$//m;
  my ($skip, $prefix) = split /#+/, $1;
  $skip   = 0  unless defined $skip;
  $prefix = '' unless defined $prefix;
  s/\s*//;

SKIP:
  {
   skip "$_: $skip" => 8 if eval $skip;

   {
    local $_ = $_;
    s/Pkg/Empty/g;

    try "return; $prefix; use indirect; $_";
    is $@,     '', "use indirect: $_";
    is @warns, 0,  'no reports';

    try "return; $prefix; no indirect; $_";
    is $@,     '', "no indirect: $_";
    is @warns, 0,  'no reports';
   }

   {
    local $_ = $_;
    s/Pkg/NotEmpty/g;

    try "return; $prefix; use indirect; $_";
    is $@,     '', "use indirect, defined: $_";
    is @warns, 0,  'no reports';

    try "return; $prefix; no indirect; $_";
    is $@,     '', "no indirect, defined: $_";
    is @warns, 0,  'no reports';
   }
  }
 }
}

# These tests must be run outside of eval to be meaningful.
{
 sub Zlott::Owww::new { }

 my (@warns, $hook, $desc, $id);
 BEGIN {
  $hook = sub { push @warns, indirect::msg(@_) };
  $desc = "test sort and line endings %d: no indirect construct";
  $id   = 1;
 }

 BEGIN { @warns = () }
 {
  no indirect hook => $hook;
  my @stuff = sort Zlott::Owww
          ->new;
 }
 BEGIN { is_deeply \@warns, [ ], sprintf $desc, $id++ }

 BEGIN { @warns = () }
 {
  no indirect hook => $hook;
  my @stuff = sort Zlott::Owww
               ->new;
 };
 BEGIN { is_deeply \@warns, [ ], sprintf $desc, $id++ }

 BEGIN { @warns = () }
 {
  no indirect hook => $hook;
  my @stuff = sort Zlott::Owww
                 ->new;
 }
 BEGIN { is_deeply \@warns, [ ], sprintf $desc, $id++ }

 BEGIN { @warns = () }
 {
  no indirect hook => $hook;
  my @stuff = sort Zlott::Owww
                  ->new;
 }
 BEGIN { is_deeply \@warns, [ ], sprintf $desc, $id++ }

 BEGIN { @warns = () }
 {
  no indirect hook => $hook;
  my @stuff = sort Zlott::Owww
                   ->new;
 }
 BEGIN { is_deeply \@warns, [ ], sprintf $desc, $id++ }

 BEGIN { @warns = () }
 {
  no indirect hook => $hook;
  my @stuff = sort Zlott::Owww
                     ->new;
 }
 BEGIN { is_deeply \@warns, [ ], sprintf $desc, $id++ }

 BEGIN { @warns = () }
 {
  no indirect hook => $hook;
  my @stuff = sort Zlott::Owww
                       ->new;
 }
 BEGIN { is_deeply \@warns, [ ], sprintf $desc, $id++ }

 BEGIN { @warns = () }
 {
  no indirect hook => $hook;
  my @stuff = sort Zlott::Owww
                          ->new;
 }
 BEGIN { is_deeply \@warns, [ ], sprintf $desc, $id++ }

 BEGIN { @warns = () }
 {
  no indirect hook => $hook;
  my @stuff = sort Zlott::Owww
                            ->new;
 }
 BEGIN { is_deeply \@warns, [ ], sprintf $desc, $id++ }

 BEGIN { @warns = () }
 {
  no indirect hook => $hook;
  my @stuff = sort Zlott::Owww
                             ->new;
 }
 BEGIN { is_deeply \@warns, [ ], sprintf $desc, $id++ }
}

__DATA__

$obj = Pkg->new;
####
$obj = Pkg->new();
####
$obj = Pkg->new(1);
####
$obj = Pkg->new(q{foo}, bar => $obj);
####
$obj = Pkg   ->   new   ;
####
$obj = Pkg   ->   new   (   )   ;
####
$obj = Pkg   ->   new   (   1   )   ;
####
$obj = Pkg   ->   new   (   'foo'   ,   bar =>   $obj   );
####
$obj = Pkg
            ->
                          new   ;
####
$obj = Pkg  

      ->   
new   ( 
 )   ;
####
$obj = Pkg
                                       ->   new   ( 
               1   )   ;
####
$obj = Pkg   ->
                              new   (   "foo"
  ,    bar     
               =>        $obj       );
####
$obj = new->new;
####
$obj = new->new; # new new
####
$obj = new->newnew;
####
$obj = newnew->new;
####
$obj = Pkg->$cb;
####
$obj = Pkg->$cb();
####
$obj = Pkg->$cb($pkg);
####
$obj = Pkg->$cb(sub { 'foo' },  bar => $obj);
####
$obj = Pkg->$meth;
####
$obj =   Pkg
   -> 
          $meth   ( 1,   2   );
####
$obj = $pkg->new   ;
####
$obj = $pkg  ->   new  (   );
####
$obj = $pkg       
           -> 
        new ( $pkg );
####
$obj = 
         $pkg
->
new        (     qr/foo/,
      foo => qr/bar/   );
####
$obj 
  =  
$pkg
->
$cb
;
####
$obj = $pkg    ->   ($cb)   ();
####
$obj = $pkg->$cb( $obj  );
####
$obj = $pkg->$cb(qw<foo bar baz>);
####
$obj = $pkg->$meth;
####
$obj 
 =
    $pkg
          ->
              $meth
  ( 1 .. 10 );
####
$obj = $y->$cb;
####
$obj =  $y
  ->          $cb   (
  'foo', 1, 2, 'bar'
);
####
$obj = $y->$meth;
####
$obj =
  $y->
      $meth   (
 qr(hello),
);
####
meh;
####
meh $_;
####
meh $x;
####
meh $x, 1, 2;
####
meh $y;
####
meh $y, 1, 2;
#### "$]" < 5.010 # use feature 'state'; state $z
meh $z;
#### "$]" < 5.010 # use feature 'state'; state $z
meh $z, 1, 2;
####
print;
####
print $_;
####
print $x;
####
print $x "oh hai\n";
####
print $y;
####
print $y "hello thar\n";
#### "$]" < 5.010 # use feature 'state'; state $z
print $z;
#### "$]" < 5.010 # use feature 'state'; state $z
print $z "lolno\n";
####
print STDOUT "bananananananana\n";
####
$x->foo($pkg->$cb)
####
$obj = "apple ${\($x->new)} pear"
####
$obj = "apple @{[$x->new]} pear"
####
$obj = "apple ${\($y->new)} pear"
####
$obj = "apple @{[$y->new]} pear"
####
$obj = "apple ${\($x->$cb)} pear"
####
$obj = "apple @{[$x->$cb]} pear"
####
$obj = "apple ${\($y->$cb)} pear"
####
$obj = "apple @{[$y->$cb]} pear"
####
$obj = "apple ${\($x->$meth)} pear"
####
$obj = "apple @{[$x->$meth]} pear"
####
$obj = "apple ${\($y->$meth)} pear"
####
$obj = "apple @{[$y->$meth]} pear"
#### # local $_ = "foo";
s/foo/return; Pkg->new/e;
#### # local $_ = "bar";
s/foo/return; Pkg->new/e;
#### # local $_ = "foo";
s/foo/return; Pkg->$cb/e;
#### # local $_ = "bar";
s/foo/return; Pkg->$cb/e;
#### # local $_ = "foo";
s/foo/return; Pkg->$meth/e;
#### # local $_ = "bar";
s/foo/return; Pkg->$meth/e;
#### # local $_ = "foo";
s/foo/return; $x->new/e;
#### # local $_ = "bar";
s/foo/return; $x->new/e;
#### # local $_ = "foo";
s/foo/return; $x->$cb/e;
#### # local $_ = "bar";
s/foo/return; $x->$cb/e;
#### # local $_ = "foo";
s/foo/return; $x->$meth/e;
#### # local $_ = "bar";
s/foo/return; $x->$meth/e;
#### # local $_ = "foo";
s/foo/return; $y->new/e;
#### # local $_ = "bar";
s/foo/return; $y->new/e;
#### # local $_ = "foo";
s/foo/return; $y->$cb/e;
#### # local $_ = "bar";
s/foo/return; $y->$cb/e;
#### # local $_ = "foo";
s/foo/return; $y->$meth/e;
#### # local $_ = "bar";
s/foo/return; $y->$meth/e;
####
"foo" =~ /(?{Pkg->new})/;
####
"foo" =~ /(?{Pkg->$cb})/;
####
"foo" =~ /(?{Pkg->$meth})/;
####
"foo" =~ /(?{$x->new})/;
####
"foo" =~ /(?{$x->$cb})/;
####
"foo" =~ /(?{$x->$meth})/;
####
"foo" =~ /(?{$y->new})/;
####
"foo" =~ /(?{$y->$cb})/;
####
"foo" =~ /(?{$y->$meth})/;
####
exec $x $x, @a;
####
exec { $a[0] } @a;
####
system $x $x, @a;
####
system { $a[0] } @a;
####
zap { };
####
zap { 1; };
####
zap { 1; 1; };
####
zap { zap { }; 1; };
####
my @stuff = sort Pkg
     ->new;
####
my @stuff = sort Pkg
              ->new;
####
my @stuff = sort Pkg
               ->new;
####
my @stuff = sort Pkg
                ->new;
####
my @stuff = sort Pkg
                 ->new;
####
my @stuff = sort Pkg
                   ->new;
####
my @stuff = sort Pkg
                     ->new;
####
my @stuff = sort Pkg
                        ->new;
####
sub {
 my $self = shift;
 return $self->new ? $self : undef;
}
####
sub {
 my $self = shift;
 return $self ? $self->new : undef;
}
####
sub {
 my $self = shift;
 return $_[0] ? undef : $self->new;
}
####
package Hurp;
__PACKAGE__->new;
####
package Hurp;
__PACKAGE__->new # Hurp
####
package Hurp;
__PACKAGE__->new;
# Hurp
####
package __PACKAGE_;
__PACKAGE__->new # __PACKAGE_
####
package __PACKAGE_;
__PACKAGE_->new # __PACKAGE__
####
package __PACKAGE___;
__PACKAGE__->new # __PACKAGE___
####
package __PACKAGE___;
__PACKAGE___->new # __PACKAGE__
