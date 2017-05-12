package TipJar::sparse::array::perl::hashbased;

use strict;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
sparse	
);

our $VERSION = '0.01';


sub sparse(\@){
    tie @{$_[0]}, __PACKAGE__
};

sub data(){ 0 } # the hash that stores the values
sub offset() { 1 }  # adjustment to index, for fast shift/unshift
sub sortedkeys() { 2 } # should always be the same as numeric-sorted keys
sub top {3} # one more than the normalized index of the highest element

sub    CLEAR { my ($this) = shift;
       @$this = ({},0,[],0)
}

sub    TIEARRAY{ # classname, LIST
     my $this = bless [];
     $this->CLEAR;
     $this
}
sub normalize { my ($this, $key) = @_;
    $key = int $key;
    $key < 0 and $key += $this->[top];
    $key + $this->[offset];
}
sub    EXISTS { my ($this, $key) = @_;
    exists $this->[data]->{$this->normalize($key)}
}
sub    FETCH { my ($this, $key) = @_;
    $this->[data]->{$this->normalize($key)}
}
use Carp ();
sub    DELETE { my ($this, $key) = @_;
    my $N = $this->normalize($key);
    ### SIZE REDUCTION ON DELETION OF LAST ELEMENT:
    if ( (1+$N) == $this->[top] ){
       $N == $this->[sortedkeys]->[-1] and pop @{$this->[sortedkeys]};
       my $newtop = $this->[sortedkeys]->[-1];
       if (defined $newtop){
           $this->[top] = 1+$newtop
       }else{
           $this->[top] = $this->[offset]
       }
    } else {
       exists $this->[data]->{$N}
       and splice @{$this->[sortedkeys]}, $this->LocateKey($N), 1;
    }
    delete $this->[data]->{$N};
}
sub LocateKey{ my ($this, $N) = @_; # return an OFFSET for splice in DELETE and STORE
   my ($lower, $upper) = (0, $#{$this->[sortedkeys]});

   while ($lower < $upper){
      my $guess = int (( 1+ $lower + $upper) / 2);
      
      my $val = $this->[sortedkeys]->[$guess];
      $val == $N and return $guess;
      if ($val > $N){
           $upper = $guess - 1;
      }else{
           $lower = $guess;
      }

   };
   $lower

}
sub    STORE { my ($this, $key, $value) = @_;
    my $N = $this->normalize($key);
    $N < $this->[offset] 
        and Carp::croak "Modification of non-creatable array value attempted, subscript $key";
    unless (exists $this->[data]->{$N}){
         my $location = 1+$this->LocateKey($N);
         splice @{$this->[sortedkeys]}, $location, 0,$N;
         $this->[top] > $N or $this->[top] = ($N+1);
    };
    $this->[data]->{$N} = $value;
}
sub    FETCHSIZE { my ($this) = @_;
       $this->[top] - $this->[offset]
}
sub    STORESIZE { my ($this, $count) = @_;
       $count = int $count;
       $count <= 0 and return $this->CLEAR;
       my $before = $this->FETCHSIZE;
       $before == $count and return;  # no-op
       if ($before < $count){ # extend the apparent length
             $this->[top] = $this->[offset]+$count;
             return
       };
       # delete [$count] and all elements north of it
       my $N = $this->normalize($count - 1);
       while ($this->[sortedkeys]->[-1] > $N ){
            my $nn = pop @{$this->[sortedkeys]};
            delete $this->[data]->{$nn};
       }
       $this->[top] = $this->[offset]+$count;
}
sub    PUSH { my ($this, @LIST) = @_;
       while (@LIST){
            $this->[data]->{$this->[top]} = shift @LIST;
            push @{$this->[sortedkeys]}, $this->[top]++
       };
}
sub    POP { my ($this) = @_;
       if (exists $this->[data]->{--$this->[top]}){
                pop @{$this->[sortedkeys]};
                return delete $this->[data]->{$this->[top]}
       }
}
sub    SHIFT { my ($this) = @_;
       $this->[top] == $this->[offset] and return undef;
       $this->[sortedkeys]->[0] == $this->[offset] and shift @{$this->[sortedkeys]};
       delete $this->[data]->{$this->[offset]++};
}
sub    UNSHIFT { my ($this, @LIST) = @_;
       my $offset = $this->[offset];
       while (@LIST){
            $this->[data]->{--$offset} = pop @LIST;
            unshift @{$this->[sortedkeys]}, $offset
       };
       $this->[offset] = $offset;
}
sub    SPLICE { my ($this, $offset, $length, @LIST) = @_;
       # follow the native array semantics of returning existing undef
       # when returning nonexistent parts; Perl does not fully
       # support an explicit "unexisting" value at this revision and
       # very probably never will: nonexistent values spliced in
       # become existing undefined values.

       my $N = $this->normalize($offset);
       if ($N > $this->[top]){
              Carp::carp "splice() offset past end of array";
              $N = $this->[top];
              $length = 0;
       };
       my $Stop = ($length < 0 ? $this->normalize($length) :  $this->normalize( $N + $length));
       $Stop > $this->[top] and $Stop = $this->[top];
       if( $Stop <= $this->[offset]){
             $N = $this->[offset];
             $Stop = $N
       };
       my $indexshift =  @LIST;
       $indexshift  -=  ($Stop - $N);
       $Stop--;
       my @retlist;
       @retlist = delete @{$this->[data]}{ $N .. $Stop };

       # in the future, we
       # can handle all the cases specifically
       # to minimize number of elements requiring renumbering
       # but for now we're just going to renumber the top section
       if ($indexshift){
             $this->[top] += $indexshift;
             my $first = $this->LocateKey($N);
             $this->[sortedkeys]->[$first] == $N or $first += 1;
             my @oldindices = @{$this->[sortedkeys]}[
                    $first .. $#{$this->[sortedkeys]}
             ];
             my @newindices = map { $_ + $indexshift }  @oldindices ;
             my @shifters = delete @{$this->[data]}{ @oldindices };
             @{$this->[data]}{ @newindices } = @shifters;
       };

       my @insertkeys = $N .. $N+$#LIST;
       @{$this->[data]}{ @insertkeys } = @LIST;

       # and then clobber [sortedkeys]
       $this->[sortedkeys] = [sort { $a <=> $b } keys %{$this->[data]}];
       @retlist;
}
sub    EXTEND { my ($this, $count) = @_;
       keys %{$this->[data]} = $count;
}
sub    DESTROY { }
sub    UNTIE { }

1;
__END__

=head1 NAME

TipJar::sparse::array::perl::hashbased - reference implementation of sparse array

=head1 SYNOPSIS

  use TipJar::sparse::array::perl::hashbased;
  sparse my @S;
  ...

=head1 DESCRIPTION

An implementation of a sparse array tie class based on 
a Perl hash. This module is intended as a reference
implementation for testing, and other modules providing
the same semantics but better performance may be
forthcoming later.

This module efficiently
provdes correct C<delete> behavior, which
is to adjust the size of the array down to the last existing
element when the top element is deleted, by maintaining
a sorted array of existing keys.

the C<splice> handler could be improved. Currently it
avoids specifically handling all the possibilities by
always renumbering existing elements
from the splice point up, then rebuilds the
sorted list of existing elements.

keys are kept relative to an adjusting offset to
support fast C<shift>/C<unshift> operations.


=head2 EXPORT

The C<sparse> function is sugar to tie its array argument
into this class.

=head1 SEE ALSO


=head1 AUTHOR

David Nicol

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by David Nicol / TipJar LLC

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
