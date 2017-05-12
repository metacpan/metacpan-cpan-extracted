# -*- perl -*-
# test the open_handler() method works as advertised

use Test::More tests => 14;
use warnings;
use strict;

BEGIN { use_ok 'Test::MockCommand'; }

# because we're using barewords for open() file handles
no strict 'refs';

package whimsy;
Test::MockCommand->open_handler(sub {
    my ($args, $pkg) = @_;
    return -69 if @{$args} == 1 && $args->[0] eq 'blah' && $pkg eq 'whimsy';
    return -1;
});
main::is open('blah'), -69, '1-arg open passed to handler';
main::is open('noblah'), -1, '1-arg open passed to handler';
package fruitbat;
main::is open('blah'), -1, '1-arg open passed to handler';

Test::MockCommand->open_handler(sub {
    my ($args, $pkg) = @_;
    return -108 if @{$args} == 2 && $args->[0] eq 'FH' && $args->[1] eq 'file';
    return -42;
});
main::is open('FH', 'file'), -108, '2-arg open passed to handler';
main::is open(FH, 'file'), -108, '2-arg open passed to handler';
main::is open(FH, 'notfile'), -42, '2-arg open passed to handler';
package whimsy;
main::is open(FH, 'file'), -108, '2-arg open passed to handler';

Test::MockCommand->open_handler(undef);
main::isnt open(FH, 'file'), -108, 'handler can be turned off';

Test::MockCommand->open_handler(sub {
    my ($args, $pkg) = @_;
    my $n_args = @{$args};
    $args->[0] = $n_args if not defined $args->[0];
    return $n_args;
});
package main;
is open('FH', 'file'), 2, 'handler can be set again after being turned off';
is open('FH', '>', 'file'), 3, 'n-arg open passed to handler';
is open('FH', '>', 'file', 'blah'), 4, 'n-arg open passed to handler';
my $fh = undef;
is open($fh, '>', 'file', 'blah'), 4, 'n-arg open passed to handler';
is $fh, 4, 'open() can set referenced variables';
