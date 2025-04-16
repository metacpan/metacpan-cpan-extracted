use 5.036;
use strict;
use warnings;

package Types::JSONSchema;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001000';

use constant { true => !!1, false => !!0 };

use Type::Library
	-extends => [ 'Types::JSONSchema::PrimativeTypes' ],
	-declare => qw/
		JSRef
		JSScope
		
		JAllOf
		JAnyOf
		JOneOf
		JNot
		JIf
		JThen
		JElse
		JDependentSchema
		
		JEnum
		JConst
		
		JMultipleOf
		JMaximum
		JExclusiveMaximum
		JMinimum
		JExclusiveMinimum
		
		JMaxLength
		JMinLength
		JPattern
		
		JMaxItems
		JMinItems
		JUniqueItems
		JItems
		
		JMaxProperties
		JMinProperties
		JRequired
		JDependentRequired
		JProperties
		JPropertyNames
		
		FmtDateTime
		FmtDate
		FmtTime
		FmtDuration
		FmtEmail
		FmtIdnEmail
		FmtHostname
		FmtIdnHostname
		FmtIpv4
		FmtIpv6
		FmtUri
		FmtUriReference
		FmtIri
		FmtIriReference
		FmtUuid
		FmtUriTemplate
		FmtJsonPointer
		FmtRelativeJsonPointer
		FmtRegex
	/;
use Types::Common -all;
use Types::Standard::ArrayRef Strings => { of => Str };
use Type::Utils;

use List::Util qw( all any );
use Regexp::Common qw( URI net time Email::Address );
use Regexp::Util qw( :all );
use Scalar::Util ();
use URI::Escape qw( uri_escape );

sub _croak {
	my $str = shift;
	if ( @_ ) {
		$str = sprintf( $str, @_ );
	}
	require Carp;
	@_ = ( $str );
	goto \&Carp::croak;
}

sub _carp {
	my $str = shift;
	if ( @_ ) {
		$str = sprintf( $str, @_ );
	}
	require Carp;
	@_ = ( $str );
	goto \&Carp::carp;
}

push our @EXPORT_OK, qw(
	json_eq
	json_safe_dumper
	jpointer_escape
	schema_to_type
	true
	false
);

signature_for json_eq => (
	method  => false,
	pos     => [ Any, Any ],
);

sub json_eq ( $x, $y ) {
	
	if ( is_JNull $x and is_JNull $y ) {
		return true;
	}

	if ( is_JTrue $x and is_JTrue $y ) {
		return true;
	}

	if ( is_JFalse $x and is_JFalse $y ) {
		return true;
	}

	if ( is_JNumber $x and is_JNumber $y ) {
		return ( $x == $y );
	}

	if ( is_JString $x and is_JString $y ) {
		return ( $x eq $y );
	}

	if ( is_JArray $x and is_JArray $y ) {
		return false unless $x->@* == $y->@*;
		for my $ix ( 0 .. $#$x ) {
			return false unless __SUB__->( $x->[$ix], $y->[$ix] );
		}
		return true;
	}

	if ( is_JObject $x and is_JObject $y ) {
		return false unless keys($x->%*) == keys($y->%*);
		for my $k ( keys $x->%* ) {
			return false unless exists $y->{$k};
			return false unless __SUB__->( $x->{$k}, $y->{$k} );
		}
		return true;
	}

	return false;
}

sub _params_to_string ( $sep, @args ) {
	my @parts = map {
		!defined() ? 'undef' :
		is_JTrue($_) ? '!!1' :
		is_JFalse($_) ? '!!0' :
		is_JInteger($_) ? int($_) :
		is_JNumber($_) ? $_ :
		is_JString($_) ? B::perlstring($_) :
		is_ArrayRef($_) ? sprintf( '[%s]', _params_to_string( q{,}, $_->@* ) ) :
		is_HashRef($_) ? sprintf( '{%s}', _params_to_string( [ q{,}, q{=>} ], do { my $h = $_; map {; $_ => $h->{$_} } sort keys $h->%* } ) ) :
		"$_"
	} @args or return '';
	if ( is_ArrayRef $sep ) {
		my $joined = $parts[0];
		for my $ix ( 1 .. $#parts ) {
			$joined .= $sep->[ $ix % $sep->@* ] . $parts[$ix];
		}
		return $joined;
	}
	else {
		return join( $sep, @parts );
	}
}

sub params_to_string {
	unshift @_, q{,};
	goto \&_params_to_string;
}

sub json_safe_dumper {
	unshift @_, q{, };
	goto \&_params_to_string;
}

sub jpointer_escape ( $raw ) {
	my $str = uri_escape( $raw );
	$str =~ s/~/~0/g;
	$str =~ s/%7E/~0/g;
	$str =~ s/%2F/~1/g;
	return $str;
}

my $name_generator = sub {
	my ( $base, @params ) = @_;
	sprintf( '%s[%s]', $base, params_to_string(@params) );
};

our %JSREF;
declare JSRef,
	name_generator => sub {
		my ( $base, @params ) = @_;
		sprintf( '%s[%s]', $base, B::perlstring($params[0]) );
	},
	constraint_generator => sub {
		my ( $path, $defs ) = @_;
		return sub {
			my $value = pop;
			my $type = $defs->{$path} or die;
			$type->check( $value );
		};
	},
	inline_generator => sub {
		my ( $path, $defs ) = @_;
		return sub {
			my $self = shift;
			my $uniq = $self->{uniq};
			my $varname = pop;
			$JSREF{$uniq} ||= sub {
				my $type = $defs->{$path} or _croak(
					q{Schema referred to by %s not found. We know: %s},
					B::perlstring($path),
					Type::Utils::english_list( map B::perlstring($_), sort keys $defs->%* ) || 'nothing',
				);
				$type->check( @_ ? $_[0] : $_ );
			};
			return sprintf( '$%s::JSREF{%s}->( %s )', __PACKAGE__, B::perlstring($uniq), $varname );
		};
	};

our ( $EVALUATED_PROPERTIES, $EVALUATED_ITEMS );
declare JSScope,
	name_generator => $name_generator,
	constraint_generator => sub {
		@_ == 1 or die;
		my $inner = shift;
		return sub {
			local $EVALUATED_PROPERTIES = {};
			local $EVALUATED_ITEMS      = {};
			$inner->check( @_ );
		};
	},
	inline_generator => sub {
		@_ == 1 or die;
		my $inner = shift;
		return unless $inner->can_be_inlined;
		return sub {
			my $varname = pop;
			sprintf(
				'do { local $%s::EVALUATED_PROPERTIES = {}; local $%s::EVALUATED_ITEMS = {}; %s }',
				__PACKAGE__,
				__PACKAGE__,
				$inner->inline_check( $varname ),
			);
		};
	};

declare JAllOf,
	name_generator => $name_generator,
	constraint_generator => sub {
		my @constraints = @_;
		_smiple(\@constraints);
		return sub {
			my $value = pop;
			all { $_->check($value) } @constraints;
		};
	},
	inline_generator => sub {
		my @constraints = @_;
		_smiple(\@constraints);
		$_->can_be_inlined || return for @constraints;
		return sub {
			my $varname = pop;
			if ( @constraints == 1 ) {
				return $constraints[0]->inline_check($varname);
			}
			if ( $varname =~ /\A\$\w+\z/ ) {
				return sprintf(
					'( %s )',
					join( ' and ', map { $_->inline_check( '$varname' ) } @constraints ),
				);
			}
			sprintf(
				'do { local $_ = %s; %s }',
				$varname,
				join( ' and ', map { $_->inline_check( '$_' ) } @constraints ),
			);
		};
	},
	deep_explanation => sub {
		my ( $self, $value, $varname ) = @_;
		return if $self->check( $value );
		my @constraints = $self->parameters->@*;
		return [
			sprintf(
				'"%s" requires that the value pass %s',
				$self,
				Type::Utils::english_list( \"and", map qq["$_"], @constraints ),
			),
			map {
				$_->get_message( $value ),
				map( "    $_", @{ $_->validate_explain( $value ) || [] } ),
			}
			grep {
				not $_->check( $value );
			} @constraints,
		];
	};

declare JAnyOf,
	name_generator => $name_generator,
	constraint_generator => sub {
		my @constraints = @_;
		return sub {
			my $value = pop;
			any { $_->check($value) } @constraints;
		};
	},
	inline_generator => sub {
		my @constraints = @_;
		$_->can_be_inlined || return for @constraints;
		return sub {
			my $varname = pop;
			if ( @constraints == 1 ) {
				return $constraints[0]->inline_check($varname);
			}
			if ( $varname =~ /\A\$\w+\z/ ) {
				return sprintf(
					'( %s )',
					join( ' or ', map { $_->inline_check( '$varname' ) } @constraints ),
				);
			}
			sprintf(
				'do { local $_ = %s; %s }',
				$varname,
				join( ' or ', map { $_->inline_check( '$_' ) } @constraints ),
			);
		};
	},
	deep_explanation => sub {
		my ( $self, $value, $varname ) = @_;
		return if $self->check( $value );
		my @constraints = $self->parameters->@*;
		return [
			sprintf(
				'"%s" requires that the value pass %s',
				$self,
				Type::Utils::english_list( \"or", map qq["$_"], @constraints ),
			),
			map {
				$_->get_message( $value ),
				map( "    $_", @{ $_->validate_explain( $value ) || [] } ),
			} @constraints,
		];
	};

