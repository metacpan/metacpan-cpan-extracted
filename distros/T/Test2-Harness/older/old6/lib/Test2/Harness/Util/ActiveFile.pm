package Test2::Harness::Util::ActiveFile;
use strict;
use warnings;

use IO::Handle;

use Test2::Harness::Util();

use Carp qw/croak/;

use Test2::Harness::HashBase qw{ -fh -buffer done };

sub open_file {
    my $class = shift;
    my ($file, %params) = @_;

    my $fh = Test2::Harness::Util::open_file($file);

    return $class->new(%params, FH() => $fh);
}

sub maybe_open_file {
    my $class = shift;
    my ($file, %params) = @_;

    my $fh = Test2::Harness::Util::maybe_open_file($file) or return undef;

    return $class->new(%params, FH() => $fh);
}

sub init {
    my $self = shift;

    croak "'fh' is a required attribute" unless $self->{+FH};

    $self->{+FH}->blocking(0);

    $self->{+BUFFER} = '';
}

# When reading from a file that is still growing we have to reset EOF
# frequently, and also may get a partial line if we read halway thorugh a line
# being written, so we need to add our own buffering.
my $call = 0;
sub read_line {
    my $self = shift;

    $call++;

    my $fh = $self->{+FH};

    my $line;
    my $loop = 0;
    until ($line) {
        $loop++;
        seek($fh,0,1); # Clear EOF
        my $got = <$fh>;
        return unless defined $got;

        $self->{+BUFFER} .= $got;

        # If the line does not end in a newline we will return for now and try
        # to read the rest of the line later. However if 'done' is set we want
        # to skip this check and return the data anyway as a newline will never
        # come.
        return unless $self->{+DONE} || substr($self->{+BUFFER}, -1, 1) eq "\n";

        chomp($line = $self->{+BUFFER});

        $self->{+BUFFER} = '';
    }

    return $line;
}

1;
