
# Package implementing a "lazy lists" via a tied arrays
package Tie::LazyList;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA         = qw( Exporter );
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT      = qw();
our $VERSION     = '0.05';


# debug variable that may be set to see the debug messages
our $debug       = 0;
sub debug ($) { print $_[0], "\n" if $debug }


# "Locality" factor - how many additional elements will be filled when
# extending an array
our $locality    = 10;


# Returns TRUE is passed parameter is a number, FALSE otherwise
# ( thank's to Joseph Hall for the trick :)
sub _is_number {
	my $number = @_ ? shift : $_;
	( ~$number & $number ) eq '0';
}

# Returns the result of applying the passed operation on two first numbers of array
# after checking that they're *really* numbers
sub _factor ($$){
	local $_;
	my ( $array_ref, $op ) = @_;
	for ( @{ $array_ref }[ 0, 1 ] ){
		( defined and _is_number()) or croak "Illegal array init by not a number !";
	}
	# checking the "division by zero" case
	if (( $op eq '/' ) and ( $array_ref->[0] == 0 )){
		croak "Illegal attempt to divide by zero !";
	}

	eval "$array_ref->[1] $op $array_ref->[0]";
}



# Predefined code abbreviations
my %CODES_ABBREV =
	(	# Arithmetic progression
		APROG     => sub {
							my ( $array_ref ) = @_;
							my $factor = _factor( $array_ref, '-' ); # factor = arr[1] - arr[0]
							sub {
								my ( $array_ref, $n ) = @_;
								$array_ref->[ $n - 1 ] + $factor;
							}
						 },
		# Geometric progression
		GPROG     => sub {
							my ( $array_ref ) = @_;
							my $factor = _factor( $array_ref, '/' ); # factor = arr[1] / arr[0]
							sub {
								my ( $array_ref, $n ) = @_;
								$array_ref->[ $n - 1 ] * $factor;
							}
						 },
		# Summary of arithmetic progression
		APROG_SUM => sub {
							my ( $array_ref ) = @_;
							my $factor = _factor( $array_ref, '-' ); # factor = arr[1] - arr[0]
							return (
								sub {
									my ( $array_ref, $n ) = @_;       # n - zero based
									my $a_0 = $array_ref->[ 0 ];      # a0
									my $a_n = $a_0 + ($factor * $n);  # an = a0 + d*n
									$array_ref->[ $n - 1 ] + $a_n;    # S(n) = S(n-1) + an
								},
								# truncating the rest of the array - we have the first elem and the factor
								[ $array_ref->[ 0 ]]
							)
						 },
		# Summary of geometric progression
		GPROG_SUM => sub {
							my ( $array_ref ) = @_;
							my $factor = _factor( $array_ref, '/' ); # factor = arr[1] / arr[0]
							return (
								sub {
									my ( $array_ref, $n ) = @_;       # n - zero based
									my $a_0 = $array_ref->[ 0 ];      # a0
									my $a_n = $a_0 * ($factor ** $n); # an = a0 * q^n
									$array_ref->[ $n - 1 ] + $a_n;    # S(n) = S(n-1) + an
								},
								# truncating the rest of the array - we have the first elem and the factor
								[ $array_ref->[ 0 ]]
							)
						 },
		 FIBON    => sub {
						 	my ( $array_ref ) = @_;
						 	@{ $array_ref } >= 2 or croak "Illegal array init - should be two elements at least !";
		 					sub {
		 						my ( $array_ref, $n ) = @_;
		 						$array_ref->[ $n - 1 ] + $array_ref->[ $n - 2 ];
		 					}
		 				 },
		 FACT     => sub {
						 	my ( $array_ref ) = @_;
						 	@{ $array_ref } >= 1 or croak "Illegal array init - should be one element at least !";
		 					sub {
		 						my ( $array_ref, $n ) = @_;
		 						$array_ref->[ $n - 1 ] * $n;
		 					}
						 },
		 POW      => sub {
							my ( $array_ref ) = @_;
							_is_number( my $x = $array_ref->[0] ) or croak "Illegal array init by not a number !";
							$x == 0 and croak "Illegal array init with zero !";
							return (
								sub {
									my ( $array_ref, $n ) = @_;
									$array_ref->[ $n - 1 ] * $x;
								},
								[ 1 ] # starting with x^0 = 1
							);
						 }
	);



