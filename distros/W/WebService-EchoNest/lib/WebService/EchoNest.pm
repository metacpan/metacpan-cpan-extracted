package WebService::EchoNest;
use Moose;
use MooseX::StrictConstructor;
use JSON::XS::VersionOneAndTwo;
use LWP::UserAgent;
use URI::QueryParam;

our $VERSION = '0.007';

has 'api_root' => (
  is      => 'rw',
  isa     => 'Str',
  default => 'http://developer.echonest.com/api/v4/'
);

has 'api_key' => (
  is       => 'rw',
  isa      => 'Str',
  required => 1,
);

has 'ua' => (
  is       => 'rw',
  isa      => 'LWP::UserAgent',
  required => 0,
  default  => sub {
    my $ua = LWP::UserAgent->new;
    $ua->agent( 'WebService::Echonest/' . $VERSION );
    $ua->env_proxy;
    return $ua;
  }
);

sub request {
  my ( $self, $method, %conf ) = @_;
  my $request = $self->create_http_request($method, %conf);
  return $self->_make_request($request);
}

sub create_http_request {
  my ( $self, $method, %conf ) = @_;

  $conf{api_key} = $self->api_key;
  my $uri = URI->new($self->api_root . $method);

  foreach my $key ( keys %conf ) {
    my $value = $conf{$key};
    $uri->query_param( $key, $value );
  }
  $uri->query_param( 'format', 'json' );

  return HTTP::Request->new( 'GET', $uri );
}

sub _make_request {
  my ( $self, $request ) = @_;
  my $ua = $self->ua;

  my $response = $ua->request($request);
  my $data     = from_json( $response->content );

  my $status = $data->{response}->{status};
  confess "Unexpected response format" if !$status;
  
  my $code = $status->{code};

  if ($code != 0) {
    confess "$code: $status->{message}";
  } else {
    return $data;
  }
}

1;

__END__

=head1 NAME

WebService::EchoNest - A simple interface to the EchoNest API

=head1 SYNOPSIS

  my $echonest = WebService::EchoNest->new(
      api_key    => 'XXX',
  );
  
  my $data = $echonest->request('artist/search',
    name   => 'Radiohead',
    bucket => ['biographies'],
    limit  => 'true'
  );

=head1 DESCRIPTION

The module provides a simple interface to the EchoNest API. To use
this module, you must first sign up at L<http://developer.echonest.com/>
to receive an API key.

You can then make requests on the API. You pass in a method name and hash of paramters, and a data structure
mirroring the response is returned.

This module confesses if there is an error.

=head1 METHODS

=head2 request

This makes a request:

  my $data = $echonest->request('artist/search',
    name   => 'Black Moth Super Rainbow',
    bucket => ['images'],
    limit  => 'true'
  );

=head2 create_http_request

If you want to integrate this module into another HTTP framework, this 
method will create an L<HTTP::Request> object:

  my $http_request = $echonest->create_http_request('artist/search',
    name   => 'Black Moth Super Rainbow',
    bucket => ['images'],
    limit  => 'true'
  );

=head1 AUTHOR

Nick Langridge <nickl@cpan.org>

=head1 CREDITS

This module was based on Net::LastFM by Leon Brocard.

=head1 COPYRIGHT

Copyright (C) 2013 Nick Langridge

=head1 LICENSE

This module is free software; you can redistribute it or 
modify it under the same terms as Perl itself.
