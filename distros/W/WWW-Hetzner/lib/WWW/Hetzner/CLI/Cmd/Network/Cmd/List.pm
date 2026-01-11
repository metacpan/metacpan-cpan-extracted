package WWW::Hetzner::CLI::Cmd::Network::Cmd::List;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: List networks

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl network list';
use JSON::MaybeXS qw(encode_json);

sub execute {
    my ($self, $args, $chain) = @_;

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    my $networks = $cloud->networks->list;

    if ($main->output eq 'json') {
        print encode_json([ map { $_->data } @$networks ]), "\n";
        return;
    }

    if (!@$networks) {
        print "No networks found.\n";
        return;
    }

    printf "%-8s %-25s %-18s %-10s\n", 'ID', 'NAME', 'IP_RANGE', 'SERVERS';
    printf "%-8s %-25s %-18s %-10s\n", '-' x 8, '-' x 25, '-' x 18, '-' x 10;

    for my $n (@$networks) {
        printf "%-8s %-25s %-18s %-10d\n",
            $n->id,
            $n->name // '-',
            $n->ip_range // '-',
            scalar(@{ $n->servers // [] });
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::Network::Cmd::List - List networks

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
