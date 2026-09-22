package WWW::Hetzner::CLI::Cmd::Server;
# ABSTRACT: Server commands

our $VERSION = '0.101';

use Moo;
use MooX::Cmd;
use MooX::Options usage_string => 'USAGE: hcloud.pl server <command> [options]';
use JSON::MaybeXS qw(encode_json);


sub execute {
    my ($self, $args, $chain) = @_;

    # Default to list
    $self->_list($chain);
}

option selector => (
    is     => 'ro',
    format => 's',
    short  => 'l',
    doc    => 'Label selector (e.g., env=prod)',
);

option name => (
    is     => 'ro',
    format => 's',
    short  => 'n',
    doc    => 'Filter by name',
);

sub _list {
    my ($self, $chain) = @_;

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    my %params;
    $params{label_selector} = $self->selector if $self->selector;
    $params{name} = $self->name if $self->name;

    my $servers = $cloud->servers->list_all(%params);

    if ($main->output eq 'json') {
        print encode_json([ map { $_->data } @$servers ]), "\n";
        return;
    }

    # Table output
    if (!@$servers) {
        print "No servers found.\n";
        return;
    }

    printf "%-10s %-25s %-12s %-16s %-10s %s\n",
        'ID', 'NAME', 'STATUS', 'IPV4', 'TYPE', 'DATACENTER';
    print "-" x 90, "\n";

    for my $s (@$servers) {
        printf "%-10s %-25s %-12s %-16s %-10s %s\n",
            $s->id,
            $s->name,
            $s->status,
            $s->ipv4 // '-',
            $s->server_type // '-',
            $s->datacenter // '-';
    }
}


1.

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::Server - Server commands

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    hcloud.pl server list
    hcloud.pl server list --selector env=prod
    hcloud.pl server create --name test --type cx22 --image debian-12
    hcloud.pl server delete <id>
    hcloud.pl server describe <id>
    hcloud.pl server poweron <id>
    hcloud.pl server poweroff <id>

=head1 DESCRIPTION

Manage Hetzner Cloud servers via CLI.

=head1 SUBCOMMANDS

=over 4

=item * L<list|WWW::Hetzner::CLI::Cmd::Server::Cmd::List> - List servers

=item * L<create|WWW::Hetzner::CLI::Cmd::Server::Cmd::Create> - Create a server

=item * L<delete|WWW::Hetzner::CLI::Cmd::Server::Cmd::Delete> - Delete a server

=item * L<describe|WWW::Hetzner::CLI::Cmd::Server::Cmd::Describe> - Show server details

=item * L<poweron|WWW::Hetzner::CLI::Cmd::Server::Cmd::Poweron> - Power on server

=item * L<poweroff|WWW::Hetzner::CLI::Cmd::Server::Cmd::Poweroff> - Power off server

=item * L<reboot|WWW::Hetzner::CLI::Cmd::Server::Cmd::Reboot> - Reboot server

=item * L<shutdown|WWW::Hetzner::CLI::Cmd::Server::Cmd::Shutdown> - Shutdown server

=item * L<reset|WWW::Hetzner::CLI::Cmd::Server::Cmd::Reset> - Reset server

=item * L<rebuild|WWW::Hetzner::CLI::Cmd::Server::Cmd::Rebuild> - Rebuild server

=item * L<rescue|WWW::Hetzner::CLI::Cmd::Server::Cmd::Rescue> - Enable rescue mode

=back

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::CLI> - Main Cloud CLI

=item * L<WWW::Hetzner::Cloud::API::Servers> - Servers API

=item * L<WWW::Hetzner::Cloud::Server> - Server entity

=item * L<WWW::Hetzner> - Main umbrella module

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
