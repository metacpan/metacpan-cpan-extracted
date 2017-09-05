
=pod

=head1 SYNOPSIS

    perl examples/lazy.pl

=head1 DESCRIPTION

This script shows how C<lazy> can be used in a script.  It intentionally uses a
C<local> prefix so that nothing actually gets installed.

=cut

use strict;
use warnings;

use lib 'lib';

use local::lib 'local';
use lazy qw( -v );

use Local::FooBar;

0;
