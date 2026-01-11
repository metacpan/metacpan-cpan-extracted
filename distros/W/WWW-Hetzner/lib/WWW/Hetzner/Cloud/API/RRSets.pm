package WWW::Hetzner::Cloud::API::RRSets;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Hetzner Cloud DNS RRSets (Records) API

our $VERSION = '0.002';

use Moo;
use Carp qw(croak);
use WWW::Hetzner::Cloud::RRSet;
use namespace::clean;


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

has zone_id => (
    is       => 'ro',
    required => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::Hetzner::Cloud::RRSet->new(
        client  => $self->client,
        zone_id => $self->zone_id,
        %$data,
    );
}

sub _wrap_list {
    my ($self, $list) = @_;
    return [ map { $self->_wrap($_) } @$list ];
}

sub _base_path {
    my ($self) = @_;
    return "/zones/" . $self->zone_id . "/rrsets";
}


sub list {
    my ($self, %params) = @_;

    my $result = $self->client->get($self->_base_path, params => \%params);
    return $self->_wrap_list($result->{rrsets} // []);
}


sub get {
    my ($self, $name, $type) = @_;
    croak "Record name required" unless $name;
    croak "Record type required" unless $type;

    my $path = $self->_base_path . "/$name/$type";
    my $result = $self->client->get($path);
    return $self->_wrap($result->{rrset});
}


sub create {
    my ($self, %params) = @_;

    croak "name required" unless $params{name};
    croak "type required" unless $params{type};
    croak "records required" unless $params{records};

    my $body = {
        name    => $params{name},
        type    => $params{type},
        records => $params{records},
    };

    $body->{ttl} = $params{ttl} if $params{ttl};

    my $result = $self->client->post($self->_base_path, $body);
    return $self->_wrap($result->{rrset});
}


sub update {
    my ($self, $name, $type, %params) = @_;
    croak "Record name required" unless $name;
    croak "Record type required" unless $type;

    my $body = {};
    $body->{ttl}     = $params{ttl}     if exists $params{ttl};
    $body->{records} = $params{records} if exists $params{records};

    my $path = $self->_base_path . "/$name/$type";
    my $result = $self->client->put($path, $body);
    return $self->_wrap($result->{rrset});
}


sub delete {
    my ($self, $name, $type) = @_;
    croak "Record name required" unless $name;
    croak "Record type required" unless $type;

    my $path = $self->_base_path . "/$name/$type";
    return $self->client->delete($path);
}


sub add_a {
    my ($self, $name, $ip, %opts) = @_;
    croak "name required" unless $name;
    croak "IP address required" unless $ip;

    return $self->create(
        name    => $name,
        type    => 'A',
        records => [{ value => $ip }],
        %opts,
    );
}


sub add_aaaa {
    my ($self, $name, $ip, %opts) = @_;
    croak "name required" unless $name;
    croak "IPv6 address required" unless $ip;

    return $self->create(
        name    => $name,
        type    => 'AAAA',
        records => [{ value => $ip }],
        %opts,
    );
}


sub add_cname {
    my ($self, $name, $target, %opts) = @_;
    croak "name required" unless $name;
    croak "target required" unless $target;

    return $self->create(
        name    => $name,
        type    => 'CNAME',
        records => [{ value => $target }],
        %opts,
    );
}


sub add_mx {
    my ($self, $name, $mailserver, $priority, %opts) = @_;
    croak "name required" unless $name;
    croak "mailserver required" unless $mailserver;
    $priority //= 10;

    return $self->create(
        name    => $name,
        type    => 'MX',
        records => [{ value => "$priority $mailserver" }],
        %opts,
    );
}


sub add_txt {
    my ($self, $name, $value, %opts) = @_;
    croak "name required" unless $name;
    croak "value required" unless $value;

    return $self->create(
        name    => $name,
        type    => 'TXT',
        records => [{ value => $value }],
        %opts,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::API::RRSets - Hetzner Cloud DNS RRSets (Records) API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use WWW::Hetzner::Cloud;

    my $cloud = WWW::Hetzner::Cloud->new(token => $ENV{HETZNER_API_TOKEN});

    # Get RRSets object for a zone
    my $rrsets = $cloud->zones->rrsets($zone_id);

    # Or from a Zone object
    my $zone = $cloud->zones->get($zone_id);
    my $rrsets = $zone->rrsets;

    # List all records
    my $records = $rrsets->list;
    my $records = $rrsets->list(type => 'A');

    # Get specific record
    my $record = $rrsets->get('www', 'A');
    printf "Record: %s -> %s\n", $record->name, $record->records->[0]{value};

    # Create records
    my $record = $rrsets->create(
        name    => 'www',
        type    => 'A',
        ttl     => 300,
        records => [{ value => '203.0.113.10' }],
    );

    # Convenience methods
    $rrsets->add_a('www', '203.0.113.10', ttl => 300);
    $rrsets->add_aaaa('www', '2001:db8::1');
    $rrsets->add_cname('blog', 'www.example.com.');
    $rrsets->add_mx('@', 'mail.example.com.', 10);
    $rrsets->add_txt('@', 'v=spf1 include:_spf.example.com ~all');

    # Update record
    $rrsets->update('www', 'A', records => [{ value => '203.0.113.20' }]);

    # Delete record
    $rrsets->delete('www', 'A');

=head1 DESCRIPTION

This module provides access to DNS RRSets (Resource Record Sets) within a zone.
RRSets are groups of DNS records with the same name and type.
All methods return L<WWW::Hetzner::Cloud::RRSet> objects.

=head2 list

    my $records = $rrsets->list;
    my $records = $rrsets->list(type => 'A', name => 'www');

Returns an arrayref of L<WWW::Hetzner::Cloud::RRSet> objects.
Optional parameters: name, type, sort, page, per_page.

=head2 get

    my $record = $rrsets->get($name, $type);
    my $record = $rrsets->get('www', 'A');

Returns a L<WWW::Hetzner::Cloud::RRSet> object.

=head2 create

    my $record = $rrsets->create(
        name    => 'www',           # required
        type    => 'A',             # required
        records => [{ value => '1.2.3.4' }],  # required
        ttl     => 300,             # optional
    );

Creates a new RRSet. Returns a L<WWW::Hetzner::Cloud::RRSet> object.

=head2 update

    my $record = $rrsets->update('www', 'A',
        ttl     => 600,
        records => [{ value => '1.2.3.5' }],
    );

Updates an existing RRSet. Returns a L<WWW::Hetzner::Cloud::RRSet> object.

=head2 delete

    $rrsets->delete('www', 'A');

Deletes an RRSet.

=head2 add_a

    my $record = $rrsets->add_a('www', '203.0.113.10', ttl => 300);

Creates an A record. Returns a L<WWW::Hetzner::Cloud::RRSet> object.

=head2 add_aaaa

    my $record = $rrsets->add_aaaa('www', '2001:db8::1', ttl => 300);

Creates an AAAA record. Returns a L<WWW::Hetzner::Cloud::RRSet> object.

=head2 add_cname

    my $record = $rrsets->add_cname('blog', 'www.example.com.', ttl => 3600);

Creates a CNAME record. Target should end with a dot.
Returns a L<WWW::Hetzner::Cloud::RRSet> object.

=head2 add_mx

    my $record = $rrsets->add_mx('@', 'mail.example.com.', 10, ttl => 3600);

Creates an MX record with priority.
Returns a L<WWW::Hetzner::Cloud::RRSet> object.

=head2 add_txt

    my $record = $rrsets->add_txt('@', 'v=spf1 include:_spf.example.com ~all');

Creates a TXT record. Returns a L<WWW::Hetzner::Cloud::RRSet> object.

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
