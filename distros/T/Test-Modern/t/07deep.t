=pod

=encoding utf-8

=head1 PURPOSE

Check that Test::Modern's weird Test::Deep support works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use Test::Modern;

my $got1      = { foo => 1 };
my $got2      = { bar => 2 };
my $expected  = { foo => 1, bar => 2 };

cmp_deeply($got1, TD->subhashof($expected), '$got1 subhashof $expected');
cmp_deeply($got2, TD->subhashof($expected), '$got2 subhashof $expected');

done_testing;