sub TIEARRAY {
	local $_;
	my $class          = shift   or croak "Undefined class !";
	defined ( my $init = shift ) or croak "Undefined array init !"; # may be a scalar or ARRAY ref

	# List's initialization variables to be set now :
	my ( @arr,         # list's main array, should be initialized
	     $code_ref );  # list's generation function

	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	# setting @arr and, possibly, $code_ref ( $code_ref will be set if the init
	# passed is a reference to another array tied to LazyList )

	my $ref = ref $init;

	unless ( $ref ){
		# init is a simple scalar variable
		@arr = ( $init );
	} elsif ( $ref eq 'ARRAY' ){
		# init is a reference to ARRAY and it may be :
		# 1) ref to another array tied to LazyList
		# 2) ref to a usual Perl array
		my $tied_object = tied @{ $init };
		if ( defined $tied_object ){
			# 1)
			$tied_object->isa( $class )
				or croak "Reference to a tied object passed which isn't a [$class] instance !";
			# taking the initialization data from this tied object : init_array and code
			my ( $init_array, $code ) = $tied_object->_init_data();
			@arr      = @{ $init_array };
			$code_ref = $code;
		}
		else {
			# 2)
			@arr = @{ $init };
		}
	} else {
		# init is an unexpected reference
		croak "Unknown [$ref] referenece passed for initializing the list !";
	}


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	# setting $code_ref ( if it wasn't set by above block ) and, possibly, @arr again
	# ( @arr will be set again if the code abbreviation that was used will return a
	# new array when fetched from the code's table )

	unless ( defined $code_ref ){

      # code is sitting in @_ and should be a scalar or CODE ref
      my $code = shift or croak "Undefined code !";
		my $ref  = ref $code;

		unless ( $ref ){
			# code is a scalar variable, should be one of the predefined code abbreviations
			exists $CODES_ABBREV{ $code } or croak "Unknown scalar [$code] passed as code abbreviation !";
			# getting the code and, possibly, array_ref for the new array
			my ( $returned_code, $array_ref ) = $CODES_ABBREV{ $code }->( \@arr );
			$code_ref = $returned_code;
			@arr      = @{ $array_ref } if defined $array_ref;
		} elsif ( $ref eq 'CODE' ){
			# code is a CODE reference
			$code_ref = $code;
		} else {
			# code is an unexpected reference
			croak "Unknown [$code_ref] reference passed as a code !";
		}
	}

	# sanity-check of result initializations
	ref [ @arr ]  eq 'ARRAY' or die "Failed to successfully initialize the array ! \a";
	ref $code_ref eq 'CODE'  or die "Failed to successfully initialize code reference ! \a";


	bless { array      => \@arr,         # the main list that will be used and expanded
			  init_array => \@arr,         # keeping the initialization array
	        code       => $code_ref,     # the generation function
	        'length'   => scalar @arr }, # the current length, will be updated every time it changes
			$class;
}


# returns the init_array ref and the code ref ( used for creating
# another tied array, initialized exactly as this one )
sub _init_data {
	local $_;
	my $self = shift;
	@{ $self }{ qw ( init_array code ) };
}


sub FETCH {
	debug "FETCH(@_)";
	local $_;
	my $self = shift;
	my ( $index ) = @_;
	my ( $array_ref, $length, $code_ref ) = @{ $self }{ qw ( array length code )};

	unless ( $index < $length ){           # we should extend the array
		my $top_fill = $index + $locality;  # top index to be filled
		$#{ $array_ref } = $top_fill;       # pre-extending array for the efficiency
		for ( $length .. $top_fill ){
			$array_ref->[ $_ ] = $code_ref->( $array_ref, $_ );
		}
		$self->{ 'length' } = $top_fill + 1;
	}

	$array_ref->[ $index ];
}

sub STORE {
	debug "STORE(@_)";
	local $_;
	my $self = shift;
	my ( $index, $value ) = @_;
	if ( defined $value ){
		$self->{ array }[ $index ] == $value or # <-- used by Perl during 'for ( @array )' loop
			croak "No STORE operation supported for class [@{[ ref $self ]}] !";
	}
}


sub FETCHSIZE {
	debug "FETCHSIZE(@_)";
	local $_;
	my $self = shift;
	$self->{ 'length' } + 1; # to make 'for ( @array )' loop iterate infinitely
}

sub STORESIZE {
	debug "STORESIZE(@_)";
	local $_;
	my $self = shift;
	croak "No STORESIZE operation supported for class [@{[ ref $self ]}] !";
}

sub EXTEND {
	debug "EXTEND(@_)";
	local $_;
	my $self = shift;
	croak "No EXTEND operation supported for class [@{[ ref $self ]}] !";
}

