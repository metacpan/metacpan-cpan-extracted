=pod

=encoding utf-8

=head1 PURPOSE

Test that methods::import compiles and works.

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
use Test::Fatal;

my $o = do {
	package Local::Foobar;
	sub foo { sprintf "foo(%s)", join ",", shift->{foo}, @_ }
	sub bar { sprintf "bar(%s)", join ",", shift->{bar}, @_ }
	bless { foo => 'F', bar => 'B' };
};

for ($o) {
	use methods::import qw( foo bar bar=bar1 ), { -curry => [1] };
	
	is foo(1,2,3), 'foo(F,1,2,3)';
	is bar(1,2,3), 'bar(B,1,2,3)';
	is bar1(2,3), 'bar(B,1,2,3)';
}

ok not __PACKAGE__->can('foo');
ok not __PACKAGE__->can('bar');
ok not __PACKAGE__->can('bar1');

for (undef) {
	use methods::import qw( foo=bar );
	my $e = exception { bar() };
	like($e, qr/Can't call method "foo" \(via imported sub "bar"\) because \$_ is not defined/);
}

done_testing;

