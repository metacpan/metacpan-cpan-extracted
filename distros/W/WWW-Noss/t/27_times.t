#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use WWW::Noss::Timestamp;

# Taken from DateTime::Format::Mail
my $MAIL_DATES = File::Spec->catfile(qw/t data mail-dates/);
my $RFC3339_DATES = File::Spec->catfile(qw/t data rfc3339-dates/);

my %MAIL = (
    '03 Jan 2003 23:30:36 -0500'            => 1041654636,
    '03 Mar 2003 00:39:25 +0100'            => 1046648365,
    '06 Mar 2003 08:21:13 -0500'            => 1046956873,
    '06-Mar-2003 09:03:29 ZE10'             => 1046941409,
    '17 Aug 2000 15:22:31 -0700'            => 966550951,
    '1 Nov 2002 03:05:00 -0000'             => 1036119900,
    '20 Aug 2002 16:45:00 -0000'            => 1029861900,
    'Fri, 10 May 2002 11:13:11 +0100 (BST)' => 1021025591,
    'Fri, 10 May 2002 18:04 +1000'          => 1021017840,
);

my %RFC3339 = (
    '2003-01-03T23:30:36-05:00' => 1041654636,
    '2003-03-03T00:39:25+01:00' => 1046648365,
    '2003-03-06T08:21:13-05:00' => 1046956873,
    '2003-03-06T09:03:29+00:00' => 1046941409,
    '2000-08-17T15:22:31-07:00' => 966550951,
    '2002-11-01T03:05:00-00:00' => 1036119900,
    '2002-08-20T16:45:00-00:00' => 1029861900,
    '2002-05-10T11:13:11+01:00' => 1021025591,
    '2002-05-10T18:04:00+10:00' => 1021017840,
);

subtest 'can correctly parse various mail dates' => sub {

    for my $k (sort keys %MAIL) {
        is(
            WWW::Noss::Timestamp->mail($k),
            $MAIL{ $k },
            "parsed '$k' correctly"
        );
    }

};

subtest 'can parse various mail dates' => sub {

    open my $fh, '<', $MAIL_DATES
        or die "Failed to open $MAIL_DATES for reading: $!\n";

    while (my $l = readline $fh) {
        chomp $l;
        ok(defined WWW::Noss::Timestamp->mail($l), "can parse '$l'");
    }

    close $fh;

};

subtest 'can correctly parse various rfc3339 dates' => sub {

    for my $k (sort keys %RFC3339) {
        is(
            WWW::Noss::Timestamp->rfc3339($k),
            $RFC3339{ $k },
            "parsed '$k' correctly"
        );
    }

};

subtest 'can parse rfc3339 dates' => sub {

    open my $fh, '<', $RFC3339_DATES
        or die "Failed to open $RFC3339_DATES for reading: $!\n";

    while (my $l = readline $fh) {
        chomp $l;
        ok(defined WWW::Noss::Timestamp->rfc3339($l), "can parse '$l'");
    }

    close $fh;

};

done_testing;

# vim: expandtab shiftwidth=4