declare JOneOf,
	name_generator => $name_generator,
	constraint_generator => sub {
		my @constraints = @_;
		return sub {
			my $value = pop;
			1 == grep { $_->check($value) } @constraints;
		};
	},
	inline_generator => sub {
		my @constraints = @_;
		$_->can_be_inlined || return for @constraints;
		return sub {
			my $varname = pop;
			if ( $varname =~ /\A\$\w+\z/ ) {
				return sprintf(
					'do { my $passes = 0; %s; $passes == 1 }',
					join( '; ', map { '++$passes if ' . $_->inline_check( $varname ) } @constraints ),
				);
			}
			sprintf(
				'do { local $_ = %s; my $passes = 0; %s; $passes == 1 }',
				$varname,
				join( '; ', map { '++$passes if ' . $_->inline_check( '$_' ) } @constraints ),
			);
		};
	},
	deep_explanation => sub {
		my ( $self, $value, $varname ) = @_;
		my @constraints = $self->parameters->@*;
		my $count = grep { $_->check($value) } @constraints;
		return [
			sprintf(
				'"%s" requires that the value pass exactly 1 of %s',
				$self,
				Type::Utils::english_list( \"or", map qq["$_"], @constraints ),
			),
			(
				map {
					$_->get_message( $value ),
					map( "    $_", @{ $_->validate_explain( $value ) || [] } ),
				} @constraints,
			),
			sprintf( "The value passed %d", $count ),
		];
	};

declare JNot,
	name_generator => $name_generator,
	constraint_generator => sub {
		my ( $constraint ) = @_;
		return sub {
			my $value = pop;
			not $constraint->check($value);
		};
	},
	inline_generator => sub {
		my ( $constraint ) = @_;
		$constraint->can_be_inlined || return;
		return sub {
			my $varname = pop;
			sprintf( 'not( %s )', $constraint->inline_check($varname) );
		};
	},
	deep_explanation => sub {
		my ( $self, $value, $varname ) = @_;
		my $constraint = $self->type_parameter;
		return [
			sprintf(
				'"%s" requires that the value fail "%s" but it does not',
				$self,
				$constraint,
			),
		];
	};

declare JIf,
	name_generator => $name_generator,
	constraint_generator => sub {
		my ( $if, $then, $else ) = @_;
		$then ||= Any;
		$else ||= Any;
		return sub {
			my $value = pop;
			$if->check( $value ) ? $then->check($value) : $else->check($value);
		};
	},
	inline_generator => sub {
		my ( $if, $then, $else ) = @_;
		$then ||= Any;
		$else ||= Any;
		$_->can_be_inlined || return for $if, $then, $else;
		return sub {
			my $varname = pop;
			if ( $varname =~ /\A\$\w+\z/ ) {
				return sprintf(
					'( %s ? %s : %s )',
					$if->inline_check( $varname ),
					$then->inline_check( $varname ),
					$else->inline_check( $varname ),
				);
			}
			sprintf(
				'do { local $_ = %s; %s ? %s : %s }',
				$varname,
				$if->inline_check( '$_' ),
				$then->inline_check( '$_' ),
				$else->inline_check( '$_' ),
			);
		};
	},
	deep_explanation => sub {
		my ( $self, $value, $varname ) = @_;
		return if $self->check( $value );
		my ( $if, $then, $else ) = $self->parameters->@*;
		$then ||= Any;
		$else ||= Any;
		if ( $if->check( $value ) ) {
			return [
				sprintf(
					'"%s" requires that that if the value passes "%s", it must also pass "%s"',
					$self,
					$if,
					$then,
				),
				sprintf( 'The value passed "%s"', $if ),
				map {
					$_->get_message( $value ),
					map( "    $_", @{ $_->validate_explain( $value ) || [] } ),
				} $then,
			];
		}
		else {
			return [
				sprintf(
					'"%s" requires that that if the value fails "%s", it must pass "%s"',
					$self,
					$if,
					$else,
				),
				map {
					$_->get_message( $value ),
					map( "    $_", @{ $_->validate_explain( $value ) || [] } ),
				} $if, $else,
			];
		}
	};

declare JThen,
	name_generator => $name_generator,
	constraint_generator => sub {
		my @constraints = @_;
		return sub {
			my $value = pop;
			return all { $_->check($value) } @constraints;
		};
	},
	inline_generator => sub {
		my @constraints = @_;
		$_->can_be_inlined || return for @constraints;
		return sub {
			my $varname = pop;
			return sprintf '( %s )', join( ' and ', map { $_->inline_check( $varname ) } @constraints );
		}
	},
	deep_explanation => JAllOf->{deep_explanation};

declare JElse,
	as JThen,
	name_generator => $name_generator,
	constraint_generator => sub {
		my @constraints = @_;
		return sub {
			my $value = pop;
			return all { $_->check($value) } @constraints;
		};
	},
	inline_generator => sub {
		my @constraints = @_;
		$_->can_be_inlined || return for @constraints;
		return sub {
			my $varname = pop;
			return sprintf '( %s )', join( ' and ', map { $_->inline_check( $varname ) } @constraints );
		}
	},
	deep_explanation => JAllOf->{deep_explanation};

declare JDependentSchema,
	name_generator => $name_generator,
	constraint_generator => sub {
		my ( $k, $then ) = @_;
		return sub {
			my $value = pop;
			exists( $value->{$k} ) ? $then->check($value) : !!1;
		};
	},
	inline_generator => sub {
		my ( $k, $then ) = @_;
		$_->can_be_inlined || return for $then;
		return sub {
			my $varname = pop;
			if ( $varname =~ /\A\$\w+\z/ ) {
				return sprintf(
					'( !exists(%s->{%s}) or ( %s ) )',
					$varname,
					B::perlstring( $k ),
					$then->inline_check( $varname ),
				);
			}
			sprintf(
				'do { local $_ = %s; !exists( $_->{%s} ) or ( %s ) }',
				$varname,
				B::perlstring( $k ),
				$then->inline_check( '$_' ),
			);
		};
	},
	deep_explanation => sub {
		my ( $self, $value, $varname ) = @_;
		return if $self->check( $value );
		my ( $k, $then ) = $self->parameters->@*;
		if ( exists $value->{$k} ) {
			return [
				sprintf(
					'"%s" requires that that if the hash has key "%s", the hash must pass "%s"',
					$self,
					$k,
					$then,
				),
				sprintf( 'The hash has key "%s"', $k ),
				map {
					$_->get_message( $value ),
					map( "    $_", @{ $_->validate_explain( $value ) || [] } ),
				} $then,
			];
		}
		else {
			return;
		}
	};

declare JEnum,
	as JAny,
	name_generator => $name_generator,
	constraint_generator => sub {
		my @things = @_;
		return sub {
			my $value = pop;
			for my $thing ( @things ) {
				return true if json_eq( $value, $thing );
			}
			return false;
		};
	},
	inline_generator => sub {
		my @things = @_;
		return sub {
			my $varname = pop;
			return sprintf(
				q{( %s )},
				join q{ || },
				map sprintf(
					'%s::json_eq( %s, %s )',
					__PACKAGE__,
					$varname,
					json_safe_dumper( $_ ),
				), @things
			);
		};
	},
	deep_explanation => sub {
		my ( $self, $value, $varname ) = @_;
		return if $self->check( $value );
		my @things = $self->parameters->@*;
		if ( not @things ) {
			return [
				sprintf(
					'"%s" cannot ever be satisifed!',
					$self,
				),
			];
		}
		return [
			sprintf(
				'"%s" requires that the value be equivalent to %s%s',
				$self,
				( @things == 1 ) ? q{} : q{one of },
				Type::Utils::english_list( \'or', map { json_safe_dumper($_) } @things ),
			),
			sprintf(
				"The value is: %s",
				json_safe_dumper( $value ),
			),
		];
	};

declare JConst,
	as JAny,
	name_generator => $name_generator,
	constraint_generator => sub {
		die if @_ != 1;
		my $thing = $_[0];
		return sub {
			my $value = pop;
			return json_eq( $value, $thing );
		};
	},
	inline_generator => sub {
		my $thing = $_[0];
		return sub {
			my $varname = pop;
			return sprintf(
				'do { %s::json_eq(%s, %s) }',
				__PACKAGE__,
				$varname,
				json_safe_dumper( $thing ),
			);
		};
	},
	deep_explanation => JEnum->{deep_explanation};

declare JMultipleOf,
	name_generator => $name_generator,
	constraint_generator => sub {
		assert_PositiveNum( my $base = shift );
		return sub {
			my $value = shift;
			is_Int( $value / $base );
		};
	},
	inline_generator => sub {
		assert_PositiveNum( my $base = $_[0] );
		return sub {
			my $varname = pop;
			sprintf(
				'do { my $tmp = %s / %s; %s }',
				$varname,
				$base,
				Int->inline_check( '$tmp' ),
			);
		};
	},
	deep_explanation => sub {
		my ( $self, $value, $varname ) = @_;
		return if $self->check( $value );
		return [
			sprintf(
				'"%s" requires the value to be a multiple of %s',
				$self,
				$self->type_parameter,
			),
			sprintf(
				'%s is not a multiple of %s',
				json_safe_dumper($value),
				$self->type_parameter,
			),
		];
	};

declare JMaximum,
	name_generator => $name_generator,
	constraint_generator => sub {
		assert_Num( my $base = shift );
		return sub {
			my $value = shift;
			$value <= $base;
		};
	},
	inline_generator => sub {
		assert_Num( my $base = $_[0] );
		return sub {
			my $varname = pop;
			"$varname <= $base";
		};
	};

