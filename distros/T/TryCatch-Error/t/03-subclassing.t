#!perl -T

use Test::More tests => 12;

package TryCatch::Error::Simple::Base;

use base 'TryCatch::Error';

sub new {
    my $proto = shift;
    my $args  = { @_ };
    
    my $class = ref $proto || $proto;
    my $self = $class->SUPER::new( @_ );
    
    $self->{object} = $args->{object};
    
    return $self;
}

sub get_object {
    my $self = shift;
    
    return $self->{object};
}

sub set_object {
    my $self = shift;
    my $arg  = shift;
    
    $self->{object} = $arg;
    
    return $self;
}

package TryCatch::Error::Simple::Moose;

use MooseX::FollowPBP;
use Moose;

extends 'TryCatch::Error';

has 'object' => (
    is       => 'rw',
    isa      => 'Object',
    default  => undef,
);

__PACKAGE__->meta->make_immutable;
no Moose;
no MooseX::FollowPBP;

package main;

my $be = TryCatch::Error::Simple::Base->new;

is( $be->get_value, 0, 'Correct value' );
is( $be->get_message, '', 'Correct message' );
is( $be->get_object, undef, 'Correct object' );

$be->set_value( 1 );
$be->set_message( 'An error' );
$be->set_object( bless { foo => 'bar' }, 'MyObject' );

is( $be->get_value, 1, 'Correct value' );
is( $be->get_message, 'An error', 'Correct message' );
isa_ok( $be->get_object, 'MyObject' );

my $me = TryCatch::Error::Simple::Moose->new;

is( $me->get_value, 0, 'Correct value' );
is( $me->get_message, '', 'Correct message' );
is( $me->get_object, undef, 'Correct object' );

$me->set_value( 1 );
$me->set_message( 'An error' );
$me->set_object( bless { foo => 'bar' }, 'MyObject' );

is( $me->get_value, 1, 'Correct value' );
is( $me->get_message, 'An error', 'Correct message' );
isa_ok( $me->get_object, 'MyObject' );
