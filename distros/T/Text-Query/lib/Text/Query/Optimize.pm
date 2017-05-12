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

package Text::Query::Optimize;

use strict;

sub new {
  my($class) = shift;
  my($self) = {};
  bless $self,$class;

  $self->initialize();

  return $self;
}

sub initialize {
}

sub optimize {
    my($self, $expr) = @_;

    return $expr;
}

1;

__END__

=head1 NAME

Text::Query::Parse - Base class for query parsers

=head1 SYNOPSIS

    package Text::Query::OptimizeSmart;

    use Text::Query::Optimize;
    
    use vars qw(@ISA);

    @ISA = qw(Text::Query::Optimize);


=head1 DESCRIPTION

This module provides a virtual base class for query optimizers.

It defines the C<optimize> method that is called by the C<Text::Query>
object to optimize the internal query.

=head1 METHODS

=over 4

=item optimize (INTERNAL)

Returns the C<INTERNAL> argument after optimization. The default implementation
returns the argument untouched.

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