declare JExclusiveMaximum,
	name_generator => $name_generator,
	constraint_generator => sub {
		assert_Num( my $base = shift );
		return sub {
			my $value = shift;
			$value < $base;
		};
	},
	inline_generator => sub {
		assert_Num( my $base = $_[0] );
		return sub {
			my $varname = pop;
			"$varname < $base";
		};
	};

declare JMinimum,
	name_generator => $name_generator,
	constraint_generator => sub {
		assert_Num( my $base = shift );
		return sub {
			my $value = shift;
			$value >= $base;
		};
	},
	inline_generator => sub {
		assert_Num( my $base = $_[0] );
		return sub {
			my $varname = pop;
			"$varname >= $base";
		};
	};

declare JExclusiveMinimum,
	name_generator => $name_generator,
	constraint_generator => sub {
		assert_Num( my $base = shift );
		return sub {
			my $value = shift;
			$value > $base;
		};
	},
	inline_generator => sub {
		assert_Num( my $base = $_[0] );
		return sub {
			my $varname = pop;
			"$varname > $base";
		};
	};

declare JMaxLength,
	name_generator => $name_generator,
	constraint_generator => sub {
		assert_PositiveOrZeroInt( my $base = shift );
		return sub {
			my $value = shift;
			length($value) <= $base;
		};
	},
	inline_generator => sub {
		assert_PositiveOrZeroInt( my $base = $_[0] );
		return sub {
			my $varname = pop;
			"length($varname) <= $base";
		};
	},
	deep_explanation => sub {
		my ( $self, $value, $varname ) = @_;
		return if $self->check( $value );
		return [
			sprintf(
				'"%s" requires the value to be at most %d characters long',
				$self,
				$self->type_parameter,
			),
			sprintf(
				'%s is %d characters long',
				json_safe_dumper($value),
				length($value),
			),
		];
	};

declare JMinLength,
	name_generator => $name_generator,
	constraint_generator => sub {
		assert_PositiveOrZeroInt( my $base = shift );
		return sub {
			my $value = shift;
			length($value) >= $base;
		};
	},
	inline_generator => sub {
		assert_PositiveOrZeroInt( my $base = $_[0] );
		return sub {
			my $varname = pop;
			"length($varname) >= $base";
		};
	},
	deep_explanation => sub {
		my ( $self, $value, $varname ) = @_;
		return if $self->check( $value );
		return [
			sprintf(
				'"%s" requires the value to be at least %d characters long',
				$self,
				$self->type_parameter,
			),
			sprintf(
				'%s is %d characters long',
				json_safe_dumper($value),
				length($value),
			),
		];
	};

declare JPattern,
	name_generator => $name_generator,
	constraint_generator => sub {
		my $pattern = shift;
		return sub {
			my $value = shift;
			$value =~ $pattern;
		};
	},
	inline_generator => sub {
		my $pattern = shift;
		my $tc = StrMatch[ $pattern ];
		return unless $tc->can_be_inlined;
		return $tc->inlined;
	};

declare JMaxItems,
	name_generator => $name_generator,
	constraint_generator => sub {
		assert_PositiveOrZeroInt( my $base = shift );
		return sub {
			my $value = shift;
			@$value <= $base;
		};
	},
	inline_generator => sub {
		assert_PositiveOrZeroInt( my $base = $_[0] );
		return sub {
			my $varname = pop;
			"\@{ $varname } <= $base";
		};
	},
	deep_explanation => sub {
		my ( $self, $value, $varname ) = @_;
		return if $self->check( $value );
		return [
			sprintf(
				'"%s" requires the array to be at most %d elements long',
				$self,
				$self->type_parameter,
			),
			sprintf(
				'The array is %d elements long',
				scalar($value->@*),
			),
		];
	};

declare JMinItems,
	name_generator => $name_generator,
	constraint_generator => sub {
		assert_PositiveOrZeroInt( my $base = shift );
		return sub {
			my $value = shift;
			@$value >= $base;
		};
	},
	inline_generator => sub {
		assert_PositiveOrZeroInt( my $base = $_[0] );
		return sub {
			my $varname = pop;
			"\@{ $varname } >= $base";
		};
	},
	deep_explanation => sub {
		my ( $self, $value, $varname ) = @_;
		return if $self->check( $value );
		return [
			sprintf(
				'"%s" requires the array to be at least %d elements long',
				$self,
				$self->type_parameter,
			),
			sprintf(
				'The array is %d elements long',
				scalar($value->@*),
			),
		];
	};

declare JUniqueItems,
	where {
		my @tmp = @$_;
		for my $i ( 0 .. $#tmp - 1 ) {
			for my $j ( $i + 1 .. $#tmp ) {
				return false if json_eq( $tmp[$i], $tmp[$j] );
			}
		}
		return true;
	},
	inline_as {
		my $varname = pop;
		sprintf q{
			do {
				my @tmp = @{ %s };
				my $bad = !!0;
				OUTER: for my $i ( 0 .. $#tmp - 1 ) {
					for my $j ( $i + 1 .. $#tmp ) {
						( ++$bad, last OUTER ) if %s::json_eq( $tmp[$i], $tmp[$j] );
					}
				}
				not $bad;
			};
		}, $varname, __PACKAGE__;
	},
	message {
		my $value = $_;
		for my $i ( 0 .. $#$value - 1 ) {
			for my $j ( $i + 1 .. $#$value ) {
				return "@{[ Type::Tiny::_dd($value) ]} has non-unique elements: index $j duplicates index $i"
					if json_eq( $value->[$i], $value->[$j] );
			}
		}
		return '';
	};

declare JMaxProperties,
	name_generator => $name_generator,
	constraint_generator => sub {
		assert_PositiveOrZeroInt( my $base = shift );
		return sub {
			my $value = shift;
			keys(%$value) <= $base;
		};
	},
	inline_generator => sub {
		assert_PositiveOrZeroInt( my $base = $_[0] );
		return sub {
			my $varname = pop;
			"keys(\%{ $varname }) <= $base";
		};
	},
	deep_explanation => sub {
		my ( $self, $value, $varname ) = @_;
		return if $self->check( $value );
		return [
			sprintf(
				'"%s" requires the hash to have at most %d keys',
				$self,
				$self->type_parameter,
			),
			sprintf(
				'The hash has %d keys',
				scalar( my @tmp = keys $value->%* ),
			),
		];
	};

declare JMinProperties,
	name_generator => $name_generator,
	constraint_generator => sub {
		assert_PositiveOrZeroInt( my $base = shift );
		return sub {
			my $value = shift;
			keys(%$value) >= $base;
		};
	},
	inline_generator => sub {
		assert_PositiveOrZeroInt( my $base = $_[0] );
		return sub {
			my $varname = pop;
			"keys(\%{ $varname }) >= $base";
		};
	},
	deep_explanation => sub {
		my ( $self, $value, $varname ) = @_;
		return if $self->check( $value );
		return [
			sprintf(
				'"%s" requires the hash to have at least %d keys',
				$self,
				$self->type_parameter,
			),
			sprintf(
				'The hash has %d keys',
				scalar( my @tmp = keys $value->%* ),
			),
		];
	};

declare JRequired,
	name_generator => $name_generator,
	constraint_generator => sub {
		my @keys = @_;
		return sub {} if !@keys;
		return sub {
			my $value = shift;
			all { exists $value->{$_} } @keys;
		};
	},
	inline_generator => sub {
		my @keys = @_;
		return sub {
			my $varname = pop;
			return '!!1' if !@keys;
			sprintf(
				'do { my $tmp = %s; %s }',
				$varname,
				join( q{ and }, map { sprintf 'exists $tmp->{%s}', B::perlstring($_) } @keys ),
			);
		}
	},
	deep_explanation => sub {
		my ( $self, $value, $varname ) = @_;
		return if $self->check( $value );
		my @keys = sort( $self->parameters->@* );
		if ( @keys == 1 ) {
			return [
				sprintf(
					'"%s" requires the key %s to exist in the hash',
					$self,
					B::perlstring( $keys[0] ),
				),
				sprintf(
					'The key %s does not exist in the hash',
					B::perlstring( $keys[0] ),
				),
			];
		}
		my @missing = grep { not exists $value->{$_} } @keys;
		return [
			sprintf(
				'"%s" requires the keys %s to exist in the hash',
				$self,
				Type::Utils::english_list( map { B::perlstring($_) } @keys ),
			),
			( @missing == 1 )
				? sprintf(
					'The key %s does not exist in the hash',
					B::perlstring( $missing[0] ),
				)
				: sprintf(
					'The keys %s do not exist in the hash',
					Type::Utils::english_list( map { B::perlstring($_) } @missing ),
				),
		];
	};

declare JDependentRequired,
	name_generator => $name_generator,
	constraint_generator => sub {
		my ( $k, @keys ) = @_;
		return sub {
			my $value = shift;
			!exists $value->{$k} or all { exists $value->{$_} } @keys;
		};
	},
	inline_generator => sub {
		my ( $k, @keys ) = @_;
		return sub {
			my $varname = pop;
			sprintf(
				'do { my $tmp = %s; !exists $tmp->{%s} or ( %s ) }',
				$varname,
				B::perlstring( $k ),
				join( q{ and }, map { sprintf 'exists $tmp->{%s}', B::perlstring($_) } @keys ),
			);
		}
	},
	deep_explanation => sub {
		my ( $self, $value, $varname ) = @_;
		return if $self->check( $value );
		my ( $k, @keys ) = $self->parameters->@*;
		if ( exists $value->{$k} ) {
			if ( @keys == 1 ) {
				return [
					sprintf(
						'"%s" requires the key %s to exist in the hash if key %s exists',
						$self,
						B::perlstring( $keys[0] ),
						B::perlstring( $k ),
					),
					sprintf(
						'The key %s exists in the hash',
						B::perlstring( $k ),
					),
					sprintf(
						'The key %s does not exist in the hash',
						B::perlstring( $keys[0] ),
					),
				];
			}
			my @missing = grep { not exists $value->{$_} } @keys;
			return [
				sprintf(
					'"%s" requires the keys %s to exist in the hash if key %s exists',
					$self,
					Type::Utils::english_list( map { B::perlstring($_) } @keys ),
					B::perlstring( $k ),
				),
				sprintf(
					'The key %s exists in the hash',
					B::perlstring( $k ),
				),
				( @missing == 1 )
					? sprintf(
						'The key %s does not exist in the hash',
						B::perlstring( $missing[0] ),
					)
					: sprintf(
						'The keys %s do not exist in the hash',
						Type::Utils::english_list( map { B::perlstring($_) } @missing ),
					),
			];
		}
		else {
			return;
		}
	};

