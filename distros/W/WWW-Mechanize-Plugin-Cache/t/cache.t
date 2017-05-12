#!/usr/bin/perl -w
use strict;
use FindBin;

BEGIN { delete @ENV{ qw( http_proxy HTTP_PROXY ) }; }

use Test::More tests => 8;
use_ok( 'WWW::Mechanize::Pluggable' );

my $agent = WWW::Mechanize::Pluggable->new(cache=>1);
isa_ok( $agent, "WWW::Mechanize::Pluggable" );

SKIP: {
    eval { require HTTP::Daemon; };
    skip "HTTP::Daemon required to test the referrer header",10 if $@;

    # We want to be safe from non-resolving local host names
    delete $ENV{HTTP_PROXY};

    # Now start a fake webserver, fork, and connect to ourselves
    my $command = qq'"$^X" "$FindBin::Bin/cache-server"';
    if ($^O eq 'VMS') {
        $command = qq'mcr $^X t/cache-server';
    }

    open SERVER, "$command |" or die "Couldn't spawn fake server: $!";
    sleep 1; # give the child some time
    my $url = <SERVER>;
    chomp $url;

    $agent->get( $url );
    is($agent->status, 200, "Got first page") or diag $agent->res->message;
    is($agent->content, "Referer: ''", "First page gets sent with empty referrer");

    $agent->get( $url );
    is($agent->status, 200, "Got second page") or diag $agent->res->message;
    isnt($agent->content, "Referer: '$url'", "Referer not sent for cached url");
    is($agent->content, "Referer: ''", "cached re-get still has empty referrer");
};

SKIP: {
    eval "use Test::Memory::Cycle";
    skip "Test::Memory::Cycle not installed", 1 if $@;

    memory_cycle_ok( $agent, "No memory cycles found" );
}

END {
    close SERVER;
};
