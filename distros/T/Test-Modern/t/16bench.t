=pod

=encoding utf-8

=head1 PURPOSE

Test Test::Modern's C<is_fastest>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern -benchmark;
no warnings qw(recursion);

sub fib {
	my $n = shift;
	$n<2 ? $n : fib($n-1)+fib($n-2);
}

is_fastest('fib_3', -1, {
	fib_3    => q{ fib(3) },
	fib_13   => q{ fib(13) },
});

done_testing;