# TODO: JItems deep_explanation
declare JItems,
	name_generator => $name_generator,
	constraint_generator => sub {
		my $items                 = $_[0];
		my @prefixItems           = ( $_[1] or [] )->@*;
		my $unevaluatedItems      = $_[2];
		my $contains              = $_[3];
		my $minContains           = $_[4];
		my $maxContains           = $_[5];
		
		$minContains //= 1 if $contains;
		
		return sub {
			my $value = shift;
			my $ident = Scalar::Util::refaddr($value);
			my $count = 0;
			for my $ix ( 0 .. $#$value ) {
				my $seen = 0;
				if ( $ix < @prefixItems ) {
					++$seen;
					my $type = $prefixItems[$ix];
					return false if !$type->check( $value->[$ix] );
				}
				elsif ( $items ) {
					++$seen;
					return false if !$items->check( $value->[$ix] );
				}
				
				if ( $contains and $contains->check( $value->[$ix] ) ) {
					++$seen;
					++$count;
				}
				
				if ( $unevaluatedItems and !$seen and !$EVALUATED_ITEMS->{"$ident//$ix"}) {
					++$seen;
					return false if !$unevaluatedItems->check( $value->[$ix] );
				}
				$EVALUATED_ITEMS->{"$ident//$ix"}++ if $seen;
			}
			return false if defined($minContains) && $count > $minContains;
			return false if defined($maxContains) && $count > $maxContains;
			return true;
		};
	},
	inline_generator => sub {
		my $items                 = $_[0];
		my @prefixItems           = ( $_[1] or [] )->@*;
		my $unevaluatedItems      = $_[2];
		my $contains              = $_[3];
		my $minContains           = $_[4];
		my $maxContains           = $_[5];
		
		$minContains //= 1 if $contains;
		
		$_->can_be_inlined || return for grep defined, $items, @prefixItems, $unevaluatedItems, $contains;
		
		return sub {
			my $varname = pop;

			my $i = 0;
			my $simpleCheck = join q{ }, map {
				my $type = $_;
				sprintf( 'elsif ( $ix eq %d ) { ++$seen; ( $bad++, last ) unless %s }', $i++, $type->inline_check('$val') );
			} @prefixItems;
			$simpleCheck =~ s/\Aels//;
			
			if ( $simpleCheck and $items ) {
				$simpleCheck .= sprintf( ' else { ++$seen; ( $bad++, last ) unless %s }', $items->inline_check('$val') );
			}
			elsif ( $items ) {
				$simpleCheck .= sprintf( '++$seen; ( $bad++, last ) unless %s;', $items->inline_check('$val') );
			}
			
			my $containsCheck = '';
			if ( $contains ) {
				$containsCheck .= sprintf( '( $seen++, $cnt++ ) if %s;', $contains->inline_check('$val') );
			}

			my $unevaluatedItemsCheck = '';
			if ( $unevaluatedItems ) {
				$unevaluatedItemsCheck = sprintf( 'if ( !$seen and !$%s::EVALUATED_ITEMS->{"$id//$ix"} ) { ++$seen; ( $bad++, last ) unless %s; }', __PACKAGE__, $unevaluatedItems->inline_check('$val') );
			}

			my ( $minContainsCheck, $maxContainsCheck ) = ( '', '' );
			$minContainsCheck = "\$bad++ if \$cnt < $minContains;" if defined $minContains;
			$maxContainsCheck = "\$bad++ if \$cnt > $maxContains;" if defined $maxContains;
			
			return sprintf(
				q{
					do {
						my $tmp = %s;
						my $id  = Scalar::Util::refaddr($tmp);
						my $bad = 0;
						my $cnt = 0;
						for my $ix ( 0 .. $#$tmp ) {
							my $val  = $tmp->[$ix];
							my $seen = 0;
							%s
							%s
							$%s::EVALUATED_ITEMS->{"$id//$ix"}++ if $seen;
						}
						%s
						%s
						not $bad;
					}
				},
				$varname,
				$simpleCheck,
				$containsCheck,
				__PACKAGE__,
				$minContainsCheck,
				$maxContainsCheck,
			);
		};
	};

# TODO: JProperties deep_explanation
declare JProperties,
	name_generator => $name_generator,
	constraint_generator => sub {
		my %properties            = ( $_[0] or [] )->@*;
		my %patternProperties     = ( $_[1] or [] )->@*;
		my $additionalProperties  = $_[2];
		my $unevaluatedProperties = $_[3];
		
		return sub {
			my $value = shift;
			my $ident = Scalar::Util::refaddr($value);
			for my $key ( sort keys $value->%* ) {
				my $seen = 0;
				if ( my $type = $properties{$key} ) {
					++$seen;
					return false if !$type->check( $value->{$key} );
				}
				for my $pattern ( sort keys %patternProperties ) {
					if ( $key =~ /$pattern/ ) {
						++$seen;
						my $type = $patternProperties{$pattern};
						return false if !$type->check( $value->{$key} );
					}
				}
				if ( $additionalProperties and !$seen ) {
					++$seen;
					return false if !$additionalProperties->check( $value->{$key} );
				}
				if ( $unevaluatedProperties and !$seen and !$EVALUATED_PROPERTIES->{"$ident//$key"}) {
					++$seen;
					return false if !$unevaluatedProperties->check( $value->{$key} );
				}
				$EVALUATED_PROPERTIES->{"$ident//$key"}++ if $seen;
			}
			return true;
		};
	},
	inline_generator => sub {
		my %properties            = ( $_[0] or [] )->@*;
		my %patternProperties     = ( $_[1] or [] )->@*;
		my $additionalProperties  = $_[2];
		my $unevaluatedProperties = $_[3];
		
		$_->can_be_inlined || return for grep defined, values(%properties), values(%patternProperties), $additionalProperties, $unevaluatedProperties;

		return sub {
			my $varname = pop;
			
			my $propertiesCheck = join q{ }, map {
				my $property = $_;
				my $type = $properties{$property};
				sprintf( 'elsif ( $key eq %s ) { ++$seen; ( $bad++, last ) unless %s }', B::perlstring($property), $type->inline_check('$val') );
			} sort keys %properties;
			$propertiesCheck =~ s/\Aels//;
			
			my $patternPropertiesCheck = join q{ }, map {
				my $pattern = $_;
				my $type = $patternProperties{$pattern};
				sprintf( 'if ( $key =~ %s ) { ++$seen; ( $bad++, last ) unless %s }', serialize_regexp(qr/$pattern/), $type->inline_check('$val') );
			} sort keys %patternProperties;
			
			my $additionalPropertiesCheck = '';
			if ( $additionalProperties ) {
				my $type = $additionalProperties;
				$additionalPropertiesCheck = sprintf( 'if ( ! $seen ) { ++$seen; ( $bad++, last ) unless %s; }', $type->inline_check('$val') );
			}
			
			my $unevaluatedPropertiesCheck = '';
			if ( $unevaluatedProperties ) {
				my $type = $unevaluatedProperties;
				$unevaluatedPropertiesCheck = sprintf( 'if ( !$seen and !$%s::EVALUATED_PROPERTIES->{"$id//$key"} ) { ++$seen; ( $bad++, last ) unless %s; }', __PACKAGE__, $type->inline_check('$val') );
			}
			
			return sprintf(
				q{
					do {
						my $tmp = %s;
						my $id  = Scalar::Util::refaddr($tmp);
						my $bad = 0;
						for my $key ( sort keys %%$tmp ) {
							my $val  = $tmp->{$key};
							my $seen = 0;
							%s
							%s
							%s
							%s
							$%s::EVALUATED_PROPERTIES->{"$id//$key"}++ if $seen;
						}
						not $bad;
					}
				},
				$varname,
				$propertiesCheck,
				$patternPropertiesCheck,
				$additionalPropertiesCheck,
				$unevaluatedPropertiesCheck,
				__PACKAGE__,
			);
		};
	};	

declare JPropertyNames,
	name_generator => $name_generator,
	constraint_generator => sub {
		@_ == 1 or die;
		my $constraint = shift;
		my $list_constraint = ArrayRef[$constraint];
		return sub {
			my $value = shift;
			$list_constraint->check( [ sort keys $value->%* ] );
		};
	},
	inline_generator => sub {
		@_ == 1 or die;
		my $constraint = shift;
		my $list_constraint = ArrayRef[$constraint];
		$list_constraint->can_be_inlined || return;
		return sub {
			my $varname = pop;
			sprintf( 'do { my $keys = [ sort keys %%{ %s } ]; %s }', $varname, $list_constraint->inline_check('$keys') );
		};
	},
	deep_explanation => sub {
		my ( $self, $value, $varname ) = @_;
		return if $self->check( $value );
		my $constraint = $self->type_parameter;
		my @fails = $constraint->complementary_type->grep( sort keys $value->%* );
		return [
			sprintf(
				'"%s" requires that each key passes "%s"',
				$self,
				$constraint,
			),
			map {
				;
				"Key @{[ B::perlstring($_) ]} did not pass type constraint \"$constraint\"",
				map( "    $_", @{ $constraint->validate_explain( $_ ) || [] } ),
			} @fails,
		];
	};

