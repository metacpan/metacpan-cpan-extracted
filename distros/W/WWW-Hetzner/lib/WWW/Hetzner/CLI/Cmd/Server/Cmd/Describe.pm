package WWW::Hetzner::CLI::Cmd::Server::Cmd::Describe;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Show server details

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl server describe <id> [options]';
use JSON::MaybeXS qw(encode_json);

sub execute {
    my ($self, $args, $chain) = @_;

    my $id = $args->[0] or die "Usage: hcloud server describe <id>\n";

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    my $server = $cloud->servers->get($id);

    if ($main->output eq 'json') {
        print encode_json($server->data), "\n";
        return;
    }

    printf "ID:          %s\n", $server->id;
    printf "Name:        %s\n", $server->name;
    printf "Status:      %s\n", $server->status;
    printf "Type:        %s\n", $server->server_type;
    printf "Datacenter:  %s\n", $server->datacenter;
    printf "IPv4:        %s\n", $server->ipv4 // '-';
    printf "IPv6:        %s\n", $server->ipv6 // '-';
    printf "Created:     %s\n", $server->created;

    my $labels = $server->labels;
    if ($labels && %$labels) {
        print "Labels:\n";
        for my $k (sort keys %$labels) {
            printf "  %s: %s\n", $k, $labels->{$k};
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::Server::Cmd::Describe - Show server details

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
