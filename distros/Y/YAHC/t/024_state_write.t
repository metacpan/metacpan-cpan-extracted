#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Temp qw/ :seekable /;
use Data::Dumper;
use YAHC;
use EV;

my $CRLF = "\x0d\x0a";

my ($yahc, $yahc_storage) = YAHC->new;
my $conn = $yahc->request({
    host   => 'www.example.com',
    method => 'GET',
    head   => [ 'User-Agent' => 'YAHC' ],
    keep_timeline => 1,
    _test => 1
});

my $fh = File::Temp->new();
$yahc->{watchers}{$conn->{id}} = {
    _fh => $fh,
    io  => $yahc->loop->io($fh, EV::WRITE, sub {})
};

$conn->{state} = YAHC::State::CONNECTED();
$conn->{selected_target}[0] = 'www.example.com';
$yahc->_set_write_state($conn->{id});
$yahc->run(YAHC::State::READING(), $conn->{id});

ok($conn->{state} == YAHC::State::READING(), "check state")
    or diag("got:\n" . YAHC::_strstate($conn->{state}) . "\nexpected:\nSTATE_READING\ntimeline: " . Dumper($conn->{timeline}));

$fh->flush;
$fh->seek(0, 0);
$fh->read(my $content, 1024);

is $content, join($CRLF, 'GET / HTTP/1.1',
                         'User-Agent: YAHC',
                         'Host: www.example.com',
                         '', '');
done_testing;
