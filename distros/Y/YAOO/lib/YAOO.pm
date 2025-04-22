package YAOO;
use strict; no strict 'refs';
use warnings;
use Carp qw/croak/; use Tie::IxHash;
use feature qw/state/;
use Blessed::Merge;
use Hash::Typed;
our $VERSION = '0.10';

our (%TYPES, %object, $LAST);

sub make_keyword {
	my ($called, $key, $cb) = @_;
	*{"${called}::$key"} = $cb;
	$LAST = 10000000000000000000;
}

sub import {
	my ($package, @attributes) = @_;

	my $called = caller();

	strict->import();
	warnings->import();

	for my $is (qw/ro rw/) {
		make_keyword($called, $is, sub { is => $is });
	}

	for my $key (qw/isa default coerce required trigger lazy delay build_order/) {
		make_keyword($called, $key, sub {
			my (@value) = @_;
			return $key => scalar @value > 1 ? @value : ($value[0] || 1);
		});
	}

	for my $isa ( qw/any string scalarref integer float boolean ordered_hash hash array object fh/ ) {
		make_keyword($called, $isa, sub {
			my (@args) = @_;
			my @return = (
				\&{"${package}::${isa}"},
				type => $isa,
				build_default => \&{"${package}::build_${isa}"}
			);
			push @return, (default => ($isa eq 'ordered_hash' ? sub { deep_clone_ordered_hash(@args) } : sub { deep_clone( scalar @args > 1 ? $isa eq 'hash' ? {@args} : \@args : @args) }))
				if (scalar @args);
			@return;
		});
	}

	make_keyword($called, 'typed_hash', sub {
		my (@args) = @_;
		my $spec = shift @args;
		if (! scalar $spec) {
			die 'Invalid declaration of a typed_hash no Hash::Typed spec passed'
		}
		if (caller(1)) {
			return Hash::Typed->new(
				deep_clone($spec),
				%{ deep_clone_ordered_hash(@args) }
			);
		}
		my @return = (
			\&{"${package}::typed_hash"},
			type => 'typed_hash',
		);
		push @return, default => sub {
			Hash::Typed->new(
				deep_clone($spec), 
				%{ deep_clone_ordered_hash(@args) }
			);
		};
		@return 
	});


	make_keyword($called, 'auto_build', sub { $object{$called}{auto_build} = 1; });

	make_keyword($called, 'extends', sub {
		my (@args) = @_;
		my $extend = caller();
  		for my $inherit (@args) {
			load($inherit);
			push @{*{\*{"${extend}::ISA"}}{ARRAY}}, $inherit;
			return unless $object{$inherit};
			my $bm = Blessed::Merge->new(blessed => 0, same => 0);
			$object{$extend} = $bm->merge($object{$extend}, $object{$inherit});
			for my $name (keys %{$object{$extend}{has}}) {
				make_keyword($extend, $name, sub {
					my ($self, $value) = @_;
					if ($value && (
						$object{$extend}{has}{$name}->{is} eq 'rw'
							|| [split '::', [caller(1)]->[3]]->[-1] =~ m/^new|build|set_defaults|auto_build$/
					)) {
						$value = $object{$extend}{has}{$name}->{coerce}($self, $value, $name)
							if ($object{$extend}{has}{$name}->{coerce});
						$object{$extend}{has}{$name}->{required}($self, $value, $name)
							if ($object{$extend}{$name}->{required});
						$value = $object{$extend}{has}{$name}->{isa}($value, $name, $called);
						$self->{$name} = $value;
						$object{$extend}{has}{$name}->{trigger}($self, $value, $name)
							if ($object{$extend}{has}{$name}->{trigger});
					}
					$self->{$name};
				});
			}
			for my $name (keys %{$object{$extend}{method}}) {
				make_keyword($extend, $name, $object{$called}{method}{$name});
			}
		}
	});

	make_keyword($called, 'require_has', sub {
		my (@args) = @_;
		push @{ $object{$called}{require_has}  }, @args;
	});

	make_keyword($called, 'require_sub', sub {
		my (@args) = @_;
		push @{ $object{$called}{require_sub}  }, @args;
	});

	make_keyword($called, 'require_method', sub {
		my (@args) = @_;
		push @{ $object{$called}{require_sub}  }, @args;
	});

	$object{$called}{has} = {};
	$object{$called}{method} = {};

	make_keyword($called, "method", sub {
		my ($name, $sub) = @_;

		$object{$called}{method}{$name} = $sub;
		make_keyword($called, $name, $sub);
	});

	make_keyword($called, 'has', sub { build_attribute($called, @_) });

	make_keyword($called, "new", sub {
		my ($pkg) = shift;
		my $self = bless { }, $pkg;
		require_has($called);
		require_sub($self, $called);
		require_method($called);
		auto_ld($self, $called, 'lazy') if ($object{$called}{lazy});
		set_defaults($self, $called);
		auto_build($self, $called, @_) if ($object{$called}{auto_build});
		$self->build(@_) if ($self->can('build'));
		auto_ld($self, $called, 'delay') if ($object{$called}{delay});
		return $self;
	});
}

