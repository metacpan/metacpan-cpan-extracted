#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use WebService::Box;

use_ok 'WebService::Box::Session';

throws_ok { WebService::Box::Session->new }
    qr/Missing .* client_id, client_secret, redirect_uri, refresh_token/,
    'new object without params dies';

throws_ok { WebService::Box::Session->new( client_id => 123 ) }
    qr/Missing .* client_secret, redirect_uri, refresh_token/,
    'new object with client_id only dies';
throws_ok {
        WebService::Box::Session->new(
            client_id => 123,
            client_secret => 'abcdef123',
        );
    }
    qr/Missing .* redirect_uri, refresh_token/,
    'new object with client_id and client_secret only dies';

my $ob = WebService::Box::Session->new(
    client_id     => 123,
    client_secret => 'abcdef123',
    refresh_token => 'hefe0815',
    redirect_uri  => 'http://localhost',
    box           => WebService::Box->new,
);

isa_ok $ob, 'WebService::Box::Session', 'new object created';

can_ok $ob, qw/file folder refresh check/;

my $folder = $ob->folder;
isa_ok $folder, 'WebService::Box::Folder';

my $file = $ob->file;
isa_ok $file, 'WebService::Box::File';

done_testing();
