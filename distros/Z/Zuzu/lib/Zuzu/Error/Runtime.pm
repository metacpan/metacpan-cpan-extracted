package Zuzu::Error::Runtime;

use utf8;

our $VERSION = '0.001003';

use Moo;

extends 'Zuzu::Error';

sub kind { 'RuntimeError' }

=pod

=head1 NAME

Zuzu::Error::Runtime - runtime error for evaluation/execution failures

=head1 DESCRIPTION

Represents failures raised while executing AST nodes.

Typical examples include calling a non-function value, assigning to a
C<const> binding, invalid indexing/member operations, and missing
module exports at import time.

=head1 INHERITANCE

Inherits from L<Zuzu::Error>.

=head1 METHODS

=head2 kind

Returns C<RuntimeError>.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Error::Runtime >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;