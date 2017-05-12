#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use Test::More tests => 12;

our %returns;

use_ok('YAWF::Request');

my $request = YAWF::Request->new(
    domain       => 'foo.bar',
    uri          => '/',
    method       => 'GET',
    documentroot => '.',
    error        => sub {
        $main::returns{error} .= join( '', @_ ) . "\n";
        return 1;
    },
    send_header => sub {
        $main::returns{header} ||= [];
        push @{ $main::returns{header} }, join( '', @_ );
        return 1;
    },
    send_body => sub {
        $main::returns{body} .= join( '', @_ );
        return 1;
    },
);
ok( defined($request), 'Create request' );
is( ref($request),          'YAWF::Request', 'Request type' );
is( $request->domain,       'foo.bar',       'Domain' );
is( $request->uri,          '/',             'Domain' );
is( $request->method,       'GET',           'Method' );
is( $request->documentroot, '.',             'Document root' );
ok( $request->error("TESTERROR"), 'Submit test error' );
is( $returns{error}, "TESTERROR\n", 'Check error handling' );
$returns{error} = undef;

# Check parent
my $yawf = $request->yawf;
is( $yawf->SINGLETON, $yawf, 'SINGLETON' );
ok( defined( $yawf->config ), 'config object' );
ok( defined( $yawf->reply ),  'reply object' );

#                $job->run or print "WARNING: Job returned with zero value!\n";
