package Zuzu::Value::Function;

use utf8;

our $VERSION = '0.001003';

use Moo;

has 'name' => ( is => 'rw' );
has 'params' => ( is => 'rw' );
has 'vararg' => ( is => 'rw' );
has 'named_vararg' => ( is => 'rw' );
has 'param_types' => ( is => 'rw', default => sub { {} } );
has 'vararg_type' => ( is => 'rw', default => sub { 'Any' } );
has 'named_vararg_type' => ( is => 'rw', default => sub { 'PairList' } );
has 'param_optional' => ( is => 'rw', default => sub { {} } );
has 'param_defaults' => ( is => 'rw', default => sub { {} } );
has 'return_type' => ( is => 'rw', default => sub { 'Any' } );
has 'body' => ( is => 'rw' );
has 'closure_env' => ( is => 'rw' );
has 'is_async' => ( is => 'rw', default => sub { 0 } );
has 'source_node' => ( is => 'rw' );
has 'is_bodyless' => ( is => 'rw', default => sub { 0 } );

sub is_truthy { 1 }

=pod

=head1 NAME

Zuzu::Value::Function - runtime value class for function values

=head1 DESCRIPTION

Represents user-defined or native callable values, including closure state.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

None.

=head1 ATTRIBUTES

=head2 name

Type: B<Str>.

Identifier name declared or referenced by the node/value.

=head2 params

Type: B<ArrayRef[Str]>.

Ordered list of named function parameters.

=head2 vararg

Type: B<Maybe[Str]>.

Optional parameter name that receives trailing arguments.

=head2 body

Type: B<InstanceOf["Zuzu::AST::Block"]>.

Function or loop block executed by the node/value.

=head2 closure_env

Type: B<Maybe[InstanceOf["Zuzu::Env"]]>.

Lexical environment captured when the function is created.

=head1 METHODS

=head2 is_truthy

Returns this runtime value's truthiness in ZuzuScript.

=head1 SEE ALSO

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Value::Function >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
