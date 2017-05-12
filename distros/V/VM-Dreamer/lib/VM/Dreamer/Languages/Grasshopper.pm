package VM::Dreamer::Languages::Grasshopper;

use strict;
use warnings;

our $VERSION = '0.851';

use VM::Dreamer::Instructions qw( input_to_mb output_from_mb store load add subtract branch_always branch_if_zero branch_if_positive halt );

require Exporter; 

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw( get_instruction_set );

my %instruction_set = (
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
);

sub get_instruction_set {
    return \%instruction_set;
}

# MDL - Machine Definition Language - 1.0

# name:Grasshopper
# base:10
# op_code_width:1
# operand_width:2
# language:Grasshopper

# validate_definition(%definition);

#  - all required keys are present
#  - no keys which not expected
#  - all values are of proper form relative to key they define

#  - name is lte 32 characters
#            starts with a letter
#            contains only letters, numbers or underscores

#  - language is lte 32 characters
#            starts with a capital letter
#            contains only letters, numbers or underscores

1;

=pod

=head1 AUTHOR

William Stevenson <dreamer at coders dot coop>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by William Stevenson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)
 
=cut
