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

package Text::Query::Solve;

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

sub match {
    my($self, $expr) = shift;

    croak("not implemented");
}

sub matchscalar {
    my($self, $expr) = shift;

    croak("not implemented");
}

1;

__END__

=head1 NAME

Text::Query::Solve - Base class for query resolution

=head1 SYNOPSIS

    package Text::Query::SolveSource;

    use Text::Query::Parse;
    
    use vars qw(@ISA);

    @ISA = qw(Text::Query::Solve);


=head1 DESCRIPTION

This module provides a virtual base class for query resolution.

It defines the C<match> and C<matchscalar> method that is called by the C<Text::Query>
object to apply a query on a data source.

=head1 METHODS

=over 4

=item match (EXPR [TARGET])

If C<TARGET> is a scalar, C<match> returns a true value if the data source 
specified by C<TARGET> matches the C<EXPR> query expression.  If 
C<TARGET> is not given, the match is made against C<$_>.

If C<TARGET> is an array, C<match> returns a (possibly empty) list of all 
matching elements.  If the elements of the array are references to sub- 
arrays, the match is done against the first element of each sub-array.  
This allows arbitrary information (e.g. filenames) to be associated with 
each data source to match. 

If C<TARGET> is a reference to an array, C<match> returns a reference to 
a (possibly empty) list of all matching elements.  

=item matchscalar (EXPR [TARGET])

Behaves just like C<MATCH> when C<TARGET> is a scalar or is not given.  

=head1 SEE ALSO

Text::Query(3)

=head1 AUTHORS

Eric Bohlman (ebohlman@netcom.com)

Loic Dachary (loic@senga.org)

=cut

# Local Variables: ***
# mode: perl ***
# End: ***
