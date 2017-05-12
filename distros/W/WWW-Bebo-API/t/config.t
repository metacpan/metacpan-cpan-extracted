#######################################################################
# $Date: 2007-07-11 07:21:31 -0700 (Wed, 11 Jul 2007) $
# $Revision: 146 $
# $Author: david.romano $
# ex: set ts=8 sw=4 et
#########################################################################
use Test::More tests => 8;
use WWW::Bebo::API;
use strict;
use warnings;

local %ENV;
my $api = WWW::Bebo::API->new;
for ( qw/api_key secret desktop session_key/ ) {
    is $api->$_, '', "$_ initialized";
}

my $fn = 'wfa';
open my $file, '>', $fn or die "Cannot write to '$fn'";
print { $file } <<"END_CONFIG";
WBA_API_KEY=1
WBA_SECRET=2
WBA_SESSION_KEY=3
WBA_DESKTOP=4   
END_CONFIG
close $file;

$api = WWW::Bebo::API->new( config => 'wfa' );
is $api->api_key, 1, 'api_key set';
is $api->secret, 2, 'secret set';
is $api->session_key, 3, 'session_key set';
is $api->desktop, 4, 'desktop set';

unlink 'wfa';
