#!/usr/bin/perl
use strict;
use utf8;
use warnings;
use WebService::Lingr;

binmode STDOUT, ":utf8";

my $nick = "WebService::Lingr/" . WebService::Lingr->VERSION;

my $lingr = WebService::Lingr->new(api_key => $ARGV[0]);
$lingr->call('room.enter', { id => 'lingr-perl', nickname => $nick });

my $ticket = $lingr->response->{ticket};
$lingr->call('room.say', { message => "Hello World", ticket => $ticket });
$lingr->call('room.say', { message => "日本語のテスト", ticket => $ticket });

my $counter = $lingr->response->{counter};
while (1) {
    $lingr->call('room.observe', { ticket => $ticket, counter => $counter });

    my $messages = $lingr->response->{messages} || [];
    for my $msg (@$messages) {
        print "$msg->{nickname}: $msg->{text} ($msg->{timestamp})\n";
    }
    $counter = $lingr->response->{counter};
}

