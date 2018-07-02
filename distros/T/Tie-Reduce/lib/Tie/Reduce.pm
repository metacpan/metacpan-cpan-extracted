use 5.006001;
use strict;
use warnings;

package Tie::Reduce;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

## suppresses warnings

sub import {
	my $class  = shift;
	my $caller = caller;
	eval "package $caller; our (\$a, \$b)";
}

## tie interface

sub TIESCALAR {
	my $class = shift;
	$class->new(@_);
}

sub FETCH {
	ref($_[0]) ne __PACKAGE__
		? $_[0]->get_value
		: $_[0][0];  # shortcut if not subclassed
}

sub STORE {
	# if subclassed
	if (ref($_[0]) ne __PACKAGE__) {
		# take non-optimal route
		my $av = $_[0]->can('assign_value');
		goto $av; # preserve caller
	}
	
	my ($self) = shift;
	my ($new_value) = @_;
	my ($old_value, $coderef) = @$self;

	my ($caller_a, $caller_b) = do {
		my $pkg = caller();
		no strict 'refs';
		\*{$pkg . '::a'}, \*{$pkg . '::b'};
	};
	local (*$caller_a, *$caller_b);
	
	*$caller_a = \$old_value;
	*$caller_b = \$new_value;
	
	$self->[0] = $coderef->($old_value, $new_value);
}

## OO interface

sub new {
	my $class = shift;
	my ($coderef, $initial_value) = @_;
	no warnings 'uninitialized';
	if (ref($coderef) ne 'CODE') {
		require Carp;
		Carp::croak("Expected coderef; got $coderef");
	}
	bless [$initial_value, $coderef] => $class;
}

sub get_value {
	$_[0][0];
}

sub set_value {
	$_[0][0] = $_[1];
}

sub assign_value {
	my ($self) = shift;
	my ($new_value) = @_;
	my $old_value = $self->get_value;

	my ($caller_a, $caller_b) = do {
		my $pkg = caller();
		no strict 'refs';
		\*{$pkg . '::a'}, \*{$pkg . '::b'};
	};
	local (*$caller_a, *$caller_b);
	
	*$caller_a = \$old_value;
	*$caller_b = \$new_value;
	
	$self->set_value( $self->get_coderef->($old_value, $new_value) );
}

sub get_coderef {
	$_[0][1];
}

sub _set_coderef {
	$_[0][1] = $_[1];
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Tie::Reduce - a scalar that reduces its old and new values to a single value

=head1 SYNOPSIS

  use Tie::Reduce;
  
  tie my $sum, "Tie::Reduce", sub { $a + $b }, 0;
  
  $sum = 1;
  $sum = 2;
  $sum = 3;
  $sum = 4;
  
  say $sum;  # 10

This is similar in spirit to:

  use List::Util qw(reduce);
  
  my $sum = reduce { $a + $b } 0, 1, 2, 3, 4;
  
  say $sum;  # 10

=head1 DESCRIPTION

Tie::Reduce allows you to create a scalar which when assigned a new value,
passes its old value and assigned value to a coderef, and uses the result as
its new value.

=head2 Tie API

=over

=item C<< tie($scalar, "Tie::Reduce", \&reduction, $initial_value) >>

Ties the scalar using the given coderef for reducing values.

The initial value is optional and will default to undef. This value is
set to the scalar immediately without being passed through the reduction
coderef.

=item C<< $scalar >> (FETCH)

Returns the current value of the scalar.

=item C<< $scalar >> (STORE)

Sets the current value to the result of passing the old value and the
stored value into the coderef.

Within the coderef, the old and new values are available as the special
package variables C<< $a >> and C<< $b >> (like C<reduce> from L<List::Util>
and the Perl built-in C<sort> function).

=back

=head2 Object API

The object API is not generally useful for end users of Tie::Reduce,
with the possible exception of C<set_value>. It is mostly documented for
people wishing to subclass this module.

=over

=item C<< Tie::Reduce->new($coderef, $initial_value) >>

Constructor.

This is called by C<< TIESCALAR >>.

=item C<< tied($scalar)->get_value >>

Returns the current value of the scalar variable.

This is called by C<< FETCH >>.

=item C<< tied($scalar)->set_value($value) >>

Sets the scalar variable I<without> passing it through the coderef.

=item C<< tied($scalar)->assign_value($value) >>

Sets the scalar variable, passing it through the coderef.

Subclassers should be aware that this method uses C<caller> to find the
name of the calling package and access package variables C<< $a >> and
C<< $b >>.

This is called by C<< STORE >>.

=item C<< tied($scalar)->get_coderef >>

Returns the coderef being used to reduce values.

=item C<< tied($scalar)->_set_coderef($coderef) >>

Sets the coderef used to reduce values. This is only documented for people
subclassing Tie::Reduce. Variables tied with Tie::Reduce are confusing enough
without changing the coderef part-way through the variable's lifetime!

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Tie-Reduce>.

=head1 SEE ALSO

L<perlfunc/"tie">, L<perltie>, L<Tie::Scalar>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

