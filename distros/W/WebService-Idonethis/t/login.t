#!/usr/bin/perl -w

BEGIN {
    unless ($ENV{AUTHOR_TESTING}) {
        require Test::More;
        Test::More::plan(skip_all => 'these tests are for testing by the author');
    }
}

use 5.010;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Config::Tiny;
use WebService::Idonethis;

my $config = Config::Tiny->read("$ENV{HOME}/.idonethisrc");

if (not $config->{auth}{user}) {
    plan skip_all => "No login data in ~/.idonethisrc";
}

throws_ok 
    { WebService::Idonethis->new( user => "notauser", pass => "notapass") }
    qr{Login.*failed},
    "Login fails with bogus credentials"
;

my $idt = WebService::Idonethis->new(
    user => $config->{auth}{user},
    pass => $config->{auth}{pass},
);

ok(1, "Login successful");

if ($config->{auth}{user} eq "pjf") {
    # Author tests. :)

    my $dones = $idt->get_day("2013-02-05");

    is($dones->[1]{text}, "Returned to Melbourne.", "Test specific done");
}

done_testing;
