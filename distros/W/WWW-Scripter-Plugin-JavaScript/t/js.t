#!perl

# This was the original test file for wspjs. Then things started being
# moved into other files. Whatever is in here now is the miscellaneous
# stuff that didn’t fit anywhere else.

use strict; use warnings; use utf8;
use lib 't';
use Test::More;

use URI::file;
use WWW::Scripter 0.006; # submit method that triggers events

# blank page for playing with JS; some tests need their own, though
my $js = (my $m = new WWW::Scripter)->use_plugin('JavaScript');
$m->get(URI::file->new_abs( 't/blank.html' ));
$js->new_function($_ => \&$_) for qw 'is ok';

sub data_url {
	my $u = new URI 'data:';
	$u->media_type('text/html');
	$u->data(shift);
	$u
}


use tests 1; # class binding bug
{
	my $m;
	ok eval {
	($m = new WWW::Scripter)
	 ->use_plugin('JavaScript', engine => 'JE')
	 ->bind_classes({
		'My::Package' => 'foo',
		'foo' => {}
	 }); 1
	}, 'bind_classes works before a page is fetched';
}

use tests 2; # line numbers for inline scripts
{
	my $warning;
	local $SIG{__WARN__} = sub { $warning = shift;};

	(my $m = new WWW::Scripter)->use_plugin('JavaScript',
		engine => "JE");
	$m->get(URI::file->new_abs( 't/js-die.html' ));
	like $warning, qr/line 8(?!\d)/, 'line numbers for inline scripts';
	SKIP :{
		skip "requires HTML::DOM 0.012 or higher", 1
			if HTML::DOM->VERSION < 0.012;
		$m->document->getElementsByTagName('a')->[0]->
			trigger_event('click');
		like $warning, qr/line 11(?!\d)/,
			'line numbers for event attributes';
	}
}

use tests 1; # screen
{
	$m->eval('
		is(typeof this.screen, "object","screen object");
	');
}

use tests 2; # open
{
	$m->eval('
		open("foo"); // this will be a 404
	');
	like $m->uri, qr/foo$/, 'url after open()';
	$m->back;
	# ~~~ This is temporary. Once I have support for multiple windows,
	#     this test will have to be changed.
	like $m->uri, qr/blank\.html$/, 'open() adds to the history';
}

use tests 2; # navigator
{
	$m->eval('
		is(typeof this.navigator, "object","navigator object");
		is(navigator.appName,"WWW::Scripter","navigator.appName");
	') or diag $@;
}

use tests 2; # multiple JS environments
{
	# The purpose of creating a baz variable in one page, but not the
	# other, is to make sure that we are actually creating a new JS
	# environment, and not just overwriting existing variables.
	$m->get( data_url '<script>foo="bar",baz=1</script>' );
	$m->get( data_url '<script>foo="baz"</script>' );
	is $m->eval('foo+window.baz'), 'bazundefined',
		'which JS env are we in after going to another page?';
	$m->back;
	is $m->eval('foo+window.baz'), 'bar1',
		'and which one after we go back?';
	$m->back;
}

use tests 1; # location stringification
{
	$m->eval(
		'is(location, location.href, "location stringification")'
	);
}

use tests 2; # javascript:
{
	my $uri = $m->uri;
	$m->get("Javascript:%20foo=%22ba%ca%80%22");
	is $m->eval('foo'), 'baʀ', 'javascript: URLs are executed'
		or diag $@;
	is $m->uri, $uri, '  and do not affect the page stack'
		or diag $m->response->as_string;
}

use tests 1; # non-HTML pages
{
	(my $m = new WWW::Scripter)->use_plugin('JavaScript');
	$m->get('data:text/plain,');
	is eval{$m->eval("35")}, 35,
	  'JS is available even when the page is not HTML'
	   or diag $@;
}

use tests 4; # <!-- -->  (first two tests based on RT #43582 by Imre Rad)
{
	my $alert;
	(my $m = new WWW::Scripter)->use_plugin(JavaScript=>);
	$m->set_alert_function( sub { $alert = shift } );

	$m->get(data_url <<"_");
<html>
<head>
<script type="text/javascript" src="${\data_url(<<'__')}"></script>
<!--
window.alert("hello wrodl");
//-->
__
</head>
<body>
</body>
</html>
_
	is $alert, "hello wrodl", '<!-- in external JS file';

	$m->get(data_url <<'_');
<script>
<!--
window.alert("foobar");
-->
</script>
_
	is $alert, "foobar", 'trailing --> without //';

	$m->get('javascript:<!--%0aalert("hoetn")');
	is $alert, "hoetn", "javascript:<!--%0a URLs";

	my $warning;
	local $SIG{__WARN__} = sub { $warning = shift;};
	$m->get(data_url<<'_');
<title></title>>
<script type='application/javascript'>


<!--
pweegonk() // line 6
</script>
_
	like $warning, qr/line 6/, 'line numbers after <script>\n\n\n<!--';
}

use tests 3; # event handlers
{
 $m->get(my $url = data_url <<'');
  <form name=f onsubmit='return false' action="404">

 $m->submit;
 is $m->uri, $url, '<form onsubmit="return false">' or back $m;
 
 like $m->eval(" document.f.onsubmit "), qr/return false/,
  'form.onsubmit returns a JS function when assigned via the HTML attr';
  # used to return function { [native code] }

 $m->eval(" document.f.onsubmit = function(){ return false } ");
 $m->submit;
 is $m->uri, $url, 'form.onsubmit=function(){return false}';
}

use tests 1; # iframes (bug in 0.003 and earlier)
{
 my $iframe_url = data_url <<'';
  <script>top.pass = this == top[0]</script>

 $m->get(my $url = data_url "<iframe src='$iframe_url'>");
 
 ok $m->eval('pass'),
  'scripts in iframes run in the correct JS environment';
}
