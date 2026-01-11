package WWW::Hetzner::CLI::Cmd::Firewall::Cmd::AddRule;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Add a rule to a firewall

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl firewall add-rule <id> --direction <in|out> --protocol <tcp|udp|icmp|gre|esp> --port <port> [--source-ips <ips>]';

option direction => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => 'Direction: in or out',
);

option protocol => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => 'Protocol: tcp, udp, icmp, gre, esp',
);

option port => (
    is     => 'ro',
    format => 's',
    doc    => 'Port or port range (e.g. 22 or 80-443)',
);

option 'source_ips' => (
    is        => 'ro',
    format    => 's@',
    long_doc  => 'source-ips',
    doc       => 'Source IPs (can specify multiple)',
    default   => sub { ['0.0.0.0/0', '::/0'] },
);

sub execute {
    my ($self, $args, $chain) = @_;
    my $id = $args->[0] or die "Usage: hcloud.pl firewall add-rule <id> --direction <in|out> --protocol <tcp|udp|icmp> --port <port>\n";

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    # Get existing firewall
    my $fw = $cloud->firewalls->get($id);
    my @rules = @{ $fw->rules // [] };

    # Build new rule
    my $rule = {
        direction => $self->direction,
        protocol  => $self->protocol,
    };
    $rule->{port} = $self->port if $self->port;

    if ($self->direction eq 'in') {
        $rule->{source_ips} = $self->source_ips;
    } else {
        $rule->{destination_ips} = $self->source_ips;  # reuse for simplicity
    }

    push @rules, $rule;

    print "Adding rule to firewall $id...\n";
    $cloud->firewalls->set_rules($id, @rules);
    print "Rule added.\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::Firewall::Cmd::AddRule - Add a rule to a firewall

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
