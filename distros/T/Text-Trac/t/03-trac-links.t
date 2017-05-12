use strict;
use warnings;
use t::TestTextTrac;

run_tests;

__DATA__

### ticket link test 1
--- input
#1
--- expected
<p>
<a class="ticket" href="http://trac.mizzy.org/public/ticket/1">#1</a>
</p>

### ticket link test 2
--- input
ticket:1
--- expected
<p>
<a class="ticket" href="http://trac.mizzy.org/public/ticket/1">ticket:1</a>
</p>

### ticket link test 3
--- input
!#1
--- expected
<p>
#1
</p>

### ticket link test 4
--- input
!ticket:1
--- expected
<p>
ticket:1
</p>

### ticket link test 5
--- input
[ticket:1]
--- expected
<p>
<a class="ticket" href="http://trac.mizzy.org/public/ticket/1">1</a>
</p>

### ticket link test 6
--- input
[ticket:1 ticket 1]
--- expected
<p>
<a class="ticket" href="http://trac.mizzy.org/public/ticket/1">ticket 1</a>
</p>

### ticket link test 7
--- input
![ticket:1]
--- expected
<p>
[ticket:1]
</p>

### report link test 1
--- input
{1}
--- expected
<p>
<a class="report" href="http://trac.mizzy.org/public/report/1">{1}</a>
</p>

### report link test 2
--- input
report:1
--- expected
<p>
<a class="report" href="http://trac.mizzy.org/public/report/1">report:1</a>
</p>

### report link test 3
--- input
!{1}
--- expected
<p>
{1}
</p>

### report link test 4
--- input
!report:1
--- expected
<p>
report:1
</p>

### report link test 5
--- input
[report:1]
--- expected
<p>
<a class="report" href="http://trac.mizzy.org/public/report/1">1</a>
</p>

### report link test 6
--- input
[report:1 report 1]
--- expected
<p>
<a class="report" href="http://trac.mizzy.org/public/report/1">report 1</a>
</p>

### report link test 7
--- input
![report:1]
--- expected
<p>
[report:1]
</p>

### changeset link test 1
--- input
[1]
--- expected
<p>
<a class="changeset" href="http://trac.mizzy.org/public/changeset/1">[1]</a>
</p>

### changeset link test 2
--- input
changeset:1
--- expected
<p>
<a class="changeset" href="http://trac.mizzy.org/public/changeset/1">changeset:1</a>
</p>

### changeset link test 3
--- input
r1
--- expected
<p>
<a class="changeset" href="http://trac.mizzy.org/public/changeset/1">r1</a>
</p>

### changeset link test 4
--- input
[changeset:1]
--- expected
<p>
<a class="changeset" href="http://trac.mizzy.org/public/changeset/1">1</a>
</p>

### changeset link test 5
--- input
[changeset:1 changeset 1]
--- expected
<p>
<a class="changeset" href="http://trac.mizzy.org/public/changeset/1">changeset 1</a>
</p>

### changeset link test 6
--- input
![1]
--- expected
<p>
[1]
</p>

### changeset link test 7
--- input
!changeset:1
--- expected
<p>
changeset:1
</p>


### changeset link test 8
--- input
!r1
--- expected
<p>
r1
</p>

### changeset link test 9
--- input
![changeset:1]
--- expected
<p>
[changeset:1]
</p>



### revision log link test 1
--- input
r1:3
--- expected
<p>
<a class="source" href="http://trac.mizzy.org/public/log/?rev=3&amp;stop_rev=1">r1:3</a>
</p>

### revision log link test 2
--- input
[1:3]
--- expected
<p>
<a class="source" href="http://trac.mizzy.org/public/log/?rev=3&amp;stop_rev=1">[1:3]</a>
</p>

### revision log link test 3
--- input
log:#1:3
--- expected
<p>
<a class="source" href="http://trac.mizzy.org/public/log/?rev=3&amp;stop_rev=1">log:#1:3</a>
</p>

