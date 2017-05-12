use strict;
use warnings;
use UR;
use Command;

package Command::Test::Echo;

class Command::Test::Echo {
    is => 'Command',
    has => [
        in => { is => 'Text' },
        out => { is => 'Text', is_output => 1, is_optional => 1 },
    ],
    doc => 'echo the input back, and die or fail if those words appear in the input',
};

sub execute {
    my $self = shift;
    print "job " . $self->id . " started at " . $self->__context__->now . "\n";
    print STDERR "test error!\n";
    for (1..10) {
        print $self->in,"\n";
        sleep 1;
    }
    if ($self->in =~ /fail/) {
        return;
    }
    elsif ($self->in =~ /die/) {
        die $self->in;
    }
    $self->out($self->in);
    return 1;
}

1;

