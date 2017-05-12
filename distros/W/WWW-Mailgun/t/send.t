#!/usr/bin/perl

use strict;
use warnings;

use LWP::UserAgent;
use JSON;
use Test::MockModule;
use Test::More;
use Test::Differences;
use WWW::Mailgun;

my $msg = {
    'from'        => "sender\@acme.com",
    'to'          => "recipient\@acme.com",
    'subject'     => "Hello, World",
    'text'        => "MailGun is a set of powerful APIs that enable you to ".
                     "send, receive and track email effortlessly.",
    'attachments' => [ 'hello.txt', 'world.xml' ],
    'o:tag'       => [ 'perl', 'mailgun', 'ruby', 'python' ],
};

my $expect = {
    'from'       => [ $msg->{from} ],
    'to'         => [ $msg->{to} ],
    'subject'    => [ $msg->{subject} ],
    'text'       => [ $msg->{text} ],
    'attachment' => [ [ 'hello.txt' ], [ 'world.xml' ] ],
    'o:tag'      => [ 'perl', 'mailgun', 'ruby' ], # spliced
};

_send_and_assert($msg, $expect);

$msg = {
    to => 'some_email@gmail.com',
    subject => 'hello',
    html => '<html><h3>hello</h3><strong>world</strong></html>',
    attachment => ['hello.txt']
};

my $extra_mg_attrs = {
    from => "sender\@acme.com",
};

$expect = {
    'from'       => [ $extra_mg_attrs->{from} ],
    'to'         => [ $msg->{to} ],
    'subject'    => [ $msg->{subject} ],
    'html'       => [ $msg->{html} ],
    'text'       => [ '' ],
    'attachment' => [ [ 'hello.txt' ] ],
};

_send_and_assert($msg, $expect, $extra_mg_attrs);

# Module users shouldn't have to know that attachments need to be in an array.
$msg->{attachment} = 'hello.txt';
_send_and_assert($msg, $expect, $extra_mg_attrs);

done_testing;

sub _send_and_assert {
    my ($msg, $expect, $extra_mg_attrs) = @_;

    WWW::Mailgun->new({
        key    => 'key-3ax6xnjp29jd6fds4gc373sgvjxteol0',
        domain => 'samples.mailgun.org',
        ua     => _mock_ua($expect),
        %{ $extra_mg_attrs || {} },
    })->send($msg);
}

sub _mock_ua {
    my $ua = new Test::MockModule('LWP::UserAgent');
    $ua->mock(post => sub {
        my ($self, $uri, %headers_and_content) = @_;

        is(
            $uri,
            "https://api.mailgun.net/v2/samples.mailgun.org/messages",
            "URI is correct"
        );

        is(
            $headers_and_content{Content_Type},
            "multipart/form-data",
            "Content-Type is correct",
        );

        my $hash = _form_data_to_hash($headers_and_content{Content});
        eq_or_diff($hash, $expect, "Content is correct");
        return HTTP::Response->new(200, "OK", [], to_json({}));
    });

    return $ua;
}

sub _form_data_to_hash {
    my $form_data = shift;
    my $hash = {};
    while ( @$form_data ) {
        my $key = shift @$form_data;
        my $value = shift @$form_data;
        $hash->{$key} ||= [];
        push @{$hash->{$key}}, $value;
    }

    return $hash;
}