sub build_attribute {
	my ($called, $name, @attrs) = @_;

	my $ref = ref $name || 'STRING';

	my $attribute_extend;
	if ($name =~ s/^_([a-zA-Z].*)/$1/) {
		$attribute_extend = 1;
	}

	if ($ref eq 'ARRAY') {
		build_attribute($called, $_, @attrs) for @{ $name };
	} elsif ($ref eq 'HASH') {
		build_attribute($called, $_, %{ $name->{$_} }) for keys %{ $name };
	}

	if ( !$attribute_extend && $object{$called}{has}{$name} ) {
		croak sprintf "%s attribute already defined for %s object.", $name, $called;
	}

	if ( scalar @attrs % 2 ) {
		croak sprintf "Invalid attribute definition odd number of key/value pairs (%s) passed with %s in %s object", scalar @attrs, $name, $called;
	}

	$object{$called}{has}{$name} = {@attrs};

	$object{$called}{has}{$name}{is} = 'rw'
		if (! $object{$called}{has}{$name}{is});

	$object{$called}{has}{$name}{isa} = $TYPES{all}
		if (not defined $object{$called}{has}{$name}{isa});

	if ($object{$called}{has}{$name}{default}) {
		if ($object{$called}{has}{$name}{default} =~ m/^1$/) {
			$object{$called}{has}{$name}{value} = $object{$called}{has}{$name}{build_default}();
		} elsif (ref $object{$called}{has}{$name}{default} eq 'CODE') {
			$object{$called}{has}{$name}{value} = $object{$called}{has}{$name}{default}();
		} else {
			$object{$called}{has}{$name}{value} = $object{$called}{has}{$name}{type} eq 'ordered_hash'
				? deep_clone_ordered_hash($object{$called}{has}{$name}{default})
				: deep_clone($object{$called}{has}{$name}{default});
		}
	}

	if ($object{$called}{has}{$name}{required}) {
		$object{$called}{has}{$name}{required} = \&required;
	}

	if ($object{$called}{has}{$name}{lazy}) {
		push @{$object{$called}{lazy}}, $name;
	}

	if ($object{$called}{has}{$name}{delay}) {
		push @{$object{$called}{delay}}, $name;
	}

	make_keyword($called, $name, sub {
		my ($self, $value) = @_;
		if (@_ > 1 && (
			$object{$called}{has}{$name}->{is} eq 'rw'
				|| [split '::', [caller(1)]->[3]]->[-1] =~ m/^new|build|set_defaults|auto_build$/
		)) {
			if (defined $value) {
				$value = $object{$called}{has}{$name}->{coerce}($self, $value, $name)
					if ($object{$called}{has}{$name}->{coerce});
				$object{$called}{has}{$name}{required}($self, $value, $name)
					if ($object{$called}{$name}->{required});
				$value = $object{$called}{has}{$name}{isa}($value, $name, $called);
				$self->{$name} = $value;
				$object{$called}{has}{$name}{trigger}($self, $value, $name)
					if ($object{$called}{has}{$name}->{trigger});
			} else {
				$self->{$name} = undef;
			}
		}
		$self->{$name};
	}) unless $attribute_extend;
}

