=pod

=encoding utf-8

=head1 PURPOSE

Test that Tie::Reduce compiles and works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More tests => 1;

use Tie::Reduce;

tie my $var, 'Tie::Reduce', sub { $a + $b }, 0;

$var = 1;
$var = 2;
$var = 3;
$var = 4;

is($var, 10);
