package Try;
BEGIN {
  $Try::AUTHORITY = 'cpan:DOY';
}
{
  $Try::VERSION = '0.03';
}
use strict;
use warnings;
# ABSTRACT: nicer exception handling syntax

use Devel::CallParser;
use XSLoader;

XSLoader::load(
    __PACKAGE__,
    exists $Try::{VERSION} ? ${ $Try::{VERSION} } : (),
);

use Exporter 'import';
our @EXPORT = our @EXPORT_OK = ('try');

use Try::Tiny ();



sub try {
    my ($try, $catch, $finally) = @_;
    &Try::Tiny::try(
        $try,
        ($catch   ? (&Try::Tiny::catch($catch))     : ()),
        ($finally ? (&Try::Tiny::finally($finally)) : ()),
    );
}


1;

__END__

=pod

=head1 NAME

Try - nicer exception handling syntax

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    try {
        die "foo";
    }
    catch {
        when (/foo/) {
            warn "Caught foo";
        }
    }

=head1 DESCRIPTION

This module implements a try/catch/finally statement. It is based heavily on
(and mostly implemented via) L<Try::Tiny>. The differences are:

=over 4

=item *

It is a statement. C<< my $foo = try { ... } >> doesn't work anymore, but in
return, you don't have to remember the trailing semicolon anymore. C<eval>
still works fine if you need an expression (in 5.14+ at least).

=item *

The blocks are ordered, and only one catch and finally block are supported.
C<< try { } finally { } catch { } >> and
C<< try { } catch { } finally { } finally { } >> do not work with this module,
mostly because that's just extra complexity for no real purpose.

=item *

C<catch> and C<finally> are no longer exported - they are just part of the
syntax of the C<try> statement. This is almost certainly not an issue.

=back

=head1 EXPORTS

=head2 try

C<try> takes a block to run, and catch exceptions from. The block can
optionally be followed by C<catch> and another block and C<finally> and another
block. The C<catch> block is run when the C<try> block throws an exception, and
the exception thrown will be in both C<$_> and C<@_>. The C<finally> block will
be run after the C<try> and C<catch> blocks regardless of what happens, even if
the C<catch> block rethrows the exception. The exception thrown will be in
C<@_> but B<not> C<$_> (this may change in the future, since I'm pretty sure
the reasoning for this is no longer useful in 5.14).

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-try at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Try>.

=head1 SEE ALSO

L<Try::Tiny>, L<TryCatch>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Try

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Try>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Try>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Try>

=item * Search CPAN

L<http://search.cpan.org/dist/Try>

=back

=head1 AUTHOR

Jesse Luehrs <doy at cpan dot org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
