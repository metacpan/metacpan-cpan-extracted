use 5.008001;
use strict;
use warnings;

use Exporter::Tiny ();
use Scalar::Util ();

package Type::Nano;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.012';
our @ISA       = qw( Exporter::Tiny );
our @EXPORT_OK = qw(
	Any Defined Undef Ref ArrayRef HashRef CodeRef Object Str Bool Num Int Object
	class_type role_type duck_type union intersection enum type
);

# Built-in type constraints
#

our %TYPES;

sub Any () {
	$TYPES{Any} ||= __PACKAGE__->new(
		name         => 'Any',
		constraint   => sub { !!1 },
	);
}

sub Defined () {
	$TYPES{Defined} ||= __PACKAGE__->new(
		name         => 'Defined',
		parent       => Any,
		constraint   => sub { defined $_ },
	);
}

sub Undef () {
	$TYPES{Undef} ||= __PACKAGE__->new(
		name         => 'Undef',
		parent       => Any,
		constraint   => sub { !defined $_ },
	);
}

sub Ref () {
	$TYPES{Ref} ||= __PACKAGE__->new(
		name         => 'Ref',
		parent       => Defined,
		constraint   => sub { ref $_ },
	);
}

sub ArrayRef () {
	$TYPES{ArrayRef} ||= __PACKAGE__->new(
		name         => 'ArrayRef',
		parent       => Ref,
		constraint   => sub { ref $_ eq 'ARRAY' },
	);
}

sub HashRef () {
	$TYPES{HashRef} ||= __PACKAGE__->new(
		name         => 'HashRef',
		parent       => Ref,
		constraint   => sub { ref $_ eq 'HASH' },
	);
}

sub CodeRef () {
	$TYPES{CodeRef} ||= __PACKAGE__->new(
		name         => 'CodeRef',
		parent       => Ref,
		constraint   => sub { ref $_ eq 'CODE' },
	);
}

sub Object () {
	$TYPES{Object} ||= __PACKAGE__->new(
		name         => 'Object',
		parent       => Ref,
		constraint   => sub { Scalar::Util::blessed($_) },
	);
}

sub Bool () {
	$TYPES{Bool} ||= __PACKAGE__->new(
		name         => 'Bool',
		parent       => Any,
		constraint   => sub { !defined($_) or (!ref($_) and { 1 => 1, 0 => 1, '' => 1 }->{$_}) },
	);
}

sub Str () {
	$TYPES{Str} ||= __PACKAGE__->new(
		name         => 'Str',
		parent       => Defined,
		constraint   => sub { !ref $_ },
	);
}

sub Num () {
	$TYPES{Num} ||= __PACKAGE__->new(
		name         => 'Num',
		parent       => Str,
		constraint   => sub { Scalar::Util::looks_like_number($_) },
	);
}

sub Int () {
	$TYPES{Int} ||= __PACKAGE__->new(
		name         => 'Int',
		parent       => Num,
		constraint   => sub { /\A-?[0-9]+\z/ },
	);
}

sub class_type ($) {
	my $class = shift;
	$TYPES{CLASS}{$class} ||= __PACKAGE__->new(
		name         => $class,
		parent       => Object,
		constraint   => sub { $_->isa($class) },
		class        => $class,
	);
}

sub role_type ($) {
	my $role = shift;
	$TYPES{ROLE}{$role} ||= __PACKAGE__->new(
		name         => $role,
		parent       => Object,
		constraint   => sub { my $meth = $_->can('DOES') || $_->can('isa'); $_->$meth($role) },
		role         => $role,
	);
}

sub duck_type {
	my $name    = ref($_[0]) ? '__ANON__' : shift;
	my @methods = sort( ref($_[0]) ? @{+shift} : @_ );
	my $methods = join "|", @methods;
	$TYPES{DUCK}{$methods} ||= __PACKAGE__->new(
		name         => $name,
		parent       => Object,
		constraint   => sub { my $obj = $_; $obj->can($_)||return !!0 for @methods; !!1 },
		methods      => \@methods,
	);
}

sub enum {
	my $name   = ref($_[0]) ? '__ANON__' : shift;
	my @values = sort( ref($_[0]) ? @{+shift} : @_ );
	my $values = join "|", map quotemeta, @values;
	my $regexp = qr/\A(?:$values)\z/;
	$TYPES{ENUM}{$values} ||= __PACKAGE__->new(
		name         => $name,
		parent       => Str,
		constraint   => sub { $_ =~ $regexp },
		values       => \@values,
	);
}

sub union {
	my $name  = ref($_[0]) ? '__ANON__' : shift;
	my @types = ref($_[0]) ? @{+shift} : @_;
	__PACKAGE__->new(
		name         => $name,
		constraint   => sub { my $val = $_; $_->check($val) && return !!1 for @types; !!0 },
		types        => \@types,
	);
}

