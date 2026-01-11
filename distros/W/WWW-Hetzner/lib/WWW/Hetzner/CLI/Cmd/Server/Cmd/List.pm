package WWW::Hetzner::CLI::Cmd::Server::Cmd::List;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: List servers

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options usage_string => 'USAGE: hcloud.pl server list [options]';
use JSON::MaybeXS qw(encode_json);

option selector => (
    is     => 'ro',
    format => 's',
    short  => 'l',
    doc    => 'Label selector (e.g., env=prod)',
);

sub execute {
    my ($self, $args, $chain) = @_;

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    my %params;
    $params{label_selector} = $self->selector if $self->selector;

    my $servers = $cloud->servers->list(%params);

    if ($main->output eq 'json') {
        print encode_json([map { $_->data } @$servers]), "\n";
        return;
    }

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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::Server::Cmd::List - List servers

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
