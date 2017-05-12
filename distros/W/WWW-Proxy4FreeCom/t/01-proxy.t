#!perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('Carp');
    use_ok('URI');
    use_ok('LWP::UserAgent');
    use_ok('Mojo::DOM');
    use_ok('Class::Accessor::Grouped');
    use_ok( 'WWW::Proxy4FreeCom' );
}

diag( "Testing WWW::Proxy4FreeCom $WWW::Proxy4FreeCom::VERSION, Perl $], $^X" );

my $o = WWW::Proxy4FreeCom->new( timeout => 10, debug=> 1 );
isa_ok($o,'WWW::Proxy4FreeCom');
can_ok($o,qw(
    new
    get_list
    list
    error
    ua
    debug
    _parse_proxy_list
    _set_error
));
isa_ok($o->ua, 'LWP::UserAgent');
SKIP: {
    my $list_ref = $o->get_list;
    unless ( $list_ref ) {
        if ( $o->error =~ /Parse error/ ) {
            BAIL_OUT('Parse error occured: ' . $o->error
                . 'If this error repeats, the module is very likely broken'
                . 'Please inform the author at zoffix@cpan.org'
            );
        }
        diag "Got error: " . $o->error;
        skip 'Some error', 12;
    }

    diag "\nGot " . @$list_ref . " proxies in a list\n\n";
    @$list_ref or BAIL_OUT('We got zero proxies in the list.'
        . ' If that repeats, this module is very likely broken.'
        . 'Please inform the author at zoffix@cpan.org'
    );

    is( ref $list_ref, 'ARRAY', 'get_list() must return an arrayref' );

    my ($flail,$flail_keys) = (0,0);
    my %test;
    @test{qw/rating  country  access_time  uptime  online_since  last_test
        domain  features_hian  features_ssl
    /} = (0) x 9;

    my %test_res = (
        'domain' => qr/^[\w.-]+$/,
        'rating' => qr/^[\d-]+$/,
        'country' => qr/^[\w' ()-]+$/,
        'access_time' => qr/^([\d.]+|-)$/,
        'uptime' => qr/^(\d+|-)$/,
        'online_since' => qr/^[\w\s.-]+$/,
        'last_test' => qr/^[\w\s.-]+$/,
        'features_hian' => qr/^[01]$/,
        'features_ssl' => qr/^[01]$/,
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
}

done_testing();