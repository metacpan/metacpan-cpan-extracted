package XS::MagicExt;

use 5.008_001;
use strict;

our $VERSION = '0.05';

use DynaLoader;
local *dl_load_flags = sub{ 0x01 };
DynaLoader::bootstrap_inherit(__PACKAGE__, $VERSION);

1;
__END__

=head1 NAME

XS::MagicExt - Provides PERL_MAGIC_ext manipulators for XS modules

=head1 VERSION

This document describes XS::MagicExt version 0.05.

=head1 SYNOPSIS

	# in Makefile.PL
	requires_xs 'XS::MagicExt'; # done by Module::Install::XSUtil

	# in YourModule.pm
	use XS::MagicExt;

	/* Then, in YourModule.xs */

	#include "magic_ext.h"

	static MGVTBL id;

	/* ... */
	void foo(pTHX_ SV* sv){
		SV* obj = newSViv(42);
		/* ... */

		mg = mgx_attach(sv, &id, obj);

		mg = mgx_find(sv, &id);
		mg = MGX_FIND(sv, &id);
		mg = mgx_get(sv, &id);

		if(SvOK(MG_obj(mg))){
			/* ... */
		}

		mgx_detach(sv, &id);
	}

=head1 DESCRIPTION

XS::MagicExt provides MAGIC manipulators for XS modules.

MAGIC manipulators are an interface to C<sv_magicext()>, C<mg_find()>, and
C<sv_unmagic()>, which distinguish magic identities from others' MAGICs by C<MGVTBL>.

=head1 FUNCTIONS

=head2 MAGIC* mgx_attach_with_ptr(SV* sv, MGVTBL* id, SV* obj, void* ptr, I32 len)

Attaches a MAGIC identified by I<id> to I<sv> with I<obj> and I<ptr> / I<len>.

Similar to C<sv_magicext(sv, obj, PERL_MAGIC_ext, id, ptr, len)>, but does not increase
the refcount of I<obj>.

=head2 MAGIC* mgx_attach_with_sv(SV* sv, MGVTBL* id, SV* obj, SV* data)

Attaches a MAGIC identified by I<id> to I<sv> with I<obj> and I<data>,
not increasing the refcount of I<data>.

The same as C<mgx_attach_with_ptr(sv, id, obj, (SV*)ptr, HEf_SVKEY)>.

=head2 MAGIC* mgx_attach(SV* sv, MGVTBL* id, SV* obj)

Attaches a MAGIC identified by I<id> to I<sv> with I<obj>.

The same as C<mgx_attach_with_ptr(sv, id, obj, NULL, 0)>.

=head2 MAGIC* mgx_find(SV* sv, const MGVTBL* id)

Finds a MAGIC identified by I<id>.

If not found, it will return NULL.

=head2 MAGIC* mgx_get(SV* sv, const MGVTBL* id)

Finds a MAGIC identified by I<id>.

If not found, it will die.

=head2 void mgx_detach(SV* sv, const MGVTBL* id)

Removes all the MAGICs identified by I<id>.

=head1 MACROS

=head2 MAGIC* MGX_FIND(SV* sv, const MGVTBL* id)

Checks if I<sv> has any MAGICs, and finds a MAGIC like C<mgx_find()>.

=head2 SV* MG_obj(MAGIC* mg)

The same as C<< mg->mg_obj >>.

=head2 U16 MG_private(MAGIC* mg)

The same as C<< mg->mg_private >>.

=head2 char* MG_ptr(mg)

The same as C<< mg->mg_ptr >>.

=head2 char* MG_len(mg)

The same as C<< mg->mg_len >>.

=head2 void* MG_vptr(mg)

The same as C<< (void*)mg->mg_ptr >>.

=head2 SV*   MG_sv(mg)

The same as C<< (SV*)mg->mg_ptr >>.

C<MG_len(mg)> must be C<HEf_SVKEY>.

=head2 SV* MG_sv_set(mg, sv)

Sets I<sv> to C<MG_sv(mg)>, and C<MG_len(mg) = HEf_SVKEY>.

=head2 bool  MG_ptr_is_sv(mg)

The same as C<< MG_len(mg) == HEf_SVKEY >>.

=head1 DEPENDENCIES

Perl 5.8.1 or later, and a C compiler.

=head1 BUGS

No bugs have been reported.

Please report any bugs or feature requests to the author.

=head1 SEE ALSO

F<magic_ext.h>.

L<perlapi>.

L<perlguts>.

F<sv.c>.

F<mg.h>.

F<mg.c>.

L<Module::Install::XSUtil>.

=head1 AUTHOR

Goro Fuji (gfx) E<lt>gfuji(at)cpan.orgE<gt>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Goro Fuji (gfx). Some rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
