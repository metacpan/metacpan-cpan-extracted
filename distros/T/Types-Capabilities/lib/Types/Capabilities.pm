use 5.010001;
use strict;
use warnings;

package Types::Capabilities;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002001';

use Type::Library -base;

use Class::Method::Modifiers ();
use Sub::HandlesVia::CodeGenerator ();
use Sub::HandlesVia::Handler ();
use Sub::HandlesVia::HandlerLibrary::Array ();
use Types::Capabilities::Constraint ();

my $_munge_handler = sub {
	my $handler = shift;
	return ref( $handler )->new( %$handler, prefer_shift_self => 0 );
};

BEGIN {
	# I don't like doing this, but curried arguments are breaking things...

	*Sub::HandlesVia::HandlerLibrary::Array::peek = sub {
		return Sub::HandlesVia::Handler->new(
			name      => 'Array:peek',
			args      => 0,
			template  => '($GET)->[0]',
		);
	};

	*Sub::HandlesVia::HandlerLibrary::Array::peekend = sub {
		return Sub::HandlesVia::Handler->new(
			name      => 'Array:peekend',
			args      => 0,
			template  => '($GET)->[0]',
		);
	};

	push @Sub::HandlesVia::HandlerLibrary::Array::METHODS, qw( peek peekend );
};

do {
	my $array_class = 'Types::Capabilities::CoercedValue::ARRAYREF';

	my @array_capabilities = (
		[ 'Mappable'    => { 'map'      => 'map'      } => [ 'map' ]         ],
		[ 'Greppable'   => { 'grep'     => 'grep'     } => [ 'grep' ]        ],
		[ 'Sortable'    => { 'sort'     => 'sort'     } => [ 'sort' ]        ],
		[ 'Reversible'  => { 'reverse'  => 'reverse'  } => [ 'reverse' ]     ],
		[ 'Countable'   => { 'count'    => 'count'    } => undef             ],
		[ 'Joinable'    => { 'join'     => 'join'     } => undef             ],
		[ 'Eachable'    => { 'each'     => 'for_each' } => undef             ],
	);

	my %already;

	for my $capability ( @array_capabilities ) {
		my ( $cap_name, $cap_methods, $need_wrapper ) = @$capability;
		my $lc_cap_name = lc $cap_name;
		
		my $cap_type = __PACKAGE__->get_type($cap_name) || __PACKAGE__->add_type(
			Types::Capabilities::Constraint->new(
				name    => $cap_name,
				methods => [ sort keys %$cap_methods ],
				autobox => $array_class,
			)
		);

		my $cg = Sub::HandlesVia::CodeGenerator->new(
			target                     => $array_class,
			generator_for_slot         => sub { return '$_[0]' },
			generator_for_get          => sub { return '$_[0]' },
			generator_for_set          => sub { return '$_[0] = ' . pop; },
			generator_for_default      => sub { return '[]'; },
			generator_for_usage_string => sub { "\$@{[ $lc_cap_name ]}->@{[ $_[1] ]}(@{[ $_[2] ]})" }
		);

		for my $method ( sort keys %$cap_methods ) {
			next if $already{$method}++;
			Sub::HandlesVia::Handler
				->lookup( $cap_methods->{$method}, 'Array' )
				->loose
				->$_munge_handler
				->install_method( method_name => $method, code_generator => $cg );
		}

		Class::Method::Modifiers::install_modifier(
			$array_class,
			'around',
			@$need_wrapper,
			sub {
				my $next = shift;
				wantarray ? $next->(@_) : $cap_type->coerce( [ $next->(@_) ] );
			},
		) if defined $need_wrapper;
	}
};

do {
	my $array_class = 'Types::Capabilities::CoercedValue::QUEUE';

	my @array_capabilities = (
		[ 'Enqueueable' => { 'enqueue'  => 'push...'  } => undef             ],
		[ 'Dequeueable' => { 'dequeue'  => 'shift'    } => undef             ],
		[ 'Peekable'    => { 'peek'     => 'peek'     } => undef             ],
	);

	my %already;

	for my $capability ( @array_capabilities ) {
		my ( $cap_name, $cap_methods, $need_wrapper ) = @$capability;
		my $lc_cap_name = lc $cap_name;
		
		my $cap_type = __PACKAGE__->get_type($cap_name) || __PACKAGE__->add_type(
			Types::Capabilities::Constraint->new(
				name    => $cap_name,
				methods => [ sort keys %$cap_methods ],
				autobox => $array_class,
			)
		);

		my $cg = Sub::HandlesVia::CodeGenerator->new(
			target                     => $array_class,
			generator_for_slot         => sub { return '$_[0]' },
			generator_for_get          => sub { return '$_[0]' },
			generator_for_set          => sub { return '$_[0] = ' . pop; },
			generator_for_default      => sub { return '[]'; },
			generator_for_usage_string => sub { "\$@{[ $lc_cap_name ]}->@{[ $_[1] ]}(@{[ $_[2] ]})" }
		);

		for my $method ( sort keys %$cap_methods ) {
			next if $already{$method}++;
			Sub::HandlesVia::Handler
				->lookup( $cap_methods->{$method}, 'Array' )
				->loose
				->$_munge_handler
				->install_method( method_name => $method, code_generator => $cg );
		}
	}
};

