package WebService::MinFraud::Error::Generic;

use Moo;
use namespace::autoclean;

our $VERSION = '1.009001';

extends 'Throwable::Error';

1;

# ABSTRACT: A generic exception class for WebService::MinFraud errors

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::MinFraud::Error::Generic - A generic exception class for WebService::MinFraud errors

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
      $client->insights( $request );
  }
  catch {
      die $_ unless blessed $_;
      die $_ if $_->isa('WebService::MinFraud::Error::Generic');

      # handle other exceptions
  };

=head1 DESCRIPTION

This class represents a generic error. It extends L<Throwable::Error> and does
not add any additional attributes.

=head1 METHODS

This class has two methods, both of which are inherited from
L<Throwable::Error>.

=head2 message

=head2 stack_trace

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/minfraud-api-perl/issues>.

=head1 AUTHOR

Mateu Hunter <mhunter@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2019 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
