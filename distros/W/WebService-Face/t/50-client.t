#!/usr/bin/perl 

use strict; 
use warnings; 

use Test::More; 
use WebService::Face::Client; 
use JSON;

unless ( $ENV{FACE_API_KEY} && $ENV{FACE_API_SECRET}) {
    warn("\n\nSet FACE_API_KEY, FACE_API_SECRET for testing\n\n");
    plan skip_all => ' Set environment vars for API access';
}

plan tests => 19;

my $client;
eval { $client = WebService::Face::Client->new() };
ok( !$@, "new()" );

isa_ok( $client, 'WebService::Face::Client' );

########################################################################
#                   Client API
########################################################################

can_ok( $client, "faces_recognize" );
can_ok( $client, "faces_train" );
can_ok( $client, "faces_status" );

can_ok( $client, "tags_get" );
can_ok( $client, "tags_add" );
can_ok( $client, "tags_save" );
can_ok( $client, "tags_remove" );

can_ok( $client, "account_limits" );
can_ok( $client, "account_users" );

########################################################################
#                   helper functions
########################################################################


my $client_h = WebService::Face::Client->new({api_key => 'key', api_secret => 'secret'}); 
is($client_h->_get_credential_parameters(),'&api_key=key&api_secret=secret');
$client_h = WebService::Face::Client->new(); 
is($client_h->_get_credential_parameters(),'&api_key='.$ENV{FACE_API_KEY}.'&api_secret='.$ENV{FACE_API_SECRET});


########################################################################
#                   Face recognition scenario
########################################################################

my @tags = $client->faces_detect(
    { urls => "http://img.clubic.com/03520176-photo-kevin-polizzi-fondateur-jaguar-network.jpg,http://media.linkedin.com/mpr/pub/image-ydXbyfluDqrF4odQH8fDyBF07ONcpJdQHNaYyXk1s4K8Dk6Q/kevin-polizzi.jpg,http://experts-it.fr/files/2011/01/Jaguar-Kevin-Polizzi.jpg,http://www.jaguar-network.com/jn/templates/images/img57.jpg" }
);
my $ids = join ",", map {$_->tid} @tags;
my @st = $client->tags_save(
     { tids => $ids,uid => 'kevin.polizzi@face-client-perl' }
);
is ($client->response->status,"success", "Test for error code");
@tags = $client->tags_get( { uids => 'kevin.polizzi@face-client-perl' } );
cmp_ok($#st,'==',$#tags,"Get saved tags");

my @users = $client->account_users( { namespaces => 'face-client-perl' } );
cmp_ok($#users ,"==", 0,"Zero user before training");
$client->faces_train( { uids => 'kevin.polizzi@face-client-perl' } );
@users = $client->account_users( { namespaces => 'face-client-perl' } );
is_deeply(@users,('kevin.polizzi@face-client-perl'),'users are the same');
@tags = $client->faces_recognize(
    { 
        urls => "http://img.clubic.com/03520176-photo-kevin-polizzi-fondateur-jaguar-network.jpg",
        uids => 'kevin.polizzi@face-client-perl'
    }
);
ok ($tags[0]->recognized, 'User recognized');
@tags = $client->faces_recognize(
    {
    urls => 'http://img2.imagesbn.com/images/137400000/137404562.JPG', 
    uids => 'kevin.polizzi@face-client-perl'
    }
);
ok (!$tags[0]->recognized, 'Bad user NOT recognized');
