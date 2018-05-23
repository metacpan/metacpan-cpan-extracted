=pod

=encoding utf-8

=head1 PURPOSE

Test that Type::Tiny::XS's Bool implementation disallows blessed objects.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More tests => 9;

use_ok('Type::Tiny::XS');

my $code = Type::Tiny::XS::get_coderef_for('Bool');

ok $code->(0);
ok $code->(1);
ok $code->("");
ok $code->(undef);

BEGIN {
	package MyBool;
	use overload bool => sub { not ${ $_[0] } }, fallback => 1;
	our $TRUE  = bless do { my $x = 0; \$x };
	our $FALSE = bless do { my $x = 1; \$x };
};

ok     $MyBool::TRUE;
ok not $MyBool::FALSE;
ok not $code->($MyBool::TRUE);
ok not $code->($MyBool::FALSE);

done_testing;
