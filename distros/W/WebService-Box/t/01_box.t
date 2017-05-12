#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Warn;

use_ok 'WebService::Box';

{
    my $box = WebService::Box->new;
    isa_ok $box, 'WebService::Box';

    can_ok $box, qw/create_session error warn/;

    # standard api_url
    is $box->api_url, "", 'standard api_url';

    # standard upload_url
    is $box->upload_url, "", 'standard upload_url';
}

{
    # set an invalid value for on_error
    throws_ok
        { WebService::Box->new( on_error => 'test' ) }
        qr/invalid value for 'on_error'/,
        'invalid value for on_error (string)';

    throws_ok
        { WebService::Box->new( on_error => {} ) }
        qr/invalid value for 'on_error'/,
        'invalid value for on_error (hashref)';
}

{
    # set an invalid value for on_warn
    throws_ok
        { WebService::Box->new( on_warn => 'test' ) }
        qr/invalid value for 'on_warn'/,
        'invalid value for on_warn (string)';

    throws_ok
        { WebService::Box->new( on_warn => {} ) }
        qr/invalid value for 'on_warn'/,
        'invalid value for on_warn (hashref)';
}

{
    # set new values for urls
    my $box = WebService::Box->new(
        api_url => 'http://localhost/',
        upload_url => 'http://localhost/upload',
    );

    is $box->api_url, 'http://localhost/', 'new api_url';
    is $box->upload_url, 'http://localhost/upload', 'new upload_url';
}

{
    my $warning = '';
    my $error   = '';

    # set new warn and error handler
    my $box = WebService::Box->new(
        on_warn  => sub { $warning .= $_[0] },
        on_error => sub { $error   .= $_[0] },
    );

    $box->error( 'testerror' );
    $box->warn( 'testwarning' );

    is $error, 'testerror', 'testerror';
    is $warning, 'testwarning', 'testwarning';
}

{
    # set new warn and error handler
    my $box = WebService::Box->new;

    throws_ok
        { $box->error( 'testerror' ); }
        qr/testerror/,
        'standard error dies';

    warning_like
        { $box->warn( 'testwarning' ); }
        qr/testwarning/,
        'standard warning does not die';
}

done_testing();

