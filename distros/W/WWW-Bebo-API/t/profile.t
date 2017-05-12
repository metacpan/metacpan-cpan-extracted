#######################################################################
# $Date: 2007-06-28 13:05:21 -0700 (Thu, 28 Jun 2007) $
# $Revision: 120 $
# $Author: david.romano $
# ex: set ts=8 sw=4 et
#########################################################################
use Test::More;
use WWW::Bebo::API;
use strict;
use warnings;

BEGIN {
    if ( 3 != grep defined,
        @ENV{qw/WBA_API_KEY_TEST WBA_SECRET_TEST WBA_SESSION_KEY_TEST/} )
    {
        plan skip_all => 'Live tests require API key, secret, and session';
    }
    plan tests => 3;
}

my $api = WWW::Bebo::API->new( app_path => 'test' );

my $fbml_orig = $api->profile->get_fbml();
my $time      = time();
ok $api->profile->set_fbml( markup => $time ), 'set fbml';
like $api->profile->get_fbml(), qr{\A <fb:fbml [^>]+ >$time</fb:fbml> \z }xms,
    'get fbml';
ok $api->profile->set_fbml( markup => $fbml_orig ), 'reset fmbl';
