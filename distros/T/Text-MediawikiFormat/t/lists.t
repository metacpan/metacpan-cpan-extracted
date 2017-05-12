#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;

use Test::More tests => 8;
use Test::NoWarnings;

use_ok 'Text::MediawikiFormat', as => 'wf', process_html => 0 or exit;
ok exists $Text::MediawikiFormat::tags{blockorder}, 'T:MF should have a blockorder entry in %tags';

# isan ARRAY
isa_ok $Text::MediawikiFormat::tags{blockorder}, 'ARRAY', '...and it should be an array';

like join( ' ', @{ $Text::MediawikiFormat::tags{blockorder} } ), qr/^code/, '...and code should come before everything';

my $wikitext = <<END_HERE;
* first list item
* second list item
* list item with a [[Wiki Link]]
END_HERE

my $htmltext = wf($wikitext);

like $htmltext, qr!<li>first list item!, 'lists should be able to start on the first line of text';
like $htmltext, qr!href='Wiki%20Link'!,  'list item content should be formatted';

###
### Dictionary Lists
###
$wikitext = <<END_HERE;
; Term 1 : definition 1.1
: definition 1.2
; Term 2
: definition 2.1
: definition 2.2

: indented 1
: indented 2
END_HERE

$htmltext = wf($wikitext);

is $htmltext, '<dl>
<dt>Term 1</dt>
<dd>definition 1.1</dd>
<dd>definition 1.2</dd>
<dt>Term 2</dt>
<dd>definition 2.1</dd>
<dd>definition 2.2</dd>
</dl>
<dl>
<dd>indented 1</dd>
<dd>indented 2</dd>
</dl>
', 'dictionary lists format correctly';
