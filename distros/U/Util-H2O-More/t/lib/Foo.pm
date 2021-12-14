package Foo;

use strict;
use warnings;
use Util::H2O::More qw/baptise baptise_deeply/;

sub new {
    my $pkg  = shift;
    my %opts = @_;
    my $self = baptise \%opts, $pkg, qw/bar/;
    return $self;
}

sub new_deeply {
    my $pkg  = shift;
    my %opts = @_;
    my $self = baptise_deeply \%opts, $pkg, qw/bar/;
    return $self;
}

sub boop {
    return 'boop';
}

sub beep {
    return 'beep';
}

1;
