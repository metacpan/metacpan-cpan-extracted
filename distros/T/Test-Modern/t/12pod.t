=pod

=encoding utf-8

=head1 PURPOSE

Test that Test::Modern's pod testing works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern qw( -more -pod );

pod_file_ok(__FILE__);

all_pod_files_ok();

pod_coverage_ok("Test::Modern");

all_pod_coverage_ok();

done_testing( 4 + !$ENV{PERL_TEST_MODERN_ALLOW_WARNINGS} );
