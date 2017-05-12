use strict;
use warnings;
use UR;
use Command;

package Command::Test::Tree1::Echo2;

class Command::Test::Tree1::Echo2 {
    is => 'Command',
    has => [
        in => { is => 'Text' },
        out => { is => 'Text', is_output => 1, is_optional => 1 },
    ],
    doc => 'test command 2 to echo output',
};

sub execute {
    my $self = shift;
    for (1..6) {
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

