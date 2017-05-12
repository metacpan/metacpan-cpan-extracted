package Grepper;

# This is an example of how to use the Text::Filter class.
#
# It implements a module that provides a single instance method: grep,
# that performs some kind of grep(1)-style function (how surprising!).
#
# A class method 'grepper' is also provided for easy access to do 'the
# right thing'.

use strict;

use base qw(Text::Filter);
use base qw(Exporter);
our @EXPORT = qw(grepper);

# Constructor. All is done by the superclass.

# Instance method, just an example. No magic.
sub grep {
    my $self = shift;
    my $pat = shift;
    my $line;
    while ( defined ($line = $self->readline) ) {
	$self->writeline ($line) if $line =~ $pat;
    }
}

# Class method, for convenience.
# Usage: grepper (<input file>, <output file>, <pattern>);
sub grepper {
    my ($input, $output, $pat) = @_;

    # Create a Grepper object.
    my $grepper = new Grepper (input => $input, output => $output);

    # Call its grep method.
    $grepper->grep ($pat);
}

1;
