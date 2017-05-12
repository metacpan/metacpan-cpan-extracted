package XML::Smart::Shared  ;

use 5.006                   ;

use strict                  ;
use warnings FATAL => 'all' ;

use Exporter 'import'       ;

=head1 NAME

XML::Smart::Shared - Shared functions and variables for XML::Smart.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Shared functions and variables for XML::Smart.

=head1 EXPORT

All functions are exported through export_ok

=cut 

our @EXPORT_OK = qw(_unset_sig_warn _reset_sig_warn SIG_WARN _unset_sig_die _reset_sig_die SIG_DIE );  

=head1 GLOBAL VARIABLES

our ( $SIG_WARN , $SIG_DIE )  ;

=cut

my ( $SIG_WARN , $SIG_DIE )  ;

=head1 SUBROUTINES/METHODS

=head2 _unset_sig_warn

This function saves current __WARN__ and sets it to none. 

=cut

sub _unset_sig_warn {
    $SIG_WARN = $SIG{__WARN__} ;
    $SIG{__WARN__} = sub {} ;
}

=head2 _reset_sig_warn

This function replaces __WARN__ with value saved by _unset_sig_warn

=cut

sub _reset_sig_warn {
    $SIG{__WARN__} = $SIG_WARN ;
}


=head2 _unset_sig_die

This function saves current __DIE__ and sets it to none. 

=cut

sub _unset_sig_die {
    $SIG_DIE  = $SIG{__DIE__}  ;
    $SIG{__DIE__}  = sub {}    ;
}

=head2 _reset_sig_die

This function replaces __DIE__ with value saved by _unset_sig_warn

=cut

sub _reset_sig_die {
    $SIG{__DIE__}  = $SIG_DIE  ;
}


=head1 AUTHOR

Harish Madabushi, C<< <harish.tmh at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xml-smart at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Smart>.  Both the author and the
maintainer will be notified, and then you'll automatically be notified of progress on your bug as changes are made.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::Smart

You can also look for information at:

=over 5

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Smart>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-Smart>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-Smart>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-Smart/>

=item * GitHub CPAN

L<https://github.com/harishmadabushi/XML-Smart>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Harish Madabushi.

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

1; # End of XML::Smart::Shared
