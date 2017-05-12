package Unexpected::TraitFor::Throwing;

use namespace::autoclean;

use Carp                    ( );
use English               qw( -no_match_vars );
use Scalar::Util          qw( blessed );
use Unexpected::Functions qw( is_one_of_us parse_arg_list );
use Unexpected::Types     qw( Maybe Object );
use Moo::Role;

requires qw( BUILD );

# Private functions
my $_cache_key = sub {
   # uncoverable branch true
   return $PID.'-'.(exists $INC{ 'threads.pm' } ? threads->tid() : 0);
};

my $_exception_cache = {};

# Public attributes. Lifted from Throwable
has 'previous_exception' => is => 'ro', isa => Maybe[Object],
   builder               => sub { $_exception_cache->{ $_cache_key->() } };

# Construction
after 'BUILD' => sub {
   my $self = shift; my $e = $self->clone; delete $e->{previous_exception};

   $_exception_cache->{ $_cache_key->() } = $e;

   return;
};

# Private methods
my $_is_object_ref = sub {
   my ($self, @args) = @_; blessed $self or return 0;

   scalar @args and Carp::confess
      'Trying to throw an Exception object with arguments';
   return 1;
};

# Public methods
sub caught {
   my ($self, @args) = @_;

   $self->$_is_object_ref( @args ) and return $self;

   my $attr  = parse_arg_list @args;
   my $error = $attr->{error} ||= $EVAL_ERROR; $error or return;

   return (is_one_of_us $error) ? $error : $self->new( $attr );
}

sub clone {
   my ($self, $args) = @_;

   my $class = blessed $self or $self->throw( 'Clone is an object method' );

   return bless { %{ $self }, %{ $args // {} } }, $class;
}

sub throw {
   my ($self, @args) = @_;

   $self->$_is_object_ref( @args ) and die $self;
   is_one_of_us $args[ 0 ]         and die $args[ 0 ];
                                       die $self->new( @args );
}

sub throw_on_error {
   my $e; $e = shift->caught( @_ ) and die $e; return;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Unexpected::TraitFor::Throwing - Detects and throws exceptions

=head1 Synopsis

   use Moo;

   with 'Unexpected::TraitFor::Throwing';

=head1 Description

Detects and throws exceptions

=head1 Configuration and Environment

Modifies C<BUILD> in the consuming class. Caches the new exception for
use by the C<previous_exception> attribute in the next exception thrown

Requires the consuming class to have the class method C<is_one_of_us>

Defines the following list of attributes;

=over 3

=item C<previous_exception>

May hold a reference to the previous exception in this thread

=back

=head1 Subroutines/Methods

=head2 BUILD

After construction the current exception is cached so that it can become
the previous exception the next time an exception is thrown

=head2 caught

   $exception_object_ref = Unexpected->caught( @optional_args );

Catches and returns a thrown exception or generates a new exception if
C<$EVAL_ERROR> has been set. Returns either an exception object or undefined

=head2 clone

   $cloned_exception_object_ref = $exception_object_ref->clone( $args );

Returns a clone of the invocant. The optional C<$args> hash reference mutates
the returned clone

=head2 throw

   Unexpected->throw 'Path [_1] not found', args => [ 'pathname' ];

Create (or re-throw) an exception. If the passed parameter is a
blessed reference it is re-thrown. If a single scalar is passed it is
taken to be an error message, a new exception is created with all
other parameters taking their default values. If more than one
parameter is passed the it is treated as a list and used to
instantiate the new exception. The 'error' parameter must be provided
in this case

=head2 throw_on_error

   Unexpected->throw_on_error( @optional_args );

Calls L</caught> passing in the options C<@args> and if there was an
exception L</throw>s it otherwise returns undefined

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<namespace::autoclean>

=item L<Moo::Role>

=item L<Unexpected::Types>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2017 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
