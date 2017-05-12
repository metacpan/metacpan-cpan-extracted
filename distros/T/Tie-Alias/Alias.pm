package Tie::Alias;

use 5.008;

use Carp ();
our $VERSION = '1.01';


sub TIESCALAR {

	my ( $class , $ref ) = @_ ;
	ref($ref) or $ref = \$_[1];
	if ( tied($$ref) ) {
		# we are re-tieing something
		return tied ($$ref);
	}else{
		# $ref is already a pointer to the object
		bless $ref, $class;
	};
};

sub STORE {
	${$_[0]} = $_[1];
};


sub FETCH {
	${$_[0]};
};

sub TIEARRAY {
	goto &Tie::Alias::Array::TIEARRAY;
};

sub TIEHASH {
	goto &Tie::Alias::Hash::TIEHASH;
};


sub import {
	@_ == 1 and return;
	shift;
	goto &alias;
};
sub alias(@) {
	@_ % 2 and Carp::croak "Uneven alias => original pairings in use Tie::Alias";

	while(@_){
		my $r = ref($_[0]);
	   	if (!$r){
			tie $_[0], __PACKAGE__, \$_[1];
		}elsif( $r eq 'ARRAY' ){
			tie @{$_[0]}, __PACKAGE__, $_[1];

		}elsif( $r eq 'HASH' ){
			tie %{$_[0]}, __PACKAGE__, $_[1];
		}else{
			# Carp::carp "Object references already have aliasing semantics";
			tie $_[0], __PACKAGE__, \$_[1];
			

		};


		shift; shift;
	};

};



package Tie::Alias::Array;


sub TIEARRAY {

        my ( $class , $ref ) = @_ ;
	my $rval = eval {
          if ( tied(@$ref)  ) {
                # we are re-aliasing something
                return tied ($$ref);
          }else{
                # $ref is already a pointer to the object
                return bless $ref, __PACKAGE__;
          };
	};
        $@ and Carp::croak "$ref IS NOT AN ARRAY REFERENCE";
	return $rval;
};

sub FETCH{
	$_[0]->[$_[1]];
};
sub STORE{
	$_[0]->[$_[1]] = $_[2];
};
sub FETCHSIZE{
	scalar @{$_[0]};
};
sub STORESIZE{
	$#{$_[0]} = $_[1] -1 ;
};
sub POP{
	pop @{$_[0]};
};
sub CLEAR{
	@{$_[0]} = ();
};
sub PUSH{
	my $r = shift;
	push @{$r}, @_;
};
sub SHIFT{
	shift @{$_[0]};
};
sub UNSHIFT{
	my $r = shift;
	unshift @{$r}, @_;
};
sub SPLICE{
	my $r = shift;
	my $o = shift || 0;
	my $l = shift || scalar(@{$r}) - $o;
	splice @{$r}, $o, $l, @_;
};
sub DELETE{
	delete $_[0]->[$_[1]];
};
sub EXISTS{
	exists $_[0]->[$_[1]];
};

package Tie::Alias::Hash;


sub TIEHASH {
        my ( $class , $ref ) = @_ ;
	my $rval = eval {
          if ( tied(%$ref)  ) {
                # we are re-aliasing something
                return tied (%$ref);
          }else{
                # $ref is already a pointer to the object
                return bless $ref, __PACKAGE__;
          };
	};
        $@ and Carp::croak "$ref IS NOT A HASH REFERENCE";
	return $rval;
};


sub FETCH{
	$_[0]->{$_[1]};
};
sub STORE{
	$_[0]->{$_[1]} = $_[2];
};
sub EXISTS{
	exists $_[0]->{$_[1]};
};
sub DELETE{
	delete $_[0]->{$_[1]};
};
sub CLEAR{
	%{$_[0]} = ();
};
sub FIRSTKEY{
	keys %{$_[0]};
	each %{$_[0]};
};
sub NEXTKEY{
	each %{$_[0]};
};

1;
__END__

=head1 NAME

Tie::Alias - create aliases in pure perl

=head1 SYNOPSIS

  use Tie::Alias;
  my $scalar = 'sad puppy';
  tie my $alias, Tie::Alias => \$scalar;  # just like local *alias = \$scalar
  $alias = 'happy puppy';
  print $scalar,"\n";	# prints happy puppy

Alternately, and more simply

  Tie::Alias::alias( $alias => $scalar );

or even

  use Tie::Alias $alias => $scalar;

although that will work only at BEGIN time.  C<Tie::Alias::alias> can
take any number of alias => original pairs, and does NOT take the backslash.

This module can be used to effect adding a reference onto @_ before
a C<goto &EXPR>, in case you ever need to do that

 tie $_[@_], 'Tie::Alias' => $X; goto &NeedsPBR;


=head1 ABSTRACT

create aliases to lexicals, container members, what-have-you,
through a tie interface. Aliases to variables that are already tied
are done by returning the existing tie object.  Aliases to object
references, which are silly, are done by taking a reference to the
object reference and using that as the base object of the Tie::Alias
object.

=head1 DESCRIPTION

the Tie::Alias TIESCALAR function takes one argument, which is a reference
to the scalar which is to be aliased. Since version 1.0, the argument no
longer needs to be a reference. In case the scalar is already tied,
the alias gets tied to whatever the scalar is already tied to also.

Tie::Alias works for scalars, arrays, and hashes.

  tie @alias, 'Tie::Alias' => \@array;
  tie %alias, 'Tie::Alias' => \%hash;

=head2 EXPORT

None, although Tie::Alias::alias is now available.  Import it if you
wish like so:

   use Tie::Alias;
   BEGIN { *alias = \&Tie::Alias::alias }

Or just use it in place:

  use Tie::Alias;
  Tie::Alias::alias \@alias => \@array, \%alias => \%hash, $alias => $scalar;

=head1 CHANGES

version 1.0 June 3 2007:  Documenting the fallthroughs to hashes and
arrays, which have been in place since 2002 but weren't described as
actually working in the docs.  Also adding use time invocation, although
that will only work at C<BEGIN> time, and combining the array and hash
packages into this one file, and scrapping the placeholder support
for aliasing handles.


=head1 SEE ALSO

L<perltie>, L<Lexical::Alias>, L<Data::Alias>, L<Variable::Alias>, L<Macrame>


=head1 COPYRIGHT AND LICENSE

Copyright 2002, 2007 by david nicol davidnico@cpan.org

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

