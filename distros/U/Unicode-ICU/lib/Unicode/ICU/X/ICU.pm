# Copyright 2022 cPanel, LLC. (copyright@cpanel.net)
# Author: Felipe Gasper
#
# Copyright (c) 2022, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

package Unicode::ICU::X::ICU;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Unicode::ICU::X::ICU - Errors from ICU functions

=head1 DESCRIPTION

This class indicates a generic error from some ICU function.
It extends L<Unicode::ICU::X::Base>.

=head1 ATTRIBUTES

=over

=item * C<function> - The name of the ICU function that indicated
failure.

=item * C<error> - The numeric error code. (cf. L<Unicode::ICU>’s
C<get_error_name()>)

=item * C<extra> - Either undef or some string that contains extra
(potentially useful) diagnostic information.

=back

=cut

#----------------------------------------------------------------------

use parent 'Unicode::ICU::X::Base';

use Unicode::ICU;

sub _new {
    my ($class, $icu_func, $errnum, $extra_msg) = @_;

    my $errname = Unicode::ICU::get_error_name($errnum);

    my $msg = "ICU ($icu_func) error: $errname";
    if (defined $extra_msg) {
        $msg .= " ($extra_msg)";
    }

    return $class->SUPER::_new($msg,
        function => $icu_func,
        error => $errnum,
        extra => $extra_msg,
    );
}

1;
