=head1 PURPOSE

Check the C<< -anon >> import option works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More;

like
	do {use package::compute -anon; __PACKAGE__ },
	qr{__ANON__},
;
done_testing;
