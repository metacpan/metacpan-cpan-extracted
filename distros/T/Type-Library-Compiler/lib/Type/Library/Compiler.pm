use 5.008001;
use strict;
use warnings;

package Type::Library::Compiler;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.008';

use Type::Library::Compiler::Mite -all;
use B ();

has types => (
	is => ro,
	isa => 'Map[NonEmptyStr,Object]',
	builder => sub { [] },
);

has pod => (
	is => rw,
	isa => 'Bool',
	coerce => true,
	default => true,
);

has destination_module => (
	is => ro,
	isa => 'NonEmptyStr',
	required => true,
);

has constraint_module => (
	is => ro,
	isa => 'NonEmptyStr',
	builder => sub {
		sprintf '%s::TypeConstraint', shift->destination_module;
	},
);

has destination_filename => (
	is => lazy,
	isa => 'NonEmptyStr',
	builder => sub {
		( my $module = shift->destination_module ) =~ s{::}{/}g;
		return sprintf 'lib/%s.pm', $module;
	},
);

sub compile_to_file {
	my $self = shift;

	open( my $fh, '>', $self->destination_filename )
		or croak( 'Could not open %s: %s', $self->destination_filename, $! );

	print { $fh } $self->compile_to_string;

	close( $fh )
		or croak( 'Could not close %s: %s', $self->destination_filename, $! );

	return;
}

sub compile_to_string {
	my $self = shift;

	my @type_names = sort keys %{ $self->types or {} };

	my $code = '';
	$code .= $self->_compile_header;
	$code .= $self->_compile_type( $self->types->{$_}, $_ ) for @type_names;
	$code .= $self->_compile_footer;

	if ( $self->pod ) {
		$code .= $self->_compile_pod_header;
		$code .= $self->_compile_pod_type( $self->types->{$_}, $_ ) for @type_names;
		$code .= $self->_compile_pod_footer;
	}

	return $code;
}

sub _compile_header {
	my $self = shift;

	return sprintf <<'CODE', $self->destination_module, $self->VERSION, $self->constraint_module, $self->destination_module;
use 5.008001;
use strict;
use warnings;

package %s;

use Exporter ();
use Carp qw( croak );

our $TLC_VERSION = "%s";
our @ISA = qw( Exporter );
our @EXPORT;
our @EXPORT_OK;
our %%EXPORT_TAGS = (
	is     => [],
	types  => [],
	assert => [],
);

BEGIN {
	package %s;
	our $LIBRARY = "%s";

	use overload (
		fallback => !!1,
		'|'      => 'union',
		bool     => sub { !! 1 },
		'""'     => sub { shift->{name} },
		'&{}'    => sub {
			my $self = shift;
			return sub { $self->assert_return( @_ ) };
		},
	);

	sub union {
		my @types  = grep ref( $_ ), @_;
		my @checks = map $_->{check}, @types;
		bless {
			check => sub { for ( @checks ) { return 1 if $_->(@_) } return 0 },
			name  => join( '|', map $_->{name}, @types ),
			union => \@types,
		}, __PACKAGE__;
	}

	sub check {
		$_[0]{check}->( $_[1] );
	}

	sub get_message {
		sprintf '%%s did not pass type constraint "%%s"',
			defined( $_[1] ) ? $_[1] : 'Undef',
			$_[0]{name};
	}

	sub validate {
		$_[0]{check}->( $_[1] )
			? undef
			: $_[0]->get_message( $_[1] );
	}

	sub assert_valid {
		$_[0]{check}->( $_[1] )
			? 1
			: Carp::croak( $_[0]->get_message( $_[1] ) );
	}

	sub assert_return {
		$_[0]{check}->( $_[1] )
			? $_[1]
			: Carp::croak( $_[0]->get_message( $_[1] ) );
	}

	sub to_TypeTiny {
		if ( $_[0]{union} ) {
			require Type::Tiny::Union;
			return 'Type::Tiny::Union'->new(
				display_name     => $_[0]{name},
				type_constraints => [ map $_->to_TypeTiny, @{ $_[0]{union} } ],
			);
		}
		if ( my $library = $_[0]{library} ) {
			local $@;
			eval "require $library; 1" or die $@;
			my $type = $library->get_type( $_[0]{library_name} );
			return $type if $type;
		}
		require Type::Tiny;
		my $check = $_[0]{check};
		my $name  = $_[0]{name};
		return 'Type::Tiny'->new(
			name       => $name,
			constraint => sub { $check->( $_ ) },
			inlined    => sub { sprintf '%%s::is_%%s(%%s)', $LIBRARY, $name, pop }
		);
	}

	sub DOES {
		return 1 if $_[1] eq 'Type::API::Constraint';
		return 1 if $_[1] eq 'Type::Library::Compiler::TypeConstraint';
		shift->SUPER::DOES( @_ );
	}
};

CODE
}

sub _compile_footer {
	my $self = shift;

	return <<'CODE';

1;
__END__

CODE
}

