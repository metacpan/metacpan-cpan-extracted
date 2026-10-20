#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;
use Time::Keeper::Natural;

# The Match and the deaths at their edges: an assumption given twice is
# listed once, a death names the word as typed, options belong to new, and a
# death names the caller's line with no backtrace.
local $Time::Keeper::CLOCK = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, minute => 30, zone => 'Europe/London');
my $n = Time::Keeper::Natural->new(locale => 'en-GB', zone => 'Europe/London');

my $m = Time::Keeper::Natural::Match->_new(value => 1, kind => 'point', precision => 'day', assumed => [qw(time zone time)], text => 'x');
is_deeply([ $m->assumed ], [qw(time zone)], 'an assumption given twice is listed once');

ok(!eval { $n->parse('NEXT WEEK ZZZ'); 1 }, 'a word after a phrase dies');
like($@, qr/cannot read 'NEXT WEEK ZZZ' at 'ZZZ': no such word in en-GB/, 'naming the word as it was typed');

ok(!eval { $n->match('tomorrow', locale => 'fr'); 1 }, 'an option after the text of a parser');
like($@, qr/^Time::Keeper::Natural->match: options go to new, not to match at /, 'dies saying where options go');

my $line = __LINE__ + 1;
ok(!eval { $n->match('x', zone => 'UTC'); 1 }, 'again');
like($@, qr/ at \Q${\ __FILE__}\E line $line\.\n\z/, 'the death names this line, with no backtrace');

$line = __LINE__ + 1;
ok(!eval { $n->parse('zzz'); 1 }, 'parse of nothing');
like($@, qr/ at \Q${\ __FILE__}\E line $line\.\n\z/, 'names this line too');

# The token a death names: after the longest head that reads as a whole
# phrase or as units, as 0.01 chose it.
{
    my $id = Time::Keeper::Natural->new(locale => 'id', zone => 'Europe/London');
    ok(!eval { $id->parse('delapan kuartal lalu rabu lalu'); 1 }, 'id: two phrases run together');
    like($@, qr/at 'delapan': no such word in id/, 'the token is the first word');
}

# A death after a file was read names no handle, as Carp's message did.
{
    open my $fh, '<', __FILE__ or die $!;
    my $first = <$fh>;
    ok(!eval { $n->parse('zzz'); 1 }, 'parse of nothing after reading a file');
    unlike($@, qr/<\$fh> line/, 'the death does not name the handle');
    close $fh;
}

done_testing;
