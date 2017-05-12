#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Path::Tiny;
use W3C::SOAP::WADL::Parser;
use WWW::Mechanize;
use TryCatch;
use Data::Dumper qw/Dumper/;

my $app  = path($0)->parent->child('app.pl');
my $port = 4000;
my $pid  = fork;

if ( !defined $pid ) {
    plan skip_all => "Couldn't start test server! $!\n";
    exit 0;
}
elsif ( !$pid ) {
    # Keep test output clean by hiding server details
    close STDERR;
    open STDERR, '>', '/dev/null';
    close STDOUT;
    open STDOUT, '>', '/dev/null';

    $ENV{PORT} = $port;
    exec $app, 'daemon', '--listen', "http://*:$port";
}

sleep 1;
my $mech = WWW::Mechanize->new;
$mech->get("http://localhost:$port/wadl");
my $wadl = $mech->content;

if ( $mech->status != 200 || $wadl !~ m{^<application \s xmlns="http://wadl.dev}xms ) {
    plan skip_all => "Couldn't connect to the test server! $!\n";
    exit 0;
}

try {

    my $parser = get_parser();
    check_dynamic($parser);

}
catch ($e) {
    ok !$e, 'no errors';
    diag $e;
}

kill 9, $pid or diag "Error killing child! $!\n";
done_testing();

sub get_parser {
    $mech->get("http://localhost:$port/wadl");
    my $wadl = $mech->content;
    ok $wadl, 'Get the WADL text from the server'
        or diag $mech->status;

    my $parser = W3C::SOAP::WADL::Parser->new( string => $wadl );
    ok $parser, 'Get a parser object';

    my $orig = W3C::SOAP::WADL::Parser::load_wadl( "http://localhost:$port/wadl" );

    is $orig, W3C::SOAP::WADL::Parser::load_wadl( "http://localhost:$port/wadl" ), 'Values are cached';

    return $orig;
}

sub check_dynamic {
    my $wadl = shift;

    ok $wadl, 'Created new object';

    my ($res, $ping) = $wadl->ping_GET(
        'X_Request_ID'       => 1,
        'X_Request_DateTime' => 'now',
        'X_Request_TimeZone' => 'Z',
        'X_Partner_ID'       => 'test',
    );
    ok $ping, 'Get ping response';
    is $ping->X_Response_ID, 0, 'Get response id';
    is $ping->I_Response_ID, 1, 'Get response id';

    ($res, $ping) = $wadl->ping_POST(
        'X_Request_ID'       => 1,
        'X_Request_DateTime' => 'now',
        'X_Request_TimeZone' => 'Z',
        'X_Partner_ID'       => 'test',
    );
    ok $ping, 'Get ping response';
    is $ping->X_Response_ID, 1, 'Get response id';
    is $ping->Response_ID, 2, 'Get response id';

    ($res, $ping) = $wadl->ping_POST(
        'X_Request_ID'       => 1,
        'X_Request_DateTime' => 'now',
        'X_Request_TimeZone' => 'Z',
        'X_Partner_ID'       => 'test',
        'I_Status'           => 400,
    );
    ok $ping, 'Get ping 400 response';

    ($res, $ping) = $wadl->ping_POST(
        'X_Request_ID'       => 1,
        'X_Request_DateTime' => 'now',
        'X_Request_TimeZone' => 'Z',
        'X_Partner_ID'       => 'test',
        'I_Status'           => 401,
    );
    ok $ping, 'Get ping 401 response';
    is $res->{multi}, 'true', 'Get multi param';

    ($res, $ping) = $wadl->ping_POST(
        'X_Request_ID'       => 1,
        'X_Request_DateTime' => 'now',
        'X_Request_TimeZone' => 'Z',
        'X_Partner_ID'       => 'test',
        'I_Status'           => 402,
    );
    ok $ping, 'Get ping 402 response';
    is $res->{form}, '1', 'Get form param';

    ($res, $ping) = $wadl->ping_POST(
        'X_Request_ID'       => 1,
        'X_Request_DateTime' => 'now',
        'X_Request_TimeZone' => 'Z',
        'X_Partner_ID'       => 'test',
        'I_Status'           => 403,
    );
    ok $ping, 'Get ping 403 response';
    is $res->{url}, 'u', 'Get url param';

    ($res, $ping) = $wadl->ping_POST(
        'X_Request_ID'       => 1,
        'X_Request_DateTime' => 'now',
        'X_Request_TimeZone' => 'Z',
        'X_Partner_ID'       => 'test',
        'I_Status'           => 404,
    );
    ok $ping, 'Get ping 404 response';
    ok ref $res, 'get xml back'
        or diag Dumper $res, $ping;
}
