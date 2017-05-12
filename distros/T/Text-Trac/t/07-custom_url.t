#!perl -T

use strict;
use warnings;
use Test::Base;
use Text::Trac;

delimiters('###');

plan tests => 1 * blocks;

my $p = Text::Trac->new(
	trac_attachment_url => 'http://mizzy.org/attachment',
	trac_changeset_url  => 'http://mizzy.org/changeset',
	trac_log_url        => 'http://mizzy.org/log',
	trac_milestone_url  => 'http://mizzy.org/milestone',
	trac_report_url     => 'http://mizzy.org/report',
	trac_source_url     => 'http://mizzy.org/source',
	trac_ticket_url     => 'http://mizzy.org/ticket',
	trac_wiki_url       => 'http://mizzy.org/wiki',
);

sub parse {
	local $_ = shift;
	$p->parse($_);
	$p->html;
}

filters { input => 'parse', expected => 'chomp' };
run_is 'input' => 'expected';

__DATA__

### attachment
--- input
attachment:ticket:33:DSCF0001.jpg
--- expected
<p>
<a class="attachment" href="http://mizzy.org/attachment/ticket/33/DSCF0001.jpg">attachment:ticket:33:DSCF0001.jpg</a>
</p>

### changeset
--- input
[1]
--- expected
<p>
<a class="changeset" href="http://mizzy.org/changeset/1">[1]</a>
</p>

### revision log
--- input
r1:3
--- expected
<p>
<a class="source" href="http://mizzy.org/log/?rev=3&amp;stop_rev=1">r1:3</a>
</p>

### milestone
--- input
milestone:1.0
--- expected
<p>
<a class="milestone" href="http://mizzy.org/milestone/1.0">milestone:1.0</a>
</p>

### report
--- input
{1}
--- expected
<p>
<a class="report" href="http://mizzy.org/report/1">{1}</a>
</p>

### source
--- input
source:trunk/COPYING
--- expected
<p>
<a class="source" href="http://mizzy.org/source/trunk/COPYING">source:trunk/COPYING</a>
</p>

### ticket
--- input
#1
--- expected
<p>
<a class="ticket" href="http://mizzy.org/ticket/1">#1</a>
</p>

### wiki
--- input
TracLinks
--- expected
<p>
<a class="wiki" href="http://mizzy.org/wiki/TracLinks">TracLinks</a>
</p>
