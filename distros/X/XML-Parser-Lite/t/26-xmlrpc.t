#!/bin/perl 

use strict;
use warnings;

use Test::More;

BEGIN { plan tests => 6 }

eval { require XMLRPC::Lite; require SOAP::Test; };

SKIP: {
    skip 'need XMLRPC::Lite and SOAP::Test', 6 if $@;

    my ( $a, $s, $r );

    my $proxy = 'http://betty.userland.com/RPC2';

    # ------------------------------------------------------

    $s = XMLRPC::Lite->proxy($proxy)->on_fault( sub { } );
    eval {
        $s->transport->timeout( $SOAP::Test::TIMEOUT = $SOAP::Test::TIMEOUT );
    };
    $r = $s->test_connection;

    unless ( defined $r && defined $r->envelope ) {
        skip 'need XMLRPC::Lite', 6 if $@;
        print "1..0 # Skip: ", $s->transport->status, "\n";
        exit;
    }

    # ------------------------------------------------------

    ok(
        (
            XMLRPC::Lite->proxy($proxy)
              ->call( 'examples.getStateStruct',
                { state1 => 12, state2 => 28 } )->result
              or ''
        ) eq 'Idaho,Nevada'
    );

    ok(
        (
            XMLRPC::Lite->proxy($proxy)->call( 'examples.getStateName', 21 )
              ->result
              or ''
        ) eq 'Massachusetts'
    );

    ok(
        (
            XMLRPC::Lite->proxy($proxy)
              ->call( 'examples.getStateNames', 21, 22, 23, 24 )->result
              or ''
        ) =~ /Massachusetts\s+Michigan\s+Minnesota\s+Mississippi/
    );

    $s =
      XMLRPC::Lite->proxy($proxy)->call( 'examples.getStateList', [ 21, 22 ] );
    ok( ( $s->result or '' ) eq 'Massachusetts,Michigan' );
    ok( !defined $s->fault );
    ok( !defined $s->faultcode );

    print "XMLRPC autodispatch and fault check test(s)...\n";

    eval "use XMLRPC::Lite +autodispatch =>
    proxy => '$proxy',
  ; 1" or die;

    $r = XMLRPC->getStateName(21);

    # Looks like this test requires saving away the result of the
    # last call - which introduces a memory leak (removed in 0.70_01)
    # Looks like we'll have to introduce different Fault handling...
    #
    #
    print "#TODO: fix fault handling ...\n";
    last;
    $r = XMLRPC::Lite->self->call;

    ok( ref $r->fault eq 'HASH' );
    ok( $r->fault->{faultString} =~ /Can't evaluate/ );
    ok( $r->faultstring =~ /Can't evaluate/ );
    ok( $r->faultcode == 7 );

}
