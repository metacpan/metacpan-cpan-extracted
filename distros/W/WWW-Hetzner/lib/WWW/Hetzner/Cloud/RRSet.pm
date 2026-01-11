package WWW::Hetzner::Cloud::RRSet;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Hetzner Cloud DNS RRSet object

our $VERSION = '0.002';

use Moo;
use Carp qw(croak);
use namespace::clean;


has _client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
    init_arg => 'client',
);

has zone_id => ( is => 'ro', required => 1 );


has name => ( is => 'ro' );


has type => ( is => 'ro' );


has ttl => ( is => 'rw' );


has records => ( is => 'rw', default => sub { [] } );


sub update {
    my ($self) = @_;
    croak "Cannot update RRSet without zone_id" unless $self->zone_id;
    croak "Cannot update RRSet without name" unless $self->name;
    croak "Cannot update RRSet without type" unless $self->type;

    my $path = "/zones/" . $self->zone_id . "/rrsets/" . $self->name . "/" . $self->type;
    $self->_client->put($path, {
        ttl     => $self->ttl,
        records => $self->records,
    });
    return $self;
}


sub delete {
    my ($self) = @_;
    croak "Cannot delete RRSet without zone_id" unless $self->zone_id;
    croak "Cannot delete RRSet without name" unless $self->name;
    croak "Cannot delete RRSet without type" unless $self->type;

    my $path = "/zones/" . $self->zone_id . "/rrsets/" . $self->name . "/" . $self->type;
    $self->_client->delete($path);
    return 1;
}


sub values {
    my ($self) = @_;
    return [ map { $_->{value} } @{$self->records} ];
}


sub data {
    my ($self) = @_;
    return {
        zone_id => $self->zone_id,
        name    => $self->name,
        type    => $self->type,
        ttl     => $self->ttl,
        records => $self->records,
    };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::RRSet - Hetzner Cloud DNS RRSet object

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $record = $zone->rrsets->get('www', 'A');

    # Read attributes
    print $record->name, "\n";
    print $record->type, "\n";
    print $record->ttl, "\n";

    # Get values
    my $values = $record->values;  # ['1.2.3.4']

    # Update
    $record->ttl(600);
    $record->records([{ value => '5.6.7.8' }]);
    $record->update;

    # Delete
    $record->delete;

=head1 DESCRIPTION

This class represents a Hetzner Cloud DNS RRSet (Resource Record Set).
Objects are returned by L<WWW::Hetzner::Cloud::API::RRSets> methods.

=head2 zone_id

Zone ID this record belongs to (read-only).

=head2 name

Record name, e.g. "www" or "@" for apex (read-only).

=head2 type

Record type: A, AAAA, CNAME, MX, TXT, etc. (read-only).

=head2 ttl

Time to live in seconds (read-write).

=head2 records

Arrayref of record values: C<[{ value => '1.2.3.4' }, ...]> (read-write).

=head2 update

    $record->ttl(600);
    $record->records([{ value => '5.6.7.8' }]);
    $record->update;

Saves changes to TTL and records back to the API.

=head2 delete

    $record->delete;

Deletes the RRSet.

=head2 values

    my $values = $record->values;  # ['1.2.3.4', '5.6.7.8']

Returns an arrayref of just the record values (without the hash structure).

=head2 data

    my $hashref = $record->data;

Returns all RRSet data as a hashref (for JSON serialization).

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-hetzner/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