{
	use feature qw(multidimensional);
	declare FmtDateTime, as StrMatch[ qr{\A$RE{time}{iso}\z} ];
	declare FmtDate, as StrMatch[ qr{\A$RE{time}{tf}{-pat=>'yyyy-mm-dd'}\z/} ];
	declare FmtTime, as StrMatch[ qr{\A(?:$RE{time}{tf}{-pat=>'hh:mm:ss'})|(?:$RE{time}{tf}{-pat=>'hh:mm'})\z} ];
	declare FmtDuration, as Str;
	declare FmtEmail, as StrMatch[ qr{\A$RE{Email}{Address}\z} ];
	declare FmtIdnEmail, as Str;
	declare FmtHostname, as StrMatch[ qr{\A$RE{net}{domain}\z} ];
	declare FmtIdnHostname, as Str;
	declare FmtIpv4, as StrMatch[ qr{\A$RE{net}{IPv4}{strict}\z} ];
	declare FmtIpv6, as StrMatch[ qr{\A$RE{net}{IPv6}\z} ];
	declare FmtUri, as StrMatch[ qr{\A$RE{URI}\z} ];
	declare FmtUriReference, as Str;
	declare FmtIri, as Str;
	declare FmtIriReference, as Str;
	declare FmtUuid, as Str;
	declare FmtUriTemplate, as Str;
	declare FmtJsonPointer, as Str;
	declare FmtRelativeJsonPointer, as Str;
	declare FmtRegex, as Str;
}

signature_for schema_to_type => (
	method  => false,
	pos     => [
		JObject|JBoolean,
		HashRef,      { default => {} },
		Str,          { default => '#' },
	],
	returns => TypeTiny,
);

sub schema_to_type ( $schema, $defs, $path ) {
	
	return Any if is_JTrue $schema;
	return ~Any if is_JFalse $schema;
	
	for my $xxx ( qw/ $defs definitions / ) {
		if ( is_HashRef $schema->{$xxx} ) {
			for my $k ( sort keys $schema->{$xxx}->%* ) {
				my $newpath = "$path/$xxx/" . jpointer_escape($k);
				my $type = schema_to_type( $schema->{$xxx}{$k}, $defs, $newpath );
				$defs->{$newpath} = $type;
			}
		}
		elsif ( exists $schema->{$xxx} ) {
			_croak "Invalid '%s' at %s: %s", $xxx, $path, $schema->{$xxx};
		}
	}

	if ( is_Str $schema->{'$ref'} ) {
		return JSRef[ $schema->{'$ref'}, $defs ];
	}
	elsif ( exists $schema->{'$ref'} ) {
		_croak "Invalid '\$ref' at %s: %s", $path, $schema->{'$ref'};
	}

	my ( @tc, $need_to_scope );
	_schema_to_type_basics( \@tc, $schema, $defs, $path ) and ++$need_to_scope;
	_schema_to_type_nested( \@tc, $schema, $defs, $path ) and ++$need_to_scope;
	_schema_to_type_number( \@tc, $schema, $defs, $path ) and ++$need_to_scope;
	_schema_to_type_string( \@tc, $schema, $defs, $path ) and ++$need_to_scope;
	_schema_to_type_arrays( \@tc, $schema, $defs, $path ) and ++$need_to_scope;
	_schema_to_type_object( \@tc, $schema, $defs, $path ) and ++$need_to_scope;
	
	_smiple( \@tc );
	
	my $intersection =
		( @tc == 0 ) ? Any :
		( @tc == 1 ) ? $tc[0] :
		do {
			require Type::Tiny::Intersection;
			Type::Tiny::Intersection->new( type_constraints => \@tc );
		};
	my $scoped = $need_to_scope ? JSScope[$intersection] : $intersection;
	
	$defs->{$path} = $scoped;
	Scalar::Util::weaken( $defs->{$path} ) unless $path eq '#';
	$defs->{'#' . jpointer_escape($schema->{'$anchor'})} = $scoped if is_Str $schema->{'$anchor'};
	$defs->{$schema->{'$id'}} = $scoped if is_Str $schema->{'$id'};

	return $scoped;
}

our $OPTIMIZE = true;

sub _smiple ( $orig ) {
	return unless $OPTIMIZE;
	my @tc = $orig->@*;
	my @new;
	while ( @tc ) {
		my $got = shift @tc;
		if ( @tc and eval { $got->parent->strictly_equals(JIf) } ) {
			my $next = $tc[0];
			if ( eval { $next->parent->strictly_equals(JIf) } and $next->type_parameter->strictly_equals( $got->type_parameter ) ) {
				$next = shift @tc;
				my @then =
					map { $_->equals(Any) ? () : $_ }
					map { !$_ ? () : eval { $_->parent->strictly_equals(JThen) } ? $_->parameters->@* : $_ }
					map { $_->parameters->[1] }
					$got, $next;
				my @else =
					map { $_->equals(Any) ? () : $_ }
					map { !$_ ? () : eval { $_->parent->strictly_equals(JElse) } ? $_->parameters->@* : $_ }
					map { $_->parameters->[2] }
					$got, $next;
				push @new, JIf[ $got->type_parameter, @then ? JThen[@then] : Any, @else ? JElse[@else] : () ];
				next;
			}
		}
		push @new, $got;
	}
	
	$orig->@* = @new;
}

sub _schema_to_type_basics ( $tc, $schema, $defs, $path ) {
	my $T = JSPrimativeName | Enum['integer'];
	if ( $T->check( $schema->{type} ) ) {
		push $tc->@*, to_JSPrimativeType $schema->{type};
	}
	elsif ( ArrayRef->of( $T )->check( $schema->{type} ) ) {
		if ( $schema->{type}->@* == 1 ) {
			push $tc->@*, to_JSPrimativeType $schema->{type}[0];
		}
		else {
			require Type::Tiny::Union;
			push $tc->@*, Type::Tiny::Union->new(
				type_constraints => [ JSPrimativeType->map( $schema->{type}->@* ) ],
			);
		}
	}
	elsif ( exists $schema->{type} ) {
		_croak "Invalid 'type' at %s: %s", $path, $schema->{type};
	}
	
	if ( is_ArrayRef $schema->{enum} ) {
		push $tc->@*, JEnum->of( $schema->{enum}->@* );
	}
	elsif ( exists $schema->{enum} ) {
		_croak "Invalid 'enum' at %s: %s", $path, $schema->{enum};
	}
	
	if ( exists $schema->{const} ) {
		push $tc->@*, JConst->of( $schema->{const} );
	}
	
	return false;
}

