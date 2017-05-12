#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 9;

use_ok( 'WebService::FuncNet::Request' );
use_ok( 'WebService::FuncNet::Job' );
use_ok( 'WebService::FuncNet::JobStatus' );
use_ok( 'WebService::FuncNet::Results' );

my $ra_ref_proteins   = [ 'A3EXL0', 'Q8NFN7', 'O75865' ];
my $ra_query_proteins = [ 'Q9H8H3', 'Q5SR05', 'P22676' ];

isa_ok(
    my $r = WebService::FuncNet::Request->new(
        $ra_ref_proteins, $ra_query_proteins, 'test@example.com'
    ),
    'WebService::FuncNet::Request'
);

##
## returns a WebService::FuncNet::Job object

isa_ok( my $j = $r->submit(), 'WebService::FuncNet::Job' );

isa_ok( my $status = $j->status(), 'WebService::FuncNet::JobStatus' );

print "Status is initially " . $status->status() . "\n";

while ( $status->status() eq 'WORKING' ) {
    print "Status was WORKING, going back to sleep\n";
    sleep 30;
    $status = $j->status();
}

print "Status is " . $status->status() . "\n";

if ( $status ) {

    ##
    ## returns a WebService::FuncNet::Results object

    isa_ok( my $r = $j->results, 'WebService::FuncNet::Results' );

    if ( $r ) {
        ok( $r->as_xml, 'results are well defined' );
    }
}
else {
    die "status was undef, something horrible went wrong!\n";
}
