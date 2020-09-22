use 5.008008;
use strict;
use warnings;

package Z;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.005';

use Import::Into ();
use Module::Runtime qw( use_module );
use Zydeco::Lite qw( true false );

BEGIN {
	*PERL_IS_MODERN = ( $] ge '5.014' ) ? \&true : \&false;
}

sub import {
	my ($target, $class ) = ( scalar caller, shift );
	
	my $mode = '-modern';
	( $_[0] || '' ) =~ /^-/ and $mode = shift;
	
	my $collection = 'modules';
	
	if ( PERL_IS_MODERN ) {
		$collection = 'compat_modules' if $mode eq '-compat';
	}
	else {
		$collection = 'compat_modules';
		
		if ( $mode eq '-modern' ) {
			require Carp;
			return Carp::croak( "$target requires Perl v5.14 or above; stopping" );
		}
		elsif ( $mode eq '-detect' ) {
			require Carp;
			Carp::carp( "$target may require Perl v5.14 or above; attempting compatibility mode" );
		}
	}
	
	for my $modules ( $class->$collection ) {
		my ( $name, $version, @args ) = @$modules;
		use_module( $name, $version )->import::into( $target, @args );
	}
	
	eval {
		require indirect;
		'indirect'->unimport::out_of( $target );
	};
	
	$class->also( $target, @_ );
	
	use_module( 'namespace::autoclean' )->import::into( $target );
	
	return $class;
}

sub modules {
	my $class = shift;
	
	return (
		[ 'Syntax::Keyword::Try',     '0.018',     qw( try                ) ],
		[ 'Zydeco::Lite',             '0.070',     qw( -all               ) ],
		[ 'Types::Standard',          '1.010000',  qw( -types -is -assert ) ],
		[ 'Types::Common::Numeric',   '1.010000',  qw( -types -is -assert ) ],
		[ 'Types::Common::String',    '1.010000',  qw( -types -is -assert ) ],
		[ 'Types::Path::Tiny',        '0',         qw( -types -is -assert ) ],
		[ 'Object::Adhoc',            '0.003',     qw( object             ) ],
		[ 'Path::Tiny',               '0.101',     qw( path               ) ],
		[ 'match::simple',            '0.010',     qw( match              ) ],
		[ 'strict',                   '0',         qw( refs subs vars     ) ],
		[ 'warnings',                 '0',         qw( all                ) ],
		[ 'feature',                  '0',         qw( say state          ) ],
	);
}

sub compat_modules {
	my $class = shift;
	
	my @modules =
		grep { my $name = $_->[0]; $name !~ /feature|Try/ }
		$class->modules;

	push @modules, [ 'Try::Tiny', '0.30' ];

	if ( $] ge '5.010' ) {
		push @modules, [ 'feature', '0', qw( say ) ];
	}
	else {
		push @modules, [ 'Perl6::Say',      '0.06'  ];
		push @modules, [ 'UNIVERSAL::DOES', '0.001' ];
	}
	
	return @modules;
}

