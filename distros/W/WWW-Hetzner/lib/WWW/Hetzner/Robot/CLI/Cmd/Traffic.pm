package WWW::Hetzner::Robot::CLI::Cmd::Traffic;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Query traffic statistics

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options usage_string => 'USAGE: hrobot.pl traffic --ip <ip> --type <day|month|year> --from <date> --to <date>';


option ip => (
    is        => 'ro',
    format    => 's@',
    doc       => 'IP address(es) to query (repeatable)',
    autosplit => ',',
);

option subnet => (
    is        => 'ro',
    format    => 's@',
    doc       => 'Subnet(s) to query (repeatable)',
    autosplit => ',',
);

option type => (
    is       => 'ro',
    format   => 's',
    short    => 't',
    required => 1,
    doc      => 'Query type: day, month, year',
);

option from => (
    is       => 'ro',
    format   => 's',
    short    => 'f',
    required => 1,
    doc      => 'Start date/time',
);

option to => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => 'End date/time',
);

option single_values => (
    is      => 'ro',
    short   => 's',
    doc     => 'Return hourly/daily/monthly breakdown',
    default => 0,
);

sub execute {
    my ($self, $args, $chain) = @_;
    my $root = $chain->[0];
    my $robot = $root->robot;

    unless ($self->ip || $self->subnet) {
        die "At least one --ip or --subnet required\n";
    }

    my %params = (
        type => $self->type,
        from => $self->from,
        to   => $self->to,
    );

    $params{ip}            = $self->ip     if $self->ip;
    $params{subnet}        = $self->subnet if $self->subnet;
    $params{single_values} = 1             if $self->single_values;

    my $traffic = $robot->traffic->query(%params);

    if ($root->output eq 'json') {
        require JSON::MaybeXS;
        print JSON::MaybeXS::encode_json($traffic);
        print "\n";
    } else {
        print "Traffic ($traffic->{type}): $traffic->{from} - $traffic->{to}\n\n";

        if ($self->single_values && ref $traffic->{data} eq 'HASH') {
            # Single values mode - data has time-based keys
            _print_single_values($traffic->{data});
        } else {
            # Aggregated mode - data keyed by IP/subnet
            printf "%-20s %12s %12s %12s\n", 'IP/SUBNET', 'IN (GB)', 'OUT (GB)', 'TOTAL (GB)';
            print "-" x 60, "\n";

            for my $addr (sort keys %{$traffic->{data}}) {
                my $d = $traffic->{data}{$addr};
                printf "%-20s %12.2f %12.2f %12.2f\n",
                    $addr,
                    $d->{in}  // 0,
                    $d->{out} // 0,
                    $d->{sum} // 0;
            }
        }
    }
}

sub _print_single_values {
    my ($data) = @_;

    printf "%-20s %-20s %12s %12s %12s\n", 'IP/SUBNET', 'TIME', 'IN (GB)', 'OUT (GB)', 'TOTAL (GB)';
    print "-" x 80, "\n";

    for my $addr (sort keys %$data) {
        my $addr_data = $data->{$addr};
        if (ref $addr_data eq 'HASH') {
            for my $time (sort keys %$addr_data) {
                my $d = $addr_data->{$time};
                if (ref $d eq 'HASH') {
                    printf "%-20s %-20s %12.2f %12.2f %12.2f\n",
                        $addr, $time,
                        $d->{in}  // 0,
                        $d->{out} // 0,
                        $d->{sum} // 0;
                }
            }
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Robot::CLI::Cmd::Traffic - Query traffic statistics

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    hrobot.pl traffic --ip 1.2.3.4 --type day --from 2024-01-01T00 --to 2024-01-02T00
    hrobot.pl traffic --ip 1.2.3.4 --type month --from 2024-01-01 --to 2024-02-01
    hrobot.pl traffic --ip 1.2.3.4 --type year --from 2024-01 --to 2024-12
    hrobot.pl traffic --ip 1.2.3.4 --type day --from 2024-01-01T00 --to 2024-01-02T00 --single-values

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
