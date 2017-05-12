package Tie::Quicksort::Lazy;
@Tie::Quicksort::Lazy::Stable::ISA = qw/ Tie::Quicksort::Lazy /;

use Carp;

use 5.006001;
use strict;
use warnings;

our $VERSION = '0.04';
sub DEBUG() { 0 };

# object field names:
BEGIN {
   my $i = 0;
   for (qw/comparator size ready parts/){  # a coderef, then an arrayref, then an arrayref of arrayrefs.
      eval "sub $_ () {".$i++.'}'
   }
}

our $trivial = 2 ;  # if you want to call sort you have to ask for it

sub import {
	shift; # lose package name
        my %args = @_;
        $trivial = $args{TRIVIAL} || $trivial;
};

sub TIEARRAY{
   my $obj = bless [];
   shift; # lose package name
   if ( ( ref $_[0] ) eq 'CODE' ) {
      $obj->[comparator] = shift
   }else{
      $obj->[comparator] = sub {
 DEBUG and ((defined $_[0] and defined $_[1] ) or Carp::confess "undefined arg to comparator");
 $_[0] cmp $_[1] };
   };

   $obj->[size] = @_;
   $obj->[ready] = [];
   $obj->[parts] = [ [ @_ ] ];  # the stack of unsorted partitions

   return $obj;
};


sub _sort {
   my $obj = shift;
   my $comp_func = $obj->[comparator];
   for(;;){
    my $arr = pop @{$obj->[parts]};
    DEBUG and warn "arr is [ @$arr ]";

    if (@$arr == 1 ) {
      $obj->[ready] = $arr ;
      return
    } elsif (@$arr == 2 ) {
      $obj->[ready] = ( $comp_func->(@$arr) > 0 ? [@$arr[1,0]] : $arr ) ;
      return
    } elsif (@$arr <= $trivial ) {
      $obj->[ready] = [ sort { $comp_func->($a,$b) } @$arr ];
      return
    };
    my (@HighSide, @LowSide) = ();

    # by choosing a random pivot and treating equality differently
    # when examining the before and after parts of the partition,
    # we get stability without scrambling and without any
    # degenerate cases, even contrived ones. (choosing the midpoint
    # gives n*log(n) performance for sorted input, but it would be
    # possible to contrive a quadratic case)
 
    my $pivot_index = int rand @$arr;
 
    my $pivot = $arr->[$pivot_index];
 
    # BEFORE THE PIVOT ELT:
    for ( splice @$arr, 0, $pivot_index ) {
       if ($comp_func->($pivot, $_) < 0 ){
          # we are looking at an elt that belongs after the pivot
          push @HighSide, $_
       }else{
          push @LowSide, $_
       };
    };
 
    shift @$arr;  # shift off the pivot elt
 
    # AFTER THE PIVOT ELT:
    for ( @$arr ) {
       if ($comp_func->($pivot, $_) > 0 ){
          # we are looking at an elt that belongs before the pivot
          push @LowSide, $_
       }else{
          push @HighSide, $_
       };
    };
 
    @HighSide and push @{$obj->[parts]}, \@HighSide; # defer the high side
    push @{$obj->[parts]}, [$pivot]; # this pivot,
    @LowSide and push @{$obj->[parts]}, \@LowSide; # do the low side, if any, next
   } # for (;;)

}


sub FETCHSIZE { 
	 $_[0]->[size] 
}

sub SHIFT {
    my $obj = shift;
    $obj->[size] or return undef; 
    my $rarr = $obj->[ready];
         
    unless (@$rarr){
        $obj->_sort;
        $rarr = $obj->[ready];
    };
 
    $obj->[size]-- ; 
    shift @$rarr;
}

*STORE = *PUSH = *UNSHIFT = *FETCH =
*STORESIZE = *POP = *EXISTS = *DELETE =
*CLEAR = sub {
   require Carp;
   Carp::croak ('"SHIFT"  and "FETCHSIZE" are the only methods defined for a '.
               __PACKAGE__ . " array");
};

1;
__END__

=head1 NAME

Tie::Quicksort::Lazy - a lazy quicksort with tiearray interface

=head1 SYNOPSIS

  use Tie::Quicksort::Lazy TRIVIAL => 1023;
  tie my @producer, Tie::Quicksort::Lazy, @input;
  while (@producer){
    my $first_remaining = shift @producer;
    ...
  };
  
  use sort 'stable';
  tie my @StableProducer, Tie::Quicksort::Lazy, \&comparator,  @input;
  ...

=head1 DESCRIPTION

A pure-perl lazy, stable, quicksort.  The only defined way to
access the resulting tied array is with C<shift>.

Sorting is deferred until an item is required.

Stability is maintained by choosing a pivot element randomly
and treating equal elements differently in the before and
after sections.

=head2 memory use

This module operates on a copy of the input array, which
becomes the initial partition.  As the partitions are divided,
the old partitions are let go. 

=head2 trivial partitions

For a stable variant, tie to Tie::Quicksort::Lazy::Stable instead
and use a stable perl sort for the trivial sort or set 
"TRIVIAL" to 1 on the use line.

=head2 BYO (Bring Your Own) comparator

when the first parameter is an unblessed coderef,
that coderef will be used as the sort
comparison function. The default is

   sub { $_[0] cmp $_[1] }

Ergo, if you want to use this module to sort a list of coderefs,
you will need to bless the first one.

=head2 trivial partition

A variable C<$trivial> is defined which declares the size of a partition
that we simply hand off to Perl's sort for sorting. by default, this is
no longer used, but it is still available if you want it.

=head1 INSPIRATION

this module was inspired by an employment interview question
concerning the quicksort-like method of selecting the first k
from n items ( see L<http://en.wikipedia.org/wiki/Quicksort#Selection-based_pivoting> )

=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.23 with options

  -ACX
	-b
	5.6.1
	-n
	Tie::Quicksort::Lazy

=item 0.02

revised to use perl arrays for partitioning operations instead of a
confusing profusion of temporary index variables

=item 0.04 

revised internal data structure, no longer using perl's sort for
anything by default, no longer scrambling input due to random pivot
element selection.

=back



=head1 SEE ALSO

L<Tie::Array::Sorted::Lazy> is vaguely similar

=head1 AUTHOR

David L. Nicol davidnico@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by the author

This library is free software; you may redistribute and/or modify
it under the same terms as Perl.


=cut

