package WWW::Hetzner::CLI::Cmd::Iso;
# ABSTRACT: ISO commands

our $VERSION = '0.101';

use Moo;
use MooX::Cmd;
use MooX::Options usage_string => 'USAGE: hcloud.pl iso [--architecture x86|arm] [--name NAME] [options]';
use JSON::MaybeXS qw(encode_json);


option architecture => (
    is     => 'ro',
    format => 's',
    doc    => 'Filter by architecture (x86, arm)',
);


option name => (
    is     => 'ro',
    format => 's',
    doc    => 'Filter by exact ISO name',
);


sub execute {
    my ($self, $args, $chain) = @_;

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    my %params;
    $params{architecture} = $self->architecture if $self->architecture;
    $params{name}         = $self->name         if $self->name;

    my $isos = $cloud->isos->list_all(%params);

    if ($main->output eq 'json') {
        print encode_json([ map { $_->data } @$isos ]), "\n";
        return;
    }

    if (!@$isos) {
        print "No ISOs found.\n";
        return;
    }

    printf "%-8s %-40s %-8s %-6s %s\n", 'ID', 'NAME', 'TYPE', 'ARCH', 'DEPRECATED';
    printf "%-8s %-40s %-8s %-6s %s\n", '-' x 8, '-' x 40, '-' x 8, '-' x 6, '-' x 10;

    for my $iso (@$isos) {
        printf "%-8s %-40s %-8s %-6s %s\n",
            $iso->id,
            $iso->name // '-',
            $iso->type // '-',
            $iso->architecture // '-',
            ($iso->deprecation ? $iso->deprecation->{unavailable_after}
                               : $iso->deprecated) // '-';
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::Iso - ISO commands

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    hcloud.pl iso                            # List ISOs
    hcloud.pl iso --architecture arm         # Only ARM ISOs
    hcloud.pl iso --name netboot.xyz.iso     # Look up one ISO by name

=head2 --architecture

Only list ISOs for that CPU architecture: C<x86> or C<arm>.

=head2 --name

Only list the ISO with that exact name.

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
