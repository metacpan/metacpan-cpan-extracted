package WebService::MinFraud::Record::Issuer;

use Moo;
use namespace::autoclean;

our $VERSION = '1.009001';

use WebService::MinFraud::Types qw( Bool BoolCoercion Str );

has matches_provided_name => (
    is        => 'ro',
    isa       => Bool,
    coerce    => BoolCoercion,
    predicate => 1,
);

has matches_provided_phone_number => (
    is        => 'ro',
    isa       => Bool,
    coerce    => BoolCoercion,
    predicate => 1,
);

has name => (
    is        => 'ro',
    isa       => Str,
    predicate => 1,
);

has phone_number => (
    is        => 'ro',
    isa       => Str,
    predicate => 1,
);

1;

# ABSTRACT: Contains data for the issuer of the credit card associated with a transaction

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::MinFraud::Record::Issuer - Contains data for the issuer of the credit card associated with a transaction

=head1 VERSION

version 1.009001

=head1 SYNOPSIS

  use 5.010;

  use WebService::MinFraud::Client;

  my $client = WebService::MinFraud::Client->new(
      account_id  => 42,
      license_key => 'abcdef123456',
  );
  my $request  = { device => { ip_address => '24.24.24.24' } };
  my $insights = $client->insights($request);
  my $issuer   = $insights->credit_card->issuer;
  say $issuer->name;

=head1 DESCRIPTION

This class contains the data for the issuer of the credit card associated with
a transaction.

=head1 METHODS

This class provides the following methods:

=head2 matches_provided_name

Returns a boolean indicating whether the name provided matches the known bank
name associated with the credit card.

=head2 matches_provided_phone_number

Returns a boolean indicating whether the phone provided matches the known bank
phone associated with the credit card.

=head2 name

Returns the name of the issuer of the credit card.

=head2 phone_number

Returns the phone number of the issuer of the credit card.

=head1 PREDICATE METHODS

The following predicate methods are available, which return true if the related
data was present in the response body, false if otherwise:

=head2 has_matches_provided_name

=head2 has_matches_provided_phone_number

=head2 has_name

=head2 has_phone_number

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/minfraud-api-perl/issues>.

=head1 AUTHOR

Mateu Hunter <mhunter@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2019 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
