package WWW::Hetzner::CLI::Cmd::Zone::Cmd::Create;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Create a DNS zone

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options usage_string => 'USAGE: hcloud.pl zone create --name <domain> [--ttl <seconds>]';
use JSON::MaybeXS qw(encode_json);

option name => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => 'Zone name (domain)',
);

option ttl => (
    is     => 'ro',
    format => 'i',
    doc    => 'Default TTL in seconds',
);

sub execute {
    my ($self, $args, $chain) = @_;

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    my %params = (
        name => $self->name,
    );
    $params{ttl} = $self->ttl if $self->ttl;

    my $zone = $cloud->zones->create(%params);

    if ($main->output eq 'json') {
        print encode_json($zone->data), "\n";
        return;
    }

    print "Zone created:\n";
    printf "  ID:     %s\n", $zone->id;
    printf "  Name:   %s\n", $zone->name;
    printf "  Status: %s\n", $zone->status // 'pending';

    my $ns = $zone->ns;
    if (@$ns) {
        print "  Nameservers:\n";
        for my $n (@$ns) {
            print "    - $n\n";
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::Zone::Cmd::Create - Create a DNS zone

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
