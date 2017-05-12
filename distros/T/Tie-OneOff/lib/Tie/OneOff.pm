package Tie::OneOff;
our $VERSION = 1.03;

=head1 NAME

Tie::OneOff - create tied variables without defining a separate package 

=head1 SYNOPSIS

    require Tie::OneOff;
    
    tie my %REV, 'Tie::OneOff' => sub {
	reverse shift;
    };

    print "$REV{olleH}\n"; # Hello

    sub make_counter {
	my $step = shift;
	my $i = 0;
        Tie::OneOff->scalar({
	    BASE => \$i, # Implies: STORE => sub { $i = shift }
	    FETCH => sub { $i += $step },
        });
    }

    my $c1 = make_counter(1);
    my $c2 = make_counter(2);
    $$c2 = 10;
    print "$$c1 $$c2 $$c2 $$c2 $$c1 $$c1\n"; # 1 12 14 16 2 3

    sub foo : lvalue {
	+Tie::OneOff->lvalue({
	    STORE => sub { print "foo()=$_[0]\n" },
	    FETCH => sub { "wibble" },
	});
    }

    foo='wobble';              # foo()=wobble
    print "foo()=", foo, "\n"; # foo()=wibble

=head1 DESCRIPTION

The Perl tie mechanism ties a Perl variable to a Perl object.  This
means that, conventionally, for each distinct set of tied variable
semantics one needs to create a new package.  The package symbol table
then acts as a dispatch table for the intrinsic actions (such as
C<FETCH>, C<STORE>, C<FETCHSIZE>) that can be performed on Perl
variables.

Sometimes it would seem more natural to associate a dispatch table
hash directly with the variable and pretend as if the intermediate
object did not exist.  This is what C<Tie::OneOff> does.

It is important to note that in this model there is no object to hold
the instance data for the tied variable.  The callbacks in the
dispatch table are called not as object methods but as simple
subroutines.  If there is to be any instance information for a
variable tied using C<Tie::OneOff> it must be in lexical variables
that are referenced by the callback closures.

C<Tie::OneOff> does not itself provide any default callbacks.  This
can make defining a full featured hash interface rather tedious.  To
simplify matters the element C<BASE> in the dispatch table can be used
to specify a "base object" whose methods provide the default
callbacks.  If a reference to an unblessed Perl variable is specified
as the C<BASE> then the variable is blessed into the appropriate
C<Tie::StdXXXX> package.  In this case the unblessed variable used as
the base must, of course, be of the same type as the variable that is
being tied.

In C<make_counter()> in the synopsis above, the variable C<$i> gets blessed
into C<Tie::StdScalar>. Since there is no explict STORE in the dispatch
table, an attempt to store into a counter is implemented by calling
C<(\$i)-E<gt>STORE(@_)> which in turn is resolved as
C<Tie::StdScalar::STORE(\$i,@_)> which in turn is equivalent to C<$i=shift>.

Since many tied variables need only a C<FETCH> method C<Tie::OneOff>
ties can also be specified by giving a simple code reference that is
taken to be the variable's C<FETCH> callback.

For convience the class methods C<scalar>, C<hash> and C<array> take
the same arguments as the tie inferface and return a reference to an
anonymous tied variable.  The class method C<lvalue> is like C<scalar>
but returns an lvalue rather than a reference.

=head1 Relationship to other modules

This module's original working title was Tie::Simple however it was
eventually released as Tie::OneOff.  Some time later another,
substancially identical, module was developed independantly and
released as L<Tie::Simple>.

This module can be used as a trick to make functions that interpolate
into strings but if that's all you want you may want to use
L<Interpolation> instead.

XXX Want XXX

=head1 SEE ALSO

L<perltie>, L<Tie::Scalar>, L<Tie::Hash>, L<Tie::Array>, L<Interpolation>, L<Tie::Simple>.

=cut

use strict;
use warnings;
use base 'Exporter';

my %not_pass_to_base = 
    (
     DESTROY => 1,
     UNTIE => 1,
     );

sub AUTOLOAD {
    my $self = shift;
    my ($func) = our $AUTOLOAD =~ /(\w+)$/ or die;
    # All class methods are the contstuctor
    unless ( ref $self ) {
	unless ($func =~ /^TIE/) {
	    require Carp;
	    Carp::croak("Non-TIE class method $func called for $self");
	}
	$self = bless ref $_[0] eq 'CODE' ? { FETCH => $_[0] } :
	    ref $_[0] ? shift : { @_ }, $self;
	if ( my $base = $self->{BASE} ) {
	    require Scalar::Util;
	    unless ( Scalar::Util::blessed($base)) {
		my $type = ref $base;
		unless ( "TIE$type" eq $func ) {
		    require Carp;
		    $type ||= 'non-reference';
		    Carp::croak("BASE cannot be $type in " . __PACKAGE__ . "::$func");
		}
		require "Tie/\u\L$type.pm";
		bless $base, "Tie::Std\u\L$type";
	    }
	} 
	return $self;
    }
    my $code = $self->{$func} or do {
	return if $not_pass_to_base{$func};
	my $base = $self->{BASE};
	return $base->$func(@_) if $base;
	require Carp;
	Carp::croak("No $func handler defined in " . __PACKAGE__ . " object");
    }; 
    goto &$code;
}

sub scalar {
    my $class = shift;
    tie my ($v), $class, @_;
    \$v;
}

sub lvalue : lvalue {
    my $class = shift;
    tie my($v), $class, @_;
    $v;
}

sub hash {
    my $class = shift;
    tie my(%v), $class, @_;
    \%v;
}

sub array {
    my $class = shift;
    tie my(@v), $class, @_;
    \@v;
}

1;