sub _schema_to_type_nested ( $tc, $schema, $defs, $path ) {
	my $need_to_scope = false;
	
	my %basic = (
		allOf => JAllOf,
		anyOf => JAnyOf,
		oneOf => JOneOf,
	);
	
	for my $k ( sort keys %basic ) {
		if ( is_ArrayRef $schema->{$k} ) {
			my $i = 0;
			my @nested = map { schema_to_type($_, ($defs), "$path/$k/@{[ $i++ ]}" ) } $schema->{$k}->@*;
			push $tc->@*, $basic{$k}->of( @nested );
		}
		elsif ( exists $schema->{$k} ) {
			_croak "Invalid '%s' at %s: %s", $k, $path, $schema->{$k};
		}
	}
	
	if ( is_JObject $schema->{not} or is_JBoolean $schema->{not} ) {
		my $nested = schema_to_type $schema->{not}, ($defs), "$path/not";
		push $tc->@*, JNot[ $nested ];
	}
	elsif ( exists $schema->{not} ) {
		_croak "Invalid 'not' at %s: %s", $path, $schema->{not};
	}
	
	if ( is_JObject $schema->{if} or is_JBoolean $schema->{if} ) {
		my $if   = schema_to_type $schema->{if}, ($defs), "$path/if";
		my $then = exists $schema->{then} ? ( schema_to_type $schema->{then}, ($defs), "$path/then" ) : Any;
		my $else = exists $schema->{else} ? ( schema_to_type $schema->{else}, ($defs), "$path/else" ) : Any;
		
		push $tc->@*, JIf[ $if, JThen[$then], JElse[$else] ];
	}
	elsif ( exists $schema->{if} ) {
		_croak "Invalid 'if' at %s: %s", $path, $schema->{if};
	}
	
	# Also support older(?) 'dependencies'.
	for my $xxx ( qw/ dependentSchemas dependencies / ) {
		if ( is_JObject $schema->{$xxx} ) {
			my %ds = $schema->{$xxx}->%*;
			my @tc2;
			
			for my $k ( sort keys %ds ) {
				next if is_ArrayRef $ds{$k};
				my $nested = schema_to_type $ds{$k}, ($defs), "$path/$xxx/$k";
				push @tc2, JDependentSchema[ $k, JThen[$nested] ];
			}
			
			if ( @tc2 ) {
				my @primatives = JSPrimativeType->grep( $tc->@* );
				
				if ( @primatives == 1 and $primatives[0] == JObject ) {
					push $tc->@*, @tc2;
				}
				else {
					push $tc->@*, JIf[ JObject, JThen[@tc2] ];
				}
			}
		}
		elsif ( exists $schema->{$xxx} ) {
			_croak "Invalid '%s' at %s: %s", $xxx, $path, $schema->{$xxx};
		}
	}
	
	{
		my %H;
		if ( is_ArrayRef $schema->{prefixItems} ) {
			my $i = 0;
			$H{prefixItems} = [ map { schema_to_type( $_, ($defs), "$path/prefixItems/@{[ $i++ ]}") } $schema->{prefixItems}->@* ];
		}
		elsif ( exists $schema->{prefixItems} ) {
			_croak "Invalid 'prefixItems' at %s: %s", $path, $schema->{prefixItems};
		}
		
		if ( is_ArrayRef $schema->{items} ) {
			$H{prefixItems} ||= [];
			my $i = @{ $H{prefixItems} };
			push $H{prefixItems}->@*, map { schema_to_type( $_, ($defs), "$path/items/@{[ $i++ ]}") } $schema->{items}->@*;
		}
		elsif ( is_JObject $schema->{items} or is_JBoolean $schema->{items} ) {
			$H{items} = schema_to_type( $schema->{items}, ($defs), "$path/items");
		}
		elsif ( exists $schema->{items} ) {
			_croak "Invalid 'items' at %s: %s", $path, $schema->{items};
		}

		if ( is_JFalse $schema->{additionalItems} and not exists $schema->{items} ) {
			$H{items} = Any;
		}
		elsif ( is_JObject $schema->{additionalItems} or is_JBoolean $schema->{additionalItems} ) {
			if ( $H{items} ) {
				_carp "Conflicting 'items' and 'additionalItems' at %s", $path;
			}
			else {
				$H{items} = schema_to_type( $schema->{additionalItems}, ($defs), "$path/additionalItems");
			}
		}
		elsif ( exists $schema->{additionalItems} ) {
			_croak "Invalid 'additionalItems' at %s: %s", $path, $schema->{additionalItems};
		}
		
		if ( is_JObject $schema->{contains} or is_JBoolean $schema->{contains} ) {
			$H{contains} = schema_to_type( $schema->{contains}, ($defs), "$path/contains");
			
			if ( is_PositiveOrZeroInt $schema->{maxContains} ) {
				$H{maxContains} = $schema->{maxContains};
			}
			elsif ( exists $schema->{maxContains} ) {
				_croak "Invalid 'maxContains' at %s: %s", $path, $schema->{maxContains};
			}
			
			if ( is_PositiveOrZeroInt $schema->{minContains} ) {
				$H{minContains} = $schema->{minContains};
			}
			elsif ( exists $schema->{minContains} ) {
				_croak "Invalid 'minContains' at %s: %s", $path, $schema->{minContains};
			}
		}
		elsif ( exists $schema->{contains} ) {
			_croak "Invalid 'contains' at %s: %s", $path, $schema->{contains};
		}

		if ( is_JObject $schema->{unevaluatedItems} or is_JBoolean $schema->{unevaluatedItems} ) {
			$H{unevaluatedItems} = schema_to_type( $schema->{unevaluatedItems}, ($defs), "$path/unevaluatedItems" );
		}
		elsif ( exists $schema->{unevaluatedItems} ) {
			_croak "Invalid 'contains' at %s: %s", $path, $schema->{unevaluatedItems};
		}
		
		if ( keys %H ) {
			my @args = (
				$H{items}            || undef,
				$H{prefixItems}      || undef,
				$H{unevaluatedItems} || undef,
				$H{contains}         || undef,
				$H{minContains}      || undef,
				$H{maxContains}      || undef,
			);
			while ( not defined $args[-1] ) {
				pop @args;
			}
			my $tc2 = JItems[@args];
			my @primatives = JSPrimativeType->grep( $tc->@* );
			if ( @primatives == 1 and $primatives[0] == JArray ) {
				push $tc->@*, $tc2;
			}
			else {
				push $tc->@*, JIf[ JArray, JThen[$tc2] ];
			}
		}
	}
	
	{
		my %H;
		for my $k ( qw/ properties patternProperties / ) {
			if ( is_JObject $schema->{$k} ) {
				for my $k2 ( sort keys $schema->{$k}->%* ) {
					push @{ $H{$k} ||= [] }, $k2 => schema_to_type( $schema->{$k}{$k2}, ($defs), "$path/$k/$k2");
				}
			}
			elsif ( exists $schema->{$k} ) {
				_croak "Invalid '%s' at %s: %s", $k, $path, $schema->{$k};
			}
		}
		
		if ( is_JObject $schema->{additionalProperties} or is_JBoolean $schema->{additionalProperties} ) {
			$H{additionalProperties} = schema_to_type( $schema->{additionalProperties}, ($defs), "$path/additionalProperties");
		}
		elsif ( exists $schema->{additionalProperties} ) {
			_croak "Invalid 'additionalProperties' at %s: %s", $path, $schema->{additionalProperties};
		}

		if ( is_JObject $schema->{unevaluatedProperties} or is_JBoolean $schema->{unevaluatedProperties} ) {
			$H{unevaluatedProperties} = schema_to_type( $schema->{unevaluatedProperties}, ($defs), "$path/unevaluatedProperties");
			$need_to_scope = true;
		}
		elsif ( exists $schema->{unevaluatedProperties} ) {
			_croak "Invalid 'unevaluatedProperties' at %s: %s", $path, $schema->{unevaluatedProperties};
		}

		if ( keys %H ) {
			my @args = (
				$H{properties} || undef,
				$H{patternProperties} || undef,
				$H{additionalProperties} || undef,
				$H{unevaluatedProperties} || undef,
			);
			while ( not defined $args[-1] ) {
				pop @args;
			}
			my $tc2 = JProperties[@args];
			my @primatives = JSPrimativeType->grep( $tc->@* );
			if ( @primatives == 1 and $primatives[0] == JObject ) {
				push $tc->@*, $tc2;
			}
			else {
				push $tc->@*, JIf[ JObject, JThen[$tc2] ];
			}
		}
	}

	if ( is_JObject $schema->{propertyNames} or is_JBoolean $schema->{propertyNames} ) {
		my $tc2 = schema_to_type( $schema->{propertyNames}, ($defs), "$path/propertyNames");
		my @primatives = JSPrimativeType->grep( $tc->@* );
		if ( @primatives == 1 and $primatives[0] == JObject ) {
			push $tc->@*, JPropertyNames[$tc2];
		}
		else {
			push $tc->@*, JIf[ JObject, JThen[JPropertyNames[$tc2]] ];
		}
	}
	elsif ( exists $schema->{propertyNames} ) {
		_croak "Invalid 'propertyNames' at %s: %s", $path, $schema->{propertyNames};
	}

	return $need_to_scope;
}

sub _schema_to_type_number ( $tc, $schema, $defs, $path ) {
	my @tc2;
	
	if ( is_PositiveNum $schema->{multipleOf} ) {
		push @tc2, JMultipleOf->of( $schema->{multipleOf} );
	}
	elsif ( exists $schema->{multipleOf} ) {
		_croak "Invalid 'multipleOf' at %s: %s", $path, $schema->{multipleOf};
	}

	my %basic = (
		maximum           => JMaximum,
		exclusiveMaximum  => JExclusiveMaximum,
		minimum           => JMinimum,
		exclusiveMinimum  => JExclusiveMinimum,
	);
	
	for my $k ( sort keys %basic ) {
		if ( is_Num $schema->{$k} ) {
			push @tc2, $basic{$k}->of( $schema->{$k} );
		}
		elsif ( exists $schema->{$k} ) {
			_croak "Invalid '%s' at %s: %s", $k, $path, $schema->{$k};
		}
	}
	
	if ( @tc2 ) {
		my @primatives = JSPrimativeType->grep( $tc->@* );
		
		if ( @primatives == 1 and $primatives[0] == JNumber ) {
			push $tc->@*, @tc2;
		}
		else {
			push $tc->@*, JIf[ JNumber, JThen[@tc2] ];
		}
	}
	
	return false;
}

sub _schema_to_type_string ( $tc, $schema, $defs, $path ) {
	my @tc2;
	
	if ( is_PositiveOrZeroInt $schema->{maxLength} ) {
		push @tc2, JMaxLength->of( $schema->{maxLength} );
	}
	elsif ( exists $schema->{maxLength} ) {
		_croak "Invalid 'maxLength' at %s: %s", $path, $schema->{maxLength};
	}

	if ( is_PositiveOrZeroInt $schema->{minLength} ) {
		push @tc2, JMinLength->of( $schema->{minLength} );
	}
	elsif ( exists $schema->{minLength} ) {
		_croak "Invalid 'minLength' at %s: %s", $path, $schema->{minLength};
	}

	if ( is_RegexpRef $schema->{pattern} ) {
		push @tc2, JPattern->of( $schema->{pattern} );
	}
	elsif ( is_Str $schema->{pattern} ) {
		my $pattern = $schema->{pattern};
		push @tc2, JPattern->of( qr/$pattern/ );
	}
	elsif ( exists $schema->{pattern} ) {
		_croak "Invalid 'pattern' at %s: %s", $path, $schema->{pattern};
	}
	
	state $formats = {
		'date-time'              => FmtDateTime,
		'date'                   => FmtDate,
		'time'                   => FmtTime,
		'duration'               => FmtDuration,
		'email'                  => FmtEmail,
		'idn-email'              => FmtIdnEmail,
		'hostname'               => FmtHostname,
		'idn-hostname'           => FmtIdnHostname,
		'ipv4'                   => FmtIpv4,
		'ipv6'                   => FmtIpv6,
		'uri'                    => FmtUri,
		'uri-reference'          => FmtUriReference,
		'iri'                    => FmtIri,
		'iri-reference'          => FmtIriReference,
		'uuid'                   => FmtUuid,
		'uri-template'           => FmtUriTemplate,
		'json-pointer'           => FmtJsonPointer,
		'relative-json-pointer'  => FmtRelativeJsonPointer,
		'regex'                  => FmtRegex,
	};
	
	if ( is_Str $schema->{format} and exists $formats->{$schema->{format}} ) {
		push @tc2, $formats->{$schema->{format}};
	}

	if ( @tc2 ) {
		my @primatives = JSPrimativeType->grep( $tc->@* );
		
		if ( @primatives == 1 and $primatives[0] == JString ) {
			push $tc->@*, @tc2;
		}
		else {
			push $tc->@*, JIf[ JString, JThen[@tc2] ];
		}
	}
	
	return false;
}

