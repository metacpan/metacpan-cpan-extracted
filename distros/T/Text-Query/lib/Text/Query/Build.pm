#
#   Copyright (C) 1999 Eric Bohlman, Loic Dachary
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the
#   Free Software Foundation; either version 2, or (at your option) any
#   later version.  You may also use, redistribute and/or modify it
#   under the terms of the Artistic License supplied with your Perl
#   distribution
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, 675 Mass Ave, Cambridge, MA 02139, USA. 

package Text::Query::Build;

use strict;

sub new {
  my $class=shift;
  my $self={};
  bless $self,$class;

  $self->initialize();

  return $self;
}

sub initialize {
}

sub matchstring {
    my($self) = @_;

    return $self->{matchstring};
}

sub build_init {
    my ($self)=@_;
}

sub build_final_expression {
    my($self, $t1) = @_;

    return $self->{matchstring} = $t1;
}

sub build_expression {
    my($self, $l, $r) = @_;

    return "[ or $l $r ]";
}

sub build_expression_finish {
    my($self, $l) = @_;

    return $l;
}

sub build_conj {
    my($self, $l, $r, $first) = @_;

    return "[ and $l $r ]";
}

sub build_near {
    my($self, $l, $r) = @_;

    return "[ near $l $r ]";
}

sub build_concat {
    my($self, $l, $r) = @_;

    return "[ concat $l $r ]";
}

sub build_negation {
    my($self, $t) = @_;

    return "[ not $t ]";
}

sub build_literal {
    my($self, $t) = @_;

    return "[ literal $t ]";
}

sub build_scope_start {
    my($self) = @_;
}

sub build_scope_end {
    my($self, $scope, $t) = @_;

    return "[ scope '$scope->[0]' $t ]";
}

sub build_mandatory {
    my($self, $t) = @_;

    return "[ mandatory $t ]";
}

sub build_forbiden {
    my($self, $t) = @_;

    return "[ forbiden $t ]";
}

1;

=head1 NAME

Text::Query::Build - Base class for query builders

=head1 SYNOPSIS

    package Text::Query::BuildMy;

    use Text::Query::Build;
    
    use vars qw(@ISA);

    @ISA = qw(Text::Query::Build);


=head1 DESCRIPTION

This module provides a virtual base class for query builders.

Query builders are called by the parser logic. A given set of functions is
provided by the builder to match a Boolean logic.
All the methods return a scalar corresponding to the code that performs 
the specified options.

Parameters Q1 and Q2 are the same type of scalar as the return values.

=head1 METHODS

=over 4

=item matchstring()

Return a string that represent the last built expression. Two identical expressions
should generate the same string. This is for testing purpose.

=back

=head1 CODE-GENERATION METHODS

=over 4

=item build_init()

Called before building the expression. A chance to initialize object data.

=item build_final_expression(Q1)

Does any final processing to generate code to match a top-level expression.  
The return value is NOT necessarily of a type that can be passed to 
the other code-generation methods.

=item build_expression(Q1,Q2)

Generate code to match C<Q1> OR C<Q2>

=item build_expression_finish(Q1)

Generate any code needed to enclose an expression. 

=item build_conj(Q1,Q2,F)

Generate code needed to match C<Q1> AND C<Q2>.  F will be true if this is the first 
time this method is called in a sequence of several conjunctions.
 
=item build_near(Q1,Q2)

Generate code needed to match C<Q1> NEAR C<Q2>.

=item build_concat(Q1,Q2)

Generate code needed to match C<Q1> immediately followed by C<Q2>.

=item build_negation(Q1)

Generate code needed to match NOT C<Q1>.

=item build_literal(Q1)

Generate code to match C<Q1> as a literal.

=item build_scope_start($scope)

Generate code to enter in the C<$scope> query context.

=item build_scope_end($scope,Q1)

Generate code needed to match C<Q1> in the C<$scope> context.

=item build_mandatory(Q1)

Generate code to match C<Q1> (think + in AltaVista syntax).

=item build_forbiden(Q1)

Generate code to match NOT C<Q1> (think - in AltaVista syntax).

=back

=head1 SEE ALSO

Text::Query(3)

=head1 AUTHORS

Eric Bohlman (ebohlman@netcom.com)

Loic Dachary (loic@senga.org)

=cut

# Local Variables: ***
# mode: perl ***
# End: ***
