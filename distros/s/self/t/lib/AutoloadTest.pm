package AutoloadTest;
use strict;
use warnings;
use self;

sub new {
    return bless {}, self;
}

sub out {
    self->{out}
}

our $AUTOLOAD;
sub AUTOLOAD {
    $AUTOLOAD =~ m/::(.*)/;
    self->{out} = $1;
};

1;
