package Tie::Array::Cavity;

use 5.006;
use strict;
use warnings;
use Tie::Array;

our $VERSION = '0.03';


sub TIEARRAY
{
    my ( $class ) = @_;
    bless {
        _step => $_[1] || 1,
        _base => $_[2] || 0,
        _data => [],
    }, $class;
}


sub STORE
{
    use integer;
    my $i = ( $_[1] - $_[0]->{ _base } ) / $_[0]->{ _step };
    $i = 0 if ( $i < 0 );
    no integer;
    $_[0]->{ _data }->[$i] = $_[2];
}



sub STORESIZE
{
    $#{ $_[0] } = $_[1] - 1;
}


sub FETCHSIZE
{
    scalar @{ $_[0]->{ _data } };
}


sub FETCHCAVITY
{
    use integer;
    my $i = ( $_[1] - $_[0]->{ _base } ) / $_[0]->{ _step };
    $i = 0 if ( $i < 0 );
    no integer;
    $_[0]->{ _data }->[$i];
}



sub FETCHKEY
{
    use integer;
    my $i = ( $_[1] - $_[0]->{ _base } ) / $_[0]->{ _step };
    $i = 0 if ( $i < 0 );
    no integer;
    ( $i * $_[0]->{ _step } ) + $_[0]->{ _base };
}


sub FETCHKEYCAVITY
{
    use integer;
    my $i = ( ($_[1] || 0 ) * $_[0]->{ _step } ) + $_[0]->{ _base };
    $i = 0 if ( $i < 0 );
    no integer;
    $i;
}


sub FETCH
{
    $_[0]->{ _data }->[ $_[1] ];
}



sub POP
{
    pop @{ $_[0]->{ _data } };
}


sub SHIFT
{
    shift @{ $_[0]->{ _data } };
}



sub PUSH
{
    push @{ $_[0]->{ _data } }, $_[1];
}




sub UNSHIFT
{
    unshift @{ $_[0]->{ _data } }, $_[1];
}


sub EXISTSCAVITY
{
    use integer;
    my $i = ( $_[1] - $_[0]->{ _base } ) / $_[0]->{ _step };
    $i = 0 if ( $i < 0 );
    no integer;
    exists $_[0]->{ _data }->[$i];
}


sub EXISTS
{
    exists $_[0]->{ _data }->[$_[1]];
}


sub DELETECAVITY
{
    use integer;
    my $i = ( $_[1] - $_[0]->{ _base } ) / $_[0]->{ _step };
    $i = 0 if ( $i < 0 );
    no integer;
    delete $_[0]->{ _data }->[$i];
}


sub DELETE
{
    delete $_[0]->{ _data }->[$_[1]];
}



sub SPLICECAVITY
{
    my $self = shift;
    my $offset = @_ ? shift : 0;
    my $s = $self->{ _step };
    my $b = $self->{ _base };
    use integer;
    my $off = ( $offset - $b ) / $s;
    $off = 0 if ( $off < 0 );
    my $sz = $self->FETCHSIZE;
    $off += $sz if $off < 0;
    my $len = @_ ? shift : $sz - $off;
    no integer;
    return splice( @{$self->{ _data }}, $off, $len, @_ );

}


sub SPLICE
{
    my $self = shift;
    my $offset = @_ ? shift : 0;
    my $sz = $self->FETCHSIZE;
    $offset += $sz if $offset < 0;
    my $len = @_ ? shift : $sz - $offset;
    return splice( @{$self->{ _data }}, $offset, $len, @_ );
}



1;    # End of Tie::Array::Cavity

__END__

=pod

=head1 NAME

Tie::Array::Cavity - create an array where key are aggregated by step ( and optionally could start with an offset )

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

A Tie array module where the keys ( indexes ) are like a cavity bucket and collect all the keys from a specific neighbor range


Perhaps a little code snippet.

    use Tie::Array::Cavity;

    my $tied = tie my @a, 'Tie::Array::Cavity' , 10 , 5;
    
    $a[1] = 1;
    $a[15] = 15;
    $a[25]=25;
    $a[24]=240;
    $a[31]=31;
    $a[40]=40;
   
   Result:
        [
          1,
          15,
          240,
          31,
          40
        ];
    
    as a consequence, 
    $a[1];
    and 
    $a[2];
    refer to the same element of the array 
    In the previous code     
       $a[25]=25;   
    set the the 3 element with the value 25,but
      $a[24]=240;
    over write the 3 element with the value 240.
    
    
    !!!!! BECARE !!!!!
    lvalue update are not working as expected.
    In the example above,
    $a[24]++;
    is setting the second element of the array with '1' because fetching the value $a[24] return the 24 element of the array.
    It is "by design" to allow normal iteration on the array ( e.g. foreach ( @a ) or Dumper(\@a ) )
      
    
    
      
