=pod

=encoding utf-8

=head1 PURPOSE

Test that prototypes work.

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
	sub foo {
		my $self = shift;
		my ($coderef, @args) = @_;
		uc $coderef->($self, @args);
	}
	bless { foo => 123 };
};

use methods::import qw(foo==&@);
for ($o) {
	my $r = foo {
		join '/', $_[0]{foo}, $_[1];
	} 'abc';
	is $r, '123/ABC';
}

done_testing;

