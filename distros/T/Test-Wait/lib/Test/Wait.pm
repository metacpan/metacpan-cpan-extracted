package Test::Wait;
# vim:syn=perl

use strict;
use warnings;

use vars qw( $VERSION @ISA @EXPORT );

require Exporter;
@ISA = qw( Exporter );
@EXPORT = qw( wait_stdin wait_x );

our $VERSION = '0.04';

use constant DEFAULT_WAIT_SECONDS                                                           => 10;

=head1 NAME

Test::Wait - Make tests wait for manual testing purposes.

=head1 DESCRIPTION

Test::Wait is a tool for use in conjunction with test libraries such as Test::More for manual testing purposes.

It was initially designed for use in Selenium based tests however it can be used in any test script.

Test::Wait provides a simple interface to pause test scripts at any given point, allowing you to inspect the test output or
use the test-created data to run manual tests against the application in a browser or terminal.

=head1 SYNOPSIS

    use Test::Wait;

    wait_stdin( [ 'i'm waiting for you to hit return' ] );

    wait_x( [ [ int seconds_to_wait ] [, "i'm waiting $seconds_to_wait seconds" ] ] );

=head1 INTERFACE

=cut

=head2 wait_stdin( [ str message ] ) : nothing

wait ( for return key press ) before continuing a test.

ignored if running under prove or make test.

=cut

sub wait_stdin {
    my $msg = shift;
    return if ( $ENV{HARNESS_ACTIVE} ); # don't wait if running under test harness eg; prove, make test
    my ( $pkg, $filename, $line ) = caller();
    my $out_msg = 'I> ' . __PACKAGE__ . "::wait_stdin() - waiting at '$pkg' line '$line' ( $filename )";
    $out_msg .= ": '$msg'" if ( defined($msg) );
    print STDERR "$out_msg\n";
    <STDIN>;
}

=head2 wait_x( [ [ int seconds_to_wait ] [, str message ] ] ) : nothing

wait for $seconds_to_wait seconds before continuing a test.

ignored if running under prove or make test.

=cut

sub wait_x {
    my ( $seconds, $msg ) = @_;
    return if ( $ENV{HARNESS_ACTIVE} ); # don't wait if running under test harness eg; prove, make test
    $seconds = DEFAULT_WAIT_SECONDS() if ( !defined($seconds) || $seconds !~ /^\d+$/ );
    my ( $pkg, $filename, $line ) = caller();
    my $out_msg = 'I> ' . __PACKAGE__ . "::wait_x() - waiting '$seconds' seconds at '$pkg' line '$line' ( $filename )";
    $out_msg .= ": '$msg'" if ( defined($msg) );
    print STDERR "$out_msg\n";
    sleep( $seconds );
}

=head1 SEE ALSO

Test::More, Test::Builder, Test::Simple, Selenium::Remote::Driver, Test::Harness

=head1 AUTHORS

Ben Hare <ben@benhare.com>

=head1 CREDITS

Inspired by code written by Chris Hutchinson <chris@hutchinsonsoftware.com>.

=head1 COPYRIGHT

Copyright (c) Ben Hare <ben@benhare.com>, 2014.

This program is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=cut


1;

__END__