my %also = (
	Dumper => sub {
		require Data::Dumper;
		return sub {
			local $Data::Dumper::Deparse;
			Data::Dumper::Dumper(@_);
		},
	},
	croak => sub {
		return sub {
			require Carp;
			Carp::croak( @_ > 1 ? sprintf(shift, @_) : @_ );
		};
	},
	carp => sub {
		return sub {
			require Carp;
			Carp::carp( @_ > 1 ? sprintf(shift, @_) : @_ );
		};
	},
	cluck => sub {
		return sub {
			require Carp;
			Carp::cluck( @_ > 1 ? sprintf(shift, @_) : @_ );
		};
	},
	maybe => sub {
		if ( eval 'use PerlX::Maybe::XS 0.003 (); 1' ) {
			return \&PerlX::Maybe::XS::maybe;
		}
		return sub ($$@) {
			( defined $_[0] and defined $_[1] )
				? @_
				: ( ( @_ > 1 ) ? @_[2 .. $#_] : qw() )
		};
	},
	provided => sub {
		if ( eval 'use PerlX::Maybe::XS 0.003 (); 1' ) {
			return \&PerlX::Maybe::XS::provided;
		}
		return sub ($$$@) {
			( shift )
				? @_
				: ( ( @_ > 1 ) ? @_[2 .. $#_] : qw() )
		};
	},
	encode_json => sub {
		if ( eval 'use JSON::MaybeXS 1.003000 (); 1' ) {
			return \&JSON::MaybeXS::encode_json;
		}
		require JSON::PP;
		return \&JSON::PP::encode_json;
	},
	decode_json => sub {
		if ( eval 'use JSON::MaybeXS 1.003000 (); 1' ) {
			return \&JSON::MaybeXS::decode_json;
		}
		require JSON::PP;
		return \&JSON::PP::decode_json;
	},
	all            => q(List::Util),
	any            => q(List::Util),
	first          => q(List::Util),
	head           => q(List::Util),
	max            => q(List::Util),
	maxstr         => q(List::Util),
	min            => q(List::Util),
	minstr         => q(List::Util),
	none           => q(List::Util),
	notall         => q(List::Util),
	pairfirst      => q(List::Util),
	pairgrep       => q(List::Util),
	pairkeys       => q(List::Util),
	pairmap        => q(List::Util),
	pairs          => q(List::Util),
	pairvalues     => q(List::Util),
	product        => q(List::Util),
	reduce         => q(List::Util),
	reductions     => q(List::Util),
	sample         => q(List::Util),
	shuffle        => q(List::Util),
	sum            => q(List::Util),
	sum0           => q(List::Util),
	tail           => q(List::Util),
	uniq           => q(List::Util),
	uniqnum        => q(List::Util),
	uniqstr        => q(List::Util),
	unpairs        => q(List::Util),
	blessed        => q(Scalar::Util),
	dualvar        => q(Scalar::Util),
	isdual         => q(Scalar::Util),
	isvstring      => q(Scalar::Util),
	isweak         => q(Scalar::Util),
	looks_like_number => q(Scalar::Util),
	openhandle     => q(Scalar::Util),
	readonly       => q(Scalar::Util),
	refaddr        => q(Scalar::Util),
	reftype        => q(Scalar::Util),
	set_prototype  => q(Scalar::Util),
	tainted        => q(Scalar::Util),
	unweaken       => q(Scalar::Util),
	weaken         => q(Scalar::Util),
	prototype      => q(Sub::Util),
	set_prototype  => q(Sub::Util),
	set_subname    => q(Sub::Util),
	subname        => q(Sub::Util),
);

sub also {
	my ( $class, $target ) = ( shift, shift );
	
	my %imports;
	for my $arg ( @_ ) {
		my ( $func, $dest ) = split /:/, $arg;
		$dest = $func unless $dest;
		
		my $source = $also{$func} or do {
			require Carp;
			Carp::croak( "Do not know where to find function $func" );
			next;
		};
		
		push @{ $imports{ ref($source) or $source } ||= [] },
			ref($source) ? [ $dest, $source ] : [ $dest, $func ];
	}
	
	for my $source ( sort keys %imports ) {
		if ( $source eq 'CODE' ) {
			for my $func ( @{$imports{$source}} ) {
				my ( $name, $gen ) = @$func;
				no strict 'refs';
				*{"$target\::$name"} = $gen->();
			}
		}
		else {
			use_module( $source );
			for my $func ( @{$imports{$source}} ) {
				my ( $name, $orig ) = @$func;
				no strict 'refs';
				*{"$target\::$name"} = \&{"$source\::$orig"};
			}
		}
	}
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Z - collection of modules for rapid app development

=head1 SYNOPSIS

This:

 use Z;

Is a shortcut for:

 use strict;
 use warnings;
 use feature 'say', 'state';
 use namespace::autoclean;
 use Syntax::Keyword::Try 'try';
 use Zydeco::Lite -all;
 use Path::Tiny 'path';
 use Object::Adhoc 'object';
 use match::simple 'match';
 use Types::Standard -types, -is, -assert;
 use Types::Common::String -types, -is, -assert;
 use Types::Common::Numeric -types, -is, -assert;
 use Types::Path::Tiny -types, -is, -assert;

It will also do C<< no indirect >> if L<indirect> is installed.

=head1 DESCRIPTION

Just a shortcut for loading a bunch of modules that allow you to
quickly code Perl stuff. I've tried to avoid too many domain-specific
modules like HTTP::Tiny, etc. The modules chosen should be broadly
useful for a wide variety of tasks.

=head2 Perl Version Compatibility

By default, Z requires Perl v5.14, but it has a compatibility mode where
for Perl v5.8.8 and above.

It will use L<Try::Tiny> instead of L<Syntax::Keyword::Try>. (Bear in mind
that these are not 100% compatible with each other.) It will also load
L<Perl6::Say> as a fallback for the C<say> built-in. And it will not provide
C<state>. It will also load L<UNIVERSAL::DOES> if there's no built-in
UNIVERSAL::DOES method.

You can specify whether you want the modern modules or the compatibility
modules:

 use Z -modern;
 # Uses modern modules.
 # Requres Perl 5.14+.
 
 use Z -compat;
 # Uses compatible modules.
 # Requires Perl 5.8.8+.
 
 use Z -detect;
 # Uses modern modules on Perl 5.14+.
 # Prints a warning and uses compatible modules on Perl 5.8.8+.

The default is C<< -modern >>.

=head2 Additional Functions

There are a whole bunch of other useful functions that Z I<could> make
available, but it's hard to know the best place to draw the line. So
other functions are available on request:

 use Z qw( weaken unweaken isweak );
 
 use Z -compat, qw( pairmap pairgrep );
 
 # Rename functions...
 use Z qw( pairmap:pmap pairgrep:pgrep );

(The things listed in the L</SYNOPSIS> are always imported and don't
support the renaming feature.)

The additional functions available are: everything from L<Scalar::Util>,
everything from L<List::Util>, everything from L<Sub::Util>, everything
from L<Carp> (wrapped versions with C<sprintf> functionality, except
C<confess> which is part of the standard set of functions already),
C<Dumper> from L<Data::Dumper>, C<maybe> and C<provided> from
L<PerlX::Maybe>, and C<encode_json> and C<decode_json> from
L<JSON::MaybeXS> or L<JSON::PP> (depending which is installed).

If you specify a compatibility mode (like C<< -modern >>), this must be
first in the import list.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Z>.

=head1 SEE ALSO

L<Zydeco::Lite>,
L<Types::Standard>,
L<Syntax::Feature::Try>,
L<Path::Tiny>,
L<match::simple>,
L<Object::Adhoc>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