sub _schema_to_type_arrays ( $tc, $schema, $defs, $path ) {
	my @tc2;
	
	if ( is_PositiveOrZeroInt $schema->{maxItems} ) {
		push @tc2, JMaxItems->of( $schema->{maxItems} );
	}
	elsif ( exists $schema->{maxItems} ) {
		_croak "Invalid 'maxItems' at %s: %s", $path, $schema->{maxItems};
	}
	
	if ( is_PositiveOrZeroInt $schema->{minItems} ) {
		push @tc2, JMinItems->of( $schema->{minItems} );
	}
	elsif ( exists $schema->{minItems} ) {
		_croak "Invalid 'minItems at %s: %s", $path, $schema->{minItems};
	}

	if ( is_JBoolean $schema->{uniqueItems} ) {
		push @tc2, JUniqueItems if is_JTrue $schema->{uniqueItems};
	}
	elsif ( exists $schema->{uniqueItems} ) {
		_croak "Invalid 'uniqueItems' at %s: %s", $path, $schema->{uniqueItems};
	}
	
	if ( @tc2 ) {
		my @primatives = JSPrimativeType->grep( $tc->@* );
		
		if ( @primatives == 1 and $primatives[0] == JArray ) {
			push $tc->@*, @tc2;
		}
		else {
			push $tc->@*, JIf[ JArray, JThen[@tc2] ];
		}
	}
	
	return false;
}

sub _schema_to_type_object ( $tc, $schema, $defs, $path ) {
	my @tc2;
	
	if ( is_PositiveOrZeroInt $schema->{maxProperties} ) {
		push @tc2, JMaxProperties->of( $schema->{maxProperties} );
	}
	elsif ( exists $schema->{maxProperties} ) {
		_croak "Invalid 'maxProperties' at %s: %s", $path, $schema->{maxProperties};
	}

	if ( is_PositiveOrZeroInt $schema->{minProperties} ) {
		push @tc2, JMinProperties->of( $schema->{minProperties} );
	}
	elsif ( exists $schema->{minProperties} ) {
		_croak "Invalid 'minProperties' at %s: %s", $path, $schema->{minProperties};
	}

	if ( is_Strings $schema->{required} ) {
		push @tc2, JRequired->of( $schema->{required}->@* );
	}
	elsif ( exists $schema->{required} ) {
		_croak "Invalid 'required' at %s: %s", $path, $schema->{required};
	}

	# Also support older(?) 'dependencies'.
	for my $xxx ( qw/ dependentRequired dependencies / ) {
		if ( is_HashRef $schema->{$xxx} ) {
			my %dr = $schema->{$xxx}->%*;
			for my $k ( sort keys %dr ) {
				if ( is_Strings $dr{$k} ) {
					my @r = assert_Strings( $dr{$k} )->@*;
					push @tc2, JDependentRequired->of( $k, @r ) if @r;
				}
			}
		}
		elsif ( exists $schema->{$xxx} ) {
			_croak "Invalid '%s' at %s: %s", $xxx, $path, $schema->{$xxx};
		}
	}

	if ( @tc2 ) {
		my @primatives = JSPrimativeType->grep( $tc->@* );
		
		if ( @primatives == 1 and $primatives[0] == JObject ) {
			push $tc->@*, @tc2;
		}
		else {
			push $tc->@*, JIf[ JObject, JThen[@tc2] ];
		}
	}
	
	return false;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Types::JSONSchema - somewhat experimental conversion of JSON Schema schemas into Type::Tiny type constraints

=head1 SYNOPSIS

  use JSON qw( decode_json );
  use Types::JSONSchema qw( schema_to_type );
  
  my $schema = decode_json q( {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "https://example.com/product.schema.json",
    "title": "Product",
    "description": "A product from Acme's catalog",
    "type": "object",
    "properties": {
      "productId": {
        "description": "The unique identifier for a product",
        "type": "integer"
      },
      "productName": {
        "description": "Name of the product",
        "type": "string"
      },
      "price": {
        "description": "The price of the product",
        "type": "number",
        "exclusiveMinimum": 0
      },
      "tags": {
        "description": "Tags for the product",
        "type": "array",
        "items": {
          "type": "string"
        },
        "minItems": 1,
        "uniqueItems": true
      }
    },
    "required": [ "productId", "productName", "price" ]
  } );
  
  my $data = decode_json q( {
    "productId": 1,
    "productName": "A green door",
    "price": 12.50,
    "tags": [ "home", "green" ]
  } );
  
  my $type = schema_to_type( $schema );
  if ( $type->check($data) ) {
    print "All good!\n";
  }

=head1 DESCRIPTION

This is a L<Type::Library> exporting L<Type::Tiny> type constraints,
but also exports some useful functions and constants.

Nothing is exported by default. You need to request things explicitly.

  use Types::JSONSchema qw( json_eq schema_to_type :types );

=head2 Functions

=over

=item C<< json_eq( $x, $y ) >>

Checks if the two values are considered equal/equivalent by JSON Schema's
rules.

=item C<< schema_to_type( $schema ) >>

Given a JSON Schema as a hashref, converts that to a type constraint.

As a shortcut, C<< schema_to_type( true ) >> returns B<< Any >>
and C<< schema_to_type( false ) >> returns B<< ~Any >>.

Limitation: C<< $ref >> cannot be used to refer to external schemas
or arbitrary relative JSON pointers, only to the root schema (as '#')
and schemas defined in C<< $defs >> (as '#/$defs/foo', etc or using
their C<< $anchor >> or C<< $id >>).

Limitation: The error messages from these type constraints are very
opaque and don't give you much of an idea I<why> a value failed to
validate. This will be addressed in a future version.

Limitation: infinite loops are not detected.

=item C<< json_safe_dumper( @things ) >>

Like L<Data::Dumper>. Despite the name, dumps Perl code, not JSON for
a data structure. Can't handle cyclical data structures, blessed
objects (except B<JBoolean>), or any other data structures not found in
JSON. The advantage of using this over L<Data::Dumper> is that it
preserves the C<created_as_number>, C<created_as_string>, C<is_bool>
results for non-reference scalars. Hashrefs are always output sorted by key.

This is internally used by the B<JEnum> and B<JConst> type constraints
for serializing values into generated Perl code.

=item C<< jpointer_escape( $str ) >>

Escapes special characters based on JSON Pointer rules. Returns the
escaped string.

=back

=head2 Constants

=over

=item C<true>

=item C<false>

=back

=head2 Types

It is not anticipated that you'd normally use these types directly, but
they may be found in the output of C<schema_to_type>.

=head3 General

=over

=item B<< JSRef[`key, `hashref] >>

A type which refers to a type defined in a hashref. At run-time, when the
type is being checked, the type will be looked up in the hashref by its
key.

=item B<< JSScope[`inner] >>

Establishes a scope for B<JItems> and B<JProperties> which may not always
work outside the scope!

=item B<< JAllOf[`a, `b, ...] >>

Values meet this type constraint if they meet all the inner type constraints.

=item B<< JAnyOf[`a, `b, ...] >>

Values meet this type constraint if they meet any of the inner type constraints.

=item B<< JOneOf[`a, `b, ...] >>

Values meet this type constraint if they meet exactly one of the inner type
constraints.

=item B<< JNot[`a] >>

Values meet this type constraint if they fail to meet the inner type
constraint.

=item B<< JIf[ `a, JThen[`b], JElse[`c] ] >>

Values which meet C<< `a >> are also expected to meet C<< `b >>.
Values which fail to meet C<< `a >> are expected to meet C<< `c >>.

If either the B<JThen> or B<JElse> are omitted, B<Any> is assumed.

=item B<< JThen[`a, `b, ...] >>

Intended for use with B<JIf>. If used on its own, acts like B<JAllOf>.

=item B<< JElse[`a, `b, ...] >>

Intended for use with B<JIf>. If used on its own, acts like B<JAllOf>.

=item B<< JEnum[`a, `b, `c...] >>

Checks that the value is exactly equal to one of the given values, by JSON
Schema's definition of equality. (In particular, two arrayrefs are equal
if their items are equal, and two hashrefs are equal if their keys and
values are equal.)

=item B<< JConst[`a] >>

Effectively means the same as B<JEnum>, but only accepts one value.

=back

=head3 Number

Although these type constraints are useful for numbers, they do not
actually check the value being constrained is a number, meaning they
can be used with non-numeric data such as strings which can be numified
("76 trombones" numifies to 76) or overloaded objects. If you need to
also check that the value is a number or integer, you can combine
these type constraint with other type constraints, like
B<< JAllOf[ JNumber, JMultipleOf[2] ] >>.

=over

=item B<< JMultipleOf[`n] >>

