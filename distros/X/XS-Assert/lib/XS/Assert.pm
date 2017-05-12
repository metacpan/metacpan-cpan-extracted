package XS::Assert;

use 5.005_03;

$VERSION = '0.002';

1;
__END__

=head1 NAME

XS::Assert - Provides assertion macros for XS modules

=head1 VERSION

This document describes XS::Assert version 0.002.

=head1 SYNOPSIS

    # in your Makefile.PL
    requires_xs 'XS::Assert'; # done by M::X::XSUtil

    /* in MyModule.xs */
	#include "xs_assert.h"

	/* and later */

	assert_sv_ok(sv);
	assert_sv_is_av(sv);

=head1 DESCRIPTION

XS::Assert provides various assertion macros for XS modules,
which are enabled only if C<XS_ASSERT> macro is defined.

=head1 MACROS

=head2 assert(expr)

=head2 assert_not_null(ptr)

=head2 assert_sv_type_is(sv, svtype)

=head2 assert_sv_is_av(sv)

=head2 assert_sv_is_hv(sv)

=head2 assert_sv_is_cv(sv)

=head2 assert_sv_is_gv(sv)

=head2 assert_sv_is_avref(sv)

=head2 assert_sv_is_hvref(sv)

=head2 assert_sv_is_cvref(sv)

=head2 assert_sv_is_gvref(sv)

=head2 assert_sv_is_object(sv)

=head2 assert_sv_ok(sv)

=head2 assert_sv_pok(sv)

=head2 assert_sv_iok(sv)

=head2 assert_sv_nok(sv)

=head2 assert_sv_rok(sv)

=head1 DEPENDENCIES

Perl 5.5.3 or later, and a C compiler.

=head1 BUGS

No bugs have been reported.

Please report any bugs or feature requests to the author.

=head1 SEE ALSO

L<Module::Install::XSUtil>.

=head1 AUTHOR

Goro Fuji (gfx) E<lt>gfuji(at)cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Goro Fuji (gfx). Some rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
