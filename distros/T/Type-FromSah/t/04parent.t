=pod

=encoding utf-8

=head1 PURPOSE

Check that Type::FromSah sets C<parent>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Type::FromSah -all;
use Types::Standard qw( Item Optional );

my $Int1 = sah2type( [ 'int*' ], name => 'Int1' );
my $Int2 = sah2type( [ 'int' ],  name => 'Int2' );

ok $Int1->parent == Item;
ok $Int1->parent != Optional[Item];
ok $Int2->parent == Optional[Item];
ok $Int2->parent != Item;

done_testing;

