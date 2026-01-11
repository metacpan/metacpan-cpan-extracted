package WWW::Hetzner::Robot::API::Traffic;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Hetzner Robot Traffic API

our $VERSION = '0.002';

use Moo;
use Carp qw(croak);
use namespace::clean;


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub query {
    my ($self, %params) = @_;

    # Validate required params
    croak "Parameter 'type' required (day, month, year)"
        unless $params{type};
    croak "Invalid type '$params{type}' - must be day, month, or year"
        unless $params{type} =~ /^(day|month|year)$/;
    croak "Parameter 'from' required" unless $params{from};
    croak "Parameter 'to' required" unless $params{to};
    croak "At least one 'ip' or 'subnet' required"
        unless $params{ip} || $params{subnet};

    # Build POST data
    my %post;
    $post{type} = $params{type};
    $post{from} = $params{from};
    $post{to}   = $params{to};

    # Handle arrays for ip[] and subnet[]
    if ($params{ip}) {
        my @ips = ref $params{ip} eq 'ARRAY' ? @{$params{ip}} : ($params{ip});
        $post{'ip[]'} = \@ips;
    }
    if ($params{subnet}) {
        my @subnets = ref $params{subnet} eq 'ARRAY' ? @{$params{subnet}} : ($params{subnet});
        $post{'subnet[]'} = \@subnets;
    }

    $post{single_values} = $params{single_values} ? 'true' : 'false'
        if exists $params{single_values};

    my $result = $self->client->post('/traffic', \%post);
    return $result->{traffic};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Robot::API::Traffic - Hetzner Robot Traffic API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $robot = WWW::Hetzner::Robot->new(...);

    # Query daily traffic for an IP
    my $traffic = $robot->traffic->query(
        type => 'day',
        from => '2024-01-01T00',
        to   => '2024-01-02T00',
        ip   => '1.2.3.4',
    );

    # Query monthly traffic for multiple IPs
    my $traffic = $robot->traffic->query(
        type => 'month',
        from => '2024-01-01',
        to   => '2024-02-01',
        ip   => ['1.2.3.4', '5.6.7.8'],
    );

    # Query with single_values for hourly breakdown
    my $traffic = $robot->traffic->query(
        type          => 'day',
        from          => '2024-01-01T00',
        to            => '2024-01-02T00',
        ip            => '1.2.3.4',
        single_values => 1,
    );

=head1 DESCRIPTION

Query traffic statistics for IPs and subnets.

=head2 query

    my $traffic = $robot->traffic->query(%params);

Query traffic statistics. Returns hashref with traffic data.

B<Parameters:>

=over 4

=item type (required)

Type of traffic query: C<day>, C<month>, or C<year>.

=item from (required)

Start date/time. Format depends on type:

=over 4

=item * day: C<YYYY-MM-DDTHH> (e.g., 2024-01-01T00)

=item * month: C<YYYY-MM-DD> (e.g., 2024-01-01)

=item * year: C<YYYY-MM> (e.g., 2024-01)

=back

=item to (required)

End date/time. Same format as C<from>.

=item ip

Single IP address or arrayref of IP addresses.

=item subnet

Single subnet or arrayref of subnets.

=item single_values

If true, returns data grouped by hour/day/month.

=back

B<Response structure:>

    {
        type => 'day',
        from => '2024-01-01T00',
        to   => '2024-01-02T00',
        data => {
            '1.2.3.4' => {
                in  => 10.5,   # GB inbound
                out => 25.3,   # GB outbound
                sum => 35.8,   # GB total
            },
        },
    }

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
