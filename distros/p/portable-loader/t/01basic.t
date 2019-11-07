=pod

=encoding utf-8

=head1 PURPOSE

Test that portable::loader works.

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

use portable::loader;

my $nature = portable::loader->load('Nature');

my $tree = $nature->new_tree;
my $leaf = $tree->grow_leaf;

isa_ok($leaf, 'Moo::Object');
is(scalar(@{ $tree->leafs }), 1);

my $nature2 = portable::loader->load('Nature');
is($nature, $nature2, "don't pointlessly recreate classes");

done_testing;

