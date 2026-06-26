package Zuzu::Util::NativeHelpers;

use utf8;

our $VERSION = '0.007000';

use Exporter qw( import );
use Scalar::Util qw( blessed );

use Zuzu::Value::Array;
use Zuzu::Value::Boolean;
use Zuzu::Value::Class;
use Zuzu::Value::Dict;
use Zuzu::Value::Function;
use Zuzu::Value::Object;
use Zuzu::Value::PairList;
use Zuzu::Value::Set;
use Zuzu::Value::Bag;

our @EXPORT_OK = qw(
	native_class
	native_function
	native_functions
	native_object
	zuzu_to_perl
	perl_to_zuzu
	zuzu_bool
);

sub native_class {
	my ( %args ) = @_;

	return Zuzu::Value::Class->new(
		name => $args{name},
		parent => $args{parent},
		traits => $args{traits} // [],
		field_specs => $args{field_specs} // [],
		methods => $args{methods} // {},
		trait_methods => $args{trait_methods} // {},
		static_methods => $args{static_methods} // {},
		nested_classes => $args{nested_classes} // {},
		closure_env => $args{closure_env},
		builtin_kind => $args{builtin_kind},
	);
}

sub native_function {
	my ( %args ) = @_;

	my $fn = Zuzu::Value::Function->new(
		name => $args{name},
		params => $args{params} // [],
		vararg => exists $args{vararg} ? $args{vararg} : '__args',
		body => undef,
		closure_env => $args{closure_env},
	);
	$fn->{_native} = $args{native};
	$fn->{_native_accepts_named} = $args{accepts_named} ? 1 : 0;

	return $fn;
}

sub native_functions {
	my ( %args ) = @_;

	my $names = $args{names} // [];
	my $builder = $args{builder};
	my %out;
	for my $name ( @{ $names } ) {
		$out{$name} = native_function(
			name => $name,
			closure_env => $args{closure_env},
			native => $builder->( $name ),
		);
	}

	return \%out;
}

sub native_object {
	my ( %args ) = @_;

	my $slots = $args{slots} // {};
	my $const = $args{const} // {};
	my $types = $args{types} // {};
	for my $key ( CORE::keys %{ $slots } ) {
		$const->{$key} = 0 if not exists $const->{$key};
		$types->{$key} = 'Any' if not exists $types->{$key};
	}

	return Zuzu::Value::Object->new(
		class => $args{class},
		slots => $slots,
		const => $const,
		types => $types,
	);
}

sub zuzu_to_perl {
	my ( $value, %args ) = @_;

	my $bool_mapper = $args{boolean_mapper};
	my $unwrap = exists $args{unwrap_object_value}
		? $args{unwrap_object_value}
		: 1;

	return undef if not defined $value;
	if ( blessed($value) and $value->isa('Zuzu::Value::Boolean') ) {
		return $bool_mapper->( $value->value ? 1 : 0 )
			if defined $bool_mapper;
		return $value->value ? 1 : 0;
	}
	if ( blessed($value) and $value->isa('Zuzu::Value::Array') ) {
		return [ map { zuzu_to_perl( $_, %args ) } @{ $value->items } ];
	}
	if (
		blessed($value)
		and (
			$value->isa('Zuzu::Value::Set')
			or $value->isa('Zuzu::Value::Bag')
		)
	) {
		my @sorted = CORE::sort {
			( defined $a ? "$a" : '' ) cmp ( defined $b ? "$b" : '' )
		} @{ $value->items };
		return [ map { zuzu_to_perl( $_, %args ) } @sorted ];
	}
	if ( blessed($value) and $value->isa('Zuzu::Value::PairList') ) {
		require Tie::Hash::MultiValueOrdered;
		tie my %out, 'Tie::Hash::MultiValueOrdered';
		for my $pair ( @{ $value->list } ) {
			my $key = defined $pair->[0] ? "$pair->[0]" : '';
			$out{$key} = zuzu_to_perl( $pair->[1], %args );
		}
		tied(%out)->fetch_first;
		return \%out;
	}
	if ( blessed($value) and $value->isa('Zuzu::Value::Dict') ) {
		my %out;
		for my $key ( CORE::keys %{ $value->map } ) {
			$out{$key} = zuzu_to_perl( $value->map->{$key}, %args );
		}
		return \%out;
	}
	if (
		$unwrap
		and blessed($value)
		and $value->isa('Zuzu::Value::Object')
		and exists $value->slots->{__value}
	) {
		return zuzu_to_perl( $value->slots->{__value}, %args );
	}

	return $value;
}

sub perl_to_zuzu {
	my ( $value, %args ) = @_;

	my $is_bool = $args{is_boolean};

	return undef if not defined $value;
	if ( ref($value) eq 'ARRAY' ) {
		return Zuzu::Value::Array->new(
			items => [ map { perl_to_zuzu( $_, %args ) } @{ $value } ],
		);
	}
	if ( ref($value) eq 'HASH' ) {
		my $tied = tied(%$value);
		if ( $tied and $tied->DOES('Tie::Hash::MultiValueOrdered') ) {
			my @pairs;
			my @list = $tied->pairs;
			for ( my $i = 0; $i < @list; $i += 2 ) {
				push @pairs, [
					$list[$i],
					perl_to_zuzu( $list[$i + 1], %args ),
				];
			}
			return Zuzu::Value::PairList->new( list => \@pairs );
		}
		else {
			my %out;
			for my $key ( CORE::keys %{ $value } ) {
				$out{$key} = perl_to_zuzu( $value->{$key}, %args );
			}
			return Zuzu::Value::Dict->new( map => \%out );
		}
	}
	if ( defined $is_bool and $is_bool->($value) ) {
		return Zuzu::Value::Boolean->new( value => $value ? 1 : 0 );
	}

	return $value;
}

sub zuzu_bool {
	my ( $value, $default ) = @_;

	return $default if not defined $value;
	if ( blessed($value) and $value->isa('Zuzu::Value::Boolean') ) {
		return $value->value ? 1 : 0;
	}

	return $value ? 1 : 0;
}

1;

=pod

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Util::NativeHelpers >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
