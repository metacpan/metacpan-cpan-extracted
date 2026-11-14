package mayhaps;

use v5.14;

our $VERSION = 'v0.1.2';

sub AUTOLOAD {
    my ($caller, $cond, @args) = @_;
    my ($method) = our $AUTOLOAD =~ /^mayhaps::(\w+)$/;
    return !!$cond ? $caller->$method(@args) : $caller;
}

## ABSTRACT: call methods conditionally for any class or object


1;

__END__

=pod

=encoding UTF-8

=for stopwords mayhaps

=head1 NAME

mayhaps - call methods conditionally for any class or object

=head1 VERSION

version v0.1.2

=head1 SYNOPSIS

    use mayhaps;

    $obj->mayhaps::frobnicate( $bool, @args );

is equivalent to

    ($bool) ? $obj->frobnicate(@args) : $obj;

=head1 DESCRIPTION

This module allows you to call methods conditionally.

Methods are prefixed with C<mehaps::>, and the first argument is a conditional.
When it is true, the method is called with the remaining arguments.
Otherwise it returns the object.

This is useful for chained methods, for example:

    my $rs = $schema->resultset('Books')
              ->with_authors
              ->with_publishers
              ->mayhaps::with_sales_stats( $is_internal );

=head2 What does "mayhaps" mean?

It is an archaic English synonym for "maybe".
There is already a module called L<maybe> with a different function.

=head1 EXPORTS

None.

=head1 SECURITY CONSIDERATIONS

There is no validation of the object or the calling method.

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/perl-mayhaps>
and may be cloned from L<https://github.com/robrwo/perl-mayhaps.git>

=head1 SUPPORT

Only the latest release of this module will be supported.

This module requires Perl v5.14 or later.
Future releases may only support Perl versions released in the last ten years.

=head2 Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/perl-mayhaps/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see F<SECURITY.md> for instructions how to report security vulnerabilities.

=head1 AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
