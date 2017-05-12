#
#   Copyright (C) 1999 Eric Bohlman, Loic Dachary
#   Copyright (C) 2013 Jon Jensen
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

package Text::Query::SolveSimpleString;

BEGIN {
  require 5.005;
}

use strict;

use Text::Query::Solve;

use vars qw(@ISA);

@ISA = qw(Text::Query::Solve);

sub initialize {
}

sub match {
  my($self) = shift;
  my($expr) = shift;
  return $self->matchscalar($expr, shift || $_) if(@_ <= 1 && ref($_[0]) ne 'ARRAY');
  my($pa) = (@_ == 1 && ref($_[0]) eq 'ARRAY') ? shift : \@_;

  my(@ra);
  if(ref($pa->[0]) eq 'ARRAY') {
    @ra = map { [ @$_, $self->matchscalar($expr, $_->[0]) ] } @$pa;
  } else {
    @ra = map { [ $_, $self->matchscalar($expr, $_) ] } @$pa;
  }
  @ra = sort { $b->[-1] <=> $a->[-1] } @ra;
  return wantarray ? @ra : \@ra;
}

sub matchscalar {
  my($self) = shift;
  my($expr) = shift;

  my($target) = (shift || $_);
  my($cnt) = 0;
  my($re, $ws) = @$expr;

  while($target =~ /$re/g) {
    return 0 if(!$^R->[0]);
    $cnt += $^R->[1];
    $ws &= $^R->[0];
  }
  
  return $ws ? 0 : $cnt;
}

1;

__END__

=head1 NAME

Text::Query::SolveSimpleString - Apply query expression on strings

=head1 SYNOPSIS

  use Text::Query;
  my $q=new Text::Query('+hello +world',
                        -parse => 'Text::Query::ParseSimple',
                        -solve => 'Text::Query::SolveSimpleString',
                        -build => 'Text::Query::BuildSimpleString');

  $q->match('this hello is a world')

=head1 DESCRIPTION

Applies an expression built by C<Text::Query::BuildSimpleString>
to a list of strings.

=head1 METHODS

=over 4

=item match ([TARGET])

If C<TARGET> is a scalar, C<match> returns a true value if the string 
specified by C<TARGET> matches the query object's query expression.  If 
C<TARGET> is not given, the match is made against C<$_>.

If C<TARGET> is an array, C<match> returns a (possibly empty) list of all 
matching elements.  If the elements of the array are references to sub- 
arrays, the match is done against the first element of each sub-array.  
This allows arbitrary information (e.g. filenames) to be associated with 
each string to match. 

If C<TARGET> is a reference to an array, C<match> returns a reference to 
a (possibly empty) list of all matching elements.  

=item matchscalar ([TARGET])

Behaves just like C<MATCH> when C<TARGET> is a scalar or is not given.  
Slightly faster than C<MATCH> under these circumstances.

=head1 AUTHORS

Eric Bohlman (ebohlman@netcom.com)

Loic Dachary (loic@senga.org)

Jon Jensen, jon@endpoint.com

=cut

# Local Variables: ***
# mode: perl ***
# End: ***
