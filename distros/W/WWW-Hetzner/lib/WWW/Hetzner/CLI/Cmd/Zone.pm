package WWW::Hetzner::CLI::Cmd::Zone;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: DNS Zone commands

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options usage_string => 'USAGE: hcloud.pl zone [list|describe|create|delete] [options]';
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
    doc    => 'Filter by zone name',
);

sub _list {
    my ($self, $chain) = @_;

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    my %params;
    $params{label_selector} = $self->selector if $self->selector;
    $params{name} = $self->name if $self->name;

    my $zones = $cloud->zones->list(%params);

    if ($main->output eq 'json') {
        print encode_json($zones), "\n";
        return;
    }

    if (!@$zones) {
        print "No zones found.\n";
        return;
    }

    printf "%-15s %-30s %-10s %-8s %s\n",
        'ID', 'NAME', 'STATUS', 'TTL', 'LABELS';
    print "-" x 80, "\n";

    for my $z (@$zones) {
        my $labels = join(', ', map { "$_=$z->{labels}{$_}" } keys %{$z->{labels} // {}});
        printf "%-15s %-30s %-10s %-8s %s\n",
            $z->{id},
            $z->{name},
            $z->{status} // '-',
            $z->{ttl} // '-',
            $labels || '-';
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::Zone - DNS Zone commands

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    hcloud.pl zone                      # List all zones
    hcloud.pl zone list                 # List all zones
    hcloud.pl zone describe <id>        # Show zone details
    hcloud.pl zone create --name example.com
    hcloud.pl zone delete <id>

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
