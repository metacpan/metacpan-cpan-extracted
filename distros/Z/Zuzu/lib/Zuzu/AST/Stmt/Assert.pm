package Zuzu::AST::Stmt::Assert;

use utf8;

our $VERSION = '0.001005';

use Moo;

has 'expr' => ( is => 'rw' );

with 'Zuzu::AST::Role::Node';

sub evaluate { $_[1]->eval_assert($_[0]) }

1;

=pod

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Stmt::Assert >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
