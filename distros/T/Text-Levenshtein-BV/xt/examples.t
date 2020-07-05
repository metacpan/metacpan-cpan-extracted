#!perl
##use 5.008;

use strict;
use warnings;
use utf8;

use lib qw(../lib/);

use Text::Levenshtein::BV;

use Data::Dumper;
use Time::HiRes qw ( time );

my $ses = Text::Levenshtein::BV->new();

if (0) {
my $a = [split('','eonnnnnicaio')];
my $b = [split('','communicato')];
my $align = $ses->SES($a,$b);
print STDERR '$align: ',Dumper($align);
}

if (0) {
my $a = [split('','eonnnnnicaio')];
my $b = [split('','communicato')];
my $diff = $ses->distance($a,$b);
print STDERR '$diff: ',$diff,"\n";
}

if (1) {
my $a = [split('','Choerephon')];
my $b = [split('','Chrerrplzon')];
my $align = $ses->SES($a,$b);
print STDERR '$align: ',Dumper($align);
}

if (1) {
my $a = [split('','Choerephon')];
my $b = [split('','Chrerrplzon')];
my $diff = $ses->distance($a,$b);
print STDERR '$diff: ',$diff,"\n";
}

if (0) {
    my $a = [split('','Choerephon')];
    my $b = [split('','Chrerrplzon')];

    my $iters = 100000;
    my $start = time;
    for (1..$iters) { $ses->SES($a,$b); }
    my $rate = $iters / (time - $start);

    print 'Text::Levenshtein::BV->SES ',$rate,"\n";
    # 46244/s w/o prefix/suffix optimisation
    # 58812/s with prefix/suffix optimisation
}

if (0) {
    my $a = [split('','Choerephon')];
    my $b = [split('','Chrerrplzon')];

    my $iters = 100000;
    my $start = time;
    for (1..$iters) { $ses->distance($a,$b); }
    my $rate = $iters / (time - $start);

    print 'Text::Levenshtein::BV->distance ',$rate,"\n";
    # 117542/s
}

if (0) {
    my $a = [split('','Choerephon')];
    my $b = [split('','Chrerrplzon')];
    $ses->SES($a,$b);
}

if (0) {
    use Text::Levenshtein qw(distance);

    my $iters = 10000;
    my $start = time;
    for (1..$iters) { distance('Choerephon','Chrerrplzon'); }
    my $rate = $iters / (time - $start);

    print 'Text::Levenshtein->distance ',$rate,"\n";
    # 5008/s
}

if (0) {
    use Text::Levenshtein::XS qw/distance/;

    my $iters = 100000;
    my $start = time;
    for (1..$iters) { distance('Choerephon','Chrerrplzon'); }
    my $rate = $iters / (time - $start);

    print 'Text::Levenshtein::XS->distance ',$rate,"\n";
    # 1876066/s
}
if (0) {
    use Text::LevenshteinXS qw/distance/;

    my $iters = 100000;
    my $start = time;
    for (1..$iters) { distance('Choerephon','Chrerrplzon'); }
    my $rate = $iters / (time - $start);

    print 'Text::LevenshteinXS->distance ',$rate,"\n";
    # 1973167/s
}

