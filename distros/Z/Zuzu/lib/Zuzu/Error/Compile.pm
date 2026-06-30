package Zuzu::Error::Compile;

use utf8;

our $VERSION = '0.007001';

use Moo;

extends 'Zuzu::Error';

sub kind { 'CompileError' }

=pod

=head1 NAME

Zuzu::Error::Compile - compile-time error for parsing/analysis failures

=head1 DESCRIPTION

Represents failures detected before execution.

Typical examples include syntax errors, use of undeclared identifiers
detected by the parser, and invalid declarations such as using C<=>
instead of C<:=>.

=head1 INHERITANCE

Inherits from L<Zuzu::Error>.

=head1 METHODS

=head2 kind

Returns C<CompileError>.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Error::Compile >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;