package fp;

use strict;
use warnings;

our $VERSION = '0.03';

## import routine
## --------------------------------------------------
# NOTE:
# every effort has been made with import 
# subroutine to not use the assignment
# statement, but since you can't export
# without it, it had to be done. I don't
# consider this as part of the library
# but rather part of the infastructure of
# this module.
sub import {
    no strict 'refs';
    my $package = shift;
    # we have to use the build in map
    # here instead of fp::apply, in
    # order to get an accurate value
    # from caller. If we use fp::apply, 
    # it's recursion will cause issues
    # with that.
    map {
        *{(caller())[0] . "::$_"} = \&{"${package}::$_"}
        } (fp::filter(sub {
                    defined &{"${package}::$_[0]"}
                  }, (fp::is_not_equal_to(fp::len(fp::tail(@_)), 0) ?
                            fp::tail(@_)
                            :
                            fp::filter(
                                sub { fp::is_not_equal_to("import", fp::head(@_)) }, 
                                fp::list(keys %{"${package}::"})
                                )))) }

## functional constants
## --------------------------------------------------
# boolean constants
sub true  () { 1 }
sub false () { 0 }
	
# empty list constant
sub nil () { () }

## list operations
## --------------------------------------------------
# creation
sub list (@);
sub list (@) { @_ }

# emptiness predicates
sub is_empty     (@) { @_ ? 0 : 1 }
sub is_not_empty (@) { @_ ? 1 : 0 }

