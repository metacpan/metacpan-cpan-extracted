package Tmp::Count;
use strict;
use warnings;
use base "WWW::Webrobot::Print::Test";
use Test::More;


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class -> SUPER::new();
    return bless ($self, $class);
}

sub global_start {
    my $self = shift;
    $self->SUPER::global_start(@_);
    $self->{_count_testplan} = 0;
}

sub global_end {
    my $self = shift;
    $self->SUPER::global_end(@_);
    is($self->{_count_testplan}, 3, "number of  tests in testplan");
}

sub item_pre {
    my $self = shift;
    # my ($arg) = @_;
    $self->SUPER::item_pre(@_);
    $self->{_count_testplan}++;
}

1;
