package UNIVERSAL::DOES;

use 5.005_03;

$VERSION = '0.005';

use Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(does);

use strict;

*UNIVERSAL::DOES = \&DOES
	unless defined &UNIVERSAL::DOES;

# Take compatibility rather than performance.
sub DOES :method {
	my($invocant, $role) = @_;

	if(@_ != 2){
		require Carp;
		Carp::croak('Usage: invocant->DOES(kind)');
	}

	my $e = do{
		local $@;
		eval{ $invocant->isa($role) } and return 1;
		$@;
	};

	if($e){
		$e =~ s/\b isa \b/DOES/xmsg;
		die $e;
	}

	return 0;
}

my %operator_of = (
	SCALAR => '${}',
	ARRAY  => '@{}',
	HASH   => '%{}',
	CODE   => '&{}',
	GLOB   => '*{}',
);

sub does {
	my($thing, $role) = @_;

	if(@_ != 2){
		require Carp;
		Carp::croak('Usage: does(thing, role)');
	}

	return 0 unless $thing && $role;

	my $e = do{
		local $@;
		eval{ $thing->DOES($role) } and return 1;
		$@;
	};

	if($e){ # $thing is not an invocant
		return ref($thing) eq $role; # ARRAY, HASH, etc.
	}
	elsif(ref($thing)){ # $thins is an object
		my $operator = $operator_of{$role} or return 0;

		return $thing->can('()')             # overloaded?
			&& $thing->can('(' . $operator); # with the dereferencing operator?
	}

	return 0;
}

1;
__END__

=for stopwords perls dereferenced

=head1 NAME

UNIVERSAL::DOES - Provides UNIVERSAL::DOES() method for older perls

=head1 VERSION

This document describes UNIVERSAL::DOES version 0.005.

=for test_synopsis my($class, $object, $role, $thing);

=head1 SYNOPSIS

	# if you require UNIVERSAL::DOES, you can say the following:
	require UNIVERSAL::DOES
		 unless defined &UNIVERSAL::DOES;

	# you can call DOES() in any perls
	$class->DOES($role);
	$object->DOES($role);

	# also, this provides a does() function
	use UNIVERSAL::DOES qw(does);

	# use does($thing, $role), instead of UNIVERSAL::isa($thing, $role)
	does($thing, $role);   # $thing can be non-invocant
	does($thing, 'ARRAY'); # also ok, $think may have overloaded @{}

=head1 DESCRIPTION

C<UNIVERSAL::DOES> provides a C<UNIVERSAL::DOES()> method for
compatibility with perl 5.10.x.

This module also provides a C<does()> function that checks something
does some roles, suggested in L<perltodo>.

=head1 FUNCTIONS

=over 4

=item C<< does($thing, $role) >>

C<does> checks if I<$thing> performs the role I<$role>. If the thing
is an object or class, it simply checks C<< $thing->DOES($role) >>. Otherwise
it tells whether the thing can be dereferenced as an array/hash/etc.

Unlike C<UNIVERSAL::isa()>, it is semantically correct to use C<does> for
something unknown and to use it for C<reftype>.

This function handles overloading. For example, C<< does($thing, 'ARRAY') >>
returns true if the thing is an array reference, or if the thing is an object
with overloaded C<@{}>.

This is not exported by default.

=back

=head1 METHODS

The following description is just copied from L<UNIVERSAL> in perl 5.10.1.

=over 4

=item C<< $obj->DOES( $ROLE ) >>

=item C<< CLASS->DOES( $ROLE ) >>

C<DOES> checks if the object or class performs the role C<ROLE>.  A role is a
named group of specific behavior (often methods of particular names and
signatures), similar to a class, but not necessarily a complete class by
itself.  For example, logging or serialization may be roles.

C<DOES> and C<isa> are similar, in that if either is true, you know that the
object or class on which you call the method can perform specific behavior.
However, C<DOES> is different from C<isa> in that it does not care I<how> the
invocant performs the operations, merely that it does.  (C<isa> of course
mandates an inheritance relationship.  Other relationships include aggregation,
delegation, and mocking.)

By default, classes in Perl only perform the C<UNIVERSAL> role, as well as the
role of all classes in their inheritance.  In other words, by default C<DOES>
responds identically to C<isa>.

There is a relationship between roles and classes, as each class implies the
existence of a role of the same name.  There is also a relationship between
inheritance and roles, in that a subclass that inherits from an ancestor class
implicitly performs any roles its parent performs.  Thus you can use C<DOES> in
place of C<isa> safely, as it will return true in all places where C<isa> will
return true (provided that any overridden C<DOES> I<and> C<isa> methods behave
appropriately).

=back

=head1 NOTES

=over 4

=item L<perl5100delta/"UNIVERSAL::DOES()"> says:

The C<UNIVERSAL> class has a new method, C<DOES()>. It has been added to
solve semantic problems with the C<isa()> method. C<isa()> checks for
inheritance, while C<DOES()> has been designed to be overridden when
module authors use other types of relations between classes (in addition
to inheritance).

=item L<perltodo/"A does() built-in"> says:

Like ref(), only useful. It would call the C<DOES> method on objects; it
would also tell whether something can be dereferenced as an
array/hash/etc., or used as a regexp, etc.
L<http://www.xray.mpe.mpg.de/mailing-lists/perl5-porters/2007-03/msg00481.html>

=back

=head1 DEPENDENCIES

Perl 5.5.3 or later.

=head1 BUGS

No bugs have been reported.

Please report any bugs or feature requests to the author.

=head1 AUTHOR

Goro Fuji (gfx) E<lt>gfuji(at)cpan.orgE<gt>

=head1 SEE ALSO

L<UNIVERSAL>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Goro Fuji (gfx). Some rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
