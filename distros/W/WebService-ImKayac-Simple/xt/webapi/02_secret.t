#!perl

use strict;
use warnings;
use utf8;
use WebService::ImKayac::Simple;

use Test::More;

my $user     = $ENV{IM_KAYAC_SECRET_USER};
my $password = $ENV{IM_KAYAC_SECRET};
plan skip_all => "IM_KAYAC_SECRET_USER or IM_KAYAC_SECRET is not given." if !$user || !$password;

my $im = WebService::ImKayac::Simple->new(
    type     => 'secret',
    user     => $user,
    password => $password,
);

eval { $im->send("こんにちは") };
ok !$@;

done_testing;

