
package Class;
sub new { bless [] }

package main;
use strict;
use warnings;
use Test::More tests => 5;
use Validate::Tiny ':all';

my $r = { fields => [qw/a b/] };

$r->{checks} = [ a => is_a('Class') ];
ok validate( { a => undef }, $r )->{success};
ok !validate( { a => '0' }, $r )->{success};
ok validate( { a => '0' }, $r )->{error}->{a};
ok validate( { a => Class->new }, $r )->{success};

$r->{checks} = [ a => is_a('Class', 'NO') ];
is validate( { a => '0' }, $r )->{error}->{a}, 'NO';
