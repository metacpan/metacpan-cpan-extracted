package Test2::Tools::Explain;

use 5.008001;
use strict;
use warnings;

=head1 NAME

Test2::Tools::Explain -- Explain tools for Perl's Test2 framework

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

use parent 'Exporter';

our @EXPORT_OK = qw(
    explain
);

our @EXPORT = @EXPORT_OK;

=head1 SYNOPSIS

L<Test2::Suite> dropped the C<explain()> function that had been
part of Test::More.  For those who miss it in Test2, you can use
Test2::Tools::Explain.

    use Test2::Tools::Explain;

    my $errors = fleeble_the_whatzit();
    is( $errors, [], 'Should have no errors from fleebling' ) or diag explain( $errors );

=head1 EXPORTS

All functions in this module are exported by default.

=head1 SUBROUTINES

=head2 explain( @things_to_explain )

Will convert the contents of any references in a human readable format,
and return them as strings.  Usually you want to pass this into C<note>
or C<diag>.

Handy for things like:

    is( $errors, [], 'Should have no errors' ) or diag explain( $errors );

Note that C<explain> does NOT output anything.

=cut

sub explain {
    local ($@, $!);
    require Data::Dumper;

    return map {
        ref $_
        ? do {
            my $dumper = Data::Dumper->new( [$_] );
            $dumper->Indent(1)->Terse(1);
            $dumper->Sortkeys(1) if $dumper->can('Sortkeys');
            $dumper->Dump;
        }
        : $_
    } @_;
}

=head1 AUTHOR

Andy Lester, C<< <andy at petdance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
L<https://github.com/petdance/test2-tools-explain>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test2::Tools::Explain

You can also look for information at:

=over 4

=item * GitHub project page

L<https://github.com/petdance/test2-tools-explain>

=item * Search CPAN

L<http://search.cpan.org/dist/Test2-Tools-Explain/>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test2-Tools-Explain>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test2-Tools-Explain>

=back

=head1 ACKNOWLEDGEMENTS

The code for C<explain> is originally from C<Test::More> by Michael
Schwern, who took it from C<Test::Most> by Curtis Poe.

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Andy Lester.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Test2::Tools::Explain