# selection
sub head  (@) { $_[0] }
sub tail  (@) { @_[ 1 .. $#_ ] }

# selection macros
sub first  (@) { is_not_empty(@_) ? head @_ : nil }
sub second (@) { first  tail @_ }
sub third  (@) { second tail @_ }
sub fourth (@) { third  tail @_ }
sub fifth  (@) { fourth tail @_ }
sub sixth  (@) { fifth  tail @_ }

sub reduce (@) { tail @_ }

# random access
sub nth (@); # pre-declare sub so it can be used in recursion
sub nth (@) { 
	(is_empty(tail @_)) ?
		nil
		:
		((head @_) == 0) ?
			second @_
			:
			nth(((head @_) - 1), (reduce tail @_)) }
			
# length
sub len (@); # pre-declare sub so it can be used in recursion
sub len (@) { @_ ?  1 + len(reduce @_) : 0 }
			
# end access
sub end (@) { nth((len(@_) - 1), @_)  }

# add element to the head of the list 
sub prepend (@) { @_ } 			

# add element to the end of the list
sub append (@) { ((tail @_), (head @_)) }

# combine two lists
sub combine (@) { @_ }

# reverse a list
sub rev (@); # pre-declare sub so it can be used in recursion
sub rev (@) { 
	(is_empty @_) ?
		nil
		:
		(rev(reduce @_), (first @_)) }

# list membership predicate
sub member (@); # pre-declare sub so it can be used in recursion
sub member (@) {
	(is_empty(tail @_)) ? 
		false
		:
		(is_equal_to((first @_),(second @_))) ? 
			true
			:
			member((first @_), (reduce tail @_)) }
			
# make a list into a set (list with unique elements)
sub unique (@); # pre-declare sub so it can be used in recursion
sub unique (@) {
	(is_empty(@_)) ?
		nil
		:
		(member((first @_), (tail @_))) ?
			(nil, unique(reduce @_))
			:
			((first @_), unique(reduce @_)) }

# unique prepend - returns unique list or original list		
sub unique_prepend (@) {
	(member((first @_), (tail @_))) ?
		tail @_
		:
		prepend(@_) }

# unique append - returns unique list or original list
sub unique_append (@) {
	(member((first @_), (tail @_))) ?
		tail @_
		:
		append(@_) }

# unique combine function - takes the whole argument list
sub unique_combine (@) { unique(@_) }

## set (unique list) operations
## --------------------------------------------------

# adjoin a set with mutliple new elements
sub adjoin (@) { unique(@_) }

# union of two sets is a list of all thier unique elements
sub union (@) { unique(@_) }

# intersection of two sets is a list of all elements found in both
sub intersection (@); # pre-declare sub so it can be used in recursion
sub intersection (@) {
	(is_empty(@_)) ?
		nil
		:
		(member((first @_), (tail @_))) ?
			((first @_), intersection(reduce @_))
			:
			(nil, intersection(reduce @_)) }

# differnce of two sets is a list of elements from the first lists
# that are not contained in the second list
## NOTE - this cannot be implemented because of perl's auto-list-flatening

# xor of two sets is a list of elements not found in both
## NOTE - this cannot be implemented because of perl's auto-list-flatening
## --------------------------------------------------

## function constructor
## --------------------------------------------------
sub function (&);
sub function (&) { (head @_) }

## --------------------------------------------------
# map a function to a list
sub apply (@);  # pre-declare sub so it can be used in recursion
sub apply (@) {
	(is_empty(tail @_)) ?
		nil
		:
		(&{first(@_)}(second @_), apply((first @_), (reduce tail @_))) }

# filter a list based on a function
sub filter (@);  # pre-declare sub so it can be used in recursion
sub filter (@) {
	(is_empty(tail @_)) ?
		nil
		:
		(&{first(@_)}(second @_)) ?
			((second @_), filter((first @_), (reduce tail @_)))
			: 
			(nil, filter((first @_), (reduce tail @_))) }

## list reduction functions
## --------------------------------------------------
# sum a list of integers
sub sum (@); # pre-declare sub so it can be used in recursion
sub sum (@) {
	(is_empty @_) ?
		0
		:
		first(@_) + sum(reduce @_) }

# concatenate a list of strings	
sub concat (@); # pre-declare sub so it can be used in recursion
sub concat (@) {
	(is_empty @_) ?
		""
		:
		first(@_) . concat(reduce @_) }
	
# multiply a list of integers
sub product (@); # pre-declare sub so it can be used in recursion
sub product (@) {
	(is_empty @_) ?
		1
		:
		first(@_) * product(reduce @_) }

## list expansion functions
## --------------------------------------------------	
# split up a string 	
sub explode ($) { (first(@_) =~ /(.)/g) }

# split up a multi-digit numeral
sub slice_by ($) { (first(@_) =~ /\d/g) }

# get a range of elements
sub range ($$) { (first(@_) .. second(@_)) }

## misc. predicates
## --------------------------------------------------
# even and odd mutually recursive predicates
sub is_even ($) { 
	(first(@_) <= 0) ? 
		true 
		: 
		is_odd(first(@_) - 1) }
		
sub is_odd ($) { 
	(first(@_) <= 0) ? 
		false 
		: 
		is_even(first(@_) - 1) }
        
sub is_not_equal_to ($$) {
    (not is_equal_to(@_)) }        
		
sub is_equal_to ($$) {
	(is_digit(head @_)) ?
        (head(@_) == tail(@_))
        : 
        (head(@_) eq tail(@_)) }
	
sub is_digit ($) {
	(first(@_) =~ /\d/) }
	
sub is_whitespace ($) {
	(first(@_) =~ /\s/) }
	
sub is_alpha ($) {
	(first(@_) =~ /[a-zA-Z]/) }

1;

__END__

=head1 NAME

fp - a library for programming in a functional style

=head1 SYNOPSIS

  use fp;
  
  # filter out all be the even numbers
  filter(function { is_even(head(@_)) }, range(1, 100));
  
  # split the string, get unique list out of it
  # then get that list's length, and then check
  # that is equal to 26 
  is_equal_to(len(unique(explode("the quick brown fox jumped over the lazy dog and ran on down the road"))), 26);
  
  # the sum of the numbers 1 through 10 is 55
  is_equal_to(sum(range(1, 10)), 55);

=head1 DESCRIPTION

This module is an experiment in functional programming in perl. It uses nothing but a combination of; subroutines, the C<@_> array and a few built in operators to implement a style of functional programming.

None of the code above is all that interesting until you consider that at no point was variable assignment (C<=>), C<if> statements, or non-recursive iteration used. Although, do be entirely honest, there is actually two times when the C<=> operator is used in the entire module. The first time is to assign the module's version, the second time is within the import routine, but those are really not parts of this library and really more infastructure anyway. 

Variable assignment is not utilized, instead the contents of the C<@_> argument array are accessed/manipulated and passed along as the return of values from functions. Recursion is the only means of iteration, we do not use any of perl's built in iteration mechanisms (C<for>, C<foreach>, C<while>, etc.). All functions are non-destructive to their inputs, and just about everything returns an array of some sort, so function call chaining works quite well. It operates only on flat lists only, since perl will flatten any arrays given as arguments. 

This code is also written without side-effects. Meaning that each function is written to express an algorithm that produces its result rather than produce its result through the coercion of side-effects. Here is an example of what i mean, using even/odd predicate functions.

with side effects:

  sub is_even { (($_[0] % 2) == 0); }
  sub is_odd { (($_[0] % 2) != 0); }

without side efffects:

  sub is_even { ($_[0] <= 0) ? true : is_odd($_[0] - 1); }	
  sub is_odd { ($_[0] <= 0) ? false : is_even($_[0] - 1); }

The side-effect version uses the side effects of the mathematical calculation of (x % 2) to test if x is even or odd. Where the side-effect free version uses mutual recursion to continually subtract 1 from x until it reaches 0, at which point it will be either odd or even based upon the function it stops in.

=head1 FUNCTIONS

=head2 constants

=over 4

=item B<true>

Represents a true value.

=item B<false>

Represents a false value.

=item B<nil>

Represents an empty list.

=back

=head2 constructors

=over 4

=item B<list (@items)>

Constructs a list out of the elements passed to it.

=item B<range ($lower, $upper)>

Constructs a list spanning from the first argument to the second argument.

=item B<function (&block)>

Constructs a function. 

=back

=head2 list operations

=over 4

=item B<len (@list)>

Returns the length of the list.

=item B<rev (@list)>

Reverses the list given to it.

=item B<append ($element, @list)>

Appends an element to a list.

=item B<prepend ($element, @list)>

Prepends an element to a list.

=item B<head (@list)>

Returns the element at the head of the list.

=item B<tail (@list)>

Returns the list, less the first element.

=item B<nth ($n, @list)>

Returns the I<n>th element of the list.

=item B<first (@list)>

Returns the first element of the list.

=item B<second (@list)>

Returns the second element of the list.

=item B<third (@list)>

Returns the third element of the list.

=item B<fourth (@list)>

Returns the fourth element of the list.

=item B<fifth (@list)>

Returns the fifth element of the list.

=item B<sixth (@list)>

Returns the sixth element of the list.

=item B<reduce>

Reduce a list by removing the head of the list.

=item B<end (@list)>

Returns the element at the end of the list.

=item B<is_empty (@list)>

Returns true if the given list is empty (equal to C<nil>).

=item B<is_not_empty (@list)>

Returns true if the given list is not empty (equal to C<nil>).

=item B<member ($element, @list)>

Tests for the existence of a given element in the list.

=item B<filter (&function, @list)>

Filter a list with a predicate function.

=item B<apply (&function, @list)>

Apply a function to each element in a list.

=item B<slice_by ($number)>

Divides a number up into its individual numeric components.

=item B<explode ($string)>

Divides a string into characters.

=item B<concat (@list_of_strings)>

Given a list of strings, it combines them into a single string.

=item B<sum (@list_of_numbers)>

Sums a list of numbers

=item B<product (@list_of_numbers)>

Returns the product of all the elements in the list.

=item B<combine (@list, @list)>

Combine two lists into one.

=item B<unique (@list)>

Only return the unique elements of a given list.

=item B<unique_combine (@list, @list)>

Returns a unique list of two lists.

=item B<unique_prepend ($element, @list)>

Prepends the element to the list, while retaining uniqueness.

=item B<unique_append ($element, @list)>

Appends the element to the list, while retaining uniqueness.

=back

=head2 set operations

=over 4

=item B<union (@list, @list)>

Returns a union of two lists.

=item B<adjoin (@list, @list)>

Adjoin a set with mutliple new elements

=item B<intersection (@list, @list)>

Intersection of two sets is a list of all elements found in both.

=back

=head2 predicates

=over 4

=item B<is_even ($number)>

This along with its mutually recursive mate C<is_odd> will determine if a given number is even.

=item B<is_odd ($number)>

This along with its mutually recursive mate C<is_even> will determine if a given number is odd.

=item B<is_equal_to ($element, $element)>

This attempts to determine if two elements are equal. 

=item B<is_not_equal_to ($element, $element)>

This attempts to determine if two elements are not equal. 

=item B<is_digit ($element)>

This attempts to discern if a given element is a digit.

=item B<is_whitespace ($element)>

This attempts to discern if a given element is whitespace.

=item B<is_alpha ($element)>

This attempts to discern if a given element is an alphabetical character.

=back

=head1 TO DO

This library is missing two set operations, because I cannot yet figure out a way to accomplish them without resorting to assignment statements.

=over 4

=item Differnce of two sets is a list of elements from the first lists that are not contained in the second list. This cannot be implemented because of perl's auto-list-flatening.

=item xor of two sets is a list of elements not found in both. This cannot be implemented because of perl's auto-list-flatening.

=back

=head1 BUGS

None that I am currently aware of. Of course, that does not mean that they do not exist, so if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, below is the B<Devel::Cover> report on this module test suite.

 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 File                           stmt   bran   cond    sub    pod   time  total
 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 fp.pm                         100.0   88.0    n/a  100.0  100.0   69.7   97.1
 fp/functionals.pm             100.0  100.0    n/a  100.0  100.0    0.3  100.0
 fp/lambda.pm                  100.0    n/a    n/a  100.0    n/a   29.7  100.0
 fp/lambda/utils.pm            100.0    n/a    n/a  100.0  100.0    0.3  100.0
 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 Total                         100.0   89.3    n/a  100.0  100.0  100.0   98.7
 ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 SEE ALSO

This module was inspired by reading one to many books about functional programming. Here is a short list of those books, all of which I recommend reading if you are insterested in such things.

=over 4

=item ANSI Common Lisp - Paul Graham

This was really my first introduction to LISP and functional programming as a style/paradigm. It is an both informative and entertaining. Not to be missed, is Paul's web site L<http://www.paulgraham.com>, it has many a good article on it.

=item Functional Programming and its Applications

This is a collection of essays for a advanced course in functional programming given at Newcastle Univeristy in the summer of 1981. Some of the essay highlights are one by Gerald Jay Susseman (of MIT fame), and one by John H. Williams about John Backus's FP language. I got this gem on Ebay a few years ago, I doubt it is still in print, but here is the ISBN number if you want to try and track it down: 0-521-24503-6.

=item Programming Language Pragmatics - Micheal L. Scott

While not specifically about functional programming, but rather about all kinds of programming, this book is a must have for any programming language enthusiast (like myself). Its 800+ pages of densly packed inforamtion on all sorts of programming langauges.

=item Concurrent Programming in ERLANG

Erlang is a language developed by Ericson's research labs for use in soft-real-time programming. It is part-functional, part-declarative, and an extremely interesting langauge. This book, written by the 4 researchers who created Erlang, is well written and gives a great introduction into how to code, I<real> world applications in a more functional style. 

=item ML for the Working Programmer - L. C. Paulson

Standard ML is one of the more interesting functional langauges out there, and this book is an excellent reference on the langauge. I have to say that it does at times get very dense with theory and math, but it is a book I still refer to often, even when not programming functionally.

=item Can Programming Be Liberated from the von Neumann Style? - John Backus 

Not really a book, but instead the speech given by John Backus at the 1977 Turing Awards. This speech introduced FP, a very interesting (although somewhat odd) functional language. This was a very influential speech in the world of functional programming. It can be found in PDF form at L<http://www.stanford.edu/class/cs242/readings/backus.pdf>.

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004, 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
