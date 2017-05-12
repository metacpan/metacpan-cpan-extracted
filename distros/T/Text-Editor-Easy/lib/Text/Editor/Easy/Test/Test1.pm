package Text::Editor::Easy::Test::Test1;

use warnings;
use strict;

=head1 NAME

Text::Editor::Easy::Test::Test1 - Used for tests.

=head1 VERSION

Version 0.49

=cut

our $VERSION = '0.49';

use Text::Editor::Easy::Comm;

sub test1 {
    my ( $self, @param ) = @_;

    print "Dans test1 : $self|", threads->tid, "@param\n";
    return ( threads->tid, 3 * $param[0], "TEST1" . $param[1] );
}

sub test2 {
    my ( $self, @param ) = @_;

    print "Dans test2 : $self|", threads->tid, "\n";

    return ( threads->tid, 2 * $param[0], "TEST2" . $param[1] );
}

sub new {
    my ( $first, $second ) = @_;

    print "Dans Test1::new |$first|$second|   tid = ", threads->tid, "\n";

    return [ $first + 2, $second . "bof" ];
}

sub test11 {
    my ( $self, @param ) = @_;

    print "Dans test11 : $self|", threads->tid, "@param\n";
    print "SELF 1 : ", $self->[0], "\n";
    print "SELF 2 : ", $self->[1], "\n";
    return (
        threads->tid,
        3 * $param[0] + $self->[0],
        "TEST1" . $param[1] . $self->[1]
    );
}

sub test12 {
    my ( $self, @param ) = @_;

    print "Dans test2 : $self|", threads->tid, "\n";

    return (
        threads->tid,
        2 * $param[0] + 2 * $self->[0],
        "TEST2" . $param[1] . "te" . $self->[1]
    );
}

sub long_task {
    my ( $self, $loop ) = @_;
    my $dizaine  = 0;
    my $centaine = 0;
    my $millier  = 0;
    $loop = 10 if ( !defined $loop or $loop =~ /\D/ );

    print "Dans long_task : loop = $loop\n";
    while ( $millier < $loop ) {
        $dizaine += 1;
        if ( $dizaine > $loop ) {
            $dizaine = 0;
            $centaine += 1;
            if ( $centaine > $loop ) {
                $centaine = 0;
                $millier += 1;
            }
        }
        if (anything_for_me) {
            print "D|C|M|$dizaine|$centaine|$millier|\n";
            have_task_done;
            print "D|C|M|$dizaine|$centaine|$millier|\n";
        }
    }
    print "Fin interne de long_task millier = $millier\n";
}

sub init {
    my ( $self, @param ) = @_;

    print "Dans init de Text::Editor::Easy::Test::Test1 : |$self|@param\n";
}

1;

=head1 FUNCTIONS

=head2 init

=head2 long_task

=head2 new

=head2 test1

=head2 test11

=head2 test12

=head2 test2

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2009 Sebastien Grommier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

