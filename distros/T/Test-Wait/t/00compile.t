#!/usr/bin/env perl
# vim:syn=perl

use strict;
use warnings;

use Test::More;

=head1 NAME

t/00compile.t

=head1 DESCRIPTION

Test Test::Wait compiles.

=head1 SYNOPSIS

    perl -Ilib t/00compile.t

    prove -vcfl t/00compile.t

=cut

BEGIN {
    use_ok( 'Test::Wait' );
}

can_ok( 'Test::Wait', 'wait_stdin' );
can_ok( 'Test::Wait', 'wait_x' );


done_testing( 3 );


=head1 AUTHORS

Ben Hare <ben@benhare.com>

=head1 COPYRIGHT

Copyright (c) Ben Hare <ben@benhare.com>, 2014.

This program is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=cut


__END__