sub require_has {
	my ($called) = shift;
	for (@{ $object{$called}{require_has} }) {
		croak sprintf "The required %s attribute is not defined in the %s object.", $_, $called
			if (! $object{$called}{has}{$_} );
	}
}

sub require_sub {
	my ($self, $called) = @_;
	for (@{ $object{$called}{require_sub} }) {
		croak sprintf "The required %s sub is not defined in the %s object.", $_, $called
			if (! $self->can($_) );
	}
}

sub require_method {
	my ($called) = shift;
	for (@{ $object{$called}{require_method} }) {
		croak sprintf "The required %s method is not defined in the %s object.", $_, $called
			if (! $object{$called}{method}{$_} );
	}
}

sub set_defaults {
	my ($self, $called) = @_;
	map {
		defined $object{$called}{has}{$_}{value} && $self->$_($object{$called}{has}{$_}{type} eq 'ordered_hash'
			? deep_clone_ordered_hash($object{$called}{has}{$_}{value})
			: deep_clone($object{$called}{has}{$_}{value}))
	} sort { ($object{$called}{has}{$a}{build_order} || $LAST) <=> ($object{$called}{has}{$b}{build_order} || $LAST) }
		keys %{$object{$called}{has}};
	return $self;
}

sub auto_build {
	my ($self, $called, %build) = (shift, shift, scalar @_ == 1 ? %{ $_[0] } : @_);
	map {
		if ($self->can($_)) {
			$self->$_($build{$_});
		}
	} sort { ($object{$called}{has}{$a}{build_order} || $LAST) <=> ($object{$called}{has}{$b}{build_order} || $LAST) }
		keys %build;
}

sub auto_ld {
	my ($self, $called, $type) = @_;
	map {
		my $cb_value = ref $object{$called}{has}{$_}{$type} || $object{$called}{has}{$_}{$type} !~ m/^1$/ ? $object{$called}{has}{$_}{$type} : $object{$called}{has}{$_}{build_default}->();
		$self->$_($cb_value);
	} sort {
		($object{$called}{has}{$a}{build_order} || $LAST) <=> ($object{$called}{has}{$b}{build_order} || $LAST)
	} @{ $object{$called}{$type} };
}

sub required {
	my ($self, $value, $name) = @_;
	if ( not defined $value ) {
		croak sprintf "No defined value passed to the required %s attribute.",
			$name;
	}
}

sub any { $_[0] }

sub build_string { "" }

sub string {
	my ($value, $name) = @_;
	if (ref $value) {
		croak sprintf "The value passed to the %s attribute does not match the string type constraint.",
			$name;
	}
	return $value;
}

sub build_integer { 0 }

sub integer {
	my ($value, $name) = @_;
	if (ref $value || $value !~ m/^\d+$/) {
		croak sprintf "The value passed to the %s attribute does not match the type constraint.",
			$name;
	}
	return $value;
}

sub build_float { 0.00 }

sub float {
	my ($value, $name) = @_;
	if (ref $value || $value !~ m/^\d+\.\d+$/) {
		croak sprintf "The value passed to the %s attribute does not match the float constraint.",
			$name;
	}
	return $value;
}

sub build_scalarref { \"" }

sub scalarref {
	my ($value, $name) = @_;
	if (ref $value ne 'SCALAR' ) {
		croak sprintf "The value passed to the %s attribute does not match the scalarref constraint.",
			$name;
	}
	return $value;
}

sub build_boolean { \1 }

sub boolean {
	my ($value, $name) = @_;
	if (! ref $value) {
		$value = \!!$value;
	}
	if (ref $value ne 'SCALAR' ) {
		croak sprintf "The value passed to the %s attribute does not match the scalarref constraint.",
			$name;
	}
	return $value;
}

