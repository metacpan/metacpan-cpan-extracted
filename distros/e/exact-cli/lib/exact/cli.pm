package exact::cli;
# ABSTRACT: Command-line interface helper utilities extension for exact

use 5.014;
use exact;
use Util::CommandLine 1.04 ();

our $VERSION = '1.08'; # VERSION

sub import {
    my ( $self, $params, $caller ) = @_;
    $caller //= caller();

    my @methods = qw( options pod2usage readmode singleton );
    {
        no strict 'refs';

        for (@methods) {
            my $method = "Util::CommandLine::$_";
            *{ $caller . '::' . $_ } = \&$method unless ( defined &{ $caller . '::' . $_ } );
        }

        for ('podhelp') {
            *{ $caller . '::' . $_ } = \&$_ unless ( defined &{ $caller . '::' . $_ } );
        }
    }
}

sub podhelp {
    Util::CommandLine::options();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

exact::cli - Command-line interface helper utilities extension for exact

=head1 VERSION

version 1.08

=for markdown [![test](https://github.com/gryphonshafer/exact-cli/workflows/test/badge.svg)](https://github.com/gryphonshafer/exact-cli/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/exact-cli/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/exact-cli)

=head1 SYNOPSIS

    use exact -cli;

=head1 DESCRIPTION

L<exact::cli> is command-line interface helper utilities extension for L<exact>.
It effectively is an integration of L<Util::CommandLine> with L<exact>.
Consult the L<Util::CommandLine> documentation for additional information.
See the L<exact> documentation for additional information about
extensions. The intended use of L<exact::cli> is via the extension interface
of L<exact>.

    use exact -cli, -conf, -noutf8;

However, you can also use it directly, which will also use L<exact> with
default options:

    use exact::cli;

=head1 IMPORTED FUNCTIONS

The following functions are imported:

=head2 options

This is the same function from L<Util::CommandLine>.

=head2 pod2usage

This is the same function from L<Util::CommandLine>.

=head2 readmode

This is the same function from L<Util::CommandLine>.

=head2 singleton

This function is the equivalent of the C<singleton> flag to L<Util::CommandLine>.

    use Util::CommandLine 'singleton';

However, note that calling this method executes the functionally at runtime, not
during import, which is normally what happens with L<Util::CommandLine>.

=head2 podhelp

This function is the equivalent of the C<podhelp> flag to L<Util::CommandLine>.

    use Util::CommandLine 'podhelp';

However, note that calling this method executes the functionally at runtime, not
during import, which is normally what happens with L<Util::CommandLine>.

=head1 SEE ALSO

You can look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/exact-cli>

=item *

L<MetaCPAN|https://metacpan.org/pod/exact::cli>

=item *

L<GitHub Actions|https://github.com/gryphonshafer/exact-cli/actions>

=item *

L<Codecov|https://codecov.io/gh/gryphonshafer/exact-cli>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/exact-cli>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/D/exact-cli.html>

=back

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2050 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
