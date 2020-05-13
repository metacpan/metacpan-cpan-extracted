package Test::OpenTracing::Tester::CanAll;

use strict;
use warnings;

use Test::Builder::Tester;

use Moo;

has [ qw/interface_name interface_methods/ ] => ( is => 'ro', required => 1 );

has interface_class => ( is => 'lazy', init_arg => undef );

sub _build_interface_class {
    my $self = shift;
    join '::',
        'Test::OpenTracing::Interface',
        $self->interface_name()
}

sub run_tests_can_all_ok {
    my $self = shift;
    
    test_out( $self->ok_message );
    $self->test_method_can_all_ok( $self->test_object() );
    test_test( "Tests PASS when 'can_all_ok' for object" );
    
    test_out( $self->ok_message );
    $self->test_method_can_all_ok( $self->test_class_name );
    test_test( "Tests PASS when 'can_all_ok' for class" );
    
    test_out( $self->not_ok_message('MyTest::Empty') );
    test_diag( sort $self->diag_messages );
    test_fail( +20 ); # the test is run at line 48
    $self->test_method_can_all_ok( 'MyTest::Empty' );
    test_test( "Tests FAIL when 'can_all_ok' for bad class" );
    
    return
    
}

sub test_class_name { 'MyTest::' . $_[0]->interface_name }

sub test_method_can_all_ok { shift->test_method('can_all_ok', @_) }

sub test_method {
    my $self = shift;
    my $method_name = shift;
    
    my $test_method = join '::', $self->interface_class, $method_name;
    
    no strict qw/refs/;
    
    $test_method->( @_ )
    # if this above is not line 48, than test_fail, will fail
}

sub test_object { bless {}, $_[0]->test_class_name() }

sub ok_message {
    my $self = shift;
    my $test_class = shift;
    $test_class = $self->test_class_name unless defined $test_class;
    my $interface_name = $self->interface_name;
    return "ok 1 - $test_class->can_all_ok( '$interface_name' )"
}

sub not_ok_message {
    my $ok_message = shift->ok_message( @_ );
    
    return "not $ok_message"
}

sub diag_messages {
    my $self = shift;
    
    my @diag_messages = map {
        "MyTest::Empty->can('$_') failed"
    } @{$self->interface_methods};
    
    return @diag_messages
}


# Since there are is a 'ClassName' type-constraint, it needs to have an ISA
#
package MyTest::Empty;

our @ISA;



1;
