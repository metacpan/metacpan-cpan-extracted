package Test2::Harness::Parser::EventStream;
use strict;
use warnings;

our $VERSION = '0.000014';

use base 'Test2::Harness::Parser';
use Test2::Util::HashBase;

sub morph { }

sub step {
    my $self = shift;

    return ($self->parse_stderr, $self->parse_stdout);
}

sub parse_stderr {
    my $self = shift;

    my $line = $self->proc->get_err_line or return;
    chomp $line;
}

sub parse_stdout {
    my $self = shift;
    my $line = $self->proc->get_out_line or return;
    chomp($line)
}

1;
