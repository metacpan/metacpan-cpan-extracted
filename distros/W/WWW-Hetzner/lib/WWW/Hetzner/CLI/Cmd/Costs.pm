package WWW::Hetzner::CLI::Cmd::Costs;
# ABSTRACT: Show the current running cost of the project

our $VERSION = '0.102';

use Moo;
use MooX::Cmd;
use MooX::Options usage_string => 'USAGE: hcloud.pl costs [--label SELECTOR] [--net] [--json]';
use JSON::MaybeXS qw(encode_json);


option label => (
    is     => 'ro',
    format => 's',
    short  => 'l',
    doc    => 'Label selector applied to every resource list (e.g., env=prod)',
);


option net => (
    is  => 'ro',
    doc => 'Use net prices instead of gross',
);


option json => (
    is  => 'ro',
    doc => 'Print the result as JSON',
);


sub execute {
    my ($self, $args, $chain) = @_;

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    my %params;
    $params{label_selector} = $self->label if $self->label;
    $params{price} = 'net' if $self->net;

    my $costs = $cloud->costs(%params);

    if ($self->json || $main->output eq 'json') {
        print encode_json($costs), "\n";
        return;
    }

    my $cur = $costs->{currency} // 'EUR';
    printf "Prices: %s, %s (VAT %s%%)%s\n",
        $costs->{price}, $cur,
        defined $costs->{vat_rate} ? 0 + $costs->{vat_rate} : '-',
        defined $costs->{label_selector}
            ? ", label selector: $costs->{label_selector}" : '';

    my $fmt = "%-25s %-14s %-10s %-9s %-11s %11s %12s\n";
    printf $fmt, 'NAME', 'KIND', 'TYPE', 'LOCATION', 'STATUS',
        "$cur/h", "$cur/month";
    print '-' x 98, "\n";

    for my $r (@{ $costs->{resources} }) {
        printf $fmt,
            $r->{name} // $r->{id} // '-',
            $r->{kind},
            $r->{type} // '-',
            $r->{location} // '-',
            $r->{status} // '-',
            defined $r->{hourly}
                ? sprintf('%.4f%s', $r->{hourly}, $r->{hourly_derived} ? '*' : ' ')
                : '? ',
            defined $r->{monthly} ? sprintf('%.2f', $r->{monthly}) : '?';
    }

    print '-' x 98, "\n";
    printf $fmt, 'TOTAL', '', '', '', '',
        sprintf('%.4f ', $costs->{totals}{hourly}),
        sprintf('%.2f', $costs->{totals}{monthly});

    print "\n* hourly derived as monthly / $costs->{hours_per_month}h (no hourly price in the price list)\n"
        if grep { $_->{hourly_derived} } @{ $costs->{resources} };
    print STDERR "Warning: $_\n" for @{ $costs->{warnings} };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::Costs - Show the current running cost of the project

=head1 VERSION

version 0.102

=head1 SYNOPSIS

    hcloud.pl costs                          # whole project, gross prices
    hcloud.pl costs --label citiai-env=live  # only resources with that label
    hcloud.pl costs --net                    # net instead of gross prices
    hcloud.pl costs --json                   # full structure as JSON
    hcloud.pl -o json costs                  # same

Lists every priced resource (servers of any status and their backups,
volumes, primary IPs, floating IPs, load balancers) with its price per hour
and per month at its location, followed by the total. The header says
whether the prices are net or gross. Hourly prices marked with C<*> are
derived from the monthly price (see L<WWW::Hetzner::Cloud::Costs>).

=head2 label

Label selector (C<-l>), passed to every list request.

=head2 net

Show net prices instead of the default gross prices.

=head2 json

Print the full result structure as JSON (same as the global C<-o json>).

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
