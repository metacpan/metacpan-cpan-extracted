#!perl
use strict;
use warnings;
use Test::More tests => 4;
use Test::Mock::LWP::Dispatch;

my $ua = LWP::UserAgent->new;
$ua->agent('custom useragent');
$ua->default_headers->authorization_basic( 'antipasta', 'password' );
$ua->default_header(foo => 'bar');
$ua->map(
    'http://localhost',
    sub {
        my $req = shift;
        is $req->header('user-agent'), 'custom useragent',
          'Got correct useragent header';
        ok $req->header('Authorization'), 'Got authorization header';
        is scalar( $req->headers->authorization_basic ), 'antipasta:password',
          'Contents of authorization_basic are correct';
        is $req->header('foo'),'bar', 'Got custom header foo';

        return HTTP::Response->new( 200, 'OK');
    }
);
$ua->get('http://localhost');
done_testing;
