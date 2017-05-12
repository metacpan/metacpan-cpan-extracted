#!/usr/bin/perl

use Event;
use Net::XMPP2::Connection;
use XML::CompileX::Transport::SOAPXMPP;

use Test::More tests => 18;

my %connections;
my $last_set_callback;
my $expecting = '';

# Let's override some methods to have a sane testing environment.
{   package Event;
    no warnings;
    sub loop {
        return;
    }
};
{   package main;
    no warnings;
    sub loop {
        return;
    }
};
{   package Net::XMPP2::Connection;
    no warnings;
    sub new {
        my $class = shift;
        my %data = @_;
        my $res = $data{resource};
        $connections{$res} = bless \%data, 'Test::XMPP2';
        return $connections{$res};
    }
};

{   package Test::XMPP2;
    sub connect {
        return 1;
    }
    sub reg_cb {
        my $self = shift;
        my %callbacks = @_;
        $self->{callbacks} = \%callbacks;
    }
    sub send_iq {
        my ($self, $type, $cb, $rb) = @_;
        our $iq_id ||= 0;
        $iq_id++;
        return unless $expecting eq 'iq';
        $last_set_callback = $cb;
        $rb->(Test::Node->new(id => $iq_id));
        return $iq_id;
    }
    sub send_message {
        my ($self, $jid, $type, $cb, %attr) = @_;
        return unless $expecting eq 'message';
        $last_set_callback = $cb;
    }
};

{   package Test::Writer;
    sub new {
        return bless {}, 'Test::Writer';
    }
    sub raw {
        my ($self, $data) = @_;
        $self->{data} = $data;
    }
}

{   package Test::Node;
    sub new {
        my $self = shift;
        my %args = @_;
        return bless \%args, 'Test::Node';
    }
    sub attr {
        return $_[0]->{$_[1]};
    }
    sub nodes { () };
    sub text { '<node>node</node>' };
}

my $conct = Net::XMPP2::Connection->new(resource => 'test');
my $trans = XML::CompileX::Transport::SOAPXMPP->new
  (connection => $conct,
   address => 'foo@jabber.org');

my $writer = Test::Writer->new();

my $send_iq = $trans->compileClient(kind => 'request-response');
my $send_message = $trans->compileClient(kind => 'one-way');

{
    $expecting = 'iq';
    $last_set_callback = undef;

    my ($output, $trace) = $send_iq->('FooBar', {});

    ok($last_set_callback, 'Message sent.');

    $last_set_callback->($writer) if $last_set_callback;

    is($writer->{data}, 'FooBar', 'Message content set.');
    like($output->toString, '/<node>node<\/node>/', 'Message response set.');

}
{
    $expecting = 'message';
    $last_set_callback = undef;

    my ($output, $trace) = $send_message->('BarBaz', {});

    ok($last_set_callback, 'Message sent.');

    $last_set_callback->($writer) if $last_set_callback;

    is($writer->{data}, 'BarBaz', 'Message content set.');
    ok(!$output, 'Message response empty.');

}
{
    $expecting = 'message';
    $last_set_callback = undef;

    $trans->force_stanza_types('message');

    my ($output, $trace) = $send_iq->('BuzBuz', {});

    ok($last_set_callback, 'Message sent.');

    $last_set_callback->($writer) if $last_set_callback;

    is($writer->{data}, 'BuzBuz', 'Message content set.');
    ok(!$output, 'Message response empty.');

}
{
    $expecting = 'iq';
    $last_set_callback = undef;

    $trans->force_stanza_types('iq');

    my ($output, $trace) = $send_message->('BzzBzz', {});

    ok($last_set_callback, 'Message sent.');

    $last_set_callback->($writer) if $last_set_callback;

    is($writer->{data}, 'BzzBzz', 'IQ content set.');
    ok(!$output, 'IQ response is undef when its forced.');

}
{
    $expecting = 'iq';
    $last_set_callback = undef;

    $trans->force_stanza_types('iq');
    $trans->wait_iq_reply(0);

    my ($output, $trace) = $send_message->('BzztBzzt', {});

    ok($last_set_callback, 'Message sent.');

    $last_set_callback->($writer) if $last_set_callback;

    is($writer->{data}, 'BzztBzzt', 'IQ content set.');
    ok(!$output, 'IQ response empty.');

    my $id = $trans->last_sent_iq_id;
    ok($id, 'Last message sent has an id.');

    my $node = $trans->consume_iq_reply($id);
    ok($node, 'Have reply content set.');

    my $text = undef;
    $text = $node->text if $node;

    is($text, '<node>node</node>', 'Consumed reply is sane.');
}
