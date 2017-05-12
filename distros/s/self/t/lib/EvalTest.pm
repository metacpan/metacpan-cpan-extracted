use strict;
use warnings;
package EvalTest;

use self;

sub new {
    return bless {}, self;
}

sub in {
    my ($n) = args;
    self->{n} = $n;
}

sub out {
    return self->{n}
}

sub out2 {
    return eval {
        return self->{n}
    };
}

sub out3 {
    return eval "self->{n}";
}

sub out4 {
    return eval {
        eval 'self->{n}';
    };
}

sub out5 {
    eval {
        eval {
            self->{n}
        }
    }
}

sub out6 {
    eval q{eval 'self->{n}'};
}

sub out7 {
    eval q{eval {self->{n}}};
}


my $depth = 20;
sub out8 {
    if ($depth == 0) {
        return eval {
            self->{n};
        }
    }
    $depth--;
    return eval {
        self->out8;
    }
}

1;
