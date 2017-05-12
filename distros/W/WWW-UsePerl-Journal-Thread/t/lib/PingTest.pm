package PingTest;

use strict;
use warnings;

my $VERSION = '0.15';

#----------------------------------------------------------------------------

=head1 NAME

PingTest - private test module for check a network connection

=head1 DESCRIPTION

Provids one method, pingtest(), to check whether a network connection is
available.

=cut

# -------------------------------------
# Functions

# crude, but it'll hopefully do ;)
# ping returns 1 if unable to connect

sub pingtest {
    my $domain = shift || return 1;
    system("ping -q -c 1 $domain >/dev/null 2>&1");
    my $retcode = $? >> 8;
    return $retcode;
}

1;

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2009-2015 Barbie for Miss Barbell Productions.

This distribution is free software; you can redistribute it and/or
modify it under the Artistic Licence v2.

=cut
