#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Temp qw/ :seekable /;
use Data::Dumper;
use YAHC;
use EV;

my ($yahc, $yahc_storage) = YAHC->new;
my $conn = $yahc->request({
    host => 'DUMMY',
    keep_timeline => 1,
    _test => 1,
});

my $f = File::Temp->new();
my $fh = do {
    local $/ = undef;
    my $msg = join(
        "\x0d\x0a",
        'HTTP/1.1 200 OK',
        'Date: Sat, 23 Nov 2013 23:10:28 GMT',
        'Last-Modified: Sat, 26 Oct 2013 19:41:47 GMT',
        'ETag: "4b9d0211dd8a2819866bccff777af225"',
        'Content-Type: text/html',
        'Server: Example',
        'Content-Length: 4',
        '',
        'OHAI'
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

ok($conn->{state} == YAHC::State::COMPLETED(), "check state")
    or diag("got:\n" . YAHC::_strstate($conn->{state}) . "\nexpected:\nSTATE_COMPLETED\ntimeline: " . Dumper($conn->{timeline}));

my $response = $conn->{response};
is $response->{proto}, "HTTP/1.1";
is $response->{status}, 200;
is $response->{body}, "OHAI";

is_deeply $response->{head}, {
    "Date" => "Sat, 23 Nov 2013 23:10:28 GMT",
    "Last-Modified" => "Sat, 26 Oct 2013 19:41:47 GMT",
    "ETag" => '"4b9d0211dd8a2819866bccff777af225"',
    "Content-Type" => "text/html",
    "Content-Length" => "4",
    "Server" => "Example",
};

done_testing;
