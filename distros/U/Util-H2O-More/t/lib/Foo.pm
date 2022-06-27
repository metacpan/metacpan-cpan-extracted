package Foo;

use strict;
use warnings;
use Util::H2O::More qw/baptise/;

sub new {
    my $pkg  = shift;
    my %opts = @_;
    my $self = baptise -recurse, \%opts, $pkg, qw/bar/;
    return $self;
}

sub boop {
    return 'boop';
}

sub beep {
    return 'beep';
}

1;
