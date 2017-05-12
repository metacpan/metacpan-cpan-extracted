#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use WebService::Box;
use WebService::Box::Session;
use WebService::Box::File;

use t::MockRequest;

my ($error, $warning) = ('','');

my $session = WebService::Box::Session->new(
    client_id     => 123,
    client_secret => 'abcdef123',
    refresh_token => 'hefe0815',
    redirect_uri  => 'http://localhost',
    box           => WebService::Box->new(
        on_error => sub { $error   .= $_[0] },
        on_warn  => sub { $warning .= $_[0] },
    ),
);

{
    # a plain file object without any data
    my $file   = WebService::Box::File->new( session => $session );
    my $folder = $file->parent;

    ok !$folder, 'no folder object';
    is $error, 'no id for parent found and no file id exists', 'no folder object (no file id)';

    $error = '';
}

{
    # a plain file object with id
    my $file   = WebService::Box::File->new( id => 123, session => $session );
    my $folder = $file->parent;

    isa_ok $folder, 'WebService::Box::Folder';
    is $error, '', 'empty error';
    is $folder->name, 'folder_1', 'parent of file 123';
    is $folder->id, 1, 'parents id';

    $error = '';
}

done_testing();
