package OpenTracing::Implementation::Test::SpanContext;

our $VERSION = 'v0.101.2';

use Moo;
use Types::Standard qw/Int/;
use Bytes::Random::Secure qw/random_string_from/;

with 'OpenTracing::Role::SpanContext';

has '+span_id' => (
    default => \&_random_id,
);

has '+trace_id' => (
    default => \&_random_id,
);

has level => (
    is      => 'ro',
    isa     => Int,
    default => sub { 0 },
);

has context_item => (
    is      => 'ro',
    default => sub { 'default context item' },
);

sub with_level { $_[0]->clone_with( level => $_[1] ) }

sub with_next_level { $_[0]->with_level($_[0]->level +1) }

sub _random_id {
    random_string_from '0123456789abcdef', 7
}

sub with_context_item { $_[0]->clone_with(context_item => $_[1]) }

1;
__END__
=pod

=head1 NAME

OpenTracing::Implementation::Test::SpanContext - OpenTracing Test for SpanContext

=head1 DESCRIPTION

This is the C<SpanContext> used by L<OpenTracing::Implementation::Test>.
The following attributes are provided on top of L<OpenTracing::Role::SpanContext>:

=head2 level

The context will know how deep in the span hierarchy it is.
The root is always level 0.

=head2 context_item

This attributes actually does nothing. You can use it to test any code
which should set context attributes without having to subclass.

=head1 METHODS

=head2 level()

Returns the depth of the span (number of parent spans) in the hierarchy.

=head2 with_level($level)

Create a cloned object with with the new $level.

=head2 with_next_level()

Create a cloned object with C<level> increased by one.

=head2 with_context_item($new_item)

Create a cloned object with $new_item as C<context_item>.



=head1 AUTHOR

Szymon Nieznanski <snieznanski@perceptyx.com>



=head1 COPYRIGHT AND LICENSE

'Test::OpenTracing::Integration'
is Copyright (C) 2019 .. 2020, Perceptyx Inc

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

This package is distributed in the hope that it will be useful, but it is
provided "as is" and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.

=cut
