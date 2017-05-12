
package fp::functionals;

use strict;
use warnings;

our $VERSION = '0.02';

# use fp's import routine
use fp;

BEGIN {
    *import = \&fp::import;
}

## ----------------------------------------------------------------------------

# right and left currying routines

sub curry ($@) {
	my ($f, @args) = @_;
        sub { $f->(@args, @_) }}

sub rcurry ($@) {
	my ($f, @args) = @_;
        sub { $f->(@_, @args) }}
    
## ----------------------------------------------   

# composition functions to compose 
# functions out of other functions    

sub simple_compose ($$) {
	my ($f, $f2) = @_;
        sub { $f2->($f->(@_)) }}

sub compose (@); # pre-declare sub so it can be used in recursion
sub compose (@) {
	my ($f, $f2, @rest) = @_;
        (!$f2) ?
            $f
            :
            compose sub { $f2->($f->(@_)) }, @rest }
    
## ----------------------------------------------    

# identity function

sub always ($) {
    my ($K) = @_;
        sub { $K }}

## ----------------------------------------------

## short circut function compositors

sub disjoin ($$) {
	my ($f, $f2) = @_;
		sub { $f->(@_) || $f2->(@_) }}

sub conjoin ($$) {
	my ($f, $f2) = @_;
		sub { $f->(@_) && $f2->(@_) }}

## ----------------------------------------------------------------------------

# this method is really more a utility method 
# to go along with these other, it can be used
# to bind a anyonomous function to a symbol within
# the callers namespace

sub defun ($$) {
    my ($symbol, $f) = @_;
    no strict 'refs';
    *{(caller())[0] . "::$symbol"} = $f }

1;

__END__

=head1 NAME

fp::functionals - a library for programming with functions

=head1 SYNOPSIS

  use fp;
  use fp::functionals;
  
  # create a function which will either 
  # sum a list of numbers of concat a
  # list of strings based on the first
  # element of each list
  defun combine_list => disjoin(
                            conjoin (\&is_string, \&concat), 
                            conjoin(\&is_digit, \&sum)
                            );
    
  combine_list(range 1, 5); # returns 15
  combine_list(range 'a', 'g'); # returns 'abcdefg'  
  
  # create a function which will filter
  # out all but the even numbers from a list
  defun filter_even => curry(\&filter, \&is_even);
  
  filter_even(range 1, 10); # 2, 4, 6, 8, 10
  
  # create a function which itself takes
  # a function and uses that function as
  # a predicate to determine how to filter
  # the numbers 1 through 10
  defun filter_one_through_ten => rcurry(\&filter, range(1, 10));
  
  filter_one_through_ten(\&is_odd); # return 1, 3, 5, 7, 9
  
  # create a function which adds 10 to its argument
  defun add_ten => curry(function { ((first @_) + (second @_)) }, 10);
  
  # now adapt that function to be used 
  # on ranges of numbers
  defun add_ten_to_range => simple_compose(\&range, curry(\&apply, \&add_ten));  
  
  add_ten_to_range(1, 5); # returns 11, 12, 13, 14, 15

=head1 DESCRIPTION

A functional, sometimes called a higher-order function, is essentially a function which itself operates on other functions. They can both take functions as arguments and return functions as results. 

Some people confuse closures with functionals, but they are not really the same thing. A functional can be (and usually is) a closure, whereas a closure need not be a functional. Many people also think of anyonomous functions as being the same as functional, but again this is not really true. Anonymous functions can be used as arguments to functionals, but you can just as easily use named functions as well. However to return a function, anonymous functions are needed (sometimes called I<lambda> functions). 

Perl has both closures and anonymous functions, so it is ripe for programming with functionals/higher-order functions. Perl itself actually has many functionals (in the not-so-strict sense of the term), such as C<map>, C<grep>, C<sort> and any other perl function which can take a block (C<{}>) or subroutine as an argument.

=head2 Assignment Statement

Note that this module, unlike it's parent module B<fp> makes use of the assignment operation. It must do this to create the needed closures since perl does not have named function parameters. However, pains are still made to avoid any other kind of assignments other than parameters, and non-destructive list assignments are used for arguments. If only perl had named paramters, this would not even be an issue.

