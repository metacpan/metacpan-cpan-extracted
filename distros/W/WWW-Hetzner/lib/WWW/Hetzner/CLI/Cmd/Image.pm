package WWW::Hetzner::CLI::Cmd::Image;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Image commands

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options usage_string => 'USAGE: hcloud.pl image [--type system|snapshot|backup] [options]';
use JSON::MaybeXS qw(encode_json);

option type => (
    is      => 'ro',
    format  => 's',
    doc     => 'Filter by type (system, snapshot, backup)',
);

sub execute {
    my ($self, $args, $chain) = @_;

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    my %params;
    $params{type} = $self->type if $self->type;

    my $images = $cloud->images->list(%params);

    if ($main->output eq 'json') {
        print encode_json($images), "\n";
        return;
    }

    printf "%-10s %-20s %-10s %-15s %s\n",
        'ID', 'NAME', 'TYPE', 'OS', 'STATUS';
    print "-" x 70, "\n";

    for my $i (@$images) {
        printf "%-10s %-20s %-10s %-15s %s\n",
            $i->{id},
            $i->{name} // '-',
            $i->{type},
            ($i->{os_flavor} // '') . ' ' . ($i->{os_version} // ''),
            $i->{status};
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::Image - Image commands

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
