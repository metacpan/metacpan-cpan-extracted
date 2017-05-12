=pod

=encoding utf-8

=head1 PURPOSE

Test that Types::UUID works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More 0.96;
use Test::TypeTiny;

use Types::UUID;

should_pass('712391e0-ac82-11e3-9aff-f2c229fd71d9', Uuid);
should_pass('712391E0-AC82-11E3-9AFF-F2C229FD71D9', Uuid);
should_fail('712391e0ac82-11e3-9aff-f2c229fd71d9', Uuid);
should_fail('urn:uuid:712391e0-ac82-11e3-9aff-f2c229fd71d9', Uuid);

should_pass(Uuid->coerce(undef), Uuid, 'Value coerced from undef passes type constraint Uuid');
should_fail(Uuid->coerce(''), Uuid, 'Value coerced from empty string fails type constraint Uuid');
should_fail(Uuid->coerce([]), Uuid, 'Value coerced from [] fails type constraint Uuid');
should_fail(Uuid->coerce({}), Uuid, 'Value coerced from {} fails type constraint Uuid');

my $from_uri = Uuid->coerce('urn:uuid:712391E0-AC82-11E3-9AFF-F2C229FD71D9');
should_pass($from_uri, Uuid, 'Value coerced from URI passes type constraint Uuid');
is(lc($from_uri), '712391e0-ac82-11e3-9aff-f2c229fd71d9', '... and is the expected value');

my $from_str = Uuid->coerce('7123-91E0AC8211E39AFFF2C229FD-71D9');
should_pass($from_str, Uuid, 'Value coerced from weirdly formatted string passes type constraint Uuid');
is(lc($from_str), '712391e0-ac82-11e3-9aff-f2c229fd71d9', '... and is the expected value');

SKIP: {
	skip "URI not installed", 2 unless eval { require URI };
	
	my $from_obj = Uuid->coerce( URI->new("urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6") );
	should_pass($from_obj, Uuid, 'Value coerced from URI object passes type constraint Uuid');
	is(lc($from_obj), 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6', '... and is the expected value');
}

should_pass( Uuid->generate, Uuid, 'Uuid->generate' );
should_pass( Uuid->generator->(), Uuid, 'Uuid->generator' );

done_testing;