do {
	my $array_class = 'Types::Capabilities::CoercedValue::STACK';
	
	my @array_capabilities = (
		[ 'Pushable'    => { 'push'     => 'push...'  } => undef             ],
		[ 'Poppable'    => { 'pop'      => 'pop'      } => undef             ],
		[ 'Peekable'    => { 'peek'     => 'peekend'  } => undef             ],
	);
	
	my %already;
	
	for my $capability ( @array_capabilities ) {
		my ( $cap_name, $cap_methods, $need_wrapper ) = @$capability;
		my $lc_cap_name = lc $cap_name;
		
		my $cap_type = __PACKAGE__->get_type($cap_name) || __PACKAGE__->add_type(
			Types::Capabilities::Constraint->new(
				name    => $cap_name,
				methods => [ sort keys %$cap_methods ],
				autobox => $array_class,
			)
		);
		
		my $cg = Sub::HandlesVia::CodeGenerator->new(
			target                     => $array_class,
			generator_for_slot         => sub { return '$_[0]' },
			generator_for_get          => sub { return '$_[0]' },
			generator_for_set          => sub { return '$_[0] = ' . pop; },
			generator_for_default      => sub { return '[]'; },
			generator_for_usage_string => sub { "\$@{[ $lc_cap_name ]}->@{[ $_[1] ]}(@{[ $_[2] ]})" }
		);
		
		for my $method ( sort keys %$cap_methods ) {
			next if $already{$method}++;
			Sub::HandlesVia::Handler
				->lookup( $cap_methods->{$method}, 'Array' )
				->loose
				->$_munge_handler
				->install_method( method_name => $method, code_generator => $cg );
		}
	}
};

__PACKAGE__->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Types::Capabilities - don't care what type of data you are given, just what you can do with it

=head1 SYNOPSIS

  package LineFilter {
    use Moo;
    use Type::Params 'signature_for';
    use Types::Capabilities 'Greppable';
    use Types::Standard 'RegexpRef';
    
    has regexp => ( is => 'ro', isa => RegexpRef, required => 1 );
    
    signature_for print_matching_lines => (
      method     => 1,
      positional => [ Greppable ],
    );
    
    sub print_matching_lines ( $self, $source ) {
      my $re = $self->regexp;
      for my $line ( $source->grep( sub { /$re/ } ) ) {
        print $line, "\n";
      }
    }
  }
  
  my $greetings = LineFilter->new( regexp => qr/Hello/ );
  $greetings->print_matching_lines( [ 'Hello world', 'Goodbye' ] );

=head1 DESCRIPTION

This module allows you to indicate when you are designing your API that you
don't care exactly what type of object is passed to you, as long as it's
"greppable" or "sortable" or some other capability you want from the object.

In particular, in the L</SYNOPSIS> example, the signature is checking that
whatever value is provided for C<< $source >>, it must offer a C<grep>
method. Exactly what the C<grep> method does isn't checked by the type
constraint, but the expected behaviour is that it must accept a coderef
and, in list context, return the values matching the grep as a list.

The key feature that this module provides is that if C<< $source >> is
I<not> an object with a C<grep> method, but is an array ref or an object
which overloads C<< @{} >>, then it will be coerced into an object with
a C<grep> method.

=head1 CONSTRAINTS

This module is a L<Type::Library>-based type constraint library and provides
the following constraints.

=head2 Constraints for Collection-Like Objects

=over

=item B<Mappable>

An object which provides a C<map> method.

The expectation is that the method should accept a coderef which transforms
a single item in a collection. Called in list context, it should return the
result of applying that to all items in that collection. The results of
calling C<map> in scalar context are not specified, but it may return another
collection-like object which further operations can be carried out on.

Can be coerced from B<ArrayRef>, B<Greppable>, B<Eachable>, or B<ArrayLike>.

=item B<Greppable>

An object which provides a C<grep> method.

The expectation is that the method should accept a coderef which returns
a boolean for each item in a collection. Called in list context, it should
return items in that collection where the coderef returned true. The results of
calling C<grep> in scalar context are not specified, but it may return another
collection-like object which further operations can be carried out on.

Can be coerced from B<ArrayRef>, B<Mappable>, B<Eachable>, or B<ArrayLike>.

=item B<Sortable>

