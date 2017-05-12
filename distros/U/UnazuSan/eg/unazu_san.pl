#!/usr/bin/env perl
use 5.010;
use warnings;
use utf8;
use Encode qw/encode_utf8/;

use UnazuSan;

my $unazu_san = UnazuSan->new(
    host       => 'example.com',
    password   => 'xxxxxxxxxxx',
    enable_ssl => 1,
    join_channels => [qw/test/],
    respond_all   => 1,
);

$unazu_san->on_message(
    qr/^\s*unazu_san:/ => sub {
        my $receive = shift;
        $receive->reply('うんうん');
    },
    qr/(.)/ => sub {
        my ($receive, $match) = @_;
        say $match;
        say $receive->message;
    },
);

$unazu_san->on_command(
    help => sub {
        my ($receive, @args) = @_;
        $receive->reply('help '. ($args[0] || ''));
    }
);

$unazu_san->run;
