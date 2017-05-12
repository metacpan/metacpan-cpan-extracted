package enum::fields::extending;

use 5.00503;
use strict;
use vars qw($VERSION %class_info %final);
use Carp;

use enum::fields;

$VERSION = 1.0;

sub import {

    shift;
    
    croak "No parent class specified" unless (@_);
    
    my $class = caller();
    my $idx = 0;
    
    my $extclass = shift;
    
    croak $@ if ($@);
    
    croak "Connot extend from parent class if this class already has fields" 
        if exists($class_info{$class});
    
    croak "Cannot add fields to class that has been inherited"
        if exists($final{$class});
    
    $class_info{$extclass} = [] unless exists($class_info{$extclass});
    $final{$extclass} = 1;

    for my $fld (@{$class_info{$extclass}}, @_) {
    
        define_constant($class, $fld, $idx++);

        $class_info{$class} = [] unless exists($class_info{$class});
        push @{$class_info{$class}}, $fld;
    }
}

1;
