package WWW::Hetzner::CLI::Cmd::FloatingIp::Cmd::List;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: List floating IPs

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl floating-ip list';
use JSON::MaybeXS qw(encode_json);

sub execute {
    my ($self, $args, $chain) = @_;

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    my $fips = $cloud->floating_ips->list;

    if ($main->output eq 'json') {
        print encode_json([ map { $_->data } @$fips ]), "\n";
        return;
    }

    if (!@$fips) {
        print "No floating IPs found.\n";
        return;
    }

    printf "%-8s %-20s %-6s %-18s %-10s %-10s\n", 'ID', 'NAME', 'TYPE', 'IP', 'LOCATION', 'SERVER';
    printf "%-8s %-20s %-6s %-18s %-10s %-10s\n", '-' x 8, '-' x 20, '-' x 6, '-' x 18, '-' x 10, '-' x 10;

    for my $fip (@$fips) {
        printf "%-8s %-20s %-6s %-18s %-10s %-10s\n",
            $fip->id,
            $fip->name // '-',
            $fip->type // '-',
            $fip->ip // '-',
            $fip->location // '-',
            $fip->server // '-';
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::FloatingIp::Cmd::List - List floating IPs

=head1 VERSION

version 0.002

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
