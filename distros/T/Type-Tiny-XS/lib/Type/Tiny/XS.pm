use 5.008005;
use strict;
use warnings;
use XSLoader ();

package Type::Tiny::XS;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.025';

__PACKAGE__->XSLoader::load( $VERSION );

use Scalar::Util qw(refaddr);

my %names = (
	map +( $_ => __PACKAGE__ . "::$_" ), qw/
		Any ArrayRef Bool ClassName CodeRef Defined
		FileHandle GlobRef HashRef Int Num Object
		Ref RegexpRef ScalarRef Str Undef Value
		PositiveInt PositiveOrZeroInt NonEmptyStr
		ArrayLike HashLike CodeLike StringLike
		Map Tuple Enum AnyOf AllOf
		/
);
$names{Item} = $names{Any};

if ( $] lt '5.010000' ) {
	require MRO::Compat;
	*Type::Tiny::XS::Util::get_linear_isa = \&mro::get_linear_isa;
	
	my $overloaded = sub {
		require overload;
		overload::Overloaded( ref $_[0] or $_[0] )
			and overload::Method( ( ref $_[0] or $_[0] ), $_[1] );
	};
	
	no warnings qw( uninitialized redefine once );
	*StringLike = sub {
		defined( $_[0] ) && !ref( $_[0] )
			or Scalar::Util::blessed( $_[0] ) && $overloaded->( $_[0], q[""] );
	};
	*CodeLike = sub {
		ref( $_[0] ) eq 'CODE'
			or Scalar::Util::blessed( $_[0] ) && $overloaded->( $_[0], q[&{}] );
	};
	*HashLike = sub {
		ref( $_[0] ) eq 'HASH'
			or Scalar::Util::blessed( $_[0] ) && $overloaded->( $_[0], q[%{}] );
	};
	*ArrayLike = sub {
		ref( $_[0] ) eq 'ARRAY'
			or Scalar::Util::blessed( $_[0] ) && $overloaded->( $_[0], q[@{}] );
	};
} #/ if ( $] < '5.010000' [)

my %coderefs;

sub _know {
	my ( $coderef, $type ) = @_;
	$coderefs{ refaddr( $coderef ) } = $type;
}

sub is_known {
	my $coderef = shift;
	$coderefs{ refaddr( $coderef ) };
}

for ( reverse sort keys %names ) {
	no strict qw(refs);
	_know \&{ $names{$_} }, $_;
}

my $id = 0;

sub get_coderef_for {
	my $type = $_[0];
	
	return do {
		no strict qw(refs);
		\&{ $names{$type} };
	} if exists $names{$type};
	
	my $made;
	
	if ( $type =~ /^ArrayRef\[(.+)\]$/ ) {
		my $child = get_coderef_for( $1 ) or return;
		$made = _parameterize_ArrayRef_for( $child );
	}
	
	elsif ( $] ge '5.010000' and $type =~ /^ArrayLike\[(.+)\]$/ ) {
		my $child = get_coderef_for( $1 ) or return;
		$made = _parameterize_ArrayLike_for( $child );
	}
	
	elsif ( $type =~ /^HashRef\[(.+)\]$/ ) {
		my $child = get_coderef_for( $1 ) or return;
		$made = _parameterize_HashRef_for( $child );
	}
	
	elsif ( $] ge '5.010000' and $type =~ /^HashLike\[(.+)\]$/ ) {
		my $child = get_coderef_for( $1 ) or return;
		$made = _parameterize_HashLike_for( $child );
	}
	
	elsif ( $type =~ /^Map\[(.+),(.+)\]$/ ) {
		my @children;
		if ( eval { require Type::Parser } ) {
			@children = map scalar( get_coderef_for( $_ ) ), _parse_parameters( $type );
		}
		else {
			push @children, get_coderef_for( $1 );
			push @children, get_coderef_for( $2 );
		}
		@children == 2 or return;
		defined        or return for @children;
		$made = _parameterize_Map_for( \@children );
	} #/ elsif ( $type =~ /^Map\[(.+),(.+)\]$/)
	
	elsif ( $type =~ /^(AnyOf|AllOf|Tuple)\[(.+)\]$/ ) {
		my $base = $1;
		my @children =
			map scalar( get_coderef_for( $_ ) ),
			( eval { require Type::Parser } )
			? _parse_parameters( $type )
			: split( /,/, $2 );
		defined or return for @children;
		my $maker = __PACKAGE__->can( "_parameterize_${base}_for" );
		$made = $maker->( \@children ) if $maker;
	} #/ elsif ( $type =~ /^(AnyOf|AllOf|Tuple)\[(.+)\]$/)
	
	elsif ( $type =~ /^Maybe\[(.+)\]$/ ) {
		my $child = get_coderef_for( $1 ) or return;
		$made = _parameterize_Maybe_for( $child );
	}
	
	elsif ( $type =~ /^InstanceOf\[(.+)\]$/ ) {
		my $class = $1;
		return unless Type::Tiny::XS::Util::is_valid_class_name( $class );
		$made = Type::Tiny::XS::Util::generate_isa_predicate_for( $class );
	}
	
	elsif ( $type =~ /^HasMethods\[(.+)\]$/ ) {
		my $methods = [ sort( split /,/, $1 ) ];
		/^[^\W0-9]\w*$/ or return for @$methods;
		$made = Type::Tiny::XS::Util::generate_can_predicate_for( $methods );
	}
	
	# Type::Tiny::Enum > 1.010003 double-quotes its enums
	elsif ( $type =~ /^Enum\[".*"\]$/ ) {
		if ( eval { require Type::Parser } ) {
			my $parsed = Type::Parser::parse( $type );
			if ( $parsed->{type} eq "parameterized" ) {
				my @todo = $parsed->{params};
				my @strings;
				my $bad;
				while ( my $todo = shift @todo ) {
					if ( $todo->{type} eq 'list' ) {
						push @todo, @{ $todo->{list} };
					}
					elsif ( $todo->{type} eq "expression"
						&& $todo->{op}->type eq Type::Parser::COMMA() )
					{
						push @todo, $todo->{lhs}, $todo->{rhs};
					}
					elsif ( $todo->{type} eq "primary" && $todo->{token}->type eq "QUOTELIKE" ) {
						push @strings, eval( $todo->{token}->spelling );
					}
					else {
						# Unexpected entry in the parse-tree, bail out
						$bad = 1;
					}
				} #/ while ( my $todo = shift ...)
				$made = _parameterize_Enum_for( \@strings ) unless $bad;
			} #/ if ( $parsed->{type} eq...)
		} #/ if ( eval { require Type::Parser...})
	} #/ elsif ( $type =~ /^Enum\[".*"\]$/)
	
	elsif ( $type =~ /^Enum\[(.+)\]$/ ) {
		my $strings = [ sort( split /,/, $1 ) ];
		$made = _parameterize_Enum_for( $strings );
	}
	
	if ( $made ) {
		no strict qw(refs);
		my $slot = sprintf( '%s::AUTO::TC%d', __PACKAGE__, ++$id );
		$names{$type} = $slot;
		_know( $made, $type );
		*$slot = $made;
		return $made;
	}
	
	return;
} #/ sub get_coderef_for