### revision log link test 4
--- input
[log:#1:3]
--- expected
<p>
<a class="source" href="http://trac.mizzy.org/public/log/?rev=3&amp;stop_rev=1">#1:3</a>
</p>

### revision log link test 5
--- input
[log:#1:3 log 1 - 3]
--- expected
<p>
<a class="source" href="http://trac.mizzy.org/public/log/?rev=3&amp;stop_rev=1">log 1 - 3</a>
</p>

### wiki link test 1
--- input
TracLinks
--- expected
<p>
<a class="wiki" href="http://trac.mizzy.org/public/wiki/TracLinks">TracLinks</a>
</p>

### wiki link test 2
--- input
wiki:trac_links
--- expected
<p>
<a class="wiki" href="http://trac.mizzy.org/public/wiki/trac_links">wiki:trac_links</a>
</p>

### wiki link test 3
--- input
!TracLinks
--- expected
<p>
TracLinks
</p>

### wiki link test 4
--- input
!wiki:TracLinks
--- expected
<p>
wiki:TracLinks
</p>

### wiki link test 5
--- input
[wiki:TracLinks Trac Links]
--- expected
<p>
<a class="wiki" href="http://trac.mizzy.org/public/wiki/TracLinks">Trac Links</a>
</p>

### milestone link test 1
--- input
milestone:1.0
--- expected
<p>
<a class="milestone" href="http://trac.mizzy.org/public/milestone/1.0">milestone:1.0</a>
</p>

### milestone link test 2
--- input
[milestone:1.0]
--- expected
<p>
<a class="milestone" href="http://trac.mizzy.org/public/milestone/1.0">1.0</a>
</p>

### milestone link test 3
--- input
[milestone:1.0 milestone 1.0]
--- expected
<p>
<a class="milestone" href="http://trac.mizzy.org/public/milestone/1.0">milestone 1.0</a>
</p>

### milestone link test 4
--- input
!milestone:1.0
--- expected
<p>
milestone:1.0
</p>

### milestone link test 5
--- input
![milestone:1.0]
--- expected
<p>
[milestone:1.0]
</p>

### attahcment link test 1
--- input
attachment:ticket:33:DSCF0001.jpg
--- expected
<p>
<a class="attachment" href="http://trac.mizzy.org/public/attachment/ticket/33/DSCF0001.jpg">attachment:ticket:33:DSCF0001.jpg</a>
</p>

### attahcment link test 2
--- input
attachment:wiki:TracLinks:DSCF0001.jpg
--- expected
<p>
<a class="attachment" href="http://trac.mizzy.org/public/attachment/wiki/TracLinks/DSCF0001.jpg">attachment:wiki:TracLinks:DSCF0001.jpg</a>
</p>

### attahcment link test 3
--- input
[attachment:ticket:33:DSCF0001.jpg]
--- expected
<p>
<a class="attachment" href="http://trac.mizzy.org/public/attachment/ticket/33/DSCF0001.jpg">ticket:33:DSCF0001.jpg</a>
</p>

### attahcment link test 4
--- input
[attachment:ticket:33:DSCF0001.jpg file]
--- expected
<p>
<a class="attachment" href="http://trac.mizzy.org/public/attachment/ticket/33/DSCF0001.jpg">file</a>
</p>

### attahcment link test 5
--- input
!attachment:ticket:33:DSCF0001.jpg
--- expected
<p>
attachment:ticket:33:DSCF0001.jpg
</p>

### attahcment link test 6
--- input
!attachment:wiki:TracLinks:DSCF0001.jpg
--- expected
<p>
attachment:wiki:TracLinks:DSCF0001.jpg
</p>

### attahcment link test 7
--- input
![attachment:wiki:TracLinks:DSCF0001.jpg]
--- expected
<p>
[attachment:wiki:TracLinks:DSCF0001.jpg]
</p>

### source link test 1
--- input
source:trunk/COPYING
--- expected
<p>
<a class="source" href="http://trac.mizzy.org/public/browser/trunk/COPYING">source:trunk/COPYING</a>
</p>

### source link test 2
--- input
source:trunk/COPYING#200
--- expected
<p>
<a class="source" href="http://trac.mizzy.org/public/browser/trunk/COPYING?rev=200">source:trunk/COPYING#200</a>
</p>

### source link test 3
--- input
[source:trunk/COPYING]
--- expected
<p>
<a class="source" href="http://trac.mizzy.org/public/browser/trunk/COPYING">trunk/COPYING</a>
</p>

### source link test 4
--- input
[source:trunk/COPYING COPYING]
--- expected
<p>
<a class="source" href="http://trac.mizzy.org/public/browser/trunk/COPYING">COPYING</a>
</p>

### source link test 5
--- input
[source:trunk/COPYING#200]
--- expected
<p>
<a class="source" href="http://trac.mizzy.org/public/browser/trunk/COPYING?rev=200">trunk/COPYING#200</a>
</p>

### source link test 6
--- input
[source:trunk/COPYING#200 COPYING]
--- expected
<p>
<a class="source" href="http://trac.mizzy.org/public/browser/trunk/COPYING?rev=200">COPYING</a>
</p>

### source link test 7
--- input
!source:trunk/COPYING
--- expected
<p>
source:trunk/COPYING
</p>

### source link test 8
--- input
!source:trunk/COPYING#200
--- expected
<p>
source:trunk/COPYING#200
</p>

### source link test 9
--- input
![source:trunk/COPYING]
--- expected
<p>
[source:trunk/COPYING]
</p>

### escaping links and wiki page names
--- input
== EscapingLinksand!WikiPageNames ==
--- expected
<h2 id="EscapingLinksandWikiPageNames"><a class="wiki" href="http://trac.mizzy.org/public/wiki/EscapingLinksand">EscapingLinksand</a>WikiPageNames</h2>

### comment link test 1
--- input
comment:ticket:1:8
--- expected
<p>
<a class="ticket" href="http://trac.mizzy.org/public/ticket/1#comment:8">comment:ticket:1:8</a>
</p>
