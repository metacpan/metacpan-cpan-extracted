package WWW::Hetzner::Cloud::Costs;
# ABSTRACT: Current running cost of a Hetzner Cloud project

our $VERSION = '0.102';

use Moo;
use Carp qw(croak);
use namespace::clean;


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);


# Hours after which hourly billing reaches the monthly cap; the ratio between
# price_monthly and price_hourly for every item that has both.
our $HOURS_PER_MONTH = 624;

sub calculate {
    my ($self, %opts) = @_;

    my $price = $opts{price} // 'gross';
    croak "price must be 'net' or 'gross', not '$price'"
        unless $price eq 'net' || $price eq 'gross';

    my %filter;
    $filter{label_selector} = $opts{label_selector}
        if defined $opts{label_selector} && length $opts{label_selector};

    my $client  = $self->client;
    my $pricing = $client->pricing->get;

    my $amount = sub {
        my ($p) = @_;
        return undef unless ref $p eq 'HASH' && defined $p->{$price};
        return 0 + $p->{$price};
    };

    my $by_location = sub {
        my ($entries, $key) = @_;
        my %index;
        for my $entry (@{ $entries // [] }) {
            for my $p (@{ $entry->{prices} // [] }) {
                $index{ $entry->{$key} }{ $p->{location} } = {
                    hourly  => $amount->($p->{price_hourly}),
                    monthly => $amount->($p->{price_monthly}),
                };
            }
        }
        return \%index;
    };

    my $server_prices = $by_location->($pricing->server_types, 'name');
    my $lb_prices     = $by_location->($pricing->load_balancer_types, 'name');
    my $pip_prices    = $by_location->($pricing->primary_ips, 'type');
    my $fip_prices    = $by_location->($pricing->floating_ips, 'type');
    my $volume_gb     = $amount->(($pricing->volume // {})->{price_per_gb_month});
    my $backup_pct    = ($pricing->server_backup // {})->{percentage};

    my (@rows, @warnings);

    my $add = sub {
        my (%row) = @_;
        my $p = delete $row{_price};
        if (!defined $p || !defined $p->{monthly}) {
            push @warnings, sprintf "no %s price for %s %s (%s) in %s",
                $price, $row{kind}, $row{name} // $row{id},
                $row{type} // '-', $row{location} // '-';
            $row{hourly} = $row{monthly} = undef;
        }
        else {
            $row{monthly} = _round($p->{monthly});
            if (defined $p->{hourly}) {
                $row{hourly} = _round($p->{hourly});
                $row{hourly_derived} = 0;
            }
            else {
                $row{hourly} = _round($p->{monthly} / $HOURS_PER_MONTH);
                $row{hourly_derived} = 1;
            }
        }
        push @rows, \%row;
    };

    for my $s (@{ $client->servers->list_all(%filter) }) {
        my %base = (
            id       => $s->id,
            name     => $s->name,
            type     => $s->server_type,
            location => $s->location,
            status   => $s->status,
        );
        my $p = _lookup($server_prices, $base{type}, $base{location});
        $add->(kind => 'server', %base, _price => $p);

        if (defined $s->backup_window && $p && defined $backup_pct) {
            my $f = $backup_pct / 100;
            $add->(kind => 'server_backup', %base, _price => {
                monthly => defined $p->{monthly} ? $p->{monthly} * $f : undef,
                hourly  => defined $p->{hourly}  ? $p->{hourly}  * $f : undef,
            });
        }
    }

    for my $v (@{ $client->volumes->list_all(%filter) }) {
        $add->(
            kind     => 'volume',
            id       => $v->id,
            name     => $v->name,
            type     => ($v->size // 0) . ' GB',
            location => $v->location,
            status   => $v->status,
            size     => $v->size,
            _price   => defined $volume_gb
                ? { monthly => ($v->size // 0) * $volume_gb } : undef,
        );
    }

    for my $ip (@{ $client->primary_ips->list_all(%filter) }) {
        my $type = $ip->type;
        my $p = exists $pip_prices->{$type // ''}
            ? _lookup($pip_prices, $type, $ip->location)
            : { hourly => 0, monthly => 0 };   # unpriced type, e.g. ipv6: free
        $add->(
            kind     => 'primary_ip',
            id       => $ip->id,
            name     => $ip->name,
            type     => $type,
            location => $ip->location,
            status   => $ip->is_assigned ? 'assigned' : 'unassigned',
            _price   => $p,
        );
    }

    for my $ip (@{ $client->floating_ips->list_all(%filter) }) {
        $add->(
            kind     => 'floating_ip',
            id       => $ip->id,
            name     => $ip->name,
            type     => $ip->type,
            location => $ip->location,
            status   => $ip->is_assigned ? 'assigned' : 'unassigned',
            _price   => _lookup($fip_prices, $ip->type, $ip->location),
        );
    }

    for my $lb (@{ $client->load_balancers->list_all(%filter) }) {
        $add->(
            kind     => 'load_balancer',
            id       => $lb->id,
            name     => $lb->name,
            type     => $lb->type_name,
            location => $lb->location_name,
            _price   => _lookup($lb_prices, $lb->type_name, $lb->location_name),
        );
    }

    my ($hourly, $monthly) = (0, 0);
    for my $r (@rows) {
        next unless defined $r->{monthly};
        $hourly  += $r->{hourly};
        $monthly += $r->{monthly};
    }

    return {
        currency        => $pricing->currency,
        vat_rate        => $pricing->vat_rate,
        price           => $price,
        label_selector  => $filter{label_selector},
        hours_per_month => $HOURS_PER_MONTH,
        resources       => \@rows,
        totals          => {
            hourly  => _round($hourly),
            monthly => _round($monthly),
        },
        warnings        => \@warnings,
    };
}


sub _lookup {
    my ($index, $name, $location) = @_;
    return undef unless defined $name && defined $location;
    return $index->{$name}{$location};
}

sub _round {
    my ($n) = @_;
    return 0 + sprintf('%.6f', $n);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::Costs - Current running cost of a Hetzner Cloud project

=head1 VERSION

version 0.102

=head1 SYNOPSIS

    use WWW::Hetzner::Cloud;

    my $cloud = WWW::Hetzner::Cloud->new(token => $ENV{HETZNER_API_TOKEN});

    my $costs = $cloud->costs(label_selector => 'env=live');

    for my $r (@{ $costs->{resources} }) {
        printf "%-14s %-20s %-8s %8.4f %8.2f\n",
            $r->{kind}, $r->{name}, $r->{location} // '-',
            $r->{hourly}, $r->{monthly};
    }
    printf "Total: %.4f %s/h, %.2f %s/month (%s)\n",
        $costs->{totals}{hourly}, $costs->{currency},
        $costs->{totals}{monthly}, $costs->{currency}, $costs->{price};

=head1 DESCRIPTION

Sums what the resources of a Hetzner Cloud project cost right now, per hour
and per month. This is a calculator over existing controllers, not an API
resource of its own: it reads the price list via
L<WWW::Hetzner::Cloud::API::Pricing/get> and the resources via the
C<list_all> method of the servers, volumes, primary IPs, floating IPs and
load balancers controllers. Every request goes through the client's normal
IO path; nothing is modified.

Usually reached through L<WWW::Hetzner::Cloud/costs>.

=head2 What is counted

=over 4

=item * B<server> -- every server that exists, whatever its status. Hetzner
bills stopped servers too, so an C<off> server is counted at full price; the
row carries C<status> so callers can see it.

=item * B<server_backup> -- for servers with backups enabled (a
C<backup_window> is set), the backup surcharge: C<server_backup.percentage>
of the server's price.

=item * B<volume> -- C<size> GB times C<volume.price_per_gb_month>.

=item * B<primary_ip> -- priced by type (C<ipv4>/C<ipv6>) and location. A
type the price list does not mention at all (currently C<ipv6>) is free and
counted as C<0>.

=item * B<floating_ip> -- priced by type and home location.

=item * B<load_balancer> -- priced by load balancer type and location.

=back

Not counted: traffic beyond the included volume, images/snapshots, and
anything outside the five resource kinds above.

=head2 Prices: location, net/gross, hourly

Server, load balancer, primary IP and floating IP prices are taken for the
resource's own location. If the price list has no entry for a resource's
type and location, the row gets C<undef> prices, is left out of the totals,
and a message is added to C<warnings>.

Prices are B<gross> by default (what the price list calls C<gross>, i.e.
including C<vat_rate>); pass C<< price => 'net' >> for net prices. The
result always says which one was used, together with C<vat_rate>.

C<monthly> is the full-month price, which is also the cap of hourly
billing. C<hourly> is the price per hour the resource exists. For volumes and
floating IPs the price list carries no hourly price; there the hourly figure
is derived as C<monthly / 624> and the row is flagged C<hourly_derived>.
624 hours is the ratio Hetzner uses for every item that has both prices
(e.g. cx23 5.49/month at 0.0088/h, ipv4 0.50/month at 0.0008/h), i.e. the
monthly cap is reached after 624 hours.

=head2 client

The L<WWW::Hetzner::Cloud> client used for all requests (required).

=head2 calculate

    my $costs = $calculator->calculate(
        label_selector => 'env=live',   # optional, passed to every list call
        price          => 'net',        # optional, 'gross' (default) or 'net'
    );

Fetches the price list and all priced resources and returns a hashref:

    {
        currency        => 'EUR',
        vat_rate        => '19.00',
        price           => 'gross',         # which price column was used
        label_selector  => 'env=live',      # or undef
        hours_per_month => 624,             # divisor for derived hourly prices
        resources       => [
            {
                kind     => 'server',       # server, server_backup, volume,
                                            # primary_ip, floating_ip, load_balancer
                id       => 42,
                name     => 'web-1',
                type     => 'cx23',         # type name, IP type, or "<size> GB"
                location => 'fsn1',
                status   => 'running',      # resource status, or (un)assigned for IPs
                hourly   => 0.0088,
                monthly  => 5.49,
                hourly_derived => 0,        # 1 if hourly = monthly / hours_per_month
                size     => 10,             # volumes only
            },
            ...
        ],
        totals   => { hourly => 0.0657, monthly => 40.98 },
        warnings => [ 'no gross price for server ...' ],
    }

C<label_selector> is applied to each resource's own labels on every list
request (servers, volumes, primary IPs, floating IPs, load balancers).
A server backup row inherits its server's label match.

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::Cloud> - Main Cloud API client (C<costs> method)

=item * L<WWW::Hetzner::Cloud::API::Pricing> - Price list

=item * L<WWW::Hetzner::CLI::Cmd::Costs> - C<hcloud.pl costs>

=back

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

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
