#!perl

use strict;
use warnings;
use utf8;
use Capture::Tiny qw/capture_stderr/;
use Ukigumo::Logger;

use Test::More;

subtest 'with no prefix' => sub {
    my $logger = Ukigumo::Logger->new;

    subtest 'infof' => sub {
        my $got = capture_stderr{ $logger->infof('foo %s', 'bar') };
        like $got, qr!\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2} \[INFO] foo bar at t/10_logger\.t line \d+!;
    };

    subtest 'warnf' => sub {
        my $got = capture_stderr{ $logger->warnf('foo %s', 'bar') };
        like $got, qr!\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2} \[WARN] foo bar at t/10_logger\.t line \d+!;
    };
};

subtest 'with prefix' => sub {
    my $logger = Ukigumo::Logger->new(
        prefix => ['[hoge]', '[fuga]'],
    );

    subtest 'infof' => sub {
        my $got = capture_stderr{ $logger->infof('foo %s', 'bar') };
        like $got, qr!\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2} \[INFO] \[hoge] \[fuga] foo bar at t/10_logger\.t line \d+!;
    };

    subtest 'warnf' => sub {
        my $got = capture_stderr{ $logger->warnf('foo %s', 'bar') };
        like $got, qr!\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2} \[WARN] \[hoge] \[fuga] foo bar at t/10_logger\.t line \d+!;
    };
};

done_testing;

