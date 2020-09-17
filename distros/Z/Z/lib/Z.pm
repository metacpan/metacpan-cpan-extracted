use 5.008008;
use strict;
use warnings;

package Z;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Import::Into ();
use Module::Runtime qw( use_module );
use Zydeco::Lite qw( true false );

BEGIN {
	*PERL_IS_MODERN = ( $] ge '5.014' ) ? \&true : \&false;
}

sub import {
	my ($target, $class, $mode) = ( scalar caller, shift, @_ );
	$mode = '-modern' unless defined $mode;
	
	my $collection = 'modules';
	
	if ( PERL_IS_MODERN ) {
		$collection = 'compat_modules' if $mode eq '-compat';
	}
	else {
		$collection = 'compat_modules';
		
		if ( $mode eq '-modern' ) {
			require Carp;
			return Carp::croak("$target requires Perl v5.14 or above; stopping");
		}
		elsif ( $mode eq '-detect' ) {
			require Carp;
			Carp::carp("$target may require Perl v5.14 or above; attempting compatibility mode");
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
	
	use_module( 'namespace::autoclean' )->import::into( $target );
	
	return $class;
}

sub modules {
	my $class = shift;
	
	return (
		[ 'Syntax::Keyword::Try',     '0.018',     qw( try                ) ],
		[ 'Zydeco::Lite',             '0.068',     qw( -all               ) ],
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
modules like HTTP::Tiny, JSON, etc. The modules chosen should be
broadly useful for a wide variety of tasks.

=head2 Perl Version Compatibility

Z has a compatibility mode where it will use L<Try::Tiny> instead of
L<Syntax::Keyword::Try>. Bear in mind that these are not 100% compatible
with each other.

It will also load L<Perl6::Say> as a fallback for the C<say> built-in.
And will not provide C<state>.

It will also load L<UNIVERSAL::DOES> if there's no built-in
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

