package TestMachines;

use strict;
use warnings;

use VM::Dreamer::Instructions qw( input_to_mb output_from_mb store load add subtract branch_always branch_if_zero branch_if_positive halt );

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw( get_test_machines get_valid_definition get_instruction_set get_expected_machine get_expected_memory );


# If you are going to add a new machine for testing, please
# add its name to test_machines.

# Then add the machine's definition to valid_definitions
# with that name as the key and also add an instruction
# set for it, again with the name as the key.

# Then add what you expect your machine to look like after
# initialization to expected_machines.

# You'll also want to add a file called valid.machine_name
# to t/files/ and a corresponding expected memory state
# to the %expected_memory hash below.


my @test_machines = qw( grasshopper gmc rmc );

my %valid_definitions = (
    grasshopper => {
        base          => 10,
        op_code_width =>  1,
        operand_width =>  2
    },

    gmc => {
        base          =>  2,
        op_code_width =>  4,
        operand_width => 12,
    },

    rmc => {
        base          =>  8,
        op_code_width =>  2,
        operand_width =>  6,
    }
);

my %instruction_sets = (
    grasshopper => {
        1 => \&input_to_mb,
        2 => \&output_from_mb,
        3 => \&store,
        4 => \&load,
        5 => \&add,
        6 => \&subtract,
        7 => \&branch_always,
        8 => \&branch_if_zero,
        9 => \&branch_if_positive,
        0 => \&halt
    },

    gmc => {},

    rmc => {}
);

my %expected_machines = (
    grasshopper => {
        memory => {},
    
        inbox  => [],
        outbox => [],
    
        counter     => [ 0, 0 ],
        accumulator => [ 0, 0, 0 ],
    
        n_flag => 0,
        halt   => 0,
    
        next_instr => '',

        instruction_set => {
            1 => \&input_to_mb,
            2 => \&output_from_mb,
            3 => \&store,
            4 => \&load,
            5 => \&add,
            6 => \&subtract,
            7 => \&branch_always,
            8 => \&branch_if_zero,
            9 => \&branch_if_positive,
            0 => \&halt
        },
    
        meta => {
            base  => 10,
            width => {
                op_code     =>  1,
                operand     =>  2,
                instruction =>  3,
            },
            greatest => {
                digit       => 9,
                op_code     => '9',
                operand     => '99',
                instruction => '999',
                # digit is numeric, the others are strings
                # this makes comparison easier for large
                # numbers as they seem to be turned into
                # scientific notation depending on the
                # machine's architecture
            },
        },
    },

    gmc => {
        memory      => {},

        inbox       => [],
        outbox      => [],

        counter     => [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
        accumulator => [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],

        n_flag      => 0,
        halt        => 0,

        next_instr  => '',

        instruction_set => {},

        meta        => {
            base  => 2,
            width => {
                op_code     => 4,
                operand     => 12,
                instruction => 16,
            },
            greatest => {
                digit       => 1,
                op_code     => '1111',
                operand     => '111111111111',
                instruction => '1111111111111111',
                # see comment above for grasshopper 
            },
        },
    },

    rmc => {
        memory      => {},

        inbox       => [],
        outbox      => [],

        counter     => [ 0, 0, 0, 0, 0, 0 ],
        accumulator => [ 0, 0, 0, 0, 0, 0, 0, 0 ],

        n_flag      => 0,
        halt        => 0,

        next_instr  => '',

        instruction_set => {},

        meta => {
            base  => 8,
            width => {
                op_code     => 2,
                operand     => 6,
                instruction => 8,
            },
            greatest => {
                digit       => 7,
                op_code     => '77',
                operand     => '777777',
                instruction => '77777777',
                # see comment above for grasshopper 
            },
        },
    },
);

my %expected_memory = (

    grasshopper => {
        '00' => '324',
        '01' => '789',
        '02' => '543',
        '03' => '672',
        '04' => '789',
        '05' => '121',
        '06' => '342',
        '07' => '343',
        '08' => '452',
        '09' => '295',
        '10' => '801',
        '22' => '954',
        '37' => '608',
        '42' => '755',
        '50' => '717',
        '63' => '604',
        '78' => '000',
        '85' => '021',
        '99' => '092'
    },

    gmc => {
        '000000000000' => '0110100110011001',
        '000000000001' => '1010100101010110',
        '000000000010' => '0000111101011100',
        '000000000011' => '0111000111100100',
        '000000000100' => '1001111111110110',
        '000000001001' => '1100010010100101',
        '000110100100' => '0110101111010110',
        '010010010111' => '1000101110111001',
        '011001101010' => '0110101101011011'
    },

    rmc => {
        '000000' => '13726510',
        '000001' => '23722015',
        '000002' => '32773110',
        '000003' => '65220010',
        '000004' => '21366221',
        '000005' => '23531001',
        '000006' => '62710024',
        '000007' => '54310002',
        '000010' => '27331204',
        '000017' => '56263740',
        '000707' => '31035442',
        '124700' => '42135442',
        '723223' => '35544103'
	}
);
        

sub get_test_machines {
    return @test_machines;
}

sub get_valid_definition {
    my $machine_name = shift;

    if ( $valid_definitions{$machine_name} ) {
        return $valid_definitions{$machine_name};
    }
    else {
        warn "WARNING: I could not find a definition for a machine called: $machine_name\n";
        return 0;
    }
}

sub get_instruction_set {
    my $machine_name = shift;

    if ( $instruction_sets{$machine_name} ) {
        return $instruction_sets{$machine_name};
    }
    else {
        warn "WARNING: I could not find an instruction set for a machine called: $machine_name\n";
        return 0;
    }
    # maybe die here and catch exception???
}

sub get_expected_machine {
    my $machine_name = shift;

    if ( $expected_machines{$machine_name} ) {
        return $expected_machines{$machine_name};
    }
    else {
        warn "WARNING: I couldn't find an expected machine called: $machine_name\n";
        return 0;
    }
}

sub get_expected_memory {
    my $machine_name = shift;

    if( $expected_memory{$machine_name} ) {
        return $expected_memory{$machine_name};
    }
    else {
        warn "WARNING: I could not find an expected memory state which would correspond to the program you are attempting to load\n";
        return 0;
    }
}


1;

=pod

=head1 AUTHOR

William Stevenson <dreamer at coders dot coop>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by William Stevenson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)
 
=cut
