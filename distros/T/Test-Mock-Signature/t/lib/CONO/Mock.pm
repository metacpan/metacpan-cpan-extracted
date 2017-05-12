package CONO::Mock;

use strict;
use warnings;

require Test::Mock::Signature;
our @ISA = qw(Test::Mock::Signature);

our $CLASS = 'CONO::Real';

sub init {
    my $mock = shift;
    return if $mock->{'skip_init'};

    $mock->method(test => 'hello')->callback(
        sub {
            'world'
        }
    );
}

42;
