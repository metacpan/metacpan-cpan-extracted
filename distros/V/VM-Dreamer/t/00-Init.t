#!/usr/bin/perl

use strict;
use warnings;

use VM::Dreamer qw( initialize_machine load_program );

use lib 't/lib';
use TestMachines qw( get_test_machines get_valid_definition get_instruction_set get_expected_machine get_expected_memory );
use InvalidMachines qw( get_invalid_init_tests );

use Test::More;

PROPER_INITIALIZATION: {

    my @test_machines = get_test_machines();

    foreach my $test_machine (@test_machines) {
        my $machine_definition = get_valid_definition($test_machine);
        my $instruction_set    = get_instruction_set($test_machine);

        my $machine;
        eval {
            $machine = initialize_machine( $machine_definition, $instruction_set );
        };
        if ($@) {
            warn "WARNING: Machine initialization raised an exception: $@\n";
        }

        my $expected_machine = get_expected_machine($test_machine);
        is_deeply( $machine, $expected_machine, "Machine properly initialized" );
    }
}

INVALID_INITIALIZATION: {

    my @invalid_init_tests = get_invalid_init_tests();

    foreach my $test (@invalid_init_tests) {
        eval {
            my $machine = initialize_machine($test);
        };
        is( $@, $test->{expected_error}, $test->{message} );
    }
}

VALID_PROGRAM_LOADING: {

    my $base          = "./t/files";
    my @test_machines = get_test_machines();

    foreach my $test_machine (@test_machines) {
        my $machine_definition = get_valid_definition($test_machine);

        my $program = "valid.$test_machine";
        my $path    = "$base/$program";

        my $expected_memory = get_expected_memory($test_machine);

        my ( $machine, $memory );
        eval {
            $machine = initialize_machine($machine_definition);
            load_program( $machine, $path );
        };
        if ($@) {
            warn "WARNING: Loading of program raised an exception: $@\n";
        }
        is_deeply( $machine->{memory}, $expected_memory, "Program $program loaded properly" );
    }
}



# );
# 
# {
#     my @load_instruction_tests = (
#         {
#             message  => "Caught non existant file",
#             program  => "$dir/non_existant.lmc",
#             expected => [ 1, "Could not open $dir/non_existant.lmc" ]
#         },
#         {
#             message  => "Caught non readable file",
#             program  => "$dir/non_readable.lmc",
#             expected => [ 1, "Could not open $dir/non_readable" ] 
#         },
#         {
#             message  => "Caught empty file",
#             program  => "$dir/empty.lmc",
#             expected => [ 1, "Your file is empty" ]
#         },
#         {
#             message  => "Caught improperly formatted line",
#             program  => "$dir/invalid.lmc",
#             expected => [ 1, "Line 5 was not properly formatted: 04	a89" ]
#         },
#         {
#             message  => "Caught redundant address",
#             program  => "$dir/redundant_address.lmc",
#             expected => [ 1, "Address 05 was used a second time on line 9: 05	452" ]
#         },
#         {
#             message  => "Loaded instructions from valid program into memory",
#             program  => "$dir/valid.lmc",
#             expected => [ 0, "Loaded instructions from ./tests/data/valid.lmc into memory", \%expected_instructions ],
#         }
#     );
# 
#     foreach my $test (@load_instruction_tests) {
#         eval{ load_instructions( $machine, $test->{program} ) };
#         is( $@, $test->{expected}, $test->{message} );
#     }
# 
# }
# 
# 
# {
#     my @next_instruction_tests = (
#         {
#             message  => "Received next instruction",
#             counter  => [ 4, 2 ],
#             expected => [ 0, 'Received instruction 755 from address 42.', '755' ]
#         },
#         {
#             message  => "Aborted when address did not hold an instruction",
#             counter  => [ 5, 1 ],
#             expected => [ 1, "Address 51 did not hold an instruction." ] 
#         }
#     );
#     
#     foreach my $test (@next_instruction_tests) {
#         my @results = get_next_instruction( $test->{counter}, \%expected_instructions );
#         is_deeply( \@results, \@{$test->{expected}}, $test->{message} );
#     }
# }
# 
# my @increment_counter_tests = (
#     {
#         message  => "Incremented counter by 1",
#         counter  => [ 5, 7 ],
#         expected => [ 5, 8 ]
#     },
#     {
#         message  => "Incremented counter by 1 with a carry",
#         counter  => [ 6, 9 ],
#         expected => [ 7, 0 ]
#     },
#     {
#         message  => "Incremented counter by 1 with a double carry",
#         counter  => [ 9, 9],
#         expected => [ 0, 0]
#     }
# );
# 
# foreach my $test (@increment_counter_tests) {
#     my @counter = increment_counter( $test->{counter} );
#     is_deeply( \@counter, $test->{expected}, $test->{message} );
# };

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
