#-------------------------------------------------------------------------------
#      $URL$
#     $Date$
#   $Author$
# $Revision$
#-------------------------------------------------------------------------------
package Wetware::Test::Suite;

use strict;
use warnings;

use Carp;
use Test::More;

use Wetware::Test::Class;
use base q{Wetware::Test::Class};

our $VERSION = 0.04;

#-----------------------------------------------------------------------------

sub class_under_test { Carp::confess('Must override in sub-class.') }

#-----------------------------------------------------------------------------
# STOP!!!! DO NOT LOAD ANY tests into this Class! Since This Class
# has the exception that will be THROWN IF class_under_test() is 
# called, and the 'Test()' will force the call to _apply_handler_AH_()
# in Attributes::Handlers....
#
# Wished i could find a simpler way. But, that gave me the idea for
# doing the Wetare::Test::CreateTestSuite
#
# REPEAT! This is a problem with the 'use thing that inherits this'
# it is not a problem with the calling 'code' 
# 
# sub test_new : Test(1) {
#     my $self           = shift;
#     my $object         = $self->object_under_test();
#     my $expected_class = $self->class_under_test();
# 
#     Test::More::isa_ok( $object, $expected_class );
#     return $self;
# }

#-----------------------------------------------------------------------------

sub set_up : Test(setup) {
    my ($self, %params)  = @_;
    $self->new_object_under_test_for(%params);
    return $self;
}
#-----------------------------------------------------------------------------

sub new_object_under_test_for {
    my ($self, %params)  = @_;
    my $class = $self->class_under_test();
    $self->{$class} = $class->new(%params);
    return $self->{$class};
}
#-----------------------------------------------------------------------------

sub object_under_test {
    my $self  = shift;
    my $class = $self->class_under_test();
    return $self->{$class};
}
#-----------------------------------------------------------------------------

sub tear_down : Test(teardown) {
    my $self = shift;
    my $class = $self->class_under_test();
    delete $self->{$class}; # the $class needs to be deleted from $self.
    return $self;
}
#-------------------------------------------------------------------------------

1; 

__END__

=pod

=head1 NAME

Wetware::Test::Suite - Basic Test::Class methods

=head1 SYNOPSIS

    use Wetware::Test::Suite;
	use base q{Wetware::Test::Suite};

=head1 DESCRIPTION

This module inherits from Wetware::Test::Class, so it will
be useable within the Test::Class::Load approach.

This module provides the five common methods that are used
over and over and over again in a Test::Class apporach to
providing appropriate test coverage.

This makes creating the simple starter test case really simple

=over

 sub test_new_method_name  : Test(1) {
   my $self = shift;
   my $class = $self->class_under_test();
   Test::More::can_ok($class, 'new_method_name');
   return $self;
 }

=back

Which is a great wayt to make sure that one is not starting
a new method that one has already inherited. 

=head1 Methods

=over

=item test_new()

This will compare that the object_under_test() returned
an object that isa_ok() for the class_under_test


=item class_under_test()

This defines which class is actually under test.

Thus subclasses override this, and put in their class.

=item set_up( [ %params ] )

This is the Test(setup) method - and it calls C<class_under_test()>.
to get the class to construct.

It can take an optional hash of parameters to pass to the constructor.

It will return $self.

It will call C<new_object_under_test_for(%params)> to
create the test object.

=item new_object_under_test_for(%params)

Passes the %params to the class constructor, and
sets the object under.

This can be used to construct a new object, and will
replace the previous one.

Note - if your sub class starts doing interesting things
with the constructor, and there are need for default params,
then overriding this method will make that reasonably simple.

=item object_under_test()

Accessor to the object under test. This way one can do the other
stock test format:

=over

 sub test_new_method_name  : Test(1) {
   my $self = shift;
   my $object = $self->object_under_test();
   Test::More::can_ok($object, 'new_method_name');

   # ever more increasing testing of the object
   # ...

   return $self;
 }
    
=back

in anticipation of actully using the one that was created
by the set_up.

=item tear_down()

Deletes the object under test.

=back

=head1 SEE ALSO

Test::Class

Test::More

Test::Differences - great eq_or_diff_text() method!

Test::Exception - because some things NEED to throw exceptions.

=head1 ACKNOWLEDGEMENTS

I want to thank Matisse Enzer for the introduction to
building up Test::Class based testing. 

I am still debating if we really gain anything with
useing 'class_under_test()' to define the key into $self
where we keep object_under_test.


=head1 AUTHOR

"drieux", C<< <"drieux [AT]  at wetware.com"> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 "drieux", all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
