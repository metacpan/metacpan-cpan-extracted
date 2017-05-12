package WebService::MyGengo::Exception;

use Moose;

with 'Throwable';

use Carp;
use Scalar::Util qw(blessed);

use overload( '""', sub { shift->message } );

=head1 NAME

WebService::MyGengo::Exception - Exception class for the WebService::MyGengo library.

=head1 SYNOPSIS

    eval { my $job = $client->get_job( "ARGH!" ) };
    if ( blessed($@) eq 'WebService::MyGengo::Exception' ) {
        printf "Exception: %s\n", $@->message;
    }

=head1 DESCRIPTION

All exceptions thrown by operations in the WebService::MyGengo library will be
instances of this object.

B<Note:> Unless specified otherwise, errors from the transport layer
are not caught and wrapped with this class.

=head1 ATTRIBUTES

=head2 message (Str)

The error message.

Object stringification is overloaded to return this attribute.

    eval { <something that throws an Exception> };
    print "Oops: '$@'\n"; # Prints the Exception message

=cut
has message => (
    is          => 'ro'
    , isa       => 'Str'
    , lazy      => 1
    , default   => "No message provided."
    );

=head2 stacktrace (Str)

A stacktrace from the point where the Exception was thrown.

The previous_exception attribute holds any previous exceptions.

See: L<Throwable>

=cut
has stacktrace => (
    is          => 'ro'
    , isa       => 'Str'
    , default   => sub { Carp::longmess() }
    );


no Moose;
__PACKAGE__->meta->make_immutable;

1;

=head1 AUTHOR

Nathaniel Heinrichs

=head1 LICENSE

Copyright (c) 2011, Nathaniel Heinrichs <nheinric-at-cpan.org>.
All rights reserved.

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
