package Text::Editor::Easy::Test::Test3;

use warnings;
use strict;

=head1 NAME

Text::Editor::Easy::Test::Test3 - Used for tests.

=head1 VERSION

Version 0.49

=cut

our $VERSION = '0.49';

sub test3 {
    my ( $self, @param ) = @_;

    print "Dans test3  de Easy::Test3: $self|", threads->tid, "|@param|\n";

    return ( threads->tid, 4 * $param[0], "TEST3" . $param[1] );
}

sub test4 {
    my ( $self, @param ) = @_;

    print "Dans test4  de Easy::Test3: $self|", threads->tid, "|@param|\n";

    return ( threads->tid, 5 * $param[0], "TEST4" . $param[1] );
}

sub object_test {
    my ( $self, @param ) = @_;

    return ( $self->[0] * 12 - 2 * $param[0], $self->[1] . "BOF" . $param[1] );
}

1;

=head1 FUNCTIONS

=head2 test3

=head2 test4

=head2 object_test

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2009 Sebastien Grommier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