sub get_subname_for {
	my $type = $_[0];
	get_coderef_for( $type ) unless exists $names{$type};
	$names{$type};
}

sub _parse_parameters {
	my $got = Type::Parser::parse( @_ );
	$got->{params} or return;
	_handle_expr( $got->{params} );
}

sub _handle_expr {
	my $e = shift;
	
	if ( $e->{type} eq 'list' ) {
		return map _handle_expr( $_ ), @{ $e->{list} };
	}
	if ( $e->{type} eq 'parameterized' ) {
		my ( $base ) = _handle_expr( $e->{base} );
		my @params = _handle_expr( $e->{params} );
		return sprintf( '%s[%s]', $base, join( q[,], @params ) );
	}
	if ( $e->{type} eq 'expression' and $e->{op}->type eq Type::Parser::COMMA() ) {
		return _handle_expr( $e->{lhs} ), _handle_expr( $e->{rhs} );
	}
	if ( $e->{type} eq 'primary' ) {
		return $e->{token}->spelling;
	}
	
	'****';
} #/ sub _handle_expr

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::Tiny::XS - provides an XS boost for some of Type::Tiny's built-in type constraints

=head1 SYNOPSIS

   use Types::Standard qw(Int);

=head1 DESCRIPTION

This module is optionally used by L<Type::Tiny> 0.045_03 and above
to provide faster, C-based implementations of some type constraints.
(This package has only core dependencies, and does not depend on
Type::Tiny, so other data validation frameworks might also consider
using it!)

Only the following three functions should be considered part of the
supported API:

=over

=item C<< Type::Tiny::XS::get_coderef_for($type) >>

Given a supported type constraint name, such as C<< "Int" >>, returns
a coderef that can be used to validate a parameter against this
constraint.

Returns undef if this module cannot provide a suitable coderef.

=item C<< Type::Tiny::XS::get_subname_for($type) >>

Like C<get_coderef_for> but returns the name of such a sub as a string.

Returns undef if this module cannot provide a suitable sub name.

=item C<< Type::Tiny::XS::is_known($coderef) >>

Returns true if the coderef was provided by Type::Tiny::XS.

=back

In addition to the above functions, the subs returned by
C<get_coderef_for> and C<get_subname_for> are considered part of the
"supported API", but only for the lifetime of the Perl process that
returned them.

To clarify, if you call C<< get_subname_for("ArrayRef[Int]") >> in a
script, this will return the name of a sub. That sub (which can be used
to validate arrayrefs of integers) is now considered part of the
supported API of Type::Tiny::XS until the script finishes running. Next
time the script runs, there is no guarantee that the sub will continue
to exist, or continue to do the same thing.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny-XS>.

=head1 SEE ALSO

L<Type::Tiny>, L<Types::Standard>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt> forked all this from
L<Mouse::Util::TypeConstraints>.

B<ArrayLike>, B<HashLike>, B<CodeLike>, and B<StringLike> constraints
based on code by ikegami on StackOverflow.

L<https://stackoverflow.com/a/64019481/1990570>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2018-2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
