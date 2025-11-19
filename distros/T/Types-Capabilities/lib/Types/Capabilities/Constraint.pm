use 5.010001;
use strict;
use warnings;

package Types::Capabilities::Constraint;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002001';

use parent 'Type::Tiny::Duck';
use Carp ();
use Module::Runtime ();

my $bc = sub {
	my $c = shift;
	my $t = $c->type_constraint;
	my @c = $t->{autobox}->_coercions;
	while ( @c ) {
		my $from_type = shift @c;
		my $code      = shift @c;
		unless ( $from_type->isa('Type::Tiny::Duck') and join(':', sort @{ $from_type->methods }) eq join(':', sort @{ $t->methods }) ) {
			$c->add_type_coercions( $from_type, $code );
		}
	}
	return $c;
};

sub new {
	my $proto = shift;

	if ( ref $proto ) {
		return $proto->{autobox}->new( @_ );
	}
	else {
		my %opts = ( @_ == 1 ) ? %{ $_[0] } : @_;
		defined( $opts{autobox} )
			? Module::Runtime::use_package_optimistically( $opts{autobox} )
			: Carp::croak("Expected paramater: autobox");
		return $proto->SUPER::new( _build_coercion => $bc, %opts );
	}
}

sub new_intersection {
	my $proto  = shift;
	my %opts   = ( @_ == 1 ) ? %{ $_[0] } : @_;

	my @types  = @{ delete $opts{type_constraints} };
	my $new_autobox = $proto->_resolve_autobox_class( @types );
	
	if ( $new_autobox ) {
		my %methods; ++$methods{$_} for map @{$_->methods}, @types;
		return $proto->new(
			%opts,
			methods       => [sort keys %methods],
			autobox       => $types[0]{autobox},
			display_name  => join( '&', map $_->display_name, @types ),
		);
	}
	
	require Type::Tiny::Intersection;
	return Type::Tiny::Intersection->new( type_constraints => \@types );
}

sub _resolve_autobox_class {
	my ( undef, @types ) = @_;

	my %autobox;
	++$autobox{ $_ or 'NONE' } for map $_->{autobox}, @types;

	if ( 1 == keys %autobox ) {
		my ( $got ) = keys %autobox;
		return $got;
	}

	if ( 2 == keys %autobox
	and $autobox{'Types::Capabilities::CoercedValue::ARRAYREF'}
	and $autobox{'Types::Capabilities::CoercedValue::QUEUE'} ) {
		return 'Types::Capabilities::CoercedValue::QUEUE';
	}

	if ( 2 == keys %autobox
	and $autobox{'Types::Capabilities::CoercedValue::ARRAYREF'}
	and $autobox{'Types::Capabilities::CoercedValue::STACK'} ) {
		return 'Types::Capabilities::CoercedValue::STACK';
	}

	return;
}

1;

__END__
