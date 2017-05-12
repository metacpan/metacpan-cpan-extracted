# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tk-MethodList.t'


use Test::More tests => 9;
use_ok ('Tk');
require_ok('Tk::PerlMethodList') ;



use strict;
use warnings;

package Testclass;

sub testmethod1;
sub testmethod2{};

package main;

warn "test running\n";

my $mw = tkinit();
my $w;
eval{$w = $mw->PerlMethodList};
ok( !$@,"instance creation: $@");
$mw->update;
{
my $text   =  $w->{text};
my $font   =  $w->{font};

my $size   = $text->fontConfigure($font,'-size');
is($size, 12, 'fontsize');

my $family = $text->fontConfigure($font,'-family');
is($family, 'Courier', 'fontfamily'); 
}

$w->classname('Tk::PerlMethodList');
is ($w->cget('-classname'), 'Tk::PerlMethodList','classname set/get');

$w->show_methods;
$w->update;
{
my $text = $w->{text};
my $line = $text->get('1.0','1.60');
like($line, qr/Tk::PerlMethodList\s*_adjust_selection/,
     q/find displayed method '_adjust_selection'/);
}

$w->classname('Testclass');
$w->show_methods;
$w->update;

{
    my $text = $w->{text};
    my $line = $text->get('1.0','2.0');
    like($line,
         qr/Testclass\s*testmethod1\s*declared/,
         q/find a declared method/);
}

package Z;
sub test{};

package C;
our @ISA = qw/Z/;

package D;
our @ISA = qw/Z/;
sub test{};

package E;
our @ISA = qw/Z/;
sub test{};

package A;
our @ISA = qw/ C D E /;
use MRO::Compat;
use mro 'c3';
#sub foo{};
Class::C3::initialize();

package main;

$w->classname('A');
$w->show_methods;
$w->update;

{
    my $text = $w->{text};
    my $line = $text->get('1.0','end');
    ok(($line =~ /D .*E .*Z /s),
         q/test C3  mro/);
}
