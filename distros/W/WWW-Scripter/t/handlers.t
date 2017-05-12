#!perl -T

BEGIN {
 
}

use warnings;
use strict;
use Test::More eval 'use LWP::UserAgent 5.815;1'
 ? (tests => 5)
 : (skip_all => 'LWP::UserAgent 5.815 required for these tests');
use URI::file;

$^W = 0;

BEGIN {
    use_ok( 'WWW::Scripter', 'abort' );
}

is \&abort, \&WWW::Scripter::abort, 'abort export';

my $uri = URI::file->new_abs( 't/form_with_fields.html' )->as_string;

{
    my $mech = WWW::Scripter->new( cookie_jar => undef );
    my $initial_response = $mech->response;
    $mech->set_my_handler(request_prepare => sub { abort });
    $mech->get($uri);
    is $mech->response, $initial_response,
     'abort from within request handler';

    my $called;
    $mech->set_my_handler(request_prepare => sub { ++$called; return });
    $mech->get('about:blank');
    $called= 0;
    $mech->get('about:blank');
    is $called, 1, 'The handler is still there after _push_page_stack';
    $mech->back;
    $mech->get('about:blank');
    is $called, 2, 'It also survives _pop_page_stack.';
}
