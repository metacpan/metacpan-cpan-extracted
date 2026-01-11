package WWW::Hetzner::CLI::Cmd::Servertype;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Server type commands

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options usage_string => 'USAGE: hcloud.pl servertype [options]';
use JSON::MaybeXS qw(encode_json);

sub execute {
    my ($self, $args, $chain) = @_;

    my $main = $chain->[0];
    my $cloud = $main->cloud;
    my $types = $cloud->server_types->list;

    if ($main->output eq 'json') {
        print encode_json($types), "\n";
        return;
    }

    printf "%-10s %-12s %-8s %-10s %-10s %s\n",
        'ID', 'NAME', 'CORES', 'MEMORY', 'DISK', 'DEPRECATED';
    print "-" x 70, "\n";

    for my $t (@$types) {
        printf "%-10s %-12s %-8s %-10s %-10s %s\n",
            $t->{id},
            $t->{name},
            $t->{cores},
            $t->{memory} . ' GB',
            $t->{disk} . ' GB',
            $t->{deprecated} ? 'yes' : '-';
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::Servertype - Server type commands

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
