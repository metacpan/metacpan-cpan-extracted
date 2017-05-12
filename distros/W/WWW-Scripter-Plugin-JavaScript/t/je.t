#!perl

# Copied from WWW::Mechanize::Plugin::JavaScript and modified.

# I have not got round to writing a complete set of tests yet. For now I’m
# just testing for fixed bugs and other changes.

use strict; use warnings;
use lib 't';
use Test::More;

use HTML'DOM 0.027;
use HTML::DOM::Interface ':all';
use URI::file;
use WWW::Scripter 0.016; # event2sub and $@

sub data_url {
	my $u = new URI 'data:';
	$u->media_type('text/html');
	$u->data(shift);
	$u
}

# blank page for playing with JS; some tests need their own, though
my $js = (my $m = new WWW::Scripter)->use_plugin('JavaScript',
	engine => 'JE'
);
$m->get(URI::file->new_abs( 't/blank.html' ));
$js->new_function($_ => \&$_) for qw 'is ok';

use tests 2; # fourth arg to new_function
{
	$js->new_function(foo => sub { return 72 }, 'String');
	$js->new_function(bar => sub { return 72 }, 'Number');
	is ($m->eval('typeof foo()'), 'string', 'third arg passed ...');
	is ($m->eval('typeof bar()'), 'number', '... to new_function');
}

use tests 1; # types of bound read-only properties
{
	is $m->eval(
		'typeof document.nodeType'
	), 'number', 'types of bound read-only properties';
}

use tests 2; # unwrap
{
	sub Foo::Bar::baz{
		return join ',', map ref||(defined()?$_:'^^'),@_
	};
	$js->bind_classes({
		'Foo::Bar' => 'Bar', 
		Bar => {
			baz => METHOD | STR
		}
	});
	$js->set($m, 'baz', bless[], 'Foo::Bar');
	is($m->eval('baz.baz(null, undefined, 3, "4", baz)'),
	   'Foo::Bar,^^,^^,JE::Number,JE::String,Foo::Bar', 'unwrap');

	is $m->eval("getComputedStyle(document.documentElement,null)"),
	  '[object CSSStyleDeclaration]',
	  'objects are unwrapped when passed to window methods';
}

use tests 4; # null DOMString
{
	sub Phoo::Bar::bar {
		return (undef,765)[!!pop];
	}
	sub Phoo::Bar::baz { "heelo" }
	sub Phoo::Bar::nullbaz {}
	$js->bind_classes({
		'Phoo::Bar' => 'Phoo', 
		Phoo => {
			bar => METHOD | STR,
			baz => STR,
			nullbaz => STR,
		}
	});
	$js->set($m, 'baz', bless[], 'Phoo::Bar');
	ok($m->eval('baz.bar(0) === null'),
		'undef --> null conversion for a DOMString retval');
	ok($m->eval('baz.bar(1) === "765"'),
		'any --> string conversion for a DOMString retval');
	ok($m->eval('baz.nullbaz === null'),
		'undef --> null conversion when getting a DOMString prop');
	ok($m->eval('baz.baz === "heelo"'),
		'any --> string conversion when getting a DOMString prop');
}

use tests 2; # window wrappers
{
	ok $m->eval('window === top'),
		'windows are wrapped up in global objects';
	ok $m->eval('window === document.defaultView'),
		'window === document.defaultView';
}

