=pod

=encoding utf-8

=head1 PURPOSE

Test that Types::LoadableClass works without Moose.

=head1 AUTHOR

Tomas Doran E<lt>bobtfish@bobtfish.netE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2010 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Class::Load 'is_class_loaded';
use Types::LoadableClass qw(LoadableClass LoadableRole);

ok !is_class_loaded('FooBarTestClassPlain');
ok LoadableClass->check('FooBarTestClassPlain');
ok is_class_loaded('FooBarTestClassPlain');

ok !LoadableClass->check('FooBarTestClassDoesNotExist');

ok !is_class_loaded('FooBarTestRolePlain');
ok LoadableRole->check('FooBarTestRolePlain');
ok is_class_loaded('FooBarTestRolePlain');

ok !LoadableRole->check('FooBarTestClassPlain');

ok !LoadableRole->check('FooBarTestRoleDoesNotExist');

if ( $ENV{EXTENDED_TESTING} ) {
	ok !$INC{'Moose.pm'};
}

done_testing;
