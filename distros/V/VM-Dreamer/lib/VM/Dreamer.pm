package VM::Dreamer;

use strict;
use warnings;

our $VERSION = '0.851';

use VM::Dreamer::Operation qw( add_one_to_counter get_new_machine );
use VM::Dreamer::Util qw( parse_program_line parse_next_instruction );
use VM::Dreamer::Validate qw( validate_definition build_valid_line_regex );

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw( initialize_machine load_program get_next_instruction increment_counter execute_next_instruction );


sub initialize_machine {
    my $definition      = shift;
    my $instruction_set = shift;

    validate_definition($definition);

    return get_new_machine( $definition->{base}, $definition->{op_code_width}, $definition->{operand_width}, $instruction_set );
}

sub load_program {
    my( $machine, $program ) = @_;

    open( my $in, "<", $program )
        or die "Could not open program $program: $!\n";

    unless( ! -z $in ) {
        die "Your file is empty!\n";
    }

    # this is a situation in which having a single machine rather than
    # creating a framework to define arbitrary ones would be much 
    # simpler

    my $valid_line_regex = build_valid_line_regex($machine);

    my $line_count = 1;
    while( <$in> ) {
        my $line = $_;
        chomp $line;

        unless( $line =~ $valid_line_regex ) {
            die "Line $line_count was not properly formatted: $line\n";
        }

        my ( $address, $instruction ) = parse_program_line($line);

        if( $machine->{memory}->{$address} ) {
            die "Address $address was used a second time on line $line_count: $line\n";
        }
        else {
            $machine->{memory}->{$address} = $instruction;
        }
    }

    return {}; 
}

sub get_next_instruction {
    my $machine = shift;

    my $address = join( '', @{ $machine->{counter} } );
    my $instruction = $machine->{memory}->{$address};
 
    if ($instruction) {
        $machine->{next_instruction} = $instruction;
    }
    else {
        die "Address $address did not hold an instruction. Most likely the addresses in your program don't start at 0 or skipped a number.\n";
        # would be nice to add the previous line in the program to this error message
    }
}
 
sub increment_counter {
    my $machine = shift;

    $machine->{counter} = add_one_to_counter( $machine->{counter}, $machine->{meta}->{greatest}->{digit} );

    return 0;
}

sub execute_next_instruction {
    my $machine = shift;

    my ( $op_code, $operand ) = parse_next_instruction($machine);

    if ( $machine->{instruction_set}->{$op_code} ) {
        $machine->{instruction_set}->{$op_code}->( $machine, $operand );
    }
    else {
        die "The op_code $op_code is not known in the instruction set for $machine->{name}\n";
    }
    # move this to VM::Dreamer::Error ?

    return 0;
}

1;       


=pod

=head1 NAME

Dreamer - An arbitrary emulator of one-operand computers 

=head1 VERSION

Version 0.851

=head1 SYNOPSIS

use VM::Dreamer qw( initialize_machine load_program get_next_instruction increment_counter execute_next_instruction );
use VM::Dreamer::Languages::Grasshopper qw( get_instruction_set );

my $definition = {
    base          => 10,
    op_code_width => 1,
    operand_width => 2
};

my $instruction_set = get_instruction_set();
my $machine         = initialize_machine( $definition, $instruction_set );

my $program = $ARGV[0];
load_program( $machine, $program );

until( $machine->{halt} ) {
    get_next_instruction($machine);
    increment_counter($machine);
    execute_next_instruction($machine);
}

=head1 DESCRIPTION

Dreamer is a framework to emulate arbitrary 1-operand computers. It comes with pre-defined machines, but also lets you define and operate your own. It was written as a generalization of the Little Man Computer to help myself and others understand the foundations of Computer Science.

=head1 EXPORT

initialize_machine
load_program
get_next_instruction
increment_counter
execute_next_instruction

=head1 FUNCTIONS

=head2 initialize_machine

Takes two hash_refs as input and returns a hash ref.

The first input is the machine's definition. It should have  and the second is it's instruction set.

=head2 load_program

Takes a reference to your machine and a path to a program for your machine. If the file cannot be opened or is not valid, it raises an exception. Otherwise it puts the instructions into the corresponding addresses in your machine's memory and returns 0.

=head1 GETTING STARTED 

The easiest way to get started is to execute a pre-written program for a pre-defined machine. This is as simple as:

    $ grasshopper sample_code/grasshopper/io

It will just ask you for a number and then give it back.

After you do that, I would try writing your own program for Grasshopper. It comes with a well-written tutorial.

From there, you could move on to writing programs for Eagle or you could start defining your own machine and writing code for it.

=head2 Defining your own machine

This is explained extensively in VM::Dreamer::Tutorial::MachineDefinition. If you'd rather learn by example, the one for Grasshopper should be a good example - see VM::Dreamer::Languages::Grasshopper.

=head2 Developing the code base

If you really get into this and you'd like to work on the code base, please let me know:

=head1 NEXT STEPS


You can also find the documenation on defining your own machines. Then you can start writing your own programs for it. If you really get bored, you can write an assembler. If that isn't enough you can create a higher level language and write a compiler for your instruction set. Really, the sky's the limit ;-)

I also thought that these simple machines could be of mathematical interest in the sense that they can operate on very, very large numbers in a relatively arbitrary base (though you could probably already do this with bc).

They might also be intersting to people who want to translate machine code from one machine to another or to target multiple platforms from a generic assembly code like UNCOL.

Enjoy!

=head1 AUTHOR

William Stevenson <dreamer at coders dot coop>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by William Stevenson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