Checks that if the value is an integer multiple of n.

The parameter must be a non-zero positive number but does not itself need
to be an integer.

=item B<< JMaximum[`n] >>

Checks that the value is less than or equal to n.

=item B<< JExclusiveMaximum[`n] >>

Checks that the value is less than n.

=item B<< JMinimum[`n] >>

Checks that the value is greater than or equal to n.

=item B<< JExclusiveMinimum[`n] >>

Checks that the value is greater than n.

=back

=head3 String

Although these type constraints are useful for strings, they do not
actually check that the value being tested is a string, meaning they can
be used with any non-strings that can be stringified, such as overloaded
objects. If you also need to check that the value is a string, you can
combine these type constraints with other type constraints, like
B<< JAllOf[ JString, JMinLength[1], JMaxLength[255] ] >>.

=over

=item B<< JMaxLength[`n] >>

Checks that the value is at most n characters long.

=item B<< JMinLength[`n] >>

Checks that the value is at least n characters long.

=item B<< JPattern[`re] >>

Checks that the value is a string matching the regular expression.
Regular expressions can either be a C<< qr/.../ >> quoted regexp, or
given as a string.

As with normal Perl regexp rules, the pattern is not implicitly
anchored to the start and end of the string.

Contrary to the notice earlier, the implementation I<does> currently
check that the value is a string, though this is subject to change
in the future.

=back

=head3 Array

Although these type constraints are useful for arrayrefs, they do not
actually check that the value being tested is an arrayref, meaning they can
also be used with overloaded objects. If you also need to check that the
value is an arrayref, you can combine these type constraints with other
type constraints, like B<< JAllOf[ JArray, JMinItems[1] ] >>.

=over

=item B<< JMaxItems[`n] >>

Checks that the array has at most n elements.

=item B<< JMinItems[`n] >>

Checks that the array has at least n elements.

=item B<< JUniqueItems >>

Checks that all items in the array are unique, using JSON Schema's
notion of equality.

=item B<< JItems[`i, [`a, `b, ...], `u, `c, `min, `max] >>

Checks that all items in the array are of type i.

If a length-n arrayref of additional types is provided as the second
parameter, then the first n elements of the array being checked are
compared to those types in order instead. (Like C<prefixItems> in
JSON Schema.)

If a type constraint is given as the third parameter, any array items
which are so-far unchecked within this scope (see B<JScope>) will be
checked against this type. (Like C<unevaluatedItems> in JSON Schema.)

If a type constraint is given as the fourth parameter, then the array
being checked is expected to contain at least one element meeting that
type constraint. (Like C<contains> in JSON Schema.)

If minimum and maximum numbers are provided as the fifth and sixth
parameters, these work with the fourth parameter to alter how many
occurances are expected of the elements matching that type.
(Like C<minContains> and C<maxContains> in JSON Schema.)

Any parameter may be undef.

For example, an array containing all numbers:
B<< JAllOf[ JArray, JItems[JNumber] ] >>

Or an array containing at least two numbers, but perhaps mixed
with other values:
B<< JAllOf[ JArray, JItems[undef, undef, undef, JNumber, 2] ] >>

Or an array containing all numbers, apart from the first element
which is a mathematical operation:
B<< JAllOf[ JArray, JItems[ JNumber, [ JEnum[qw( + - * / )] ] ] ] >>

=back

=head3 Object

Although these type constraints are useful for hashrefs ("objects" in JSON
parlance), they do not actually check that the value being tested is a hashref,
meaning they can also be used with overloaded objects, blessed hashrefs, etc.
If you also need to check that the value is a hashref, you can combine these
type constraints with other type constraints, like
B<< JAllOf[ JObject, JRequired['id'] ] >>.

=over

=item B<< JMaxProperties[`n] >>

Checks that the hash has at most n key-value pairs.

=item B<< JMinProperties[`n] >>

Checks that the hash has at least n key-value pairs.

=item B<< JRequired[`a, `b, ...] >>

Checks that the strings given as parameters exist as keys in the hash.

=item B<< JDependentRequired[`k, `a, `b, ...] >>

Checks that if k exists as a key in the hash, the others do too. If k
is absent, the others are not required.

=item B<< JProperties[`h1, `h2, `a, `u] >>

The first parameter is an arrayref of key-type pairs, similar to B<Dict>
from L<Types::Standard>. For example,
B<< JProperties[ [ foo => JString, bar => JNumber ] ] >> will check
that if the hash contains a key "foo", its value is a string, and
if the hash contains a key "bar", its value is a number. It does not
require either key to be present. (You can use B<JAllOf> and B<JRequired>
for that!)

The second parameter is an arrayref of pattern-type pairs, similar to
the first parameter except that hash keys are matched against each
pattern as a regexp. For example, to check that any hash keys called
"*_id" are numeric, use B<< JProperties[ [], [ '_id$' => JNumber ] ] >>.

The third parameter is a type constraint to match against any additional
values in the hash. For example, if a hash has a string name but all
other values are expected to be numeric, you could use
B<< JProperties[ [ name => JString ], [], JNumber ] >>.
If you additionally wanted to permit private-use hash keys with a
leading underscore:
B<< JProperties[ [ name => JString ], [ '^_' => JAny ], JNumber ] >>.

If a type constraint is given as the fourth parameter, any hash values
which are so-far unchecked within this scope (see B<JScope>) will be
checked against this type. (Like C<unevaluatedProperties> in JSON Schema.)

=item B<< JPropertyNames[`a] >>

Checks that all keys within the hash meet the type constraint parameter.

=item B<< JDependentSchema[ `key, JThen[`inner] ] >>

If the value being tested is a hashref with the given key, checks that
the value being tested also meets the inner type constraint.

For example:

  my $type = JDependentSchema[ 'foo', JThen[Tied] ];
  my $href = { foo => 42 };
  tie( %$href, 'Some::Class' );
  
  # Because this hashref has a "foo" key, we check the hashref is
  # tied. (Note we're not checking the value 42 is tied!)
  $type->assert_valid( $href );
  
  # This doesn't have a "foo" key so doesn't need to be tied.
  $type->assert_valid( { agent => 86 } );
  
  # This will die because it has a "foo" key but isn't tied.
  $type->assert_valid( { agent => 86, foo => 99 } );

I<< Warning: >> for efficiency, this does not actually check that the
value is a hashref. This allows it to be composed in interesting ways.

B<< JAllOf[ JObject, JDependentSchema[ 'foo', JThen[...] ] ] >> can be used
to check that the value is a hashref and also conditionally obeys the inner
type constraint.

B<< JIf[ JObject, JThen[ JDependentSchema[ 'foo', JThen[...] ] ] ] >>
can be used to check the value conditionally obeys the inner type constraint
when it's a hashref, but passes when it's not a hashref.

=back

=head3 Format

The following are additional constraints which can be added to strings to
constrain their format. Many of them are not properly implemented and
simply accept all strings, but may still be useful as documentation.

=over

=item B<FmtDateTime>

Strings such as '2025-04-04 07:00:00'. Implemented.

=item B<FmtDate>

Strings such as '2025-04-04'. Implemented.

=item B<FmtTime>

Strings such as '07:00:00' or '07:00'. Implemented.

=item B<FmtDuration>

Strings such as 'P1D12H'. Not implemented.

=item B<FmtEmail>

Strings such as 'foo@example.net'. Implemented.

=item B<FmtIdnEmail>

Strings such as 'foo@exämple.net'. Not implemented.

=item B<FmtHostname>

Strings such as 'example.net'. Implemented.

=item B<FmtIdnHostname>

Strings such as 'exämple.net'. Not implemented.

=item B<FmtIpv4>

Strings such as '10.0.0.1'. Implemented.

=item B<FmtIpv6>

Strings such as '2001:db8:3333:4444:5555:6666:7777:8888'. Implemented.

=item B<FmtUri>

Strings such as 'https://example.net/'. Implemented.

=item B<FmtUriReference>

Strings such as 'https://example.net/' or a relative URI reference.
Not implemented.

=item B<FmtIri>

Strings such as 'https://exämple.net/'. Not implemented.

=item B<FmtIriReference>

Strings such as 'https://exämple.net/' or a relative IRI reference.
Not implemented.

=item B<FmtUuid>

Strings such as '0811a85e-5ef1-4962-9d1e-13adeef73be3'. Not implemented.

=item B<FmtUriTemplate>

Strings such as 'https://example.net/{user}'. Not implemented.

=item B<FmtJsonPointer>

Strings such as '/foo/0'. Not implemented.

=item B<FmtRelativeJsonPointer>

Strings such as '0#'. Not implemented.

=item B<FmtRegex>

Strings such as '^[Hh]ello$'. Not implemented.

=back

=head2 Variables

=over

=item C<< $Types::JSONSchema::OPTIMIZE >>

When true, attempts to optimize type constraints in certain ways. For example,
B<< JIf[JObject,JThen[Foo]] & JIf[JObject,JThen[Bar],JElse[Baz]] >> might
become B<< JIf[JObject,JThen[Foo,Bar],JElse[Baz]] >>.

It is believed that the optimization shouldn't affect the outcome of any
type checks, but in some cases the order certain checks are done
(C<unevaluatedProperties> and C<unevaluatedItems> in particular) may
affect the overall result. Optimization is not believed to break this,
but not every possible edge case has been tested.

You can disable these optimizations by doing this:

  BEGIN {
    $Types::JSONSchema::OPTIMIZE = false;
 };

=back

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-types-jsonschema/issues>.

=head1 SEE ALSO

L<Types::JSONSchema::PrimativeTypes>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

