package Test::OpenTracing::Interface;

use strict;
use warnings;

our $VERSION = 'v0.21.0';


package Test::OpenTracing::Interface::Base;

use Moo;

use Scalar::Util qw/blessed/;
use Types::Standard qw/ClassName Object Str/;



has interface_name => (
    is => 'ro',
    isa => Str,
);

has test_this => (
    is => 'ro',
    isa => ClassName | Object,
);

has message => (
    is => 'ro',
    isa => Str,
    predicate => 1,
);

sub this_name {
    my $self = shift;
    
    my $this_name = defined blessed( $self->test_this ) ?
        blessed( $self->test_this ) : $self->test_this;
    
    return $this_name
}



package Test::OpenTracing::Interface::CanAll;

use strict;
use warnings;

use Moo;
extends 'Test::OpenTracing::Interface::Base';

use Test::Builder;
use Types::Standard qw/ArrayRef Str/;



has interface_methods => (
    is => 'ro',
    isa => ArrayRef[ Str ]
);



sub run_tests{
    my $self = shift;
    
    my $test_name = $self->this_name;
    
    my $Test = Test::Builder->new;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    
    no strict qw/refs/;
    my @failures;
    foreach my $test_method ( sort @{$self->interface_methods} ) {
        next if $self->test_this->can($test_method);
        $Test->diag( $self->diag_message($test_method) );
        push @failures, $test_method;
    }
    
    my $ok = scalar @failures ? 0 : 1;
    return $Test->ok( $ok, $self->test_message );
    
}



sub diag_message {
    my $self = shift;
    my $method_name = shift;
    
    my $this_name = $self->this_name();
    
    return "$this_name->can('$method_name') failed"
}



sub test_message {
    my $self = shift;
    
    return $self->message if $self->has_message;
    
    my $this_name = $self->this_name();
    my $interface_name = $self->interface_name;
    
    return "$this_name->can_all_ok( '$interface_name' )"
}



1;
