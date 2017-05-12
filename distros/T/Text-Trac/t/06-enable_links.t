#!perl -T

use strict;
use warnings;
use Test::Base;
use Text::Trac;

delimiters('###');

plan tests => 1 * blocks;

my $p = Text::Trac->new( enable_links => [qw( log milestone )] );

sub parse {
	local $_ = shift;
	$p->parse($_);
	$p->html;
}

filters { input => 'parse', expected => 'chomp' };
run_is 'input' => 'expected';

__DATA__

### log
--- input
r1:3
--- expected
<p>
<a class="source" href="/log/?rev=3&amp;stop_rev=1">r1:3</a>
</p>

### milestone
--- input
milestone:1.0
--- expected
<p>
<a class="milestone" href="/milestone/1.0">milestone:1.0</a>
</p>

### ticket
--- input
ticket:1
--- expected
<p>
ticket:1
</p>
