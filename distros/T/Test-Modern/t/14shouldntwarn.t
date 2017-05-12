=pod

=encoding utf-8

=head1 PURPOSE

Test that Test::Modern's C<shouldnt_warn> function works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern qw( -more shouldnt_warn );

shouldnt_warn {
	
	is(1, 1);
	
	is(2, 2);
	
	my $x = "hello";
	my $y = 1 + $x;
	
	is(3, 3);
	
	is(4, 4);
};

done_testing;