sub EXISTS {
	debug "EXISTS(@_)";
	local $_;
	my $self = shift;
	croak "No EXISTS operation supported for class [@{[ ref $self ]}] !";
}

sub DELETE {
	debug "DELETE(@_)";
	local $_;
	my $self = shift;
	croak "No DELETE operation supported for class [@{[ ref $self ]}] !";
}

sub CLEAR {
	debug "CLEAR(@_)";
	local $_;
	my $self = shift;
	croak "No CLEAR operation supported for class [@{[ ref $self ]}] !";
}

sub PUSH {
	debug "PUSH(@_)";
	local $_;
	my $self = shift;
	croak "No PUSH operation supported for class [@{[ ref $self ]}] !";
}

sub POP {
	debug "POP(@_)";
	local $_;
	my $self = shift;
	croak "No POP operation supported for class [@{[ ref $self ]}] !";
}

sub SHIFT {
	debug "SHIFT(@_)";
	local $_;
	my $self = shift;
	croak "No SHIFT operation supported for class [@{[ ref $self ]}] !";
}

sub UNSHIFT {
	debug "UNSHIFT(@_)";
	local $_;
	my $self = shift;
	croak "No UNSHIFT operation supported for class [@{[ ref $self ]}] !";
}

sub SPLICE {
	debug "SPLICE(@_)";
	local $_;
	my $self = shift;
	croak "No SPLICE operation supported for class [@{[ ref $self ]}] !";
}

sub UNTIE {
	debug "UNTIE(@_)";
	local $_;
	my $self = shift;
}

sub DESTROY {
	debug "DESTROY(@_)";
	local $_;
	my $self = shift;
}


1;

__END__


=head1 NAME

Tie::LazyList - Perl extension for lazy lists growing on demand

=head1 SYNOPSIS

  use Tie::LazyList;

  # lazy list of factorials
  tie @arr,  'Tie::LazyList', [ 1 ], 'FACT';
  tie @arr2, 'Tie::LazyList', 1, sub { my ( $array_ref, $n ) = @_; $array_ref->[ $n - 1 ] * $n };
  tie @arr3, 'Tie::LazyList', \@arr;
  print "$_\n" for @arr;   # prints ( eternally ) values of 1!, 2!, 3! ..
  print "$_\n" for @arr2;  # the same
  print "$_\n" for @arr3;  # the same

  # lazy list of powers of 2
  tie @arr,  'Tie::LazyList', 2, 'POW';
  tie @arr2, 'Tie::LazyList', 1, sub { my ( $array_ref, $n ) = @_; $array_ref->[ $n - 1 ] * 2 };
  tie @arr3, 'Tie::LazyList', \@arr2;
  print $arr [ 10 ], "\n", # prints 1024 = 2^10
        $arr2[ 10 ], "\n", # the same
        $arr3[ 10 ], "\n"; # the same

  # lasy lists of Fibonacci numbers, arithmetical/geometrical progressions and their sums, etc ..

=head1 DESCRIPTION

C<Tie::LazyList> allows you to create B<lazy lists> ( E<quot>infinite lists, whose tail remain
unevaluatedE<quot>, Watt )
growing on demand with user-defined generation function.

What you have is a usual Perl array whose elements are generated by some function and which may be
accessed by C<$arr[x]> as any other, but actually grows I<under the hood> if the element
you're accessing isn't generated yet.
This way, the amount of memory wasted for the array is no more ( and no less, unfortunately ) then you need.
Think about it as dynamically growing factorials ( Fibonacci numbers, arithmetic progression .. ) table
which you can access for any element without need to explicitly build and maintain it.

All you need to specify is the initial list elements, generation function and .. that's it, actually -
go and work with it ! See the example above - I think, they demonstrate the simplicity.

So, here are the rules : you create the new lazy list by

C<tie @array, 'Tie::LazyList'>, C<list init>, C<generation function>

or

C<tie @array, 'Tie::LazyList',> C<ARRAY reference>

where

=over 4

=item C<list init>

