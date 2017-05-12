#!/usr/bin/perl
use warnings;
use strict;

use Test::More;

BEGIN {
	use_ok( 'WWW::FreeProxyListsCom' );
}

my $o = WWW::FreeProxyListsCom->new(timeout => 10);

isa_ok($o, 'WWW::FreeProxyListsCom');
can_ok($o, qw(
        new error
        mech
        debug
        list
        filtered_list
        get_list
        filter
        _parse_list
        _set_error
     )
);

isa_ok( $o->mech, 'WWW::Mechanize' );

for my $list_type ( qw(elite anonymous x https standard ca fr us uk socks) ) {
    print "\nTesting the $list_type lists\n";
SKIP: {

    my $list_ref;

    eval { $list_ref = $o->get_list(type => $list_type); };
    if ($@){
        skip 'received error', 9;
    }

    print "Got " . @$list_ref . " proxies in $list_type list\n";

    is( ref $list_ref, 'ARRAY', 'get_list() returns an arrayref' );

    my ($flail,$flail_keys) = (0,0);
    my %test;
    @test{ qw(ip  port  is_https latency  country  last_test) } = (0) x 6;

    my %test_res = (
        # ZOMFG!! THIS IS NOT AN IP RE!!!
        ip        => qr#^((\d{1,3}\.){3}\d{1,3}|N/A)$#,
        port      => qr#^(\d+|N/A)$#,
        is_https  => qr#^(true|false|N/A)$#,
        country   => qr#^[\w./\s()'-]+$#,
        last_test =>
        qr#^( 1?\d/[1-3]?\d \s [12]?\d : [0-6]\d : [0-6]\d \s [ap]m|N/A)$#x,
        latency   => qr#^(\d+|N/A)$#,
    );

    for my $prox ( @$list_ref ) {
        ref $prox eq 'HASH' or $flail++;
        for ( keys %test ) {
            exists $prox->{$_} or $flail_keys++;
            $prox->{$_} =~ /$test_res{$_}/
                or ++$test{$_}
                and diag "Failed $_ regex test (value is: `$prox->{$_}`)";
        }
    }
    is( $flail, 0,
        "All elements of get_list() must be hashrefs ($flail of them aren't)"
    );
    is( $flail_keys, 0,
        qq|All "proxy" hashrefs must have all keys ($flail_keys are missing)|
    );

    for ( keys %test ) {
        is ( $test{$_}, 0, "test for $_ failed $test{$_} times" );
    }
}#/SKIP 
}

done_testing();
