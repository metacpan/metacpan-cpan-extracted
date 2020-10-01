#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use FindBin '$Bin';
use autodie qw/ open opendir mkdir /;
use YAML::Tidy;
use File::Copy qw/ copy /;
$|++;

my $datadir = "$Bin/generated";
mkdir $datadir unless -d $datadir;
my $ts = "$Bin/../yts";
opendir(my $dh, $ts);
my @ids = grep { m/^[A-Z0-9]{4}$/ } readdir $dh;
closedir $dh;

my @skip = qw/
    2JQS
    2LFX
    2SXE
    4ABK
    4MUZ
    5MUD
    5T43
    6BCT
    6LVF
    6M2F
    7Z25
    8XYN
    9SA2
    A2M4
    BEC7
    CFD4
    DBG4
    DK3J
    FP8R
    FRK4
    HWV9
    K3WX
    M7A3
    NHX8
    NJ66
    NKF9
    Q5MG
    QT73
    R4YG
    S3PD
    UT92
    W4TN
    W5VH
/;
my %skip;
@skip{ @skip } = (1) x @skip;
my @valid;
for my $id (sort @ids) {
    if (-e "$ts/$id/error") {
        next;
    }
    next if $skip{ $id };
    push @valid, $id;
}

my @yt = map {
    my $cfg = YAML::Tidy::Config->new( configfile => "$Bin/config$_.yaml" );
    YAML::Tidy->new( cfg => $cfg );
} (0 .. 3);
for my $id (@valid) {
    print "\r=========== $id";
    my $in = "$ts/$id/in.yaml";
    my $dir = "$datadir/$id";
    mkdir $dir unless -d $dir;
    copy $in, "$dir/in.yaml";
    open(my $fh, '<:encoding(UTF-8)', $in);
    my $yaml = do { local $/; <$fh> };
    close $fh;
    for my $i (0 .. 3) {
        my $yt = $yt[ $i ];
        my $out = $yt->tidy($yaml);
        open my $fh, '>:encoding(UTF-8)', "$dir/c$i.yaml";
        print $fh $out;
        close $fh;
    }
}
say "\ndone";
