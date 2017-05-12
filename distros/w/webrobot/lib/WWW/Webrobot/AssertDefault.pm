package WWW::Webrobot::AssertDefault;
use strict;
use warnings;


# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG

=head1 NAME

WWW::Webrobot::AssertDefault - default assertion

=head1 SYNOPSIS

For internal use only.

=head1 DESCRIPTION

This is the default assertion for HTTP responses.
It is true when the response code is 2xx.

=cut


sub new {
    my ($class) = shift;
    my $self = bless({}, ref($class) || $class);
    return $self;
}

sub check {
    my ($self, $r) = @_;
    return (undef, []) if !defined $r;
    return (200 <= $r->{_rc} && $r->{_rc} < 300) ? (0, []) : (1, []);
}


1;
