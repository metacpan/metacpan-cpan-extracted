=pod

=encoding utf-8

=head1 PURPOSE

Test that namespace::lexical compiles and works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

BEGIN {
	package My::Test;
	use Scalar::Util qw(blessed);
	use namespace::lexical;
	use Scalar::Util qw(looks_like_number);
	sub blah {
		looks_like_number($_[0])
			or do { package ABC::DEF; blessed($_[0]) };
	}
	sub get_blessed {
		package ABC::DEF;
		\&blessed;
	}
	sub eval_blessed {
		my $thing = shift;
		eval 'package ABC::DEF; blessed($thing)';
	}
};

ok(  My::Test->can('blah') );
ok(  My::Test->can('looks_like_number') );
ok( !My::Test->can('blessed') );
ok(  My::Test::blah(42) );
ok(  My::Test::blah(bless {}) );
ok( !My::Test::blah("xyz") );
ok( !My::Test::blah([]) );
is(  ref(My::Test::get_blessed()), 'CODE' );
ok(  My::Test::get_blessed()->(bless {}) );
ok( !My::Test::get_blessed()->({}) );
ok( !My::Test::get_blessed()->(42) );
ok(  My::Test::eval_blessed(bless {}) );
ok( !My::Test::eval_blessed({}) );
ok( !My::Test::eval_blessed(42) );
ok( !ABC::DEF->can('blessed') );

done_testing;

