package Zuzu::AST::Expr::PairList;

use utf8;

our $VERSION = '0.007000';

use Moo;

has 'pairs' => ( is => 'rw' ); # [ [key_expr, val_expr], ... ]

with 'Zuzu::AST::Role::Node';

sub evaluate { $_[1]->eval_pairlist($_[0]) }

1;

=pod

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Expr::PairList >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
