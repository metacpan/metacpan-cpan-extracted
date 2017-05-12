package WWW::Webrobot::AssertConstant;
use strict;
use warnings;


# Author: Stefan Trcek
# Copyright(c) 2004-2006 ABAS Software AG

=head1 NAME

WWW::Webrobot::AssertConstant - assert object for constant values

=head1 SYNOPSIS

For internal use only.

=head1 DESCRIPTION

The 'check' method of this class returns the values given in the constructor 'new'.

=cut


sub new {
    my ($class) = shift;
    my $self = bless({}, ref($class) || $class);

    my ($fail, $fail_str) = @_;
    $self->{fail} = $fail ? 1 : 0;
    $self->{fail_str} = $fail_str;

    return $self;
}

sub check {
    my ($self, $r) = @_;
    return ($self->{fail}, [ $self->{fail_str} ]);
}


1;
