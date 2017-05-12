#!perl -w

# Test the ->base method.

use lib 't';
use warnings;
no warnings qw 'utf8 parenthesis regexp once qw bareword syntax';

use URI'file;

use WWW'Scripter;
$w = new WWW'Scripter;

use tests 1; # Multiple <base> tags.
$w->get('data:text/html,
 <base href="http://websms.rogers.page.ca/skins/rogers-oct2009/">
 <base href="http://websms.rogers.page.ca/skins/rogers-oct2009/">
');
is $w->base, "http://websms.rogers.page.ca/skins/rogers-oct2009/", 
   'base with multiple <base> tags';

use tests 2; # about:blank
{
 $w->get('about:blank');
 is $w->base, 'about:blank',
  'base is about:blank for a top-level about:blank window';
 $w->get(my $url = new_abs URI'file 't/empty-iframe.html');
 is +($w->frames)->[0]->base, $url,
  'about:blank in a frame gets its base from the parent window';
}