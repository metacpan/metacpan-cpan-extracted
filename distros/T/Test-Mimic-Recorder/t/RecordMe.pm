package RecordMe;

use strict;
use warnings;

use Mom;
use Dad;

use constant {
    PI => 3, #.141592...
    ARR => [ qw( a b c d e f g h i j k l m n o p q r s t u v w x y z ) ],
};

our @ISA = qw( Mom Dad );
our $scalar_state;
our @array_state;
our %hash_state;

sub import {
    print "Importing\n";
}

sub new {
    bless {};
}

sub pos_or_neg {
    if ( $_[0] > 0 ) {
        'positive';
    } elsif ( $_[0] < 0 ) {
        'negative';
    } else {
        'zero';
    }
}

sub put {
    $_[0]->{$_[1]} = $_[2];
}

sub get {
    $_[0]->{$_[1]};
}

sub throw {
    if ($_[0]) {
        die "throw threw";
    } else {
        return "alive and well";
    }
}

sub with_prototype ($@) {
    return 'with_implicit_context_coercion_template_for_input_parameters if Tom Christiansen had his way. ;)';
    # That's a much better name. Seriously.
}

1;
