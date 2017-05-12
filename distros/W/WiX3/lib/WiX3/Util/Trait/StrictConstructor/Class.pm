package                                # Hide from PAUSE.
  WiX3::Util::Trait::StrictConstructor::Class;

# Corresponds to MooseX::StrictConstructor::Trait::Class
# 0.010004 = MX::SC 0.16

use 5.008003;
use strict;
use warnings;
use Moose::Role 2;
use namespace::autoclean;
use WiX3::Exceptions;
use B qw();

our $VERSION = '0.011';

around new_object => sub {
	my $orig     = shift;
	my $self     = shift;
	my $params   = @_ == 1 ? $_[0] : {@_};
	my $instance = $self->$orig(@_);

	my %attrs = (
		__INSTANCE__ => 1,
		(   map { $_ => 1 }
			grep {defined}
			map  { $_->init_arg() } $self->get_all_attributes() ) );

	my @bad = sort grep { !$attrs{$_} } keys %{$params};

	if (@bad) {
		WiX3::Exception::Parameter->throw(
"Found unknown attribute(s) init_arg passed to the constructor: @bad"
		);
	}

	return $instance;
};

around '_inline_BUILDALL' => sub {
	my $orig = shift;
	my $self = shift;

	my @source = $self->$orig();

	my @attrs = (
		'__INSTANCE__ => 1,',
		map    { B::perlstring($_) . ' => 1,' }
		  grep {defined}
		  map  { $_->init_arg() } $self->get_all_attributes() );

	##no critic(RequireInterpolationOfMetachars)
	return (
		@source,
		'my %attrs = (' . ( join q{ }, @attrs ) . ');',
		'my @bad = sort grep { !$attrs{$_} } keys %{ $params };',
		'if (@bad) {',
		'WiX3::Exception::Parameter->throw(',
		'"Found unknown attribute(s) passed to the constructor: @bad");',
		'}',
	);
};

1;
