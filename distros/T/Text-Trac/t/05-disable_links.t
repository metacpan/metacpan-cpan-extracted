#!perl -T

use strict;
use warnings;
use Test::Base;
use Text::Trac;

delimiters('###');

plan tests => 1 * blocks;

my $p = Text::Trac->new( disable_links => [qw( log milestone )] );

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
r1:3
</p>

### milestone
--- input
milestone:1.0
--- expected
<p>
milestone:1.0
</p>

### ticket
--- input
ticket:1
--- expected
<p>
<a class="ticket" href="/ticket/1">ticket:1</a>
</p>
