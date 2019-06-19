package WebService::MinFraud::Record::Device;

use Moo;
use namespace::autoclean;

our $VERSION = '1.009001';

use Types::UUID;
use WebService::MinFraud::Types qw( Num Str );

has confidence => (
    is        => 'ro',
    isa       => Num,
    predicate => 1,
);

has id => (
    is        => 'ro',
    isa       => Uuid,
    predicate => 1,
);

has last_seen => (
    is        => 'ro',
    isa       => Str,
    predicate => 1,
);

has local_time => (
    is        => 'ro',
    isa       => Str,
    predicate => 1,
);

1;

# ABSTRACT: Contains data for the device associated with a transaction

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::MinFraud::Record::Device - Contains data for the device associated with a transaction

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
  my $device   = $insights->device;
  say 'Device ' . $device->id . ' was last seen ' . $device->last_seen;

=head1 DESCRIPTION

This class contains the data for the device associated with a transaction.

=head1 METHODS

This class provides the following methods:

=head2 confidence

This number represents our confidence that the device_id refers to a unique
device as opposed to a cluster of similar devices.

=head2 id

A UUID that MaxMind uses for the device associated
with this IP address. Note that many devices cannot be uniquely identified
because they are too common (for example, all iPhones of a given model and
OS release). In these cases, the minFraud service will simply not return a
UUID for that device.

=head2 last_seen

This is the date and time of the last sighting of the device on the specified
IP address for your user account. The string is in the RFC 3339 format.

=head2 local_time

This is the date and time of the transaction at the UTC offset associated with
the device. The string is in the RFC 3339 format.

=head1 PREDICATE METHODS

The following predicate methods are available, which return true if the related
data was present in the response body, false if otherwise:

=head2 has_confidence

=head2 has_id

=head2 has_last_seen

=head2 has_local_time

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/minfraud-api-perl/issues>.

=head1 AUTHOR

Mateu Hunter <mhunter@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2019 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
