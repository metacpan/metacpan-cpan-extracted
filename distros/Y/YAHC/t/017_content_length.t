#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Temp qw/ :seekable /;
use Data::Dumper;
use YAHC qw/ yahc_conn_last_error /;
use EV;

my ($yahc, $yahc_storage) = YAHC->new;

my $default_tests = sub {
    my ($conn, $t) = @_;
    my $response = $conn->{response};

    is $response->{proto}, $t->{proto}, "$t->{name} - Protocol match";
    is $response->{status}, $t->{status}, "$t->{name} - Status code";
    is_deeply $response->{head}, $t->{headers}, "$t->{name} - Headers";
    is $response->{body}, $t->{body}, "$t->{name} - Body/content";
};

my @TESTS = (
    {
        name => "Simple request with content-length",
        proto => 'HTTP/1.1',
        status => '200',
        status_msg => 'OK',
        headers => {
            'server' => 'mock',
            'content-type' => 'text/plain',
            'content-length' => '230',
        },
        body => 'a' x 230,
        tests => $default_tests,
    },
    {
        name => "Simple request with smaller content-length",
        proto => 'HTTP/1.1',
        status => '200',
        status_msg => 'OK',
        headers => {
            'server' => 'mock',
            'content-type' => 'text/plain',
            'content-length' => '220',
        },
        body => 'a' x 230,
        tests => sub {
            my ($conn, $t) = @_;
            my $response = $conn->{response};

            is $response->{proto}, $t->{proto}, "$t->{name} - Protocol match";
            is $response->{status}, $t->{status}, "$t->{name} - Status code";
            is_deeply $response->{head}, $t->{headers}, "$t->{name} - Headers";
            is $response->{body}, 'a' x 220, "$t->{name} - Body/content";
        },
    },
    {
        name => "Simple request without content-length",
        proto => 'HTTP/1.1',
        status => '200',
        status_msg => 'OK',
        headers => {
            'server' => 'mock',
            'content-type' => 'text/plain',
        },
        body => 'a' x 230,
        tests => $default_tests,
    },
    {
        name => "Big request without content-length",
        proto => 'HTTP/1.1',
        status => '200',
        status_msg => 'OK',
        headers => {
            'server' => 'mock',
            'content-type' => 'text/plain',
        },
        body => 'big' x 23000,
        tests => $default_tests,
    },
    {
        name => "Request with a non-numeric content length",
        proto => 'HTTP/1.1',
        status => '200',
        status_msg => 'OK',
        headers => {
            'server' => 'mock',
            'content-type' => 'text/plain',
            'content-length' => 'fourty-two',
        },
        body => 'a' x 42,
        tests => sub {
            my ($conn, $t) = @_;
            my $response = $conn->{response};

            is $response->{proto}, $t->{proto}, "$t->{name} - Protocol match";
            is $response->{status}, $t->{status}, "$t->{name} - Status code";
            is_deeply $response->{head}, $t->{headers}, "$t->{name} - Headers";
            is $response->{body}, undef, "$t->{name} - Body/content (undef)";

            my ($err, $msg) = yahc_conn_last_error($conn);
            cmp_ok($err & YAHC::Error::RESPONSE_ERROR(), '==', YAHC::Error::RESPONSE_ERROR(), "$t->{name} - We got response error");
        },
    },
);


foreach my $t (@TESTS) {
    my $conn = $yahc->request({
        host => 'DUMMY',
        keep_timeline => 1,
        _test => 1,
    });

    my $f = File::Temp->new();
    my $fh= do {
        local $/ = undef;

        my $msg = join(
            "\x0d\x0a",
            join( " ", $t->{proto}, $t->{status}, $t->{status_msg} ),
            ( map "$_: $t->{headers}{$_}", keys %{ $t->{headers} } ),
            '',
            $t->{body}
        );
        print $f $msg;
        $f->flush;
        $f->seek(0, 0);
        $f;
    };

    $yahc->{watchers}{$conn->{id}} = {
        _fh => $fh,
        io  => $yahc->loop->io($fh, EV::READ, sub {})
    };

    $conn->{state} = YAHC::State::CONNECTED();
    $yahc->_set_read_state($conn->{id});
    $yahc->run;

    ok($conn->{state} == YAHC::State::COMPLETED(), "$t->{name} - YAHC state == completed")
        or diag("got:\n" . YAHC::_strstate($conn->{state}) . "\nexpected:\nSTATE_COMPLETED\ntimeline: " . Dumper($conn->{timeline}));

    $t->{tests}->($conn, $t);
}

done_testing;
