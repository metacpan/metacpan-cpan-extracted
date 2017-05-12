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
        on_error => sub { $error   .= $_[0]; die $_[0] },
        on_warn  => sub { $warning .= $_[0] },
    ),
);

{
    # a plain file object without any data
    my $file   = WebService::Box::File->new( session => $session );

    throws_ok
        { $file->rebuild }
        qr/cannot rebuild: file id does not exist/,
        'rebuild on id-less file fails';

    is $error, 'cannot rebuild: file id does not exist', 'no rebuild (no file id)';

    $error = '';

    throws_ok
        { $file->created_at }
        qr/invalid method call \(created_at\): file id does not exist, create a new object with id/,
        'rebuild via accessor on id-less file files';

    is $error,
        'invalid method call (created_at): file id does not exist, create a new object with id',
        'no rebuild via accessor (no file id)';

    $error = '';
}

{
    # a plain file object with id
    my $file   = WebService::Box::File->new( id => 88, session => $session );

    my $new = $file->rebuild;

    is $file->id, 88, 'id from rebuilt file (orig)';
    is $new->id, 88, 'id from rebuilt file (copy)';
    is $file->created_at->dmy('-'), '13-09-2013', 'created_at (orig)';
    is $new->created_at->dmy('-'), '13-09-2013', 'created_at (copy)';

    $error = '';
}

{
    # a plain file object with id
    my $file   = WebService::Box::File->new( id => 89, session => $session );

    my $created_at = $file->created_at;

    is $file->id, 89, 'id from rebuilt file (orig)';
    is $file->created_at->dmy('-'), '13-09-2013', 'created_at (orig)';
    is $created_at->dmy('-'), '13-09-2013', 'created_at (copy)';

    $error = '';
}

done_testing();
