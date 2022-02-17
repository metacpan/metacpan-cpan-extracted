package YAOO;
use strict; no strict 'refs';
use warnings;
use Carp qw/croak/; use Tie::IxHash;
use feature qw/state/;
use Blessed::Merge;
our $VERSION = '0.06';

our (%TYPES, %object);

sub make_keyword {
	my ($called, $key, $cb) = @_;
	*{"${called}::$key"} = $cb;
}

sub import {
	my ($package, @attributes) = @_;

	my $called = caller();

	for my $is (qw/ro rw/) {
		make_keyword($called, $is, sub { is => $is });
	}

	for my $key (qw/isa default coerce required trigger/) {
		make_keyword($called, $key, sub {
			my (@value) = @_;
			return $key => scalar @value > 1 ? @value : $value[0];
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
						$object{$extend}{has}{$name}->{required}($value, $name)
							if ($object{$extend}{$name}->{required});
						$value = $object{$extend}{has}{$name}->{isa}($value, $name);
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
		set_defaults($self, $called);
		auto_build($self, @_) if ($object{$called}{auto_build});
		$self->build(@_) if ($self->can('build'));
		return $self;
	});
}

sub build_attribute {
	my ($called, $name, @attrs) = @_;

	my $ref = ref $name || 'STRING';
	if ($ref eq 'ARRAY') {
		build_attribute($called, $_, @attrs) for @{ $name };
	} elsif ($ref eq 'HASH') {
		build_attribute($called, $_, %{ $name->{$_} }) for keys %{ $name };
	}

	if ( $object{$called}{has}{$name} ) {
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

	make_keyword($called, $name, sub {
		my ($self, $value) = @_;
		if (defined $value && (
			$object{$called}{has}{$name}->{is} eq 'rw'
				|| [split '::', [caller(1)]->[3]]->[-1] =~ m/^new|build|set_defaults|auto_build$/
		)) {
			$value = $object{$called}{has}{$name}->{coerce}($self, $value, $name)
				if ($object{$called}{has}{$name}->{coerce});
			$object{$called}{has}{$name}{required}($value, $name)
				if ($object{$called}{$name}->{required});
			$value = $object{$called}{has}{$name}{isa}($value, $name);
			$self->{$name} = $value;
			$object{$called}{has}{$name}{trigger}($self, $value, $name)
				if ($object{$called}{has}{$name}->{trigger});
		}
		$self->{$name};
	});
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
	(defined $object{$called}{has}{$_}{value} && $self->$_($object{$called}{has}{$_}{type} eq 'ordered_hash'
		? deep_clone_ordered_hash($object{$called}{has}{$_}{value})
		: deep_clone($object{$called}{has}{$_}{value})
	)) for keys %{$object{$called}{has}};
	return $self;
}

sub auto_build {
	my ($self, %build) = (shift, scalar @_ == 1 ? %{ $_[0] } : @_);

	for my $key (keys %build) {
		$self->$key($build{$key}) if $self->can($key);
	}
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

sub build_boolean { \0 }

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

Version 0.06

=cut

=head1 SYNOPSIS

	package Synopsis;

	use YAOO;

	auto_build;

	has moon => ro, isa(hash(a => "b", c => "d", e => [qw/1 2 3/], f => { 1 => { 2 => { 3 => 4 } } }));

	has stars => rw, isa(array(qw/a b c d/));

	has satellites => rw, isa(integer);

	has mind => rw, isa(ordered_hash(
		chang => 1,
		zante => 2,
		oistins => 3
	));

	has [qw/look up/] => isa(string);

	1;

	...

	Synopsis->new( satelites => 5 );

	$synopsis->mind->{oistins};

	...

	package Life;

	extends 'Synopsis';

	requires_has qw/moon stars satellites mind/

	1;

=cut

=head1 keywords

=cut

=head2 has

=cut

=head2 ro

=cut

=head2 rw

=cut

=head2 isa

=cut

=head3 any

=cut

=head3 string

=cut

=head3 scalarref

=cut

=head3 integer

=cut

=head3 float

=cut

=head3 boolean

=cut

=head3 ordered_hash

=cut

=head3 hash

=cut

=head3 array

=cut

=head3 object

=cut

=head3 fh

=cut

=head2 isa

=cut

=head2 default

=cut

=head2 coerce

=cut

=head2 required

=cut

=head2 trigger

=cut

=head2 extends

=cut

=head2 requires_has

=cut

=head2 requires_sub

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

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/YAOO>

=item * Search CPAN

L<https://metacpan.org/release/YAOO>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of YAOO
