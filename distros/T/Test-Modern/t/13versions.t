=pod

=encoding utf-8

=head1 PURPOSE

Test that Test::Modern's version testing works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern qw( -more -versions );

version_ok('lib/Test/Modern.pm');

version_all_ok();

version_all_same();

done_testing( 3 + !$ENV{PERL_TEST_MODERN_ALLOW_WARNINGS} );
