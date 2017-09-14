package WebService::Jandi::WebHook;
$WebService::Jandi::WebHook::VERSION = 'v0.0.1';
use strict;
use warnings;

use HTTP::Tiny;
use JSON qw/encode_json/;

=encoding utf8

=head1 NAME

WebService::Jandi::WebHook - Perl interface to Jandi Service Incoming Webhook

=head1 SYNOPSIS

    my $jandi = WebService::Jandi::WebHook->new('https://wh.jandi.com/connect-api/webhook/md5sum');
    my $msg = {
      body => '[[PizzaHouse]](http://url_to_text) You have a new Pizza order.',
      connectColor => '#FAC11B',
      connectInfo => [
        {
          title => 'Topping',
          description => 'Pepperoni',
        },
        {
          title => 'Location',
          description => 'Empire State Building, 5th Ave, New York',
          imageUrl => 'http://url_to_text'
        }
      ]
    };

    my $res = $jandi->request($msg);    # HTTP::Tiny response

    or

    my $res = $jandi->request('Hello, world');
    die "Failed!\n" unless $res->{success};

=head1 METHODS

=head2 new($webhook_url)

=cut

sub new {
    my ( $class, $webhook_url ) = @_;
    return unless $webhook_url;

    my $self = {
        url  => $webhook_url,
        http => HTTP::Tiny->new(
            default_headers => {
                agent          => 'WebService::Jandi::WebHook - Perl interface to Jandi Service Incoming Webhook',
                accept         => 'application/vnd.tosslab.jandi-v2+json',
                'content-type' => 'application/json',
            }
        ),
    };

    bless $self, $class;
    return $self;
}

=head2 request($message)

my $res = $self->request($message);

C<$message> is a simple string or hashref.

C<$res> is L<HTTP::Tiny> C<$response>.

Hashref format.

    {
      body => '[[PizzaHouse]](http://url_to_text) You have a new Pizza order.',
      connectColor => '#FAC11B',
      connectInfo => [
        {
          title => 'Topping',
          description => 'Pepperoni',
        },
        {
          title => 'Location',
          description => 'Empire State Building, 5th Ave, New York',
          imageUrl => 'http://url_to_text'
        }
      ]
    }

C<body> and simple string support markdown link format.

    [text](url)

=cut

sub request {
    my ( $self, $message ) = @_;
    return unless $message;
    ## TODO: $message validation

    $message = { body => $message } unless ref $message;
    my $json = encode_json($message);
    my $res  = $self->{http}->request(
        'POST',
        $self->{url},
        { content => $json }
    );

    return $res;
}

=head1 COPYRIGHT and LICENSE

The MIT License (MIT)

Copyright (c) 2017 Hyungsuk Hong

=cut

1;
