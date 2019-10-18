=pod

=encoding utf-8

=head1 PURPOSE

Test the C<using> function's one argument version.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

my $o = do {
	package Local::Foobar;
	sub foo { sprintf "foo(%s)", join ",", shift->{foo}, @_ }
	sub bar { sprintf "bar(%s)", join ",", shift->{bar}, @_ }
	bless { foo => 'F', bar => 'B' };
};

do {
	use methods::import qw( foo bar bar=bar1 ), { -curry => [1] };
	using $o;
	is foo(1,2,3), 'foo(F,1,2,3)';
	is bar(1,2,3), 'bar(B,1,2,3)';
	is bar1(2,3), 'bar(B,1,2,3)';
	is using->{foo}, 'F';
	using undef;
	is using, undef;
};

ok not __PACKAGE__->can('foo');
ok not __PACKAGE__->can('bar');
ok not __PACKAGE__->can('bar1');
ok not __PACKAGE__->can('using');

done_testing;

