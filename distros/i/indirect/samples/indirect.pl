#!/usr/bin/env perl

#use strict;
#use warnings;

use lib qw<blib/lib blib/arch>;

sub Hlagh::new { my $class = shift; bless { }, ref($class) || $class ; }

sub foo { shift; print "foo $_[0]\n" }
sub bar { print "wut\n"; }
my $bar = bless { }, 'main';

my %h;
my $x = 1;

no indirect;

$x = new Hlagh 1, 2, 3;
my $y = slap $x "what", 5;
$h{foo} = 12;

use indirect;

foo 4, 5;

no indirect;

my $pkg = 'Hlagh';
my $cb = 'new';

foo(6, 7, 8); my $y = new $_ qr/bar/;

my $y = Hlagh->new;
$y =          new Hlagh;
my $z = foo meh, 1, 2;
$y = meh $x, 7;
$y = foo(3, 4);
$y = Hlagh->new();
$y = Hlagh->new(1, 2, 3);
$y = Hlagh->$cb;
$y =      new Hlagh;
$y =                new Hlagh 1, 2, 3;
$y = 
  new   
     Hlagh
        1  ,
                2,        3;
$y = new $pkg;
$y = new $pkg 'what';
$y = $pkg->new;
$y = $pkg->new(1, 2, 3);
$y = $pkg->$cb;
$y = new(Hlagh);
$y = new { Hlagh };
$y = new { $y };
$y = Hlagh
        ->        new 
           ( 1     ,       2,    3);
$y = Hlagh
        ->        $ cb
           ( 1     ,       2,    3);
$y = new Hlagh $,;
$y = new Hlagh ',';
print { $^H{dongs} } 'bleh';
print STDERR 1;
print STDERR 'what';
print STDERR q{wat};
my $fh;
print $fh 'dongs';
