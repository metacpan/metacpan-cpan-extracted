package WWW::Hetzner::CLI::Cmd::Zone::Cmd::Describe;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Describe a DNS zone

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl zone describe <zone-id> [options]';
use JSON::MaybeXS qw(encode_json);

sub execute {
    my ($self, $args, $chain) = @_;

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    my $id = $args->[0] or die "Usage: zone describe <zone-id>\n";

    my $zone = $cloud->zones->get($id);

    if ($main->output eq 'json') {
        print encode_json($zone->data), "\n";
        return;
    }

    print "Zone:\n";
    printf "  ID:      %s\n", $zone->id;
    printf "  Name:    %s\n", $zone->name;
    printf "  Status:  %s\n", $zone->status // '-';
    printf "  TTL:     %s\n", $zone->ttl // '-';
    printf "  Created: %s\n", $zone->created // '-';

    my $ns = $zone->ns;
    if (@$ns) {
        print "  Nameservers:\n";
        for my $n (@$ns) {
            print "    - $n\n";
        }
    }

    my $labels = $zone->labels;
    if (%$labels) {
        print "  Labels:\n";
        for my $k (sort keys %$labels) {
            printf "    %s: %s\n", $k, $labels->{$k};
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::Zone::Cmd::Describe - Describe a DNS zone

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
