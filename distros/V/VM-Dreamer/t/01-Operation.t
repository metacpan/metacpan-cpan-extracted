#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use VM::Dreamer qw( increment_counter );
use VM::Dreamer::Init qw( init_counter );

COUNTER_INITIALIZATION: { 

    my $counter  = init_counter(5);
    my $expected = [ 0, 0, 0, 0, 0 ];

    is_deeply( $counter, $expected, "Counter properly initialized" );

}

COUNTER_INCREMENTING: {

    my $without_carry = {
        message => "Counter properly incremented without a carry",

        counter => [ 0, 0, 0, 0, 0, 0, 0, 0, 1, 3, 9, 3, 2, 4, 5 ],
        meta => {
            greatest => {
                digit => 9
            }
        },

        expected => [ 0, 0, 0, 0, 0, 0, 0, 0, 1, 3, 9, 3, 2, 4, 6 ]
    };

    my $with_carry = {
        message => "Counter properly incremented with a carry",
    
        counter => [ 2, 3, 7, 7, 7, 7, 7, 7, 7, 7 ],
        meta => {
            greatest => {
                digit => 7
            }
        },

        expected => [ 2, 4, 0, 0, 0, 0, 0, 0, 0, 0 ]
    };

    my $greatest = {
        message => "Counter set back to zero when highest value is incremented",

        counter => [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
        meta => {
            greatest => {
                digit => 1
            }
        },

        expected => [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ]
    };

    foreach my $test ( $without_carry, $with_carry, $greatest ) {
        increment_counter($test);
        is_deeply( $test->{counter}, $test->{expected}, $test->{message} );
    }
}

NEXT_INSTRUCTION: {
;
}



done_testing();

exit 0;

=pod

=head1 AUTHOR

William Stevenson <dreamer at coders dot coop>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by William Stevenson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)
 
=cut