use tests 3; # frames
{
	$m->eval(q|
		document.write("<iframe id=i src='data:text/html,'>")
		document.close()
	|);
	ok $m->eval('frames[0] && "document" in frames[0] &&
			frames[0].document.defaultView == frames[0]'),
		'frame access by array index', or diag $@;
	ok $m->eval('frames.i && "document" in frames.i'),
		'frame access by name';
	ok $m->eval('frames.i === frames[0]'),
		'the two methods return the same object';
}

use tests 1; # var statements should create vars (broken in 0.006
{            # [Mech plugin])
	ok $m->eval(q|
		var zarbardar;
		"zarbardar" in this
	|), 'var statements without "=" do create the vars';
}

use tests 1; # form event attributes with unusable scope chains
{            # (broken in 0.002; fixed in 0.007 [Mech plugin])
 $m->get(URI::file->new_abs( 't/je-form-event.html' ));
 $m->submit_form(
       form_name => 'y',
       button    => 'Search Now'
  );
 like $m->uri->query, qr/x=lofasz/, 'form event attributes';
}

use tests 2; # inline HTML comments (support added in 0.002)
my $warnings;
local $SIG{__WARN__} = sub { ++$warnings; diag shift };

$m->get(data_url <<'</html>');
<script type="text/javascript" language="JavaScript">
    function isginnf(omr)
      {
      avrn <!--o=wnwe aDt(e);
      ofmr.itmzeoenOffste.avleu=onwg.teTmieoznOefsfe(t);
<!-- UU_OMDP L480003D PTA- >-
      ofr.muluoignwp.avleu=ofr.mpdw.avleu;
<!-- nEdU UM_O D->-
      ertrun; 
      }
</script>
</html>
 
ok(!$warnings,
   'no warnings (syntax errors) when HTML comments are embedded in JS');
ok $m->eval('isginnf'), 'The code around the HTML comments actually runs';

use tests 17; # Those weird and utterly useless HTML-generating string
              # methods that have been part of JavaScript since day 1.
is $m->eval('"pext".anchor("med")'), '<a name="med">pext</a>', '.anchor';
is $m->eval('"clit".big   (     )'), '<big>clit</big>'       , '.big'   ;
is $m->eval('"clile".blink(     )'), '<blink>clile</blink>'  , '.blink' ;
is $m->eval('"dwew" .bold (     )'), '<b>dwew</b>'           , '.bold'  ;
is $m->eval('"dro"  .fixed(     )'), '<tt>dro</tt>'          , '.fixed' ;
is $m->eval('"crin".fontcolor("drow")'), '<font color="drow">crin</font>',
 '.fontcolor';
is $m->eval('"brelp".fontsize("blat")'), '<font size="blat">brelp</font>',
 '.fontsize';
is $m->eval('"bleen".italics (      )'), '<i>bleen</i>'       , '.italics';
is $m->eval('"crare".link  ("blon")'), '<a href="blon">crare</a>', '.link';
is $m->eval('"bleck".small (      )'), '<small>bleck</small>'   , '.small';
is $m->eval('"blee" .strike(      )'), '<strike>blee</strike>' , '.strike';
is $m->eval('"bleard".sub  (      )'), '<sub>bleard</sub>'     , '.sub'   ;
is $m->eval('"clor"  .sup  (      )'), '<sup>clor</sup>'       , '.sup'   ;
is $m->eval('"byph".anchor()'), '<a name="undefined">byph</a>',
 '.anchor with no args';
is $m->eval('"bames".fontcolor()'), '<font color="undefined">bames</font>',
 '.fontcolor with no args';
is $m->eval('"blash".fontsize()'), '<font size="undefined">blash</font>',
 '.fontsize with no args';
is $m->eval('"brode".link()'), '<a href="undefined">brode</a>',
 '.link with no args';

use tests 4; # Existence of non-core global JS properties.
# It’s possible to make properties only half-exist, in that window.foo
# returns something, but it’s not a scope variable and the hasOwnProperty
# method can’t see it.  This was the case with collection properties  prior
# to version 0.004.
$m->document->innerHTML("<iframe name=ba>");
ok $m->eval('hasOwnProperty("document")'),
 'hasOwnProperty can see window properties listed by WWW::Scripter';
ok $m->eval('hasOwnProperty("ba")'),
 'hasOwnProperty can see collection properties of the window';
ok $m->eval('document'),
 'window properties listed by WWW::Scripter are in scope';
ok $m->eval('ba'),
 'collection properties of the window are in scope';

use tests 4; # HTML event handler scope
$m->back until $m->uri =~ /blank/;
$m->eval(q{
 document.innerHTML = "<form name=f><input id=it onclick='which=thing'>"
 var it = document.getElementById('it');
 window.thing="παράθι"
 it.click(); is(which, "παράθι", 'window is in event scope')
 document.thing='ἔγγραφον'
 it.click(); is(which,'ἔγγραφον','document shadows window in event scope')
 document.f.thing='μορφὴ'
 it.click(); is(which,'μορφὴ', 'form shadows document in event scope')
 it.thing='πράγμα'
 it.click(); is(which,'πράγμα', 'target shadows form in event scope')
});

use tests 2; # UTF-16
$m->eval("
 is((node=document.createTextNode('\x{10000}aa')).length,4,'UTF-16 prop');
 node.insertData(2,'b')
 is(node.data, '\x{10000}baa', 'UTF-16 method')
");

use tests 1; # frames retaining the same global object from one page to the
             # next (problem in 0.003 and earlier)
$m->document->innerHTML(q|<iframe name=f></iframe>|);
$m->eval(q|f.smow="bar"|);
$m->frames->{f}->get("data:text/html,");
is $m->eval("''+f.smow"), 'undefined',
 "JS-less frames get a new global object when a page is fetched";

use tests 1; # Calling JS methods on other windows (bug introduced in 0.004
             # along with proxies for global objects that fixed the previ-
             # ous test; fixed in 0.006)
{
 my $buffalo;
 $m->set_alert_function(sub{ $buffalo = shift });
 $m->frames->[0]->eval("top.alert(\"ooo\")");
 is $buffalo, 'ooo', 'calling methods with JS on other windows';
}

use tests 1; # syntax errors in HTML event attributes
{
 my $w;
 local $SIG{__WARN__} = sub { $w = shift };
 $m->get('data:text/html,<body onload="a b">');
 ok $w, "syntax errors in HTML event attributes are turned into warninsg";
}
