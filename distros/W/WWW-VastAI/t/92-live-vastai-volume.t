#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use lib 't/lib';

use Test::WWW::VastAI::Live qw(
    live_client
    require_cost_env
    unique_label
);

BEGIN {
    require_cost_env();
}

my $vast = live_client();
my $label = $ENV{VAST_LIVE_VOLUME_LABEL} || unique_label('perl-volume-vast');
my $volume;

END {
    return unless $vast;
    return unless $volume;
    return unless eval { $volume->id };

    eval {
        $vast->volumes->delete($volume->id);
        diag 'cleanup: delete requested for volume ' . $volume->id;
    };
    diag "cleanup failed for volume " . $volume->id . ": $@" if $@;
}

subtest 'create list and delete a volume' => sub {
    $volume = $vast->volumes->create(
        size  => ($ENV{VAST_LIVE_VOLUME_SIZE} || 10),
        label => $label,
    );
    isa_ok($volume, 'WWW::VastAI::Volume');
    ok($volume->id, 'volume has id');

    my $volumes = $vast->volumes->list;
    my ($found) = grep { defined $_->id && $_->id eq $volume->id } @{$volumes};
    ok($found, 'new volume appears in volume list');

    my $deleted = $vast->volumes->delete($volume->id);
    ok($deleted, 'delete request accepted');

    $volumes = $vast->volumes->list;
    ($found) = grep { defined $_->id && $_->id eq $volume->id } @{$volumes};
    ok(!$found, 'volume disappeared after delete');

    undef $volume;
};

done_testing;
