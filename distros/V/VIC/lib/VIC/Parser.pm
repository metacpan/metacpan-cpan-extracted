package VIC::Parser;
use strict;
use warnings;

our $VERSION = '0.31';
$VERSION = eval $VERSION;

use Pegex::Base;
extends 'Pegex::Parser';

sub match_ref {
    my ($self, $ref, $parent) = @_;
    # create a stack to track who is the parent of the current element being
    # matched
    my $stack = $self->{stack} ||= [];
    push @$stack, $ref;
    my $rc = $self->SUPER::match_ref($ref, $parent);
    pop @$stack;
    return $rc;
}

# easy access to the stack
sub stack { shift->{stack}; }

1;

=encoding utf8

=head1 NAME

VIC::Parser

=head1 SYNOPSIS

The Pegex::Parser class for handling the parser with some modifications.

=head1 DESCRIPTION

INTERNAL CLASS.

=head1 AUTHOR

Vikas N Kumar <vikas@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2014. Vikas N Kumar

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