sub _compile_type {
	my ( $self, $type, $name ) = ( shift, @_ );

	my @code = ( "# $name", '{' );

	local $Type::Tiny::AvoidCallbacks = 1;
	local $Type::Tiny::SafePackage = '';

	push @code, sprintf <<'CODE', $name, $name, B::perlstring( $name ), B::perlstring( $type->library ), B::perlstring( $type->name ), B::perlstring( $self->constraint_module );
	my $type;
	sub %s () {
		$type ||= bless( { check => \&is_%s, name => %s, library => %s, library_name => %s }, %s );
	}
CODE

	push @code, sprintf <<'CODE', $name, $type->inline_check( '$_[0]' );
	sub is_%s ($) {
		%s
	}
CODE

	push @code, sprintf <<'CODE', $name, $type->inline_check( '$_[0]' ), $name;
	sub assert_%s ($) {
		%s ? $_[0] : %s->get_message( $_[0] );
	}
CODE

	push @code, sprintf <<'CODE', $name, $name, $name, $name, $name, $name, $name, $name;
	$EXPORT_TAGS{"%s"} = [ qw( %s is_%s assert_%s ) ];
	push @EXPORT_OK, @{ $EXPORT_TAGS{"%s"} };
	push @{ $EXPORT_TAGS{"types"} },  "%s";
	push @{ $EXPORT_TAGS{"is"} },     "is_%s";
	push @{ $EXPORT_TAGS{"assert"} }, "assert_%s";
CODE

	push @code, "}", '', '';
	return join "\n", @code;
}

sub _compile_pod_header {
	my $self = shift;

	return sprintf <<'CODE', $self->destination_module;
#=head1 NAME

%s - type constraint library

#=head1 TYPES

This type constraint library is even more basic that L<Type::Tiny>. Exported
types may be combined using C<< Foo | Bar >> but parameterized type constraints
like C<< Foo[Bar] >> are not supported.

CODE
}

sub _compile_pod_type {
	my ( $self, $type, $name ) = ( shift, @_ );

	my $based_on = '';
	if ( $type->library and not $type->is_anon ) {
		$based_on = sprintf "\n\nBased on B<%s> in L<%s>.", $type->name, $type->library;
	}

	return sprintf <<'CODE', $name, $based_on, $name, $name, $name, $self->destination_module, $name;
#=head2 B<%s>%s

The C<< %s >> constant returns a blessed type constraint object.
C<< is_%s($value) >> checks a value against the type and returns a boolean.
C<< assert_%s($value) >> checks a value against the type and throws an error.

To import all of these functions:

  use %s qw( :%s );

CODE
}

sub _compile_pod_footer {
	my $self = shift;

	return <<'CODE';
#=head1 TYPE CONSTRAINT METHODS

For any type constraint B<Foo> the following methods are available:

 Foo->check( $value )         # boolean
 Foo->get_message( $value )   # error message, even if $value is ok 
 Foo->validate( $value )      # error message, or undef if ok
 Foo->assert_valid( $value )  # returns true, dies if error
 Foo->assert_return( $value ) # returns $value, or dies if error
 Foo->to_TypeTiny             # promotes the object to Type::Tiny

Objects overload stringification to return their name and overload
coderefification to call C<assert_return>.

The objects as-is can be used in L<Moo> or L<Mite> C<isa> options.

 has myattr => (
   is => 'rw',
   isa => Foo,
 );

They cannot be used as-is in L<Moose> or L<Mouse>, but can be promoted
to Type::Tiny and will then work:

 has myattr => (
   is => 'rw',
   isa => Foo->to_TypeTiny,
 );

#=cut

CODE
}

around qw( _compile_pod_header _compile_pod_type _compile_pod_footer ) => sub {
	my ( $next, $self ) = ( shift, shift );
	my $pod = $self->$next( @_ );
	$pod =~ s{^#=}{=}gsm;
	return $pod;
};

sub parse_list {
	shift;

	my %all =
		map { ( $_->is_anon ? $_->display_name : $_->name ) => $_ }
		map {
			my ( $library, $type_names ) = split /=/, $_;
			do {
				local $@;
				eval "require $library; 1" or die $@;
			};
			if ( $type_names eq '*' or $type_names eq '-all' ) {
				map $library->get_type( $_ ), $library->type_names;
			}
			else {
				map $library->get_type( $_ ), split /\,/, $type_names;
			}
		}
		map { split /\s+/, $_ } @_;

	return \%all;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::Library::Compiler - compile a bunch of type constraints into a library with no non-core dependencies

=head1 SYNOPSIS

  type-library-compiler --module=MyApp::Types Types::Standard=-all

=head1 DESCRIPTION

This class performs the bulk of the work for F<type-library-compiler>.

=head2 Constructor

=head3 C<< new( %attributes ) >>

=head2 Attributes

=head3 C<types> B<< Map[ NonEmptyStr => Object ] >>

Required hash of L<Type::Tiny> objects. Hash keys are the names the types
will have in the generated library.

=head3 C<pod> B<< Bool >>

Should the generated module include pod? Defaults to true.

=head3 C<destination_module> B<< NonEmptyStr >>

Required Perl module name to produce.

=head3 C<constraint_module> B<< NonEmptyStr >>

Leave this as the default.

=head3 C<destination_filename> B<< NonEmptyStr >>

Leave this as the default.

=head2 Object Methods

=head3 C<< compile_to_file() >>

Writes the module to C<destination_filename>.

=head3 C<< compile_to_string() >>

Returns the module as a string of Perl code.

=head2 Class Methods

=head3 C<< parse_list( @argv ) >>

Parses a list of strings used to specify type constraints on the command line,
and returns a hashref of L<Type::Tiny> objects, suitable for the C<types>
attribute.

=head1 BUGS

Please report any bugs to
<https://github.com/tobyink/p5-type-library-compiler/issues>.

=head1 SEE ALSO

L<Mite>, L<Type::Library>, L<Type::Tiny>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

