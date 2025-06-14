package exact::fun;
# ABSTRACT: Functions and methods with parameter lists for exact

use 5.014;
use exact;
use Import::Into;
use Class::Method::Modifiers ();
use Function::Parameters     ();

our $VERSION = '1.02'; # VERSION

sub import {
    my ( $self, $params, $caller ) = @_;
    Function::Parameters->import( ( $params and $params =~ /^mod/i ) ? ( qw( :std :modifiers ) ) : ':std' );
    Class::Method::Modifiers->import::into( $caller // caller() ) if ( $params and $params =~ /^cmm/i );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

exact::fun - Functions and methods with parameter lists for exact

=head1 VERSION

version 1.02

=for markdown [![test](https://github.com/gryphonshafer/exact-fun/workflows/test/badge.svg)](https://github.com/gryphonshafer/exact-fun/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/exact-fun/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/exact-fun)

=head1 SYNOPSIS

    use exact -fun;

    fun foo ( $x, $y, $z = 5 ) {
        return $x + $y + $z;
    }

    say foo( 1, 2 );

    method bar ( $label, $n ) {
        return "$label: " . ( $n * $self->scale );
    }

=head1 DESCRIPTION

L<exact::fun> is an extension for L<exact> that imports L<Function::Parameters>
into the calling namespace.

    use exact -fun;

It can optionally include the modifiers that come with L<Function::Parameters>.

    use exact 'fun(mod)';

If instead of the modifiers that come with L<Function::Parameters> you need to
import from L<Class::Method::Modifiers> instead, do this:

    use exact 'fun(cmm)';

See the L<exact> documentation for additional information about
extensions. The intended use of L<exact::fun> is via the extension interface
of L<exact>.

    use exact -fun, -conf, -noutf8;

However, you can also use it directly, which will also use L<exact> with
default options:

    use exact::fun;

=head1 SEE ALSO

You can look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/exact-fun>

=item *

L<MetaCPAN|https://metacpan.org/pod/exact::fun>

=item *

L<GitHub Actions|https://github.com/gryphonshafer/exact-fun/actions>

=item *

L<Codecov|https://codecov.io/gh/gryphonshafer/exact-fun>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/exact-fun>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/D/exact-fun.html>

=back

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2050 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
