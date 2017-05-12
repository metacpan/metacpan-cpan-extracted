#!/usr/bin/perl 

use strict; 
use warnings; 

use Test::More; 
use WebService::Face::Store; 
use JSON;

unless ( $ENV{FACE_API_KEY} && $ENV{FACE_API_SECRET}) {
    warn("\n\nSet FACE_API_KEY, FACE_API_SECRET for testing\n\n");
    plan skip_all => ' Set environment vars for API access';
}

plan tests => 15;

my $store;
eval { $store = WebService::Face::Store->new({}) };
ok( !$@, "new()" );

isa_ok( $store, 'WebService::Face::Store' );

can_ok($store, 'create_user');
my $exist = $store->create_user('test@webservice.face.com');

can_ok($store, 'list_users');
my @users = $store->list_users('test@webservice.face.com');
is_deeply (\@users, ['test@webservice.face.com']);

can_ok($store, 'delete_user');
my $deleted = $store->delete_user('test@webservice.face.com');

@users = $store->list_users('test@webservice.face.com');
is_deeply (\@users, []);

my $url1 ='';
can_ok($store, 'train_user');
$store->train_user('test@webservice.face.com', $url1);

# Get the user reliability
$store->train_user('test@test.com');
# Add a photo
my $training1 = $store->train_user('test@test.com', 'http://photo1');
ok ($training1 > 0, 'Training for this user completed above 80%');

# Add another photo
my $training2 = $store->train_user('test@test.com', 'http://photo2');
ok ($training2 > $training1, 'Training improved');

can_ok($store, 'get_user');
can_ok($store, 'set_user');
can_ok($store, 'recognize_user');

can_ok($store, 'save');
can_ok($store, 'restore');
