package Zuzu::AST::Role::Node;

use utf8;

our $VERSION = '0.004000';

use Moo::Role;

has 'file' => ( is => 'rw' );
has 'line' => ( is => 'rw' );

requires 'evaluate';

=pod

=head1 NAME

Zuzu::AST::Role::Node - role implemented by all AST nodes

=head1 DESCRIPTION

Defines the common C<evaluate> interface and source-location
metadata contract for AST node classes.

=head1 ATTRIBUTES

=head2 file

Type: B<Maybe[Str]>.

Source filename used for diagnostics.

=head2 line

Type: B<Int>.

1-based source line number used for diagnostics.

=head1 SEE ALSO

C<Zuzu::AST::Program>,
C<Zuzu::AST::Block>,
C<Zuzu::AST::Stmt::Let>,
C<Zuzu::AST::Stmt::Assign>,
C<Zuzu::AST::Stmt::If>,
C<Zuzu::AST::Stmt::While>,
C<Zuzu::AST::Stmt::For>,
C<Zuzu::AST::Stmt::Function>,
C<Zuzu::AST::Stmt::Return>,
C<Zuzu::AST::Stmt::Next>,
C<Zuzu::AST::Stmt::Last>,
C<Zuzu::AST::Stmt::Expr>,
C<Zuzu::AST::Stmt::Import>,
C<Zuzu::AST::Expr::Literal>,
C<Zuzu::AST::Expr::Var>,
C<Zuzu::AST::Expr::Binary>,
C<Zuzu::AST::Expr::Unary>,
C<Zuzu::AST::Expr::Call>,
C<Zuzu::AST::Expr::MemberCall>,
C<Zuzu::AST::Expr::Index>,
C<Zuzu::AST::Expr::DictGet>,
C<Zuzu::AST::Expr::Array>,
C<Zuzu::AST::Expr::Dict>.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Role::Node >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;