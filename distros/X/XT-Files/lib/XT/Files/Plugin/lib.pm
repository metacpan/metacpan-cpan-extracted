package XT::Files::Plugin::lib;    ## no critic (NamingConventions::Capitalization)

use 5.006;
use strict;
use warnings;

our $VERSION = '0.002';

use parent 'XT::Files::Plugin';

use Cwd ();
use lib ();

sub run {
    my ( $self, $args ) = @_;

  ARG:
    for my $arg ( @{$args} ) {
        my ( $key, $value ) = @{$arg};

        if ( $key eq 'lib' ) {
            if ( -d $value ) {
                my $dir = Cwd::abs_path($value);

                if ( ( defined $dir ) && ( -d $dir ) ) {
                    lib->import($dir);
                }
            }

            next ARG;
        }

        $self->log_fatal("Invalid configuration option '$key = $value' for plugin 'lib'");
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XT::Files::Plugin::lib - allow loading of local plugins

=head1 VERSION

Version 0.002

=head1 SYNOPSIS

In the L<XT::Files> config file:

    [lib]
    lib = xt/lib

=head1 DESCRIPTION

Prepends the specified path to the C<@INC>. This can be used to load
L<XT::Files> plugins distributed with the distribution.

Add the library you would like to have added to C<@INC> in your distributions
L<XT::Files> configuration file in the section of the C<lib> plugin.

=head1 USAGE

=head2 new

Inherited from L<XT::Files::Plugin>.

=head2 run

The C<run> method should not be run directly. Use the C<plugin> call from
L<XT::Files>

=head1 SEE ALSO

L<XT::Files>, L<XT::Files::Plugin>

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
