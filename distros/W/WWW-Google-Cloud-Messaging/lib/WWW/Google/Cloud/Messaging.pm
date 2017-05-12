package WWW::Google::Cloud::Messaging;

use strict;
use warnings;
use 5.008_001;

use Carp qw(croak);
use LWP::UserAgent;
use LWP::ConnCache;
use HTTP::Request;
use JSON qw(encode_json);
use Class::Accessor::Lite (
    new => 0,
    rw  => [qw/ua api_url api_key/],
);

use WWW::Google::Cloud::Messaging::Response;

our $VERSION = '0.06';

our $API_URL = 'https://gcm-http.googleapis.com/gcm/send';

sub new {
    my ($class, %args) = @_;
    croak 'Usage: WWW::Google::Cloud::Messaging->new(api_key => $api_key)' unless defined $args{api_key};

    $args{ua}      ||= LWP::UserAgent->new(agent => __PACKAGE__.'/'.$VERSION, conn_cache => LWP::ConnCache->new);
    $args{api_url} ||= $API_URL;

    bless { %args }, $class;
}

sub send {
    my ($self, $payload) = @_;
    croak 'Usage: $gcm->send(\%payload)' unless ref $payload eq 'HASH';

    my $res = $self->ua->request($self->build_request($payload));
    return WWW::Google::Cloud::Messaging::Response->new($res);
}

sub build_request {
    my ($self, $payload) = @_;
    croak 'Usage: $gcm->build_request(\%payload)' unless ref $payload eq 'HASH';

    if (exists $payload->{delay_while_idle}) {
        $payload->{delay_while_idle} = $payload->{delay_while_idle} ? JSON::true : JSON::false;
    }

    my $req = HTTP::Request->new(POST => $self->api_url);
    $req->header(Authorization  => 'key='.$self->api_key);
    $req->header('Content-Type' => 'application/json; charset=UTF-8');
    $req->content(encode_json $payload);
    return $req;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

WWW::Google::Cloud::Messaging - Google Cloud Messaging (GCM) Client Library

=head1 SYNOPSIS

  use WWW::Google::Cloud::Messaging;

  my $api_key = 'Your API Key';
  my $gcm = WWW::Google::Cloud::Messaging->new(api_key => $api_key);

  my $res = $gcm->send({
      registration_ids => [ $reg_id, ... ],
      collapse_key     => $collapse_key,
      data             => {
        message => 'blah blah blah',
      },
  });

  die $res->error unless $res->is_success;

  my $results = $res->results;
  while (my $result = $results->next) {
      my $reg_id = $result->target_reg_id;
      if ($result->is_success) {
          say sprintf 'message_id: %s, reg_id: %s',
              $result->message_id, $reg_id;
      }
      else {
          warn sprintf 'error: %s, reg_id: %s',
              $result->error, $reg_id;
      }

      if ($result->has_canonical_id) {
          say sprintf 'reg_id %s is old! refreshed reg_id is %s',
              $reg_id, $result->registration_id;
      }
  }

=head1 DESCRIPTION

WWW::Google::Cloud::Messaging is a Google Cloud Messaging (GCM) client library,
which implements web application servers.

Currently this supports JSON API.

SEE ALSO L<< http://developer.android.com/guide/google/gcm/gcm.html#send-msg >>.

=head1 METHODS

=head2 new(%args)

Create a WWW::Google::Cloud::Messaging instance.

  my $gcm = WWW::Google::Cloud::Messaging->new(api_key => $api_key);

Supported options are:

=over

=item api_key : Str

Required. Set your API key.

For more information, please check L<< http://developer.android.com/guide/google/gcm/gs.html#access-key >>.

=item api_url : Str

Optional. Default values is C<< $WWW::Google::Cloud::Messaging::API_URL >>.

=item ua : LWP::UserAgent

Optional. Set a custom LWP::UserAgent instance if needed.

=back

=head2 build_request(\%payload)

Returns HTTP::Request suitable for sending with arbitrary HTTP client avalaible
on CPAN. Response can than be decoded using C<< WWW::Google::Cloud::Messaging::Response >>.

  my $res = $gcm->send({
      registration_ids => [ $reg_id ], # must be arrayref
      collapse_key     => '...',
      data             => {
          message   => 'xxxx',
          score     => 12345,
          is_update => JSON::true,
      },
  });

The possible options are as follows:

=over

=item registration_ids : ArrayRef

A string array with the list of devices (registration IDs) receiving the message. It must contain at least 1 and at most 1000 registration IDs. To send a multicast message, you must use JSON. For sending a single message to a single device, you could use a JSON object with just 1 registration id, or plain text (see below). Required.

=item collapse_key : Str

An arbitrary string (such as "Updates Available") that is used to collapse a group of like messages when the device is offline, so that only the last message gets sent to the client. This is intended to avoid sending too many messages to the phone when it comes back online. Note that since there is no guarantee of the order in which messages get sent, the "last" message may not actually be the last message sent by the application server. See Advanced Topics for more discussion of this topic. Optional.

=item data : Str

A JSON-serializable object whose fields represents the key-value pairs of the message's payload data. Optional.

=item delay_while_idle : Boolean

If included, indicates that the message should not be sent immediately if the device is idle. The server will wait for the device to become active, and then only the last message for each collapse_key value will be sent. Optional. The default value is false, and must be a JSON boolean.

=item time_to_live : Int

How long (in seconds) the message should be kept on GCM storage if the device is offline. Optional (default time-to-live is 4 weeks, and must be set as a JSON number).

=item restricted_package_name : Str

A string containing the package name of your application. When set, messages will only be sent to registration IDs that match the package name. Optional.

=item dry_run : Boolean

If included, allows developers to test their request without actually sending a message. Optional. The default value is false, and must be a JSON boolean.

=back

=head2 send(\%payload)

Build request using C<build_request> and send message to GCM. Returns C<< WWW::Google::Cloud::Messaging::Response >> instance.

The above is just a copy of the official GCM description and so could be old. You should check the latest information in L<< http://developer.android.com/guide/google/gcm/gcm.html#send-msg >>.

=head1 AUTHOR

xaicron E<lt>xaicron@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2012 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<< WWW::Google::Cloud::Messaging::Response >>

=cut