=head1 FUNCTIONALS

=over 4

=item B<curry ($f, @args)>

Pre-binds the function's arguments on the left, and returns a function. Here is an example of how this might be used, and how one might otherwise solve the same problem.

  *filter_even = curry(\&filter, \&is_even);

This creates a function which would be equivalent of this:

  sub filter_even {
     my (@list) = @_;
     filter(\&is_even, @list);
  }

You can also apply any number of arguments with curry, not just one, but they will always be on the left side.

=item B<rcurry ($f, @args)>

Pre-binds the function's arguments on the right, and returns a function. This is sort of a mirror of how C<curry> handles arguments. Here is an example, along with its equivalent.

  *filter_one_through_ten = rcurry(\&filter, range(1, 10));

Which is equivalent to:

  sub filter_one_through_ten {
      my ($func) = @_;
      filter($func, (1 .. 10));
  }

=item B<compose (@f)>

Given a list of functions, this will combine them in a I<pipeline> fashion, so that the return values of each function will be the arguments to the next. This function uses recursion to compose the function, which adds an additional cost of a wrapper function. Here is an illustration of the recursive function composition process, where the symbol I<wf> represents the wrapper function used to compose recursively.

  compose (f1, f2, f3, f4)
  compose (wf { f2 { f1 }}, f3, f4)
  compose (wf { f3 { wf { f2 { f1 }}}}, f4)
  compose (wf { f4 { wf { f3 { wf { f2 { f1 }}}}}})

=item B<simple_compose ($f, $f2)>

Given two functions, this will combine them in a I<pipeline> fashion, so that the return values of the first function will be the arguments to the second. This is a simplier, non-recursive version of C<compose> which does not have the overhead of the wrapper function (as explained above).

=item B<always ($K)>

This is basically a constant function, sometimes called an I<indenity> function. It returns a function which will always return C<$K>. This is useful when you need a constant value, but a function is expected.

=item B<conjoin ($f, $f2)>

This takes two functions and create a single function which will execute the first function passing in any arguments, if it returns a true value then it will execute the second function, again passing in any arguments. It should be noted, that it is assumed that the functions C<$f> and C<$f2> are non-desctructive of their arguments. It is basically a short circuit function, along the lines of the logical C<&&> operator.

=item B<disjoin ($f, $f2)>

This takes two functions and create a single function which will execute the first function passing in any arguments, if it returns a false value, then it will execute the second function, again passing in any arguments. It should be noted, that it is assumed that the functions C<$f> and C<$f2> are non-desctructive of their arguments. It is basically a short circuit function, along the lines of the logical C<||> operator.

=back

=head1 UTILITY FUNCTION

=over 4

=item B<defun ($symbol, $f)>

This function is really more a utility function to go along with these other, it can be used to bind a anyonomous function to a symbol within the caller's namespace. This is not really considered a higher order function itself since it doesn't return a function (although it does take one as an argument). It is just really a symbol binder so that you can avoid using assignment yourself when using this module. So code that otherwise would look like this:

  my $curried_sub = curry(\&filter, \&is_even);
  $curried_sub->(1 .. 100);

can now look like this:

  defun curried_sub => curry(\&filter, \&is_even);
  curried_sub(1 .. 100);
  
of course you can also do the same thing on your own, like this:

  *curried_sub = curry(\&filter, \&is_even);

The choice is yours.

=back

=head1 BUGS

None that I am currently aware of. Of course, that does not mean that they do not exist, so if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

See the C<CODE COVERAGE> section of B<fp> for this information.

=head1 SEE ALSO

=over 4

=item ANSI Common Lisp - Paul Graham

These functions are taken from the examples of higher-order functions shown on page 110 of this book. Paul Graham mentions that he himself got them from the language Dylan.

=item ML for the Working Programmer - L. C. Paulson

Chapter 5 of this book, "Functions and Infinite Data" is a good resource on functionals.

=item L<Higher-Order Functions|http://en.wikipedia.org/wiki/Higher-order_function>

This is a link to the WikiPedia page for Higher-Order Functions, it has lots of good info, and many of the links lead to other interesting esoteria as well.

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004, 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
