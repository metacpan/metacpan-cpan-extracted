package WebService::MinFraud::Record::Warning;

use Moo;
use namespace::autoclean;

our $VERSION = '1.009001';

use Types::Standard qw( ArrayRef Str );

has code => (
    is  => 'ro',
    isa => Str,
);

has warning => (
    is        => 'ro',
    isa       => Str,
    predicate => 1,
);

has input_pointer => (
    is        => 'ro',
    isa       => Str,
    predicate => 1,
);

1;

# ABSTRACT: A warning record returned from a web service query

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::MinFraud::Record::Warning - A warning record returned from a web service query

=head1 VERSION

version 1.009001

=head1 SYNOPSIS

  use 5.010;
  use WebService::MinFraud::Client;

  my $client = WebService::MinFraud::Client->new(
      account_id  => 42,
      license_key => 'abcdef123456',
  );
  my $request = { device => { ip_address => '24.24.24.24'} };
  my $insights = $client->insights( $request );
  foreach my $warning_object (@{$insights->warnings}) {
        say "WARNING CODE: ", $warning_object->code;
        say "WARNING MESSAGE: ", $warning_object->warning;
        say "WARNING INPUT PATH: ", join ' / ', @{$warning_object->input};
  }

=head1 DESCRIPTION

This class represents a MaxMind warning (if any) from a web service query.

=head1 METHODS

This class provides the following methods:

=head2 code

Returns a machine-readable code identifying the warning. See the L<API
documentation|https://dev.maxmind.com/minfraud/#Warning>
for the current list.

=head2 input_pointer

Returns a JSON pointer to the input field that the warning is associated with.
For instance, if the warning was about the billing city, the returned reference would be
C<< "/billing/city" >>.

=head2 warning

Returns a human-readable explanation of the warning. This description may
change at any time and should not be matched against.

=head1 PREDICATE METHODS

The following predicate methods are available, which return true if the related
data was present in the response body, false if otherwise:

=head2 has_input_pointer

=head2 has_warning

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/minfraud-api-perl/issues>.

=head1 AUTHOR

Mateu Hunter <mhunter@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2019 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
