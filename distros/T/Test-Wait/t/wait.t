#!/usr/bin/env perl
# vim:syn=perl

use strict;
use warnings;

use Test::More;

=head1 NAME

t/wait.t

=head1 DESCRIPTION

Test Test::Wait functions.

=head1 SYNOPSIS

    perl -Ilib t/wait.t

    prove -vcfl t/wait.t

=cut

BEGIN {
    use_ok( 'Test::Wait' );
}

is( Test::Wait->DEFAULT_WAIT_SECONDS(), 10, "got default wait seconds" );

is( wait_stdin(), $ENV{HARNESS_ACTIVE} ? undef : "\n", "wait_stdin output matches expected" );
is( wait_stdin( "waiting for return key press" ), $ENV{HARNESS_ACTIVE} ? undef : "\n", "wait_stdin output matches expected" );

is( wait_x(), $ENV{HARNESS_ACTIVE} ? undef : 10, "wait_x output matches expected" );
is( wait_x( undef, "waiting default seconds" ), $ENV{HARNESS_ACTIVE} ? undef : Test::Wait->DEFAULT_WAIT_SECONDS(), "wait_x output matches expected" );
is( wait_x( 20, "waiting 20 seconds" ), $ENV{HARNESS_ACTIVE} ? undef : 20, "wait_x output matches expected" );
is( wait_x( 5, "waiting 5 seconds" ), $ENV{HARNESS_ACTIVE} ? undef : 5, "wait_x output matches expected" );
is( wait_x( 0, "waiting 0 seconds" ), $ENV{HARNESS_ACTIVE} ? undef : 0, "wait_x output matches expected" );


done_testing();


=head1 AUTHORS

Ben Hare <ben@benhare.com>

=head1 COPYRIGHT

Copyright (c) Ben Hare <ben@benhare.com>, 2014.

This program is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=cut


__END__