sub build_ordered_hash { { } }

sub ordered_hash { hash(@_); }

sub typed_hash { 
	my ($value, $name, $called) = @_;

	if (ref $value ne 'Hash::Typed') {
		my $hash = $object{$called}{has}{$name}{value};

		if (!$hash) {
			croak sprintf "The value passed to the %s attribute does not match the typed_hash constraint.",
				$name;
		}

		set_typed_hash($hash, $value);

		$value = $hash;
	}

	return $value;
}

sub set_typed_hash {
	my ($hash, $value) = @_;

	for my $k (keys %{$value}) {
		if (ref $hash->{$k} eq 'Hash::Typed') {
			$hash->{$k} = set_typed_hash($hash->{$k}, $value->{$k});
		} else {
			$hash->{$k} = $value->{$k};
		}
	}
	
	for my $k (keys %{ $hash }) {
		if (! exists $value->{$k}) {
			delete $hash->{$k};
		}
	}
	
	return $hash;
}


sub build_hash { {} }

sub hash {
	my ($value, $name) = @_;
	if (ref $value ne 'HASH') {
		croak sprintf "The value passed to the %s attribute does not match the hash type constraint.",
			$name;
	}
	return $value;
}

sub build_array { [] }

sub array {
	my ($value, $name) = @_;
	if (ref $value ne 'ARRAY') {
		croak sprintf "The value passed to the %s attribute does not match the array type constraint.",
			$name;
	}
	return $value;
}

sub fh {
	my ($value, $name) = @_;
	if (ref $value ne 'GLOB') {
		croak sprintf "The value passed to the %s attribute does not match the glob type constraint.",
			$name;
	}
	return $value;
}

sub build_object { { } }

sub object {
	my ($value, $name) = @_;
	if ( ! ref $value || ref $value !~ m/SCALAR|ARRAY|HASH|GLOB/) {
		croak sprintf "The value passed to the %s attribute does not match the object type constraint.",
			$name;
	}
	return $value;
}

sub deep_clone {
	my ($data) = @_;
	my $ref = ref $data;
	if (!$ref) { return $data; }
	elsif ($ref eq 'SCALAR') { my $r = deep_clone($$data); return \$r; }
	elsif ($ref eq 'ARRAY') { return [ map { deep_clone($_) } @{ $data } ]; }
	elsif ($ref eq 'HASH') { return { map +( $_ => deep_clone($data->{$_}) ), keys %{ $data } }; }
	return $data;
}

sub deep_clone_ordered_hash {
	my (@hash) = scalar @_ == 1 ? %{ $_[0] } : @_;
	my %hash = ();
        tie(%hash, 'Tie::IxHash');
	while (@hash) {
		my ($key, $value) = (shift @hash, shift @hash);
		$hash{$key} = deep_clone($value)
	}
	return \%hash;
}

sub load {
	my ($module) = shift;
	$module =~ s/\:\:/\//g;
	require $module . '.pm';
}

1

__END__

=head1 NAME

YAOO - Yet Another Object Orientation

=head1 VERSION

Version 0.10

=cut

=head1 SYNOPSIS

	package Synopsis;

	use YAOO;

	auto_build;

	has moon => ro, isa(hash(a => "b", c => "d", e => [qw/1 2 3/], f => { 1 => { 2 => { 3 => 4 } } })), lazy, build_order(3);

	has stars => rw, isa(array(qw/a b c d/)), lazy, build_order(3);

	has satellites => rw, isa(integer), lazy, build_order(2);

	has mind => rw, isa(ordered_hash(
		chang => 1,
		zante => 2,
		oistins => 3
	)), lazy, build_order(1);

	has [qw/look up/] => isa(string), delay, coerce(sub {
		my $followed = [qw/moon starts satellites/]->[int(rand(3))];
		$_[0]->$followed;
	});

	has clouds => isa(
		typed_hash(
			[
				strict => 1, 
				required => [qw/a b c/], 
				keys => [
					moon => Int, 
					stars => Str, 
					satellites => typed_hash([keys => [ mind => Str ]], %{$_[0]})
				], 
			],
			moon => 211, 
			stars => 'test'
			satellites => { custom => 'after', mind => 'abc', },
		)
	);

	1;

	...

	Synopsis->new( satellites => 5 );

	$synopsis->mind->{oistins};

	...

	package Life;

	extends 'Synopsis';

	requires_has qw/moon stars satellites mind/

	1;

