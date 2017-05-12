#!perl

use strict;
use warnings;
use utf8;
use WebService::ImKayac::Simple;

use Test::More;

my $user = $ENV{IM_KAYAC_NONE_USER};
plan skip_all => "IM_KAYAC_NONE_USER is not given." unless $user;

my $im = WebService::ImKayac::Simple->new(
    user => $user,
);

eval { $im->send("こんにちは") };
ok !$@;

done_testing;

