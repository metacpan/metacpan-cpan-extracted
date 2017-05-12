=pod

=encoding utf-8

=head1 PURPOSE

Test that Test::Modern's C<< -requires >> feature works with
C<< "perl" >> as a requirement.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern -requires => { perl => 9 };

fail("This was supposed to be skipped!!!");

done_testing;
