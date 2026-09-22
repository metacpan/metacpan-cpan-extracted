package WWW::Hetzner::Robot::CLI::Cmd::Failover;
# ABSTRACT: Robot failover IP commands

our $VERSION = '0.101';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hrobot.pl failover [<failover-ip> [--to <server-ip> | --delete]]';


option to => (
    is     => 'ro',
    format => 's',
    short  => 't',
    doc    => 'Main IP of the server the failover IP should route to',
);

option delete => (
    is      => 'ro',
    short   => 'd',
    doc     => 'Delete the routing of the failover IP',
    default => 0,
);

sub execute {
    my ($self, $args, $chain) = @_;
    my $root = $chain->[0];
    my $robot = $root->robot;

    my $ip = $args->[0];

    unless ($ip) {
        die "A failover IP is required with --to\n"     if defined $self->to;
        die "A failover IP is required with --delete\n" if $self->delete;
        return $self->_list($robot, $root);
    }

    die "--to and --delete are mutually exclusive\n"
        if defined $self->to && $self->delete;

    my $failover;
    if ($self->delete) {
        $failover = $robot->failover->delete($ip);
    } elsif (defined $self->to) {
        $failover = $robot->failover->switch($ip, $self->to);
    } else {
        $failover = $robot->failover->get($ip);
    }

    if ($root->output eq 'json') {
        require JSON::MaybeXS;
        print JSON::MaybeXS::encode_json(_as_hash($failover));
        print "\n";
    } else {
        print "IP:               ", $failover->ip // '', "\n";
        print "Netmask:          ", $failover->netmask // '', "\n";
        print "Server Number:    ", $failover->server_number // '', "\n";
        print "Server IP:        ", $failover->server_ip // '', "\n";
        print "Active Server IP: ", $failover->active_server_ip // '', "\n";
    }
}

sub _list {
    my ($self, $robot, $root) = @_;

    my $failovers = $robot->failover->list;

    if ($root->output eq 'json') {
        require JSON::MaybeXS;
        print JSON::MaybeXS::encode_json([map { _as_hash($_) } @$failovers]);
        print "\n";
    } else {
        printf "%-40s %-16s %s\n", 'FAILOVER IP', 'SERVER', 'ACTIVE SERVER IP';
        for my $f (@$failovers) {
            printf "%-40s %-16s %s\n",
                $f->ip // '',
                $f->server_number // '',
                $f->active_server_ip // '';
        }
    }
}

sub _as_hash {
    my ($f) = @_;
    return {
        ip               => $f->ip,
        netmask          => $f->netmask,
        server_ip        => $f->server_ip,
        server_ipv6_net  => $f->server_ipv6_net,
        server_number    => $f->server_number,
        active_server_ip => $f->active_server_ip,
    };
}

1.

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Robot::CLI::Cmd::Failover - Robot failover IP commands

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    hrobot.pl failover                                    # List all failover IPs
    hrobot.pl failover 203.0.113.60                       # Show one failover IP
    hrobot.pl failover 203.0.113.60 --to 198.51.100.10    # Route it to another server
    hrobot.pl failover 203.0.113.60 --delete              # Delete the routing
    hrobot.pl failover -o json

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
