package Unexpected::TraitFor::ExceptionClasses;

use namespace::autoclean;

use Unexpected::Functions qw( inflate_message );
use Moo::Role;

my $ROOT = 'Unexpected'; my $Classes = { $ROOT => {} };

__PACKAGE__->add_exception( 'Unspecified' => {
   parents => $ROOT, error => 'Parameter [_1] not specified' } );

# Public attributes
has 'class' => is => 'ro', isa => sub {
   ($_[ 0 ] and exists $Classes->{ $_[ 0 ] }) or die inflate_message
      ( 'Exception class [_1] does not exist', $_[ 0 ] ) }, default => $ROOT;

# Construction
around 'BUILDARGS' => sub {
   my ($orig, $self, @args) = @_; my $attr = $orig->( $self, @args ); my $class;

   (exists $attr->{class} and $class = $attr->{class}) or return $attr;

   ref $class eq 'CODE' and $class = $attr->{class} = $class->();

   $self->is_exception( $class ) or return $attr;

   for my $k (grep { ! m{ \A parents \z }mx } keys %{ $Classes->{ $class } }) {
      $attr->{ $k } //= $Classes->{ $class }->{ $k };
   }

   return $attr;
};

# Public class methods
sub add_exception {
   my ($self, $class, $args) = @_; $args //= {};

   defined $class or die "Parameter 'exception class' not specified";

   exists $Classes->{ $class }
      and die "Exception class ${class} already exists";

   ref $args ne 'HASH' and $args = { parents => $args };

   my $parents = $args->{parents} //= [ $ROOT ];

   ref $parents ne 'ARRAY' and $parents = $args->{parents} = [ $parents ];

   for my $parent (@{ $parents }) {
      exists $Classes->{ $parent } or die
         "Exception class ${class} parent class ${parent} does not exist";
   }

   $Classes->{ $class } = $args;
   return;
}

sub is_exception {
   return $_[ 1 ] && !ref $_[ 1 ] && exists $Classes->{ $_[ 1 ] } ? 1 : 0;
}

# Public object methods
sub instance_of {
   my ($self, $wanted) = @_; $wanted or return 0;

   ref $wanted eq 'CODE' and $wanted = $wanted->();

   exists $Classes->{ $wanted }
      or die "Exception class ${wanted} does not exist";

   my @classes = ( $self->class );

   while (defined (my $class = shift @classes)) {
      $class eq $wanted and return 1;
      exists $Classes->{ $class }->{parents}
         and push @classes, @{ $Classes->{ $class }->{parents} };
   }

   return 0;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Unexpected::TraitFor::ExceptionClasses - Define an exception class hierarchy

=head1 Synopsis

   package YourExceptionClass;

   use Moo;

   extends 'Unexpected';
   with    'Unexpected::ExceptionClasses';

   __PACKAGE__->add_exception( 'A' );
   __PACKAGE__->add_exception( 'B', { parents => 'A' } );
   __PACKAGE__->add_exception( 'C', 'A' ); # same but shorter
   __PACKAGE__->add_exception( 'D', [ 'B', 'C' ] ); # diamond pattern

   # Then elsewhere
   __PACKAGE__->throw( 'error message', { class => 'C' } );

   # Elsewhere still
   my $e = __PACKAGE__->caught;

   $e->class eq 'C'; # true
   $e->instance_of( 'A' ); # true
   $e->instance_of( 'B' ); # false
   $e->instance_of( 'C' ); # true
   $e->instance_of( 'D' ); # false

=head1 Description

Allows for the creation of an exception class hierarchy. Exception
classes inherit from one or more existing classes, ultimately all
classes inherit from the C<Unexpected> exception class

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<class>

Defaults to C<Unexpected>. Can be used to differentiate different
classes of error. Non default values for this attribute must have been
defined with a call to L</add_exception> otherwise an exception will
be thrown. Oh the irony

=back

Defines the C<Unspecified> exception class with a default error message.
Once the exception class is defined the the following;

   use Unexpected::Functions qw( Unspecified );

will import a subroutine that when called returns it's own name. This is
a suitable value for the C<class> attribute

   YourExceptionClass->throw( class => Unspecified, args => [ 'param name' ] );

=head1 Subroutines/Methods

=head2 BUILDARGS

Applies the default error message if one exists and the attributes for the
soon to be constructed exception lacks one

=head2 add_exception

   YourExceptionClass->add_exception( 'new_classname', [ 'parent1', 'parent2']);

Defines a new exception class. Parent classes must already exist. Default
parent class is C<Unexpected>;

   $class->add_exception( 'new_classname' => {
      parents => [ 'parent1' ], error => 'Default error message [_1]' } );

Sets the default error message for the exception class

When defining your own exception class import and call
L<has_exception|File::DataClass::Functions/has_exception> which will
call this class method. The functions subroutine signature is like
that of C<has> in C<Moo>

=head2 instance_of

   $bool = $exception_obj->instance_of( 'exception_classname' );

Is the exception object an instance of the exception class. Can also pass
a code reference like the exported exception class functions

=head2 is_exception

   $bool = YourExceptionClass->is_exception( 'exception_classname' );

Returns true if the exception class exists as a result of a call to
L</add_exception>

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo::Role>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Unexpected.
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