sub intersection {
	my $name  = ref($_[0]) ? '__ANON__' : shift;
	my @types = ref($_[0]) ? @{+shift} : @_;
	__PACKAGE__->new(
		name         => $name,
		constraint   => sub { my $val = $_; $_->check($val) || return !!0 for @types; !!1 },
		types        => \@types,
	);
}

sub type {
	my $name    = ref($_[0]) ? '__ANON__' : shift;
	my $coderef = shift;
	__PACKAGE__->new(
		name         => $name,
		constraint   => $coderef,
	);
}

# OO interface
#

sub DOES {
	my $proto = shift;
	my ($role) = @_;
	return !!1 if {
		'Type::API::Constraint'              => 1,
		'Type::API::Constraint::Constructor' => 1,
	}->{$role};
	"UNIVERSAL"->can("DOES") ? $proto->SUPER::DOES(@_) : $proto->isa(@_);
}

sub new { # Type::API::Constraint::Constructor
	my $class = ref($_[0]) ? ref(shift) : shift;
	my $self  = bless { @_ == 1 ? %{+shift} : @_ } => $class;
	
	$self->{constraint} ||= sub { !!1 };
	unless ($self->{name}) {
		require Carp;
		Carp::croak("Requires both `name` and `constraint`");
	}
	
	$self;
}

sub check { # Type::API::Constraint
	my $self = shift;
	my ($value) = @_;
	
	if ($self->{parent}) {
		return unless $self->{parent}->check($value);
	}
	
	local $_ = $value;
	$self->{constraint}->($value);
}

sub get_message { # Type::API::Constraint
	my $self = shift;
	my ($value) = @_;
	
	require B;
	!defined($value)
		? sprintf("Undef did not pass type constraint %s", $self->{name})
		: ref($value)
			? sprintf("Reference %s did not pass type constraint %s", $value, $self->{name})
			: sprintf("Value %s did not pass type constraint %s", B::perlstring($value), $self->{name});
}

# Overloading
#

no strict 'refs'; # avoid loading overload.pm
*{__PACKAGE__ . '::(('} = sub {};
*{__PACKAGE__ . '::()'} = sub {};
*{__PACKAGE__ . '::()'} = do { my $x = 1; \$x };
*{__PACKAGE__ . '::(bool'} = sub { 1 };
*{__PACKAGE__ . '::(""'} = sub { shift->{name} };
*{__PACKAGE__ . '::(&{}'} = sub {
	my $self = shift;
	sub {
		my ($value) = @_;
		$self->check($value) or do {
			require Carp;
			Carp::croak($self->get_message($value));
		};
	};
};

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::Nano - simple type constraint library for testing

=head1 SYNOPSIS

  use Type::Nano qw(Int);
  
  Int->check("42");  # true

=head1 DESCRIPTION

This is a really basic implementation of L<Type::API::Constraint> for
testing modules that make use of type constraints, such as L<Type::Tie>.

It optionally exports the following type constraints:

=over

=item *

Any

=item *

Defined

=item *

Undef

=item *

Ref

=item *

ArrayRef

=item *

HashRef

=item *

CodeRef

=item *

Object

=item *

Str

=item *

Bool

=item *

Num

=item *

Int

=back

It also optionally exports the following functions for creating new type
constraints:

=over

=item *

C<< type $name, $coderef >> or C<< type $coderef >>

=item *

C<< class_type $class >>

=item *

C<< role_type $role >>

=item *

C<< duck_type $name, \@methods >> or C<< duck_type \@methods >>

=item *

C<< enum $name, \@values >> or C<< enum \@values >>

=item *

C<< union $name, \@types >> or C<< union \@types >>

=item *

C<< intersection $name, \@types >> or C<< intersection \@types >>

=back

Types support the following methods:

=over

=item C<< $type->check($value) >>

Checks the value against the constraint; returns a boolean.

=item C<< $type->get_message($failing_value) >>

Returns an error message. Does not check the value.

=back

Types overload C<< &{} >> to do something like:

  $type->check($value) or croak($type->get_message($value))

I'll stress that this module is I<only> intended for use in testing.
It eliminates Type::Tie's testing dependency on L<Types::Standard>.

L<Type::Tiny> while bigger than Type::Nano, will be I<much> faster at
runtime, and offers better integration with Moo, Moose, Mouse, and a
wide variety of other tools. Use that instead.

All that having been said, L<Type::Nano> is compatible with:
L<Type::Tie>, L<Moo>, L<Type::Tiny> (e.g. you can use Type::Tiny's
implementation of C<ArrayRef> and Type::Nano's implementation of
C<Int>, and combine them as C<< ArrayRef[Int] >>), L<Class::XSConstructor>,
and L<Variable::Declaration>.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tie>.

=head1 SUPPORT

B<< IRC: >> support is available through in the I<< #moops >> channel
on L<irc.perl.org|http://www.irc.perl.org/channels.html>.

=head1 SEE ALSO

L<Type::API>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018-2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

