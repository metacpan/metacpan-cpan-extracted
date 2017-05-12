package WebService::Prowl::AnyEventHTTP;
use warnings;
use strict;
use base qw(WebService::Prowl);
use AnyEvent::HTTP;

sub new {
    my $class = shift;
    my %params = @_;
    my $on_error   = delete $params{on_error};
    my $self = $class->SUPER::new(%params);
    $self->{on_error} = $on_error;
    ## $AnyEvent::HTTP::USERAGENT = $self->ua->agent;
    $self;
}

sub add {
    my ( $self, %params ) = @_;
    my $on_error = delete $params{on_error} || $self->{on_error} || sub {};
    my $url = $self->_build_url('add', %params);
    $self->_send_request($url, on_error => $on_error);
}

sub verify {
    my ($self, %params) = @_;
    my $on_error = delete $params{on_error} || $self->{on_error} || sub {};
    my $url = $self->_build_url('verify');
    $self->_send_request($url, on_error => $on_error);
}

sub _send_request {
    my ( $self, $url, %params) = @_;
    my $on_error = delete $params{on_error} || sub {};
    http_get $url,
        sub {
            my ($body, $hdr) = @_;
            my $data = $self->_xmlin($body);
            unless ($hdr->{Status} =~ /^[2]/) {
                $self->{error} =
                    $data->{error}
                  ? $data->{error}{code} . ': ' . $data->{error}{content}
                  : '';
                $on_error->($self->error, $url, $body, $hdr);
            }
        }
    ;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

WebService::Prowl::AnyEventHTTP - a sub class of WebService::Prowl sending http requests by using AnyEvent::HTTP 

=head1 SYNOPSIS
=for test_synopsis
my($ws,$apikey);

  use WebService::Prowl::AnyEventHTTP;
  my $ws = WebService::Prowl::AnyEventHTTP->new(apikey => $apikey, on_error => sub {warn $_[0]})

  $ws->add('event' => $event, application => $application, description => $description);

=head1 DESCRIPTION

WebService::Prowl::AnyEvent is a sub class of WebService::Prowl to use AnyEvent::HTTP non-blocking http client

=head1 SYNOPSIS
=for test_synopsis
my($ws,$apikey);

This module aims to be a implementation of a interface to the Prowl Public API by using AnyEvent::HTTP non-blocking http client library

    my $ws = WebService::Prowl::AnyEventHTTP->new(apikey => $apikey, on_error => sub {warn $_[0]});
    
    AnyEvent::Twitter::Stream->new(
        username => $username,
        passwordn => $password,
        method => 'track',
        keyword => '@' . $username,
        on_tweet => sub {
            my $tweet = shift;
            my $screen_name = Encode::decode_utf8($tweet->{user}{screen_name});
            my $text        = Encode::decode_utf8($tweet->{text});
            my $description = "$screen_name: $text";
            $ws->add('event' => $event, application => $application, description => $description);
        }
    )
    AnyEvent->condvar->recv;

=head1 METHODS

=over 4

=item new(apikey => 40byteshexadecimalstring, providerkey => yetanother40byteshex, on_error => sub { warn $_0]})

Call new() to create a Prowl Public API client object. You must pass the apikey, which you can generate on "settings" page https://prowl.weks.net/settings.php 

  my $apikey = 'cf09b20df08453f3d5ec113be3b4999820341dd2';
  my $ws = WebService::Prowl->new(apikey => $apikey, on_error => sub { warn $_[0] });

and you can specify a callback C<on_error> which is called when it gets error from Prowl API server.

If you have been whitelisted, you may want to use 'providerkey' like this:

  my $apikey      = 'cf09b20df08453f3d5ec113be3b4999820341dd2';
  my $providerkey = '68b329da9893e34099c7d8ad5cb9c94010200121';

  my $ws = WebService::Prowl->new(apikey => $apikey, providerkey => $providerkey, on_error => sub {warn $_[0]});

=over 4

=item on_error => $callback->( $error_msg, $url, $data, $headers )

When specified, this callback will be called with the error message from API server,
the url, http response body data and headers

=back

=item verify()

Sends a verify request to check if apikey is valid or not. return 1 for success.

  $ws->verify();

=item add(application => $app, event => $event, description => $desc, priority => $pri)

Sends a app request to api and return 1 for success.

  application: [256] (required)
      The name of your application

  event: [1024] (required)
      The name of the event

  description: [10000] (required)
      A description for the event

  priority: An integer value ranging [-2, 2]
      a priority of the notification: Very Low, Moderate, Normal, High, Emergency
      default is 0 (Normal)

  $ws->add(application => "Favotter App",
           event       => "new fav",
           description => "your tweet saved as sekimura's favorite");



=back

=head1 AUTHOR

Masayoshi Sekimura E<lt>sekimura@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<AnyEvent::HTTP>, L<https://prowl.weks.net/>, L<http://forums.cocoaforge.com/viewtopic.php?f=45&t=20339>

=cut
