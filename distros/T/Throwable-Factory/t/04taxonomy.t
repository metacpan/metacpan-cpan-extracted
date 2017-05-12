=head1 PURPOSE

Check that taxonomy role shortcuts (C<< -caller >>, C<< -environment >> and
C<< -notimplemented >>) work.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Try::Tiny;
use Throwable::Factory
	A => ['-caller'],
	B => ['-environment'],
	C => ['-notimplemented'],
;

try {
	A->throw;
}
catch {
	ok( $_->DOES('Throwable::Taxonomy::Caller') );
};

try {
	B->throw;
}
catch {
	ok( $_->DOES('Throwable::Taxonomy::Environment') );
};

try {
	C->throw;
}
catch {
	ok( $_->DOES('Throwable::Taxonomy::NotImplemented') );
};

ok not eval q { use Throwable::Factory D => ['-foobar']; D(); 1 };
like $@, qr/Shortcut '-foobar' has no matches/;

{
	package Local::Error::Foobar;
	use Moo::Role;
	push @Throwable::Factory::SHORTCUTS, __PACKAGE__;
}

ok eval q { use Throwable::Factory E => ['-foobar']; E(); 1 };

{
	package Local::Error2::Foobar;
	use Moo::Role;
	push @Throwable::Factory::SHORTCUTS, __PACKAGE__;
}

ok not eval q { use Throwable::Factory F => ['-foobar']; F(); 1 };
like $@, qr/Shortcut '-foobar' has too many matches/;

done_testing;
