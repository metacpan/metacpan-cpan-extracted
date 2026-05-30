package Zuzu::AST::Expr::Regexp;

use utf8;

our $VERSION = '0.001002';

use Moo;

has 'parts' => ( is => 'rw' );
has 'flags' => ( is => 'rw', default => sub { '' } );

with 'Zuzu::AST::Role::Node';

sub evaluate { $_[1]->eval_regexp_literal($_[0]) }

1;

=pod

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Expr::Regexp >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