=cut

=head1 keywords

The following keywords are exported automatically when you declare the use of YAOO.

=cut

=head2 has

Declare an attribute/accessor.

	has one => ro, isa(object);

=cut

=head2 ro

Set the attribute to read only, so it can only be set on instantiation of the YAOO object.

	has two => ro;

=cut

=head2 rw

Set the attribute tp read write, so it can be set at any time. This is the default if you do not provide ro or rw when declaring your attribute.

	has three => rw;

=cut

=head2 isa

Declare a type for the attribute, see the types below for all the current valid options.

	has four => isa(any($default_value));

=cut

=head3 any

Allow any value to be set for the attribute.

	has five => isa(any);

=cut

=head3 string

Allow only string values to be set for the attribute.

	has six => isa(string);

=cut

=head3 scalarref

Allow only scalar references to be set for the attribute.

	has seven => isa(scalarref);

=cut

=head3 integer

Allow only integer values to be be set for the attribute.

	has eight => isa(integer(10));

=cut

=head3 float

Allow only floats to be set for the attribute.

	has nine => isa(float(211.11));

=cut

=head3 boolean

Allow only boolean values to be set for the attribute.

	has ten => isa(boolean(\1));

=cut

=head3 ordered_hash

Allow only hash values to be set for the attribute, this will also assist with declaring a ordered hash which has a predicatable order for the keys based upon how it is defined.

	has eleven => isa(ordered_hash( one => 1, two => 2, three => 3 ));

=cut

=head3 hash

Allow only hash values to be set for the attribute.

	has twelve => isa(hash);

=cut

=head3 array

Allow only array values to be set for the attribute.

	has thirteen => isa(array);

=cut

=head3 object

Allow any object to be set for the attribute.

	has fourteen => isa(object);

=cut

=head3 fh

Allow any file handle to be set for the attribute

	has fifthteen => isa(fh);

=cut

=head2 default

Set the default value for the attribute, this can also be done by passing in the isa type.

	has sixteen => isa(string), default('abc');

=cut

=head2 coerce

Define a coerce sub routine so that you can manipulate the passed value when ever it is set.

	has seventeen => isa(object(1)), coerce(sub {
		JSON->new();
	});

=cut

=head2 required

Define a required sub routing so that you can dynamically check for required keys/values for the given attribute.

	has eighteen => isa(hash) required(sub {
		die "the world is a terrible place" if not $_[1]->{honesty};
	});

=cut

=head2 trigger

Define a trigger sub which is called after the attribute has been set..

	has nineteen => isa(hash) trigger(sub {
		$_[0]->no_consent;
	});

=cut

=head2 lazy

Make the attribute lazy so that it is instantiated early.

	has twenty => isa(string('Foo::Bar')), lazy;

=cut

=head2 delay

Make the attribute delayed so that it is instantiated late.

	has twenty_one => isa(object), delay, coerce(sub { $_[0]->twenty->new });

=cut

=head2 build_order

Configure a build order for the attributes, this allows you to control the order in which they are 'set'.

	has twenty_two => isa(string), build_order(18);

=cut

=head2 extends

Declare inheritance.

	extends 'Moonlight';

=cut

=head2 requires_has

Decalre attributes that must exist in the inheritance of the object.

	require_has qw/one two three/

=cut

=head2 requires_sub

Declare sub routines/methods that must exist in the inheritance of the object.

	require_sub qw/transparency dishonesty/

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-yaoo at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=YAOO>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc YAOO


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=YAOO>

=item * Search CPAN

L<https://metacpan.org/release/YAOO>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022->2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of YAOO
