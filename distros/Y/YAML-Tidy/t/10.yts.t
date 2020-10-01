#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use Test::More;
use Encode;
use Test::Deep qw/ cmp_deeply /;
use Test::Warnings qw/ :report_warnings /;

use FindBin '$Bin';
use YAML::Tidy;

my $ts = "$Bin/../yts";
opendir my $dh, $ts or die $!;
my @ids = grep { m/^[A-Z0-9]{4}$/ } readdir $dh;
closedir $dh;

# libyaml parse error
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
    CFD4
/;

# later
push @skip, qw/
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

@valid = @valid[0..168];
#@valid = $valid[0];
my @indents = (1 .. 4);

my @yt = map {
    my $cfg = YAML::Tidy::Config->new( configfile => "$Bin/../utils/config$_.yaml" );
    YAML::Tidy->new( cfg => $cfg );
} (0 .. 4);

my %failed;
for my $i (0 .. 4) {
    diag "============= config $i";
    my $yt = $yt[ $i ];
    for my $id (@valid) {
        my $label = "(config: $i) $id";
        note "======================================================= $label";
        open my $fh, '<encoding(UTF-8)', "$ts/$id/in.yaml";
        my $in = do { local $/; <$fh> };
        close $fh;
        note encode_utf8 $yt->highlight($in);
        my $out = eval {
            $yt->tidy($in)
        };
        my $err = $@;
        if ($err) {
            fail("$label - Error tidying");
            diag $err;
            die 23;
            push @{ $failed{ $i } }, $id;
            next;
        }
        my $debug = $yt->highlight($out);
        note encode_utf8 $debug;
        pass("$label - No error");

        # reparse
        my @previous_events = map {
            delete $_->{start};
            delete $_->{end};
            $_
        } @{ $yt->{events} };
        my $events = eval { $yt->_parse($out) };
        if (my $err = $@) {
            fail("$label - Reparse ok");
            diag $out;
            diag $err;
            push @{ $failed{ $i } }, $id;
            next;
        }

        shift @$events; pop @$events;
        my @events = map {
            delete $_->{start};
            delete $_->{end};
            delete $_->{id};
            delete $_->{level};
            delete $_->{nextline};
            $_;
        } @$events;
        @previous_events = map {
            delete $_->{start};
            delete $_->{end};
            delete $_->{id};
            delete $_->{level};
            delete $_->{nextline};
            $_;
        } @previous_events;
        cmp_deeply(\@events, \@previous_events, "$label - Reparse same events") or do {
            diag(Data::Dumper->Dump([\@events], ['events']));
            diag(Data::Dumper->Dump([\@previous_events], ['previous_events']));
            push @{ $failed{ $i } }, $id;
        };
    }
}

if (keys %failed) {
    diag(Data::Dumper->Dump([\%failed], ['failed']));
}


done_testing;