=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 TIEARRAY

my $tied = tie my @a, 'Tie::Array::Cavity' , 10 , 5;
	
B<Tie::Array::Cavity> tie an array where the keys are in a range
Two extra parameters are allowed:
1) the granularity of the key range ( default = 0 )
2) the initial offset ( default = 0 )
	

=head2 STORE
	
Add an element in the array at the ARRAY index with the cavity behavior;
	
my $tied = tie my @a, 'Tie::Array::Cavity' , 10 , 5;
$myarray[31] , 45646;
	
store 45646 at the 3 place in the array 

	[ 
		...,
		...,
		45646,
		...,		
		
	]
	  

=head2 STORESIZE this

Sets the total number of items in the tied array associated with
object I<this>.

=head2 FETCHSIZE this

Returns the total number of items in the tied array associated with
object I<this>. (Equivalent to C<scalar(@array)>).

=head2 FETCHCAVITY this , index

Retrieve the value in I<index> for the tied array associated with
object I<this>. But the index is calculated with the cavity feature.
	

=head2 FETCHKEY this , index

Return the calculated real key used by the cavity feature.

=head2 FETCHKEYCAVITY this , index

Return the calculated cavity key related to a normal array index.


=head2 FETCH  this , index

Retrieve the value in I<index> for the tied array associated with
object I<this>.
	

=head2 POP this

Remove the last element of the array and return it.
           
=head2 SHIFT this

Remove the first element of the array and return it.
           

=head2 PUSH this, LIST

Append elements of I<LIST> to the array.

=head2 UNSHIFT this, LIST

Insert I<LIST> elements at the beginning of the array, moving existing elements up to make room.

=head2 EXISTSCAVITY this, key

Verify that the element at index I<key> exists in the tied array this.
The key is using the cavity feature.
           

=head2 EXISTS this, key

Verify that the element at index I<key> exists in the tied array this.
           

=head2 DELETECAVITY this, key

Delete the element at index I<key> from the tied array this.
The key is using the cavity feature.

=head2 DELETE this, key

Delete the element at index I<key> from the tied array this.

=head2 SPLICECAVITY this, offset, length, LIST

Perform the equivalent of C<splice> on the array.

I<offset> is optional and defaults to zero, negative values count back
from the end of the array.

I<length> is optional and defaults to rest of the array.

I<LIST> may be empty.

Returns a list of the original I<length> elements at I<offset>.
	
The I<offset> and I<length> is using the cavity feature.

=head2 SPLICE this, offset, length, LIST

Perform the equivalent of C<splice> on the array.

I<offset> is optional and defaults to zero, negative values count back
from the end of the array.

I<length> is optional and defaults to rest of the array.

I<LIST> may be empty.

Returns a list of the original I<length> elements at I<offset>.
	

=head1 USAGE

One of the useful usage of this module is for aggregating data coming for a time series by some slice.
Example: You've got a lot of data polled each second for a day, and you would like to aggregate the result by 5 minutes starting at the beginning of the day:
	
	my %data = ( 1351551600 => 10, 1351551601 => 15, 1351551950 => 5  );
	my $tied1= tie my @d, 'Tie::Array::Cavity' , 300 ,1351551600 ;
	
	my $start = 1351551600;
	foreach my $t  ( keys %data )
	{
		$d[$t]= $tied1->FETCHCAVITY($t)+ $data{ $t }; 
	}

	say Dumper(\@d);
	


=head1 AUTHOR

DULAUNOY Fabrice, C<< <fabrice at dulaunoy.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tie-array-Cavity at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tie-Array-Cavity>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tie::Array::Cavity


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tie-Array-Cavity>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tie-Array-Cavity>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tie-Array-Cavity>

=item * Search CPAN

L<http://search.cpan.org/dist/Tie-Array-Cavity/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 DULAUNOY Fabrice.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

