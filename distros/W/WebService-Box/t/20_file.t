#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use WebService::Box;
use WebService::Box::Session;

use_ok 'WebService::Box::File';

my $session = WebService::Box::Session->new(
    client_id     => 123,
    client_secret => 'abcdef123',
    refresh_token => 'hefe0815',
    redirect_uri  => 'http://localhost',
    box           => WebService::Box->new,
);

{
    # a plain file object without any data
    my $file = WebService::Box::File->new( session => $session );

    isa_ok $file, 'WebService::Box::File';
    can_ok $file, qw(
        upload download comment parent comments rebuild
    );

    TODO: {
        local $TODO = 'not all methods implemented';
        can_ok $file, qw(
            delete copy share thumbnail recover delete_permanent tasks
        );
    }
}

{
    # a basic file object with little data
    my $file = WebService::Box::File->new(
        id      => 123,
        session => $session,
        etag    => undef,
    );

    isa_ok $file, 'WebService::Box::File';
    is $file->id, 123, 'id (basic)';
    is $file->etag, undef, 'undef etag (basic)';
}

{
    # a basic file object with little data
    my $file = WebService::Box::File->new(
        id         => 123,
        session    => $session,
        etag       => undef,
        created_at => "2013-09-13T12:55:34",
    );

    isa_ok $file, 'WebService::Box::File';
    isa_ok $file->created_at, 'DateTime', 'coercion for created_at';
    is $file->created_at->dmy('-'), '13-09-2013', 'dmy (coerced)';
}

{
    require DateTime;

    # a basic file object with little data
    my $file = WebService::Box::File->new(
        id         => 123,
        session    => $session,
        etag       => undef,
        created_at => DateTime->new(
            year  => 2013,
            month => 9,
            day   => 13,
        ),
    );

    isa_ok $file, 'WebService::Box::File';
    isa_ok $file->created_at, 'DateTime', 'created_at';
    is $file->created_at->dmy('-'), '13-09-2013', 'dmy';
}

done_testing();
