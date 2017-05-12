#!/usr/bin/perl -w
use strict;

use Test::More tests => 19;
use VCS::Lite;

my $save_output = $ENV{VCS_LITE_KEEP_OUTPUT};

my $el1 = VCS::Lite->new('data/mariner.txt');

#01
isa_ok($el1,'VCS::Lite','Return from new, passed filespec');

my $el2 = VCS::Lite->new('data/marinerx.txt');
my $dt1 = VCS::Lite::Delta->new('data/marinerx.dif',undef,'mariner.txt','marinerx.txt');

#02
isa_ok($dt1,'VCS::Lite::Delta','New delta');

my $el3 = $el1->patch($dt1);

#03
isa_ok($el3,'VCS::Lite','Return from patch method');

my $out2 = $el2->text;
my $out3 = $el3->text;

if ($save_output) {
    open (my $dfh, '>', 'patch1.out')
        or die "Failed to write output: $!";
    print $dfh $out3;
}

#04
is($out2, $out3, 'Patched file is the same as marinerx');

my $dt2 = VCS::Lite::Delta->new('data/marinerx.udif',undef,'mariner.txt','marinerx.txt');

#05
isa_ok($dt2,'VCS::Lite::Delta','New delta');

my $el4 = $el1->patch($dt2);

#06
isa_ok($el4,'VCS::Lite','Patch applied');

my $out4 = $el4->text;

#07
is($out2, $out4, 'Patched file is the same as marinerx');

my $el1c = VCS::Lite->new('data/mariner.txt', {chomp => 1});
my $el2c = VCS::Lite->new('data/marinerx.txt', {chomp => 1});
my $dt1c = VCS::Lite::Delta->new('data/marinerx.dif',{chomp => 1},
    'mariner.txt','marinerx.txt');

#08
isa_ok($dt1c,'VCS::Lite::Delta','New delta (chomped)');

my $el3c = $el1c->patch($dt1c);

#09
isa_ok($el3c,'VCS::Lite','Return from patch method (chomped)');

$out2 = $el2c->text;
$out3 = $el3c->text;

if ($save_output) {
    open (my $dfh, '>', 'patch1c.out')
        or die "Failed to write output: $!";
    print $dfh $out3;
}

#10
is($out2, $out3, 'Patched file is the same as marinerx');

my $dt2c = VCS::Lite::Delta->new('data/marinerx.udif',{chomp => 1},
    'mariner.txt','marinerx.txt');

#11
isa_ok($dt2c,'VCS::Lite::Delta','New delta');

my $el4c = $el1c->patch($dt2c);

#12
isa_ok($el4c,'VCS::Lite','Patch applied');

$out4 = $el4c->text;

#13
is($out2, $out4, 'Patched file is the same as marinerx (chomped)');

my $udiff = $dt2->udiff;

#14
ok($udiff, "udiff returns text");

if ($save_output) {
    open (my $dfh, '>', 'patch2.out')
        or die "Failed to write output: $!";
    print $dfh $udiff;
}

my $results = do { local (@ARGV, $/) = 'data/marinerx.udif'; <> }; # slurp entire file

$results =~ s/^\+\+\+.*\n//s;
$results =~ s/^---.*\n//s;
$udiff =~ s/^\+\+\+.*\n//s;
$udiff =~ s/^---.*\n//s;

#15
is($udiff,$results,'udiff output matches original udiff');

$udiff = $dt2c->udiff;

#16
ok($udiff, "udiff returns text (chomped)");

if ($save_output) {
    open (my $dfh, '>', 'patch2c.out')
        or die "Failed to write output: $!";
    print $dfh $udiff;
}

$udiff =~ s/^\+\+\+.*\n//s;
$udiff =~ s/^---.*\n//s;

#17
is($udiff,$results,'udiff output matches original udiff');


my $el5 = VCS::Lite->new('data/snarka.txt');
my $el6 = VCS::Lite->new('data/snarkb.txt');
my $dt3 = VCS::Lite::Delta->new('data/snarkab.dif',undef,'snarka.txt','snarkb.txt');
my $el7 = $el5->patch($dt3);

my $out6 = $el6->text;
my $out7 = $el7->text;

#16
is($out6, $out7, 'Patched file is the same as snarkb (diff)');

my $dt4 = VCS::Lite::Delta->new('data/snarkab.udif',undef,'snarka.txt','snarkb.txt');
my $el8 = $el5->patch($dt4);

$out7 = $el7->text;
my $out8 = $el8->text;

#17
is($out6, $out8, 'Patched file is the same as snarkb (udiff)');

