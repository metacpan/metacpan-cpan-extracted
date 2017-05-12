#!perl

use strict;
use warnings;
use utf8;
use WebService::ImKayac::Simple;

use Test::More;

my $user     = $ENV{IM_KAYAC_PASSWORD_USER};
my $password = $ENV{IM_KAYAC_PASSWORD};
plan skip_all => "IM_KAYAC_PASSWORD_USER or IM_KAYAC_PASSWORD is not given." if !$user || !$password;

my $im = WebService::ImKayac::Simple->new(
    type     => 'password',
    user     => $user,
    password => $password,
);

eval { $im->send("こんにちは") };
ok !$@;

done_testing;

