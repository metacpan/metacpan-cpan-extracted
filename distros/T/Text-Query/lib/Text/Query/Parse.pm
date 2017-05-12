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

package Text::Query::Parse;

use strict;

use Carp;

sub new {
  my $class=shift;
  my $self={};
  bless $self, $class;

  $self->initialize();

  return $self;
}

sub initialize {
}

sub prepare {
  my $self=shift;
  my $qstring=shift;

  @_ = ( %{$self->{parseopts}}, @_ ) if($self->{parseopts});
  $self->{parseopts} = { -regexp=>0, -litspace=>0, -case=>0, -whole=>0, -quotes=>"\\'\\\"", @_ };
  croak("no builder") if(!$self->{-build});
  $self->{-build}->{parseopts} = $self->{parseopts};

  delete($self->{'token'});
  delete($self->{'tokens'});
  $self->build_init();

  $self->parse_tokens($qstring);

  croak("no token found") if(!@{$self->{'tokens'}});

  return $self->build_final_expression($self->expression());
}

#parsing routines

sub expression($) {
    my($self) = @_;
    
    croak("not implemented");

    return "expression";
}

sub parse_tokens($) {
    my($self, $qstring) = @_;

    croak("not implemented");

    $self->{'tokens'} = [];
}

#
# Access builder functions
#

sub build_init {
    my($self) = @_;

    return $self->{-build}->build_init();
}

sub build_final_expression {
    my($self, $t1) = @_;

    return $self->{-build}->build_final_expression($t1);
}

sub build_expression {
    my($self, $l, $r) = @_;

    return $self->{-build}->build_expression($l, $r);
}

sub build_expression_finish {
    my($self, $l) = @_;

    return $self->{-build}->build_expression_finish($l);
}

sub build_conj {
    my($self, $l, $r, $first) = @_;

    return $self->{-build}->build_conj($l, $r, $first);
}

sub build_near {
    my($self, $l, $r) = @_;

    return $self->{-build}->build_near($l, $r);
}

sub build_concat {
    my($self, $l, $r) = @_;

    return $self->{-build}->build_concat($l, $r);
}

sub build_negation {
    my($self, $t) = @_;

    return $self->{-build}->build_negation($t);
}

sub build_literal {
    my($self, $t) = @_;

    return $self->{-build}->build_literal($t);
}

sub build_scope_start {
    my($self) = @_;

    return $self->{-build}->build_scope_start($self->{scope});
}

sub build_scope_end {
    my($self, $t) = @_;

    return $self->{-build}->build_scope_end($self->{scope}, $t);
}

sub build_mandatory {
    my($self, $t) = @_;

    return $self->{-build}->build_mandatory($t);
}

sub build_forbiden {
    my($self, $t) = @_;

    return $self->{-build}->build_forbiden($t);
}

1;

__END__

=head1 NAME

Text::Query::Parse - Base class for query parsers

=head1 SYNOPSIS

    package Text::Query::ParseThisSyntax;

    use Text::Query::Parse;
    
    use vars qw(@ISA);

    @ISA = qw(Text::Query::Parse);


=head1 DESCRIPTION

This module provides a virtual base class for query parsers.

It defines the C<prepare> method that is called by the C<Text::Query>
object to compile the query string.

=head1 MEMBERS

=over 4

=item B<-build>
Pointer to a Text::Query::Build object.

=item B<scope>
Scope stack. Defines the context in which the query must be solved.

=item B<token>
The current token. Destroyed by C<prepare>.

=item B<tokens>
A reference to the list of all the tokens. Filled by parse_tokens.
Destroyed by C<prepare>.

=item B<parseopts>
A reference to a hash table containing all the parameters given to
the C<prepare> function.

=item B<-verbose>
Integer indicating the desired verbose level.

=back

=head1 METHODS

=over 4

=item prepare (QSTRING [OPTIONS])

Compiles the query expression in C<QSTRING> to internal form and sets any 
options. First calls C<build_init> to reset the builder and destroy the
C<token> and C<tokens> members. Then calls C<parse_tokens> to fill 
the C<tokens> member. Then calls C<expression> to use the tokens from 
C<tokens>. The C<expression> is expected to call the C<build_*> functions
to build the compiled expression. At last calls C<build_final_expression>
with the result of C<expression>.

A derived parser must redefine this function to define default values for
specific options.

=item expression ()

Must be redefined by derived package. Returns the internal form of the
question built from C<build_*> functions using the C<tokens>.

=item parse_tokens (QSTRING)

Must be redefined by derived package. Parses the C<QSTRING> scalar
and fills the C<tokens> member with lexical units.

=item build_*

Shortcuts to the corresponding function of the Text::Query::Build object
found in the C<-build> member.

=back

=head1 OPTIONS

These are the options of the C<prepare> method and the constructor.

=over 4

=item -quotes defaults to \'\"

Defines the quote characters.

=item -case defaults to 0

If true, do case-sensitive match.

=item -litspace defaults to 0

If true, match spaces (except between operators) in 
C<QSTRING> literally.  If false, match spaces as C<\s+>.

=item -regexp defaults to 0

If true, treat patterns in C<QSTRING> as regular expressions 
rather than literal text.

=item -whole defaults to 0

If true, match whole words only, not substrings of words.

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
