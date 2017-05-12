#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;

use Test::More tests => 9;
use Test::NoWarnings;

use_ok 'Text::MediawikiFormat', as => 'wf', process_html => 0 or exit;

my $wikitext = <<END_HERE;
* start of list
* second line
** indented list
* now back to the first
END_HERE

my $htmltext = wf($wikitext);
like $htmltext, qr|second line<ul>.*?<li>indented|s, 'nested lists should start correctly';
like $htmltext, qr|indented list.*?</li>.*?</ul>|s,  '... and end correctly';

$wikitext = <<END_HERE;
* 1
* 2
** 2.1
*** 2.1.1
* 3

* 4
** 4.1
*** 4.1.1
*** 4.1.2
* 5
END_HERE

$htmltext = wf($wikitext);

like $htmltext, qr|<ul>\s*
	<li>1</li>\s*
	<li>2<ul>\s*
	<li>2\.1<ul>\s*
	<li>2\.1\.1</li>\s*
	</ul>\s*
	</li>\s*
	</ul>\s*
	</li>\s*
	<li>3</li>\s*
	</ul>\s*
	<ul>\s*
	<li>4<ul>\s*
	<li>4\.1<ul>\s*
	<li>4\.1\.1</li>\s*
	<li>4\.1\.2</li>\s*
	</ul>\s*
	</li>\s*
	</ul>\s*
	</li>\s*
	<li>5</li>\s*
	</ul>|sx, 'nesting should be correct for multiple levels';
like $htmltext, qr|<li>4<|s, 'spaces should work instead of tabs';
like $htmltext, qr|<li>4<ul>\s*<li>4.1<ul>\s*<li>4.1.1</li>\s*<li>4.1.2</li>\s*</ul>
	\s*</li>|sx, 'nesting should be correct for spaces too';

TODO: {
	local $TODO = 'Dictionary lists not nesting correctly.';

###
### Dictionary Lists
###
	$wikitext = <<END_HERE;
; Term 1
: Def 1.1
:; Term 1.1.1 : Def 1.1.1.1
:; Term 1.1.2 : Def 1.1.2.1
:: Def 1.1.2.2
:; Term 1.1.3
:: Def 1.1.3.1
::; Term 1.1.3.1.1 : Def 1.1.3.1.1.1
; Term 2
: Def 2.1
: Def 2.2
:; Term 2.2.1 : Def 2.2.1.1
; Term 3 : Def 3.1
END_HERE

	$htmltext = wf($wikitext);

	is $htmltext, '', 'dictionary lists nest correctly';

	$wikitext = <<END_HERE;
; A
: A.a
:# A.a.1
:## A.a.1.1
:# A.a.2
:#* A.a.2.*
:#* A.a.2.*
:#*# A.a.2.*.1
: A.b
END_HERE

	$htmltext = wf($wikitext);

	is $htmltext, '<dl>
<dt>A</dt>
<dd>A.a</dd>
<ol>
<li>A.a.1<ol>
<li>A.a.1.1</li>
</ol>
</li>
<li>A.a.2<ul>
<li>A.a.2.*</li>
<li>A.a.2.*<ol>
<li>A.a.2.*.1</li>
</ol>
</li>
</ul>
</li>
</ol>
<dd>A.b</dd>
</dl>
', 'lists nest correctly within dictionary lists';
}
