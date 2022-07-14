use 5.008001;
use strict;
use warnings;

package builtins::compat;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

sub _true () {
	!!1;
}

sub _false () {
	!!0;
}

BEGIN {
	# uncoverable statement
	*LEGACY_PERL = ( $] lt '5.036' ) ? \&_true : \&_false;
};

our %EXPORT_TAGS = (
	'5.36' => [ qw<
		true     false    is_bool
		weaken   unweaken is_weak
		blessed  refaddr  reftype
		created_as_string created_as_number
		ceil     floor    trim     indexed
	> ],
	'bool' => [ qw< true false is_bool > ],
);

sub parse_args {
	my $class = shift;
	my @args  = @_ ? @_ : ':5.36';

	my $want  = {};
	for my $arg ( @args ) {
		if ( $arg =~ /^:(.+)/ ) {
			my $tag = $1;
			if ( not exists $EXPORT_TAGS{$tag} ) {
				require Carp;
				Carp::carp( qq["$tag" is not defined in $class\::EXPORT_TAGS] );
			}
			$want->{$_} = 1 for @{ $EXPORT_TAGS{$tag} or [] };
		}
		elsif ( $arg =~ /^\!(.+)/ ) {
			my $unwanted = $1;
			delete $want->{$_};
		}
		else {
			$want->{$arg} = 1;
		}
	}

	return $want;
}

sub import {
	goto \&import_compat if LEGACY_PERL;

	my $class = shift;
	my %want  = %{ $class->parse_args( @_ ) };

	# uncoverable statement
	'warnings'->unimport( 'experimental::builtin' );

	# uncoverable statement
	'builtin'->import( keys %want );
}

sub import_compat {
	my $class = shift;

	my $caller = caller;
	my $subs   = $class->get_subs;
	my %want   = %{ $class->parse_args( @_ ) };

	for my $name ( sort keys %want ) {

		if ( my $code = $subs->{$name} ) {
			no strict 'refs';
			*{"$caller\::$name"} = $code;
		}
		else {
			require Carp;
			Carp::carp( qq["$name" is not exported by the $class module] );
			delete $want{$name}; # hide from namespace::clean
		}
	}

	require namespace::clean;
	'namespace::clean'->import(
		-cleanee => $caller,
		keys( %want ),
	);
}

{
	my $subs;
	sub get_subs {
		require Scalar::Util;
		'Scalar::Util'->VERSION( '1.36' );

		$subs ||= {
			true               => \&_true,
			false              => \&_false,
			is_bool            => \&_is_bool,
			weaken             => \&Scalar::Util::weaken,
			unweaken           => \&Scalar::Util::unweaken,
			is_weak            => \&Scalar::Util::isweak,
			blessed            => \&Scalar::Util::blessed,
			refaddr            => \&Scalar::Util::refaddr,
			reftype            => \&Scalar::Util::reftype,
			weaken             => \&Scalar::Util::weaken,
			created_as_string  => \&_created_as_string,
			created_as_number  => \&_created_as_number,
			ceil               => \&_ceil,   # POSIX::ceil has wrong prototype
			floor              => \&_floor,  # POSIX::floor has wrong prototype
			trim               => \&_trim,
			indexed            => \&_indexed,
		};
	}
}

if ( LEGACY_PERL ) {
	my $subs = __PACKAGE__->get_subs;
	while ( my ( $name, $code ) = each %$subs ) {
		no strict 'refs';
		*{"builtin::$name"} = $code
			unless exists &{"builtin::$name"};
	}
}

sub _is_bool ($) {
	my $value = shift;

	return _false unless defined $value;
	return _false if ref $value;
	return _false unless Scalar::Util::isdual( $value );
	return _true if  $value && "$value" eq '1' && $value+0 == 1;
	return _true if !$value && "$value" eq q'' && $value+0 == 0;
	return _false;
}

sub _created_as_number ($) {
	my $value = shift;

	return _false if utf8::is_utf8($value);

	require B;
	my $b_obj = B::svref_2object(\$value);
	my $flags = $b_obj->FLAGS;
	return _true if $flags & ( B::SVp_IOK() | B::SVp_NOK() ) and !( $flags & B::SVp_POK() );
	return _false;
}

sub _created_as_string ($) {
	my $value = shift;

	defined($value)
		&& !ref($value)
		&& !_is_bool($value)
		&& !_created_as_number($value);
}

sub _indexed {
	my $ix = 0;
	return map +( $ix++, $_ ), @_;
}

sub _trim {
	my $value = shift;

	$value =~ s{\A\s+|\s+\z}{}g;
	return $value;
}

sub _ceil ($) {
	require POSIX;
	return POSIX::ceil( $_[0] );
}

sub _floor ($) {
	require POSIX;
	return POSIX::floor( $_[0] );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

builtins::compat - install all the new builtins from the builtin namespace (Perl 5.36+), and try our best on older versions of Perl

=head1 SYNOPSIS

  use 5.008001;          # Or later
  use builtins::compat;  # Loads all new builtins
  
  # So now we can write...
  if ( reftype($x) eq 'ARRAY' || blessed($x) ) {
      print refaddr($x), "\n";
      if ( is_weak($x) ) {
          unweaken($x);
          print ceil( refaddr($x) / floor($y) ), "\n";
          weaken($x);
          print trim($description), "\n";
      }
  }

=head1 DESCRIPTION

This module does the same as L<builtins> on Perl 5.36 and above.
On older versions of Perl, it tries to implement the same functions
and then clean them from your namespace using L<namespace::clean>.

The pre-5.36 versions of C<created_as_number>, C<created_as_string>,
and C<is_bool> may not be 100% perfect implementations.

=head1 IMPORT

To import the functions provided in Perl 5.36:

  use builtins::compat qw( :5.36 );

If future versions of Perl add more functions to L<builtin>, then these
will be provided under different version number tags.

Importing C<< use builtins::compat >> with no arguments will import
the Perl 5.36 builtins, even if you're using a newer version of Perl.

You can import only specific functions by listing their names:

  use builtins::compat qw( refaddr reftype );

You can exclude specific functions by name too. For all the Perl 5.36
functions except C<indexed>:

  use builtins::compat qw( :5.36 !indexed );

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-builtins-compat/issues>.

=head1 SEE ALSO

L<builtins>, L<builtin>, L<Scalar::Util>.

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

