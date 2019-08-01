package XT::Files::Plugin::Excludes;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use parent 'XT::Files::Plugin';

sub run {
    my ( $self, $args ) = @_;

    my $xtf = $self->xtf;

  ARG:
    for my $arg ( @{$args} ) {
        my ( $key, $value ) = @{$arg};

        if ( $key eq 'exclude' ) {
            $xtf->exclude($value);
            next ARG;
        }

        $self->log_fatal("Invalid configuration option '$key = $value' for plugin 'Excludes'");
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XT::Files::Plugin::Excludes - plugin to configure excludes

=head1 VERSION

Version 0.001

=head1 SYNOPSIS

In the L<XT::Files> config file:

    [Excluded]
    exclude = [.]old$

=head1 DESCRIPTION

Configure excludes for L<XT::Files>. Excludes are regexes that are matched
against the base name of found files and if the file name matches the file
is not tested.

Use this to exclude backup files or temporary files from your editor.

The C<exclude> option can be used multiple times to add multiple excludes.

=head1 USAGE

=head2 new

Inherited from L<XT::Files::Plugin>.

=head2 run

The C<run> method should not be run directly. Use the C<plugin> call from
L<XT::Files>

=head1 SEE ALSO

L<XT::Files>, L<XT::Files::Plugin>, L<XT::Files::Plugin::Default>

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/skirmess/XT-Files/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/skirmess/XT-Files>

  git clone https://github.com/skirmess/XT-Files.git

=head1 AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
