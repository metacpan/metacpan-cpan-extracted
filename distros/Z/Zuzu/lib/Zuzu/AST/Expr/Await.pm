package Zuzu::AST::Expr::Await;

use utf8;

our $VERSION = '0.002000';

use Moo;

has 'block' => ( is => 'rw' );

with 'Zuzu::AST::Role::Node';

sub evaluate { $_[1]->eval_await($_[0]) }

1;

=pod

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Expr::Await >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
