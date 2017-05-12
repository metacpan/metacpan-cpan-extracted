package Test::Slow;

=encoding utf8

=head1 NAME

Test::Slow - Skip test that are too slow to run frequently

=head1 SYNOPSIS

Some test are too slow to run frequently. This module makes it
easy to skip slow tests so that you can run the others more
frequently. To mark a test as slow simply C<use> this module:

   use Test::Slow;
   use Test::More;
   ...
   done_testing;

To run just the quick tests, set the C<QUICK_TEST> environment
variable to a true value:

   $ QUICK_TEST=1 prove --lib t/*t

=cut

use warnings;
use strict;
use Test::More;

our $VERSION = '0.03';

BEGIN {
    plan(skip_all => 'Slow test.') if $ENV{QUICK_TEST};
}

=head1 COPYRIGHT & LICENSE

Copyright 2010 Tomáš Znamenáček, zoul@fleuron.cz

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

'SDG';
