# Copyright 2011, 2012, 2013 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Image is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Image.  If not, see <http://www.gnu.org/licenses/>.

package Math::NumSeq::MathImageMathSequence;
use 5.004;
use strict;
use Carp;
use Math::Sequence;

use vars '$VERSION', '@ISA';
$VERSION = 110;
use Math::NumSeq;
@ISA = ('Math::NumSeq');


# uncomment this to run the ### lines
#use Smart::Comments;

use constant name => Math::NumSeq::__('Math::Sequence expression');
use constant description => Math::NumSeq::__('Math::Sequence expression');
use constant parameter_info_array =>
  [{ name    => 'expression',
     display => __('Expression'),
     type    => 'string',
     default => ('3*x^2 + x + 2'),
     width   => 30,
     description => __('A mathematical expression for Math::Sequence.'),
   }];

sub rewind {
  my ($self) = @_;
  ### Values-File rewind()

  $self->{'i'} = 0;
  $self->{'mseq'} = Math::Sequence->new ($self->{'expression'},
                                         $self->{'i'});
}

sub next {
  my ($self) = @_;
  my $symbolic = $self->{'mseq'}->next;
  return ($self->{'i'}++, $symbolic->value);
}

sub ith {
  my ($self, $i) = @_;
  return $self->{'mseq'}->at_index($i);
}

1;
__END__
