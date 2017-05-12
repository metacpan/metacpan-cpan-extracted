package WebService::Notifo;
BEGIN {
  $WebService::Notifo::VERSION = '0.001';
}

# ABSTRACT: client for the notifo.com API

use strict;
use warnings;
use parent 'Protocol::Notifo';
use LWP::UserAgent;

sub send_notification {
  my $self = shift;

  my $req = $self->SUPER::send_notification(@_);
  my $res = $self->_do_request($req);
  return $self->parse_response(%$res);
}

sub _do_request {
  my ($self, $req) = @_;
  my $ua = $self->{ua};

  unless ($ua) {
    $ua = $self->{ua} = LWP::UserAgent->new;
    $ua->env_proxy;
    $ua->agent("WebService::Notifo $WebService::Notifo::VERSION");
  }

  my $http_req = HTTP::Request->new(@$req{qw(method url headers body)});
  my $res      = $ua->simple_request($http_req);

  return {
    http_response_code => $res->code,
    http_body          => $res->decoded_content || $res->content,
    http_status_line   => $res->status_line,
  };
}

1;


__END__
=pod

=head1 NAME

WebService::Notifo - client for the notifo.com API

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    # Uses the default values obtained from configuration file
    my $wn = WebService::Notifo->new;
    
    # ... or just pass them in
    my $wn = WebService::Notifo->new(
        api_key => 'api_key_value',
        user    => 'api_user',
    );
    
    my $res = $wn->send_notification(msg => 'my nottification text');

=head1 DESCRIPTION

A client for the L<http://notifo.com/> API.

=head1 CONSTRUCTORS

=head2 new

Creates a new C<WebService::Notifo> object. See
L<< Protocol::Notifo->new()|Protocol::Notifo/new >>
for a explanation of the parameters and the configuration file used for
default values.

=head1 METHODS

=head2 send_notification

Sends a notification. See
L<< Protocol::Notifo->send_notification()|Protocol::Notifo/send_notification >>
for list of parameters and a explanation of the response.

=head1 SEE ALSO

L<Protocol::Notifo>

=head1 AUTHOR

Pedro Melo <melo@simplicidade.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Pedro Melo.

This is free software, licensed under:

  The Artistic License 2.0

=cut

