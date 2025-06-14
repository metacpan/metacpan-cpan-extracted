package exact::me;
# ABSTRACT: Original program path locations extension for exact

use 5.014;
use exact;
use FindBin;

our $VERSION = '1.06'; # VERSION

sub import {
    my ( $self, $params, $caller ) = @_;
    $caller //= caller();

    {
        no strict 'refs';
        *{ $caller . '::me' } = \&me unless ( defined &{ $caller . '::me' } );
    }
}

sub me {
    my ($path) = @_;

    unless ($path) {
        return $FindBin::Bin;
    }
    elsif ( index( $path, '.', 0 ) == 0 ) {
        return $FindBin::Bin . '/' . $path;
    }
    else {
        return _find_dir($path);
    }

    return;
}

sub _find_dir {
    my ($suffix) = @_;

    my @search_path = split( '/', $FindBin::Bin );
    while ( @search_path > 0 ) {
        my $dir = join( '/', @search_path, $suffix );
        return $dir if ( -d $dir );
        pop @search_path;
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

exact::me - Original program path locations extension for exact

=head1 VERSION

version 1.06

=for markdown [![test](https://github.com/gryphonshafer/exact-me/workflows/test/badge.svg)](https://github.com/gryphonshafer/exact-me/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/exact-me/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/exact-me)

=head1 SYNOPSIS

    use exact -me;

    say me();              # full path to $0
    say me('../dir/file'); # full path based on relative dir from $0 dir
    say me('dir/file');    # full path found from $0 dir or in a parent of it

=head1 DESCRIPTION

L<exact::me> is an extension for L<exact> that imports a C<me()> function into
the calling namespace.

    use exact -me;

=head1 IMPORTED FUNCTION

The following function is imported:

=head2 me

This function when called without any input will return the path to the current
program (C<$0>):

    say me(); # full path to $0

When provided with a relative path, it will generate a full path by combining
the input with a full path to the current program (C<$0>):

    say me('../dir/file'); # full path based on relative dir from $0 dir

For input that is a relative path that does not begin with ".", a relative
path will be searched for at or above the directory of the program (C<$0>). If
found, that path will be returned; otherwise, C<undef>.

    say me('dir/file'); # full path found from $0 dir or in a parent of it

See the L<exact> documentation for additional information about
extensions. The intended use of L<exact::me> is via the extension interface
of L<exact>.

    use exact -me, -conf, -noutf8;

However, you can also use it directly, which will also use L<exact> with
default options:

    use exact::me;

=head1 SEE ALSO

You can look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/exact-me>

=item *

L<MetaCPAN|https://metacpan.org/pod/exact::me>

=item *

L<GitHub Actions|https://github.com/gryphonshafer/exact-me/actions>

=item *

L<Codecov|https://codecov.io/gh/gryphonshafer/exact-me>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/exact-me>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/D/exact-me.html>

=back

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020-2050 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