Initial elements of your list. It may be a single scalar variable ( number, usually )
or an array reference ( if you'd like to initialize more then one element ).
Examples : C<1> or C<2> or C<[ 1, 2, 3 ]>

=item C<generation function>

Reference to the function which will be called to generate new list elements.
When called it'll be passed the following parameters :

=over 1

=item *

reference to the array filled from index C<0> upto C<n-1>

=item *

C<n> - index of the element to generate

=back

The function should return the value of the C<n>-th array element.

In order to make our life a bit easier there is a number of, what I call, code abbreviations.
It means that C<generation function> may be not the code reference, but something much simpler -
string, having one of the predefined values.
Those values tell the module which C<generation function> to use and they are :

=over 4

=item APROG

Means B<a>rithmetic B<prog>ression, C<list init> should contain at least two elements in order to
calculate progression's factor.

=item GPROG

Means B<g>eometric B<prog>ression, C<list init> has the same restriction as in APROG.

=item APROG_SUM

Means B<a>rithmetic B<prog>ression's B<sum>mary, C<list init> should contain, again, at least
two elements, but of the I<original progression> !

=item GPROG_SUM

Means B<g>eometric B<prog>ression's B<sum>mary, C<list init> has the same restriction as in APROG_SUM.

=item FIBON

Means B<Fibon>acci numbers, C<list init> should contain at least two elements ( C<[ 0, 1 ]>, as you know )

=item FACT

Means B<fact>orials, C<list init> should contain one element at least ( C<1>, as you know )

=item POW

Means B<pow>er - arising C<x> to any power, C<list init> should contain only numbers.

=item ???

I'm not a mathematician .. If you have more ideas, send them to genie@cpan.org !

=back

=item C<ARRAY reference>

Reference to another array, already tied to C<Tie::LazyList>.

=back

=head2 EXAMPLES

  # lazy list of fractions 1/(2^n) - 1, 1/2, 1/4, 1/8 ..
  tie @array,  'Tie::LazyList', 1, sub { my( $array_ref, $n ) = @_; $array_ref->[ $n - 1 ] / 2 };

  # the same
  tie @array,  'Tie::LazyList', [ 1, 0.5 ], 'GPROG';

  # lazy list of above geometric progression's summary : arr[ n ] = 1 + 1/2 + 1/4 + .. + 1/(2^n)
  tie @array,  'Tie::LazyList', [ 1, 0.5 ], 'GPROG_SUM';

  # creating tied array from another tied array
  tie @array2, 'Tie::LazyList', \@array;

  # prints 1.99999904632568 = 1 + 1/2 + 1/4 + .. + 1/(2^20)
  print $array[ 20 ];

  # the same
  print $array2[ 20 ];

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  # lazy list of Fibonacci numbers
  tie @array, 'Tie::LazyList', [ 0, 1 ], 'FIBON';

  # the same
  tie @arr2,  'Tie::LazyList', \@array;

  # prints 13 = 5 + 8
  print $array[ 7 ];

  # the same
  print $arr2[ 7 ];

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  # lazy list of factorials
  tie @array, 'Tie::LazyList', 1, 'FACT';

  # prints 1.19785716699699e+100 = 70!
  print $array[ 70 ];

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  # lazy list of powers of e
  tie @array, 'Tie::LazyList', 2.718281828, 'POW';

  # prints 148.413158977261 = e^5
  print $array[ 5 ];

=head2 ALLOWED ARRAY OERATIONS

Having tied an array what operations can you do with it ? Does it support a usual array operations
like L<pop>, L<push> and L<splice> ?
The answer to the first question  - not so many, actually.
The answer to the second question is further shorter - no, it doesn't.

The only operations an array tied to C<Tie::LazyList> currently supports are element
access B<C<$arr[x]>> and B<C<for ( @array )>> eternal iteration I<( isn't it great already ? )>.
Trying to apply anything else is a fatal error. Some functions ( like storing ) doesn't have
any sense in lazy lists, others ( like filtering via L<grep> ) may be implemented later ..


=head2 LOCALITY

There's a B<C<$Tie::LazyList::locality>> variable stating how many additional list elements should
be evaluated when expanding it. It's default value is C<10> and it means whenever list should grow
to index C<n> it'll actually grow to index C<n + 10>.
You may set it to any number you like, but note that my benchmarks showed that locality equal to
C<0> makes iteration from C<arr[0]> to C<arr[1e6]> about 30% slower then iteration from C<arr[1e6]>
to C<arr[0]> ( which is, obviously, the fastest in the total time ), while iteration with locality equal
to C<10> showed the same result E<quot>in both directionsE<quot>.
Locality equal to C<100> and C<1000> didn't bring any further speedup, so C<10> looks Ok.

=head1 TODO

=over 4

=item 1.

Apply L<map> and L<grep> on lazy lists

=back

=head1 BUGS

Not found yet

=head1 SEE ALSO

L<perltie>

B<I<Object Oriented Perl>> by Damian Conway ( yeap, I've mentioned it too now )

=head1 AUTHOR

Goldin Evgeny E<lt>genie@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) Goldin Evgeny. All rights reserved.

This library is free software. 
You can redistribute it and/or modify it under the same terms as Perl itself.  

=cut
