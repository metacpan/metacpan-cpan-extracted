package WWW::Hetzner::CLI::Cmd::LoadBalancerType;
# ABSTRACT: Load balancer type commands

our $VERSION = '0.101';

use Moo;
use MooX::Cmd;
use MooX::Options usage_string => 'USAGE: hcloud.pl load-balancer-type [options]';
use JSON::MaybeXS qw(encode_json);


sub execute {
    my ($self, $args, $chain) = @_;

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    my $types = $cloud->load_balancer_types->list_all;

    if ($main->output eq 'json') {
        print encode_json([ map { $_->data } @$types ]), "\n";
        return;
    }

    if (!@$types) {
        print "No load balancer types found.\n";
        return;
    }

    printf "%-8s %-10s %-14s %-10s %-10s %s\n",
        'ID', 'NAME', 'CONNECTIONS', 'SERVICES', 'TARGETS', 'CERTIFICATES';
    printf "%-8s %-10s %-14s %-10s %-10s %s\n",
        '-' x 8, '-' x 10, '-' x 14, '-' x 10, '-' x 10, '-' x 12;

    for my $t (@$types) {
        printf "%-8s %-10s %-14s %-10s %-10s %s\n",
            $t->id,
            $t->name // '-',
            $t->max_connections // '-',
            $t->max_services // '-',
            $t->max_targets // '-',
            $t->max_assigned_certificates // '-';
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::LoadBalancerType - Load balancer type commands

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    hcloud.pl load-balancer-type            # List load balancer types
    hcloud.pl -o json load-balancer-type    # ... including their prices

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
