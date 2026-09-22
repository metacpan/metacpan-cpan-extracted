package WWW::Hetzner::CLI::Cmd::Pricing;
# ABSTRACT: Pricing commands

our $VERSION = '0.101';

use Moo;
use MooX::Cmd;
use MooX::Options usage_string => 'USAGE: hcloud.pl pricing [options]';
use JSON::MaybeXS qw(encode_json);


sub _gross {
    my ($price) = @_;
    return defined $price && ref $price eq 'HASH' ? ($price->{gross} // '-') : '-';
}

sub execute {
    my ($self, $args, $chain) = @_;

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    my $pricing = $cloud->pricing->get;

    if ($main->output eq 'json') {
        print encode_json($pricing->data), "\n";
        return;
    }

    printf "Currency:      %s (VAT %s%%)\n",
        $pricing->currency // '-', $pricing->vat_rate // '-';
    printf "Image:         %s per GB/month\n",
        _gross($pricing->image->{price_per_gb_month});
    printf "Volume:        %s per GB/month\n",
        _gross($pricing->volume->{price_per_gb_month});
    printf "Server backup: %s%% of the server price\n",
        $pricing->server_backup->{percentage} // '-';

    _print_type_prices('SERVER TYPES', $pricing->server_types);
    _print_type_prices('LOAD BALANCER TYPES', $pricing->load_balancer_types);
}

sub _print_type_prices {
    my ($title, $types) = @_;

    return unless $types && @$types;

    printf "\n%s\n", $title;
    printf "%-12s %-10s %-12s %s\n", 'NAME', 'LOCATION', 'HOURLY', 'MONTHLY';
    printf "%-12s %-10s %-12s %s\n", '-' x 12, '-' x 10, '-' x 12, '-' x 12;

    for my $type (@$types) {
        for my $price (@{ $type->{prices} // [] }) {
            printf "%-12s %-10s %-12s %s\n",
                $type->{name} // '-',
                $price->{location} // '-',
                _gross($price->{price_hourly}),
                _gross($price->{price_monthly});
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::Pricing - Pricing commands

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    hcloud.pl pricing            # Show the current price list
    hcloud.pl -o json pricing    # ... as the full API response

The table shows gross prices; C<--output json> carries net and gross for
every entry, including the floating IP and primary IP prices the table
leaves out.

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
