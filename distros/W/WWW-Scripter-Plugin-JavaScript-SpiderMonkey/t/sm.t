#!perl

# ~~~ We still need a complete test suite.... Probably a class provided by
#     the JS plugin that allows any back end to run the same tests....

use strict; use warnings;
use lib 't';
use Test::More;

use HTML::DOM::Interface ':all';
use URI::file;
use WWW::Scripter 0.016; # event2sub and $@

# blank page for playing with JS; some tests need their own, though
my $js = (my $m = new WWW::Scripter)->use_plugin('JavaScript',
	engine => 'SpiderMonkey'
);
$m->get(URI::file->new_abs( 't/blank.html' ));
$js->new_function($_ => \&$_) for qw 'is ok';

use tests 1; # types of bound read-only properties
{
#warn $m->eval('String(document.__proto__)');
	is $m->plugin('JavaScript')->eval(
		$m, 'typeof document.nodeType'
	), 'number', 'types of bound read-only properties';
}

use tests 1; # values passed back and forth
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
	is($js->eval($m, 'baz.baz(null, undefined, 3, "4", baz)'),
	   'Foo::Bar,^^,^^,3,4,Foo::Bar', 'passing objects');
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
	ok($js->eval($m, 'baz.bar(0) === null'),
		'undef --> null conversion for a DOMString retval');
	ok($js->eval($m, 'baz.bar(1) === "765"'),
		'any --> string conversion for a DOMString retval');
	ok($js->eval($m, 'baz.nullbaz === null'),
		'undef --> null conversion when getting a DOMString prop');
	ok($js->eval($m, 'baz.baz === "heelo"'),
		'any --> string conversion when getting a DOMString prop');
}

use tests 2; # window wrappers
SKIP:{ skip "doesn’t work yet" ,2;
	ok $js->eval($m, 'window === top'),
		'windows are wrapped up in global objects';
	ok $js->eval($m, 'window === document.defaultView'),
		'window === document.defaultView';
}

use tests 3; # frames
SKIP:{ skip "doesn’t work yet" ,3;
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


use tests 1; # syntax errors in HTML event attributes
{
 my $w;
 local $SIG{__WARN__} = sub { $w = shift };
 $m->get('data:text/html,<body onload="a b">');
 ok $w, "syntax errors in HTML event attributes are turned into warninsg";
}
