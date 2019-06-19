package WebService::MinFraud::Error::WebService;

use Moo;
use namespace::autoclean;

our $VERSION = '1.009001';

use WebService::MinFraud::Types qw( Str );

with 'WebService::MinFraud::Role::Error::HTTP';

extends 'Throwable::Error';

has code => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

1;

# ABSTRACT: An explicit error returned by the minFraud web service

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::MinFraud::Error::WebService - An explicit error returned by the minFraud web service

=head1 VERSION

version 1.009001

=head1 SYNOPSIS

  use 5.010;

  use WebService::MinFraud::Client;

  use Scalar::Util qw( blessed );
  use Try::Tiny;

  my $client = WebService::MinFraud::Client->new(
      account_id  => 42,
      license_key => 'abcdef123456',
  );

  try {
      my $request = { device => { ip_address => '24.24.24.24' } };
      $client->insights($request);
  }
  catch {
      die $_ unless blessed $_;
      if ( $_->isa('WebService::MinFraud::Error::WebService') ) {
          log_web_service_error(
              error_message => $_->message,
              maxmind_code  => $_->code,
              status        => $_->http_status,
              uri           => $_->uri,
          );
      }

      # handle other exceptions
  };

=head1 DESCRIPTION

This class represents an error returned by MaxMind's minFraud web service. It
extends L<Throwable::Error> and adds attributes of its own.

=head1 METHODS

The C<< message >> and C<< stack_trace >> methods are
inherited from L<Throwable::Error>. The message will be the value provided by
the MaxMind web service. See L<https://dev.maxmind.com/minfraud> for
details.

It also provides three methods of its own:

=head2 code

Returns the code returned by the MaxMind minFraud web service.

=head2 http_status

Returns the HTTP status. This should be either a 4xx or 5xx error.

=head2 uri

Returns the URI which gave the HTTP error.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/minfraud-api-perl/issues>.

=head1 AUTHOR

Mateu Hunter <mhunter@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2019 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
