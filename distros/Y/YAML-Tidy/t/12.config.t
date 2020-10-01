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
use YAML::Tidy::Config;

no warnings 'redefine';
sub YAML::Tidy::Config::_homedir {
    return "$Bin/something"
}
sub YAML::Tidy::Config::_cwd {
    return "$Bin/something"
}

subtest default => sub {
    my $yt = YAML::Tidy->new;
    my $cfg = YAML::Tidy::Config->new;
    cmp_deeply($yt->cfg, $cfg, "YAML::Tidy default config matches YT::Config");
};

subtest 'unknown-args' => sub {
    my $cfg = eval { YAML::Tidy::Config->new( foo => 23 ) };
    my $err = $@;
    like $err, qr{Unknown configuration keys: foo};
};

done_testing;