An object which provides a C<sort> method.

The expectation is that the method should accept a coderef which compares two
items, returning 1 if they are in the correct order, -1 if they are in the wrong
order, and 0 if the two items are of equivalent order. Called in list context,
it should return all the items in the collection sorted according to the
coderef. The results of calling C<sort> in scalar context are not specified, but
it may return another collection-like object which further operations can be
carried out on.

Can be coerced from B<ArrayRef>, B<Mappable>, B<Greppable>, B<Eachable>,
or B<ArrayLike>.

=item B<Reversible>

An object which provides a C<reverse> method.

The expectation is that when the method is called in list context, it should
return all the items in the collection in reverse order. The results of calling
C<reverse> in scalar context are not specified, but it may return another
collection-like object which further operations can be carried out on.

Can be coerced from B<ArrayRef>, B<Mappable>, B<Greppable>, B<Eachable>,
or B<ArrayLike>.

=item B<Countable>

An object which provides a C<count> method.

The expectation is that when the method is called in scalar context, it should
return the number of items in the collection.

Can be coerced from B<ArrayRef>, B<Mappable>, B<Greppable>, B<Eachable>,
or B<ArrayLike>.

=item B<Joinable>

An object which provides a C<join> method.

The expectation is that when the method is called in scalar context, it should
return a single item that is caused by joining all the items in the collection
together, typically via string concatenation. The method may be passed a value
to use as a separator; if no separator is given, the method may use a default
separator, typically something like "," or the empty string.

Can be coerced from B<ArrayRef>, B<Mappable>, B<Greppable>, B<Eachable>,
or B<ArrayLike>.

=item B<Eachable>

An object which provides an C<each> method.

The expectation is that when the method is called in void context and passed
a coderef, it should call the coderef for each item in the collection.

Can be coerced from B<ArrayRef>, B<Mappable>, B<Greppable>, or B<ArrayLike>.

=back

=head3 Constraints for Queue-Like Objects

=over

=item B<Enqueueable>

An object which provides an C<enqueue> method.

The expectation is that the method can be called with a single item to add
that item to the end of the collection.

Can be coerced from B<ArrayRef>, B<Mappable>, B<Greppable>, B<Eachable>,
or B<ArrayLike>.

=item B<Dequeueable>

An object which provides a C<dequeue> method.

The expectation is that when the method is called in a scalar context, it
will remove an item from the front of the collection and return it.

Can be coerced from B<ArrayRef>, B<Mappable>, B<Greppable>, B<Eachable>,
or B<ArrayLike>.

=item B<Peekable>

An object which provides a C<peek> method.

The expectation is that when the method is called in a scalar context, it
will return an item from the collection without altering the collection.

When used with a queue-like collection, it is expected to return the item
at the front/start of the collection; the item which would be returned by
C<dequeue>. When used with a stack-like collection, it is expected to return
the item at the back/end of the collection; the item which would be returned
by C<pop>. Otherwise, which item it returns is unspecified.

Can be coerced from B<ArrayRef>, B<Mappable>, B<Greppable>, B<Eachable>,
or B<ArrayLike>.

=back

=head3 Constraints for Stack-Like Objects

=over

=item B<Pushable>

An object which provides a C<push> method.

The expectation is that the method can be called with a single item to add
that item to the end of the collection. (This behaviour is essentially the
same as C<enqueue>.)

Can be coerced from B<ArrayRef>, B<Mappable>, B<Greppable>, B<Eachable>,
or B<ArrayLike>.

=item B<Poppable>

An object which provides a C<pop> method.

The expectation is that when the method is called in a scalar context, it
will remove an item from the end of the collection and return it.

Can be coerced from B<ArrayRef>, B<Mappable>, B<Greppable>, B<Eachable>,
or B<ArrayLike>.

=item B<Peekable>

See description above.

=back

=head2 Combined Capabilities

It is possible to specify that you need an object to provide multiple
capabilities:

  has task_queue => (
    is      => 'ro',
    isa     => Enqueueable & Dequeueable & Countable & Peekable,
    coerce  => 1,
  );

General collection-like capabilities (like C<Eachable> and C<Countable>)
may be combined with queue-like and stack-like capabilities.

=head3 Combining Conflicting Capabilities

Combining queue-like and stack-like capabilities with each other will work,
but the coercion feature will stop working and you will need to design your
own class to implement those capabilities.

  has task_queue => (
    is      => 'ro',
    isa     => ( Enqueueable & Poppable )
                 ->plus_coercions( ArrayRef, sub { MyClass->new($_) } ),
    coerce  => 1,
  );

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-types-capabilities/issues>.

=head1 SEE ALSO

Largely inspired by: L<Data::Collection>.

L<Sub::HandlesVia>, L<Hydrogen::Autobox>.

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

