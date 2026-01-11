package WWW::Hetzner::CLI::Cmd::Volume::Cmd::Resize;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Resize a volume

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl volume resize <id> --size <gb>';

option size => (
    is       => 'ro',
    format   => 'i',
    required => 1,
    doc      => 'New size in GB (can only increase)',
);

sub execute {
    my ($self, $args, $chain) = @_;
    my $id = $args->[0] or die "Usage: hcloud.pl volume resize <id> --size <gb>\n";

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    print "Resizing volume $id to ", $self->size, " GB...\n";
    $cloud->volumes->resize($id, $self->size);
    print "Volume resized.\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::Volume::Cmd::Resize - Resize a volume

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
