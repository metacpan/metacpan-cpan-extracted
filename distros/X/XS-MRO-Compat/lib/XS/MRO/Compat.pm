package XS::MRO::Compat;

use 5.008_001;
use strict;

our $VERSION = '0.14';

if($] < 5.010_000){
	require MRO::Compat;
	require DynaLoader; # unfortunately, XSLoader does not look at dl_load_flags()

	local *dl_load_flags = sub(){ 0x01 };
	__PACKAGE__->DynaLoader::bootstrap_inherit($VERSION);
}

1;
__END__

=for stopwords mro gfx pre API

=head1 NAME

XS::MRO::Compat - Provides mro functions for XS modules

=head1 VERSION

This document describes XS::MRO::Compat version 0.14.

=head1 SYNOPSIS

	# In your XS distribution

	use inc::Module::Install;

	# Add the following to your Makefile.PL
	use_ppport;
	requires_xs 'XS::MRO::Compat'; # see Module::Install::XSUtil

	/* Then put the "include" directive in your Module.xs */

	/* ... */
	#include "ppport.h"

	#include "mro_compat.h"

	/* Now you can use several mro functions in your Module.xs:
		mro_get_linear_isa()
		mro_get_pkg_gen()
		mro_method_changed_in()
	*/

	# And use XS::MRO::Compat in your module
	use XS::MRO::Compat;

=head1 DESCRIPTION

C<XS::MRO::Compat> provides several mro functions for XS modules.

This feature is provided by C<Module::Install::XSUtil>.

=head1 XS interface

=head2 AV* mro_get_linear_isa(HV* stash)

The same as C<mro::get_linear_isa()> in Perl.

In 5.10 or later, it is just a public Perl API.

In 5.8.x, it calls C<mro::get_linear_isa> provided by C<MRO::Compat>. It has a
cache mechanism as Perl 5.10 does, so it is much faster than the direct call of
C<mro::get_linear_isa> provided by C<MRO::Compat>.

=head2 void mro_method_changed_in(HV* stash)

The same as C<mro::method_changed_in()> in Perl.

=head2 U32 mro_get_pkg_gen(HV* stash)

The same as C<mro::get_pkg_gen()> in Perl. This is not a Perl API.

This may evaluate I<stash> more than once.

=head1 DEPENDENCIES

Perl 5.8.1 or later, and a C compiler.

=head1 BUGS

No bugs have been reported.

Please report any bugs or feature requests to the author.

=head1 AUTHOR

Goro Fuji(gfx) E<lt>gfuji(at)cpan.orgE<gt>.

=head1 SEE ALSO

L<mro>.

L<perlapi/"MRO Functions">.

L<MRO::Compat>.

L<Module::Install::XSUtil>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008-2009, Goro Fuji (gfx). Some rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
