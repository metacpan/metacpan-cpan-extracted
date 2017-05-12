package Tie::LazyFunction;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

sub TIESCALAR{
	shift; 
	@_ == 1 and return bless [$_[0]], 'Tie::LazyFunction';
	@_ == 2 and return bless [$_[0],\($_[ 1 ] )], 'Tie::LazyFunction::1';
	@_ == 3 and return bless [$_[0],\(@_[ 1 .. 2 ] )], 'Tie::LazyFunction::2';
	@_ == 4 and return bless [$_[0],\(@_[ 1 .. 3 ] )], 'Tie::LazyFunction::3';
	@_ == 5 and return bless [$_[0],\(@_[ 1 .. 4 ] )], 'Tie::LazyFunction::4';
	@_ == 6 and return bless [$_[0],\(@_[ 1 .. 5 ] )], 'Tie::LazyFunction::5';
	@_ == 7 and return bless [$_[0],\(@_[ 1 .. 6 ] )], 'Tie::LazyFunction::6';
	return bless [$_[0],\(@_[ 1 .. $#_ ] )], 'Tie::LazyFunction::n';
}

sub FETCH{
	my $ar = shift;
	# do the coderef in $ar->[0] with no arguments
	&{$ar->[0]};
};

sub Tie::LazyFunction::1::FETCH{
	my $ar = shift;
	# do the coderef in $ar->[0] with arguments from $ar->[1..]
	&{$ar->[0]}(
		 ${ $ar->[1] } 
	);
};

sub Tie::LazyFunction::2::FETCH{
	my $ar = shift;
	&{$ar->[0]}(
		 ${ $ar->[1] } ,
		 ${ $ar->[2] } 
	);
};

sub Tie::LazyFunction::3::FETCH{
	my $ar = shift;
	&{$ar->[0]}(
		 ${ $ar->[1] } ,
		 ${ $ar->[2] } ,
		 ${ $ar->[3] } 
	);
};

sub Tie::LazyFunction::4::FETCH{
	my $ar = shift;
	&{$ar->[0]}(
		 ${ $ar->[1] } ,
		 ${ $ar->[2] } ,
		 ${ $ar->[3] } ,
		 ${ $ar->[4] } 
	);
};

sub Tie::LazyFunction::5::FETCH{
	my $ar = shift;
	&{$ar->[0]}(
		 ${ $ar->[1] } ,
		 ${ $ar->[2] } ,
		 ${ $ar->[3] } ,
		 ${ $ar->[4] } ,
		 ${ $ar->[5] } 
	);
};

sub Tie::LazyFunction::6::FETCH{
	my $ar = shift;
	&{$ar->[0]}(
		 ${ $ar->[1] } ,
		 ${ $ar->[2] } ,
		 ${ $ar->[3] } ,
		 ${ $ar->[4] } ,
		 ${ $ar->[5] } ,
		 ${ $ar->[6] } 
	);
};

sub Tie::LazyFunction::n::FETCH{
	my $ar = shift;
	&{$ar->[0]}(
		 map { ${ $ar->[$_] }} ( 1 .. $#{$ar} )
	);
};


1;
__END__

=head1 NAME

Tie::LazyFunction - sugar to defer evaluation in a tied scalar

=head1 SYNOPSIS

   use Tie::LazyFunction;
   tie my $lazyvar, Tie::LazyFunction => 
      sub {
        something we want to defer
      }, 
      $arg1var, $arg2var, ... $ #variables which will hold arguments to the sub
   ; 

=head1 DESCRIPTION

This short module facilitates binding a coderef to a scalar in such a way
that the coderef will be evaluated when the value of the scalar is taken.

When six or fewer arguments are specified after the coderef at tie time,
the arguments are not evaluated until they are evaluated within the code.
With seven or more arguments, arguments are evaluated at function call
time and passed by value.

All arguments are referred to by reference only until FETCH time.

=head1 EXPORT

nothing

=head1 HISTORY


=head2 0.01

written in response to discusison of simple lazy variables on perl-5 porters mailing list

=head1 FUTURE

It is frustrating that there is no complementary operation to @Refs = \( @Scalars ) aside
from @Derefs = map { $$_ } @Refs which fetches the references instead of simply dereferencing them.

=head1 AUTHOR

Copyright (C) 2005 david nicol davidnico@cpan.org
released under your choice of the GNU Public or Artistic licenses

=head1 SEE ALSO

L<Data::Lazy> provides much more than this does

L<Tie::Function> makes function calls look like hash lookups

=cut
