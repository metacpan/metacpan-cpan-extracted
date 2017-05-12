package WWW::Webrobot::Print::ChildSend;
use strict;
use warnings;

# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG

use WWW::Webrobot::Ext::General::HTTP::Response;


=head1 NAME

WWW::Webrobot::Print::ChildSend - special class for multiple clients for load tests

=head1 DESCRIPTION

This is a special output listener for child user agents
that sends data to the main (forking) process.

=head1 METHODS

See L<WWW::Webrobot::pod::OutputListeners>.

=cut


sub new {
    my ($class) = shift;
    my $self = bless({}, ref($class) || $class);
    $| = 1;
    return $self;
}

sub global_start {
    # my ($self) = @_;
}

sub item_pre {
    # my ($self, $arg) = @_;
}

sub item_post {
    my ($self, $r, $arg) = @_;
    return if !$r; # <cookies>, <request>, <nop>, ...
    my $elaps = $r->elapsed_time();
    print join(" ",
               "TIME",
               $elaps,
               $arg->{fail},
               $r->code,
               $arg->{method},
               $arg->{url}),
        "\n";
}

sub global_end {
    # my ($self) = @_;
}

1;
