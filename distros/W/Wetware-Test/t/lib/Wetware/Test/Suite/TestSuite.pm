#-------------------------------------------------------------------------------
#      $URL$
#     $Date$
#   $Author$
# $Revision$
#-------------------------------------------------------------------------------
package Wetware::Test::Suite::TestSuite;

use strict;
use warnings;

use Test::Exception;

use Wetware::Test::Suite;
use base q{Wetware::Test::Suite};

our $VERSION = 0.01;

use Wetware::Test::Mock;

#-----------------------------------------------------------------------------

sub class_under_test { return 'Wetware::Test::Mock' }

#-----------------------------------------------------------------------------
# the basic stock test_new()
sub test_new : Test(1) {
    my $self           = shift;
    my $object         = $self->object_under_test();
    my $expected_class = $self->class_under_test();

    Test::More::isa_ok( $object, $expected_class );
    return $self;
}

# nice little illustration of the Test::Exception throws_ok.
sub test_parent_class_under_test : Test(1)  {
    my $self           = shift;
    
	my $exceptionMessage
		= q{Must override in sub-class.};
	Test::Exception::throws_ok {
		$self->SUPER::class_under_test( );
	}
	qr/$exceptionMessage/,
		'class_under_test() in parent - Throws Expected Exception';

    return $self;
}

# this shows two things:
#  1. that the Mock Object will return the expected value.
#  2. the new_object_under_test_for(%params) method
#
sub test_mock_does_autoloading : Test(1) {
    my $self           = shift;
    
    my $expected = 'some value';
    
    my $mock_object = $self->new_object_under_test_for( 'accessor' => $expected );
    my $got = $mock_object->accessor();
    
    Test::More::is($got, $expected, 'mock_does_autoloading');
    
    return $self;
}

#-----------------------------------------------------------------------------

1;