#!/usr/bin/perl -I./lib

use strict;
use warnings;

use VM::Dreamer qw( initialize_machine load_program get_next_instruction increment_counter execute_next_instruction );
use VM::Dreamer::Languages::Grasshopper qw( get_instruction_set );

my $definition = {
    base          => 10,
    op_code_width => 1,
    operand_width => 2
};
my $instruction_set = get_instruction_set();

my $machine = initialize_machine( $definition, $instruction_set );

my $program = $ARGV[0];

if ($program) {
    load_program( $machine, $program );
}
else {
    give_help();
}

until( $machine->{halt} ) {
    get_next_instruction($machine);
    increment_counter($machine);
    execute_next_instruction($machine);
}

exit 0;

sub give_help {
    my $message =
        "Please pass the program you would like to run.\n" .
        "For example: \$ $0 sample_code/grasshopper/io\n";

    die $message;
}

=pod

=head1 AUTHOR

William Stevenson <dreamer at coders dot coop>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by William Stevenson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)
 
=cut

