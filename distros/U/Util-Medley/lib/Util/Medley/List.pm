package Util::Medley::List;
$Util::Medley::List::VERSION = '0.058';
#########################################################################################

use v5.16;
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka '-all';
use Data::Printer alias => 'pdump';
use List::Util;
use List::Compare;
use Sort::Naturally;

=head1 NAME

Util::Medley::List - utility methods for working with lists

=head1 VERSION

version 0.058

=cut

=head1 SYNOPSIS

 %map = $util->listToMap(@list);
 %map = $util->listToMap(list => \@list);
 
 $min = $util->min(@list);
 $min = $util->min(list => \@list);
 
 $max = $util->max(@list);
 $max = $util->max(list => \@list);

 @list = $util->undefsToStrings(@list);
 @list = $util->undefsToStrings(list => \@list);

 @uniq = $util->uniq@list);
 @uniq = $util->uniq(list => \@list); 
 
=head1 DESCRIPTION

...

=cut

#########################################################################################

=head1 METHODS

=head2 contains

Search for pattern in a list.

Returns bool

=over

=item usage:

  $bool = $util->contains(\@list, 'mystring');
  $bool = $util->contains(\@list, undef);
  $bool = $util->contains(\@list, qr/myregex/);

  $bool = $util->contains(list => \@list, match => 'mystring');
  $bool = $util->contains(list => \@list, match => undef);
  $bool = $util->contains(list => \@list, match => qr/myregex/);;
   
=item args:

=over

=item list [ArrayRef] 

An array of values.

=item match [Str|Regexp|Undef]

Pattern to search for.  This can be a string, regex, or undef.

=back

=back
 
=cut

multi method contains (ArrayRef            :$list!, 
                       Str|RegexpRef|Undef :$match) {

    my $matchUndef = 0;
    my $matchString = 0;
    my $matchRegexp = 0;
  
    my $refType = ref($match);
    if (!$refType) {
        if (defined $match) {
           $matchString = 1;    
        }
        else {
           $matchUndef = 1; 
        }
    }
    else {
        $matchRegexp = 1;
    }
     
    foreach my $item (@$list) {
     
        if ($matchUndef) {
            if (!defined $item) {
               return 1;    
            }  
        }
        elsif ($matchString) {
            if (defined $item) {
               if ($item eq $match) {
                   return 1;    
               }    
            }
        }
        else {
            if (defined $item) {
               if ($item =~ $match) {
                   return 1;    
               }    
            }
        }
    }   
    
    return 0;
}


multi method contains (ArrayRef            $list!, 
                       Str|RegexpRef|Undef $match!) {

    return $self->contains(list => $list, match => $match);                         
}

=head2 diff

Returns an array of elements that are found in list1 or list2, but not both.

Wrapper around List::Compare::get_symmetric_difference().

=over

=item usage:

  @diff = $util->diff(\@list1, \@list2, $sort);

  @diff = $util->diff(list1 => \@list1,
  		 			  list2 => \@list2,
  		 			  sort => $sort);
   
=item args:

=over

=item list1 [ArrayRef]

The first array.

=item list2 [ArrayRef]

The second array.

=item sort [Bool]

Flag to enable/disable pre-sorting.  This leverages the nsort method, within
this class, rather than Perl's sort routine.

Default is 1.

=back

=back
 
=cut

multi method diff (ArrayRef :$list1!,
				   ArrayRef :$list2!,
				   Bool     :$sort = 1) {

	if ($sort) {
		$list1 = [ $self->nsort(list => $list1) ];		
		$list2 = [ $self->nsort(list => $list2) ];	
	}
	
	my $lc = List::Compare->new('--unsorted', $list1, $list2);
	
	return $lc->get_symmetric_difference;
}

multi method diff (ArrayRef $list1, 
				   ArrayRef $list2, 
				   Bool 	$sort = 1) {

	return $self->diff(list1 => $list1, list2 => $list2, sort => $sort);
}

=head2 differ

Compares two arrays and returns true if they differ or false if not.

=over

=item usage:

  $bool = $util->differ(\@list1, \@list2, $sort);

  $bool = $util->diff(list1 => \@list1,
  		 			  list2 => \@list2,
  		 			  sort  => $sort);
   
=item args:

=over

=item list1 [ArrayRef]

The first array.

=item list2 [ArrayRef]

The second array.

=item sort [Bool]

Flag to enable/disable pre-sorting.  This leverages the nsort method, within
this class, rather than Perl's sort routine.

Default is 1.

=back

=back
 
=cut

multi method differ (ArrayRef :$list1!,
				     ArrayRef :$list2!,
				     Bool     :$sort = 1) {

	my @diff = $self->diff(list1 => $list1, list2 => $list2, sort => $sort);
	if (@diff) {
		return 1
	}
	
	return 0;
}

multi method differ (ArrayRef $list1, 
				     ArrayRef $list2, 
				     Bool 	  $sort = 1) {

	return $self->differ(list1 => $list1, list2 => $list2, sort => $sort);
}

=head2 isArray

Checks if the scalar value passed in is an array.

=over

=item usage:

  $bool = $util->isArray(\@a);

  $bool = $util->listToMap(ref => \@a);
   
=item args:

=over

=item ref [Any]

The scalar value you wish to check.

=back

=back
 
=cut

multi method isArray (Any :$ref!) {
    
    if (defined $ref) {
        if (ref($ref) eq 'ARRAY') {
            return 1;	
        }	
    }	
    
    return 0;
}

multi method isArray (Any $ref!) {
    
    return $self->isArray(ref => $ref);	
}

=head2 listToMap

=over

=item usage:

  %map = $util->listToMap(@list);

  %map = $util->listToMap(list => \@list);
   
=item args:

=over

=item list [Array|ArrayRef]

The array you wish to convert to a hashmap.

=back

=back
 
=cut

multi method listToMap (@list) {

    my %map = map { $_ => 1 } @list;
    return %map;
}

multi method listToMap (ArrayRef :$list!) {

	return $self->listToMap(@$list);
}

=head1 min

Just a passthrough to List::Util::min()

=over

=item usage:

 $min = $util->min(@list);
 
 $min = $util->min(list => \@list);

=back
 
=cut

multi method min (@list) {

    return List::Util::min(@list);    
}

multi method min (ArrayRef :$list!) {

	return $self->min(@$list);	
}

=head1 max

Just a passthrough to List::Util::max()

=over

=item usage:

 $max = $util->max(@list);
 
 $max = $util->max(list => \@list);

=back
 
=cut

multi method max (@list) {

    return List::Util::max(@list);    
}

multi method max (ArrayRef :$list!) {

	return $self->max(@$list);	
}


=head1 nsort 

Sort an array naturally (case in-sensitive).  This behaves the same way
Sort::Naturally::nsort does with the exception of using fc (casefolding) 
instead of lc (lowercase).  This guarantees the same results without
regard to locale (which Sort::Naturally::nsort does use).

=over

=item usage:

 @sorted = $util->nsort(@list);
 
 @sorted = $util->nsort(list => \@list);

=item args:

=over

=item list [Array|ArrayRef]

The list to act on.

=back

=back
 
=cut

multi method nsort (ArrayRef :$list!) {

	#
	# parse each element into an arrayref splitting by number
	#
	my @bits;
	foreach my $el (@$list) {

		my $x   = defined($el) ? $el : '';
		my @bit = ($x);

		if ( $x =~ m/^[+-]?(?=\d|\.\d)\d*(?:\.\d*)?(?:[Ee](?:[+-]?\d+))?\z/s ) {

			# pure numeric
			push @bit, '', $x;
		}
		else {
			# Consume the string.
			while ( length $x ) {
				push @bit, ( $x =~ s/^(\D+)//s ) ? fc($1) : '';
				push @bit, ( $x =~ s/^(\d+)//s ) ? $1     : 0;
			}
		}

		push @bits, \@bit;
	}

	#
	# sort each element by its parsed bits
	#
	my @sorted_bits = sort {

		# Uses $i as the index variable, $x as the result.
		my $x;
		my $i = 1;

		while ( $i < @$a and $i < @$b ) {
			$x = 0;

			last if ( $x = ( $a->[$i] cmp $b->[$i] ) );    # lexicographic
			++$i;

			last if ( $x = ( $a->[$i] <=> $b->[$i] ) );    # numeric
			++$i;
		}

		# unless we found a result for $x in the while loop,
		# use length as a tiebreaker, otherwise use cmp
		return $x || ( @$a <=> @$b ) || ( $a->[0] cmp $b->[0] );
	} @bits;

	#
	# return the first element of each arrayref (which is the orig)
	#
	return map $_->[0], @sorted_bits;
}
	
multi method nsort (@list) {

	return $self->nsort(list => \@list);
}
    

=head1 shuffle

Just a passthrough to List::Util::shuffle()

=over

=item usage:

 $max = $util->shuffle(@list);
 
 $max = $util->shuffle(list => \@list);

=back
 
=cut

multi method shuffle (@list) {

    return List::Util::shuffle(@list);    
}

multi method shuffle (ArrayRef :$list!) {

	return $self->shuffle(@$list);	
}

=head2 undefsToStrings

=over

=item usage:

 %map = $util->undefsToStrings($list, [$string]);

 %map = $util->undefsToStrings(list => \@list, [string => $str]);
   
=item args:

=over

=item list [ArrayRef]

The list to act on.

=item string [Str]

What to convert undef items to.  Default is empty string ''.

=back

=back
 
=cut

multi method undefsToStrings (ArrayRef $list,
                              Str 	   $string = '') {

    my @return;
    foreach my $val (@$list) {
        $val = $string if !defined $val;
        push @return, $val;
    }

    return \@return;
}

multi method undefsToStrings (ArrayRef :$list!,
                              Str 	   :$string = '') {
                              	
	return $self->undefsToStrings($list, $string);                              	
}	


=head1 uniq

Just a proxy to List::Util::uniq().

=over

=item usage:

 @uniq = $util->uniq(@list);

 @uniq = $util->uniq(list => \@list);

=back
   
=cut

multi method uniq (@list) {

    return List::Util::uniq(@list);    
}

multi method uniq (ArrayRef :$list!) {

	return $self->uniq(@$list);
}

1;
