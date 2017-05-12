#!perl

use strict; use warnings;
use lib 't';
use Test::More;

use utf8;
use WWW::Scripter;
use WWW::Scripter::Plugin::JavaScript 0.002; # new init interface
use HTTP::Headers;
use HTTP::Response;

# The HTML serialisation test triggers a bug in older versions of JE.
eval{require WWW'Scripter'Plugin'JavaScript'SpiderMonkey}
 or eval '1;use JE 0.041' or die $@;

our %SRC;

# For faking HTTP requests; this gets the source code from the global %SRC
# hash, using the "$method $url" as the key. Each element of the hash
# is an array ref containing (0) the Content-Type and (1) text that is to
# become the body of the response or a coderef.
no warnings 'redefine';
{
	package FakeProtocol;
	use LWP::Protocol;
	our @ISA = LWP::Protocol::;

	LWP'Protocol'implementor $_ => __PACKAGE__ for qw/ http file /;

	sub _create_response_object {
		my $request = shift;

		my $src_ary =
			$'SRC{join ' ',method $request,$request->uri};
		my $h = new HTTP::Headers;
		header $h 'Content-Type', $$src_ary[0] if $src_ary;
		my $r = new HTTP::Response
			$src_ary
				? (200, 'Okey dokes')
				: (404, 'Knot found'),
			$h;
		$r, $src_ary && ref $$src_ary[1]
			? $$src_ary[1]->($request)
			: $$src_ary[1];

	}

	sub request {
		my($self, $request, $proxy, $arg) = @_;
	
		          # This weird syntax ensures it can be overridden:
		my($response,$src) =
			(\&{'_create_response_object'})->($request);

		my $done;
		defined $src or $src = "";
		$self->collect($arg, $response, sub {
			\($done++ ? '' : "$src")
			      # LWP has a heart attack without those quotes
		});
	}
	
}

# For echo requests (well, not exactly; the responses have an HTTP response
# header as well)
$SRC{'POST http://foo.com/echo'}=['text/plain; charset=iso-8859-1',sub{ shift->as_string }];
$SRC{'GET http://foo.com/echo'}=['text/plain; charset=iso-8859-1',sub{ shift->as_string }];


my $m = new WWW::Scripter;

#----------------------------------------------------------------#
use tests 1; # plugin isa

isa_ok $m->use_plugin('Ajax' => init => sub {
	for my $js_plugin(shift->plugin('JavaScript')){
		$js_plugin->new_function($_ => \&$_)
			for qw 'ok is diag pass fail unlike like';
	}
}), 'WWW::Scripter::Plugin::Ajax';


#----------------------------------------------------------------#
use tests 2; # inline & constructor

$SRC{'GET http://foo.com/inline.html'}=['text/html',<<'EOT'];
<title>Tests that checks whether AJAX works inline and the constructor's
basic functionality is present</title>
<script type='application/javascript'>

var request = new XMLHttpRequest
is(typeof request, 'object', 'typeof new XMLHttpRequest')
is(request, '[object XMLHttpRequest]',
	'stringification of the new object')

</script>
EOT
$m->get('http://foo.com/inline.html');



#----------------------------------------------------------------#
use tests 37; # basic request, setRequestHeader, and responseText

defined $m->eval(<<'EOT2') or die;
	
	with(request) {
		open('POST','http://foo.com/echo',0),
		setRequestHeader('User-Agent', 'wmpajax'),
		setRequestHeader('Accept-Language','el'),
		setRequestHeader('Ignore-This', null),
		setRequestHeader('accept-encoding', 'Carmigian'),
		setRequestHeader('connectiON', 'user-agent'),
		setRequestHeader('content-length', 2),
		setRequestHeader('contEnt-Transfer-encoding', 'chunked'),
		setRequestHeader('date', '1 jan 1929'),
		setRequestHeader('expect', 'stand-on-one-leg'),
		setRequestHeader('host', 'www.apple.com'),
		setRequestHeader('kEep-Alive', 'and well'),
		setRequestHeader('reFeRer', "http://google.com/"),
		setRequestHeader('Te', 'kori'),
		setRequestHeader('traIler', 'x-foo'),
		setRequestHeader('transfer-encoding', 'gzip'),
		setRequestHeader('upgrade', 'HTTP/7.0'),
		setRequestHeader('via', 'http://1.2.3.4/'),
		setRequestHeader('proxy-whatever', 'eetewvw'),
		setRequestHeader('sec-otnoned', 'eeetewvw'),
		send('stuff'),
		ok(status === 200, '200 status') ||
			diag(status+' '+typeof status),
		ok(responseText.match(
			/^POST http:\/\/foo\.com\/echo\r?\n/
		), 'first line of request (POST ...) and responseText'),
		ok(responseText.match(/^User-Agent: wmpajax$/m),
			'User-Agent in request'),
		ok(responseText.match(/^Accept-Language: el$/m),
			'Accept-Language in request'),
		ok(responseText.match(/\r?\n\r?\nstuff(?:\r?\n)?$/),
			'body of the request')
			|| diag(responseText),
		ok(!responseText.match(/Ignore-This/i),
			'setRequestHeader(foo,null) is ignored'),
		ok(!responseText.match(/accept-encoding:.*Carmigian/i),
			'setRequestHeader ignores Accept-Encoding'),
		ok(!responseText.match(/connection/i),
			'setRequestHeader ignores Connection header'),
		ok(!responseText.match(/content-length: 2/i),
			'setRequestHeader ignores Content-Length'),
		ok(responseText.match(/^Content-Length: 5$/m),
			'send adds its own Content-Length'),
		ok(!responseText.match(/content-transfer-encoding/i),
		  'setRequestHeader ignores Content-Transfer-Encoding'),
		ok(!responseText.match(/date/i),
			'setRequestHeader ignores Date header'),
		ok(!responseText.match(/Expect/i),
			'setRequestHeader ignores Expect header'),
		ok(!responseText.match(/host/i),
			'setRequestHeader ignores Host header'),
		ok(!responseText.match(/keep-alive/i),
			'setRequestHeader ignores "Stay alive!" header'),
		ok(!responseText.match(/referer: http:\/\/google/i),
			'setRequestHeader ignores Referer'),
		ok(!responseText.match(/\bte\b/i),
			'setRequestHeader ignores TE'),
		ok(!responseText.match(/Trailer/i),
			'setRequestHeader ignores Trailer header'),
		ok(!responseText.match(/transfer-encoding/i),
			'setRequestHeader ignores Transfer-Encoding'),
		ok(!responseText.match(/upgrade/i),
			'setRequestHeader ignores Upgrade header'),
		ok(!responseText.match(/via/i),
			'setRequestHeader ignores Via header'),
		ok(!responseText.match(/proxy-/i),
			'setRequestHeader ignores Proxy-*'),
		ok(!responseText.match(/sec-/i),
			'setRequestHeader ignores Sec-*')
	}
	0,function(){with(new XMLHttpRequest) {
		try{ setRequestHeader('no','tono');
		     fail('setRequestHeader fails to die before open');
		     fail('setRequestHeader fails to die before open');
		}catch(e) {
			ok(e instanceof DOMException,
			 'class of error; setRequestHeader b4 open')
			is(e.code, DOMException.INVALID_STATE_ERR,
			  'error code after setRequestHeader b4 open')
		}
		open('POST','http://foo.com/echo',1)
		try{ setRequestHeader('n\\o','tono');
		     fail('setRequestHeader with invalid header name');
		     fail('setRequestHeader with invalid header name');
		}catch(e) {
		  ok(e instanceof DOMException,
		    'class of error ' +
		    '(setRequestHeader w/invalid header name)')
		  is(e.code, DOMException.SYNTAX_ERR,
		    'error code after setRequestHeader w/invalid header')
		}
		try{ setRequestHeader('no','t\x08ono');
		     fail('setRequestHeader with invalid header value');
		     fail('setRequestHeader with invalid header value');
		}catch(e) {
		  ok(e instanceof DOMException,
		    'class of error ' +
		    '(setRequestHeader w/invalid header value)')
		  is(e.code, DOMException.SYNTAX_ERR,
		    'error code after setRequestHeader w/invalid value')
		}
		var tn = {}
		tn[XMLHttpRequest.OPENED] = 'on send';
		tn[XMLHttpRequest.HEADERS_RECEIVED]
			= 'upon receipt of headers';
		tn[XMLHttpRequest.LOADING] = 'while loading';
		tn[XMLHttpRequest.DONE] = 'when req is done';
		onreadystatechange = function() {
			try{ setRequestHeader('no','tono');
			  fail('setRequestHeader fails to die '
			    + tn[readyState]);
			  fail('setRequestHeader fails to die '
			    + tn[readyState]);
			}catch(e) {
			  ok(e instanceof DOMException,
			   'class of error; setRequestHeader '
			      + tn[readyState])
			  is(e.code, DOMException.INVALID_STATE_ERR,
			    'error code after setRequestHeader '
			      +tn[readyState])
			}
		}
		send('stuff')
	}}()
EOT2


#----------------------------------------------------------------#
use tests 2; # GET and send(null)

defined $m->eval(<<'EOT3') or die;
	with(request)
		open('GET','http://foo.com/echo',0),
		send(null),
		ok(responseText.match(
			/^GET http:\/\/foo\.com\/echo\r?\n/
		), 'first line of request (GET ...)'),
		ok(responseText.match(/\r?\n\r?\n$/), 'send(null)')

EOT3


#----------------------------------------------------------------#
use tests 16; # name & password
{
	# I’ve got to override one of FakeProtocol’s function, since what
	# we have above is not sufficient for this case.

	no warnings 'redefine';
	local *FakeProtocol::_create_response_object = sub {
		my $request = shift;

		my $h = new HTTP::Headers;
		header $h 'Content-Type', 'text/html; charset=iso-8859-1';
		header $h 'WWW-Authenticate', 'basic realm="foo"';
		my $auth_present = $request->header('Authorization');
		my $r = new HTTP::Response
			$auth_present
			? (200, "hokkhe", $h)
			: (401, "Hugo's there", $h);
		my $src =
			$auth_present
			? '<title>Wellcum</title><h1>'.
			  $request->authorization_basic .'</h1>'
			: '<title>401 Forbidden</title><h1>Fivebidden</h1>'
			;
#use DDS;
#diag Dump $request->authorization_basic;
		$r, $src;
	};

	defined $m->eval(<<'	EOT3b') or die;
		with(request)
			open('GET','http://foo.com/echo',0),
			send(null),
			is(status, 401, ' \x08401'),
			ok(responseText.match(/Fivebidden/), '401 msg'),
			open('GET','http://foo.com/echo',0,'me','dunno'),
			send(null),
			ok(responseText.match(/>me:dunno</),
				'authentication')
				 || diag(getAllResponseHeaders()),
			open('GET','http://foo.com/echo',0),
			send(null),
			ok(responseText.match(/>me:dunno</),
				'auth info is preserved by send')
		with(new XMLHttpRequest)
			open('GET','http://foo.com/echo',0),
			send(null),
			is(status,401,
				'credentials don\'t leak 2 other xhrs')
		with(request) {
			open('GET','http://y%6fu:d%6fono@foo.com/echo',0),
			send(null),
			ok(responseText.match(/>you:doono</),
				'credentials in the URL')
				 || diag(responseText),
			open('GET','http://me@foo.com/echo',0),
			send(null),
			ok(responseText.match(/>me:doono</),
				'name@ in URL; password from last time')
				 || diag(responseText),
			open('GET','http://me:@foo.com/echo',0),
			send(null),
			ok(responseText.match(/>me:</),
				'blank password in URL')
				 || diag(responseText),
			open('GET','http://him:her@foo.com/echo',0,'name'),
			send(null),
			ok(responseText.match(/>name:her</),
				'name arg overriding url')
				 || diag(responseText),
			open('GET','http://hymned:heard@foo.com/echo',0,
				'name','pwd'),
			send(null),
			ok(responseText.match(/>name:pwd</),
				'both name and pw args overriding url')
				 || diag(responseText),
			open('GET','http://hymned:heard@foo.com/echo',0,
				'name', null),
			send(null),
			ok(responseText.match(/>name:</),
				'null pwd arg overriding url')
				 || diag(responseText),
			open('GET','http://hymned:heard@foo.com/echo',0,
				null),
			send(null),
			is(status, 401, 'null name arg')

			try{ open('GET','http://foo.com/',0,'a:b','c');
			     fail('name with colon should die')
			     fail('name with colon should die')
			}catch(e){
			 ok(
			   e instanceof DOMException,
			  'name with colon produces DOMException'
			 )
			 is(
			   e.code, DOMException.SYNTAX_ERR,
			  'name with colon produces SYNTAX_ERR'
			 )
			}

			open('GET','http://foo.com/echo',0,
				'ÿ', 'þ'),
			send(null),
			ok(
			  responseText.match(/>Ã¿:Ã¾</),
			 'UTF-8 encoding for name & pw in octet range'
			) || diag(responseText)
			open('GET','http://foo.com/echo',0,
				'əɯɐu', 'pɹoʍssɐd'),
			send(null),
			ok(responseText.match(/>ÉÉ¯Éu:pÉ¹oÊssÉd</),
				'UTF-8 encoding for name & pw')
				 || diag(responseText)
		}
	EOT3b
}


#----------------------------------------------------------------#
use tests 3; # cookies
defined $m->eval(<<'EOT4') or die;
	document.cookie="foo=bar;expires=" +
	    new Date(new Date().getTime()+24000*3600*365).toGMTString();
	    // shouldn't take more than a year to run this test :-)
	with(request)
		open('GET','http://foo.com/echo',0),
		send(),
		ok(responseText.match(
			/^Cookie: foo=bar$/m
		), 'real cookies') || diag(responseText),
		open('GET','http://foo.com/echo',0),
		setRequestHeader('Cookie','baz=bonk'),
		send(),
		ok(  responseText.match(
		 /^Cookie: (?:foo=bar; baz=bonk|baz=bonk; foo=bar)$/m
		), 'phaque cookies') || diag(responseText)
	// erase the real cookie:
	document.cookie="foo=bar;expires=" +
	    new Date(new Date().getTime()-24000).toGMTString();
	with(request)
		open('GET','http://foo.com/echo',0),
		setRequestHeader('Cookie','baz=bonk'),
		send(),
		is(responseText.match(/^Cookie: baz=bonk$/mg).length, 1,
			'phake cookies without real ones')
		|| diag('Contains too many occurrences of baz=bonk:\n'
			+ responseText)
EOT4


#----------------------------------------------------------------#
use tests 1; # 404

defined $m->eval(<<'EOT5') or die;
	with(request)
		open('GET','http://foo.com/eoeoeoeoeo',0),
		send(null),
		ok(status === 404, " \x08404")

EOT5


#----------------------------------------------------------------#
use tests 10; # responseXML

# XML example stolen from XML::DOM::Lite’s test suite
$SRC{'GET http://foo.com/xmlexample'}=['text/xml',<<XML];
<?xml version="1.0"?>
<!-- this is a comment -->
<root>
  <item1 attr1="/val1" attr2="val2">text</item1>
  <item2 id="item2id">
    <item3 instance="0"/>
    <item4>
      deep text 1
      <item5>before</item5>
      deep text 2
      <item6>after</item6>
      deep text 3
    </item4>
    <item3 instance="1"/>
  </item2>
  some more text
</root>
XML

$SRC{'GET http://foo.com/appxmlexample'}=['application/xml',<<XML2];
<?xml version="1.0"?><root>app</root>
XML2

$SRC{'GET http://foo.com/+xmlexample'}=['image/foo+xml',<<XML3];
<?xml version="1.0"?><root>+xml</root>
XML3

$SRC{'GET http://foo.com/badxml'}=['text/xml',<<XML4];
<?xml version="1.0"?<root>bad</root>
XML4

$SRC{'GET http://foo.com/htmlexample'}=['text/html',<<HTML];
<title> This is a small HTML document</title>
<p>Which is perfectly valid except for the missing doctype header even
though it's missing half its tags
HTML

defined $m->eval(<<'EOT6') or die;
	with(request)
		open('GET','http://foo.com/htmlexample',0),
		send(null),
		ok(responseXML===null, 'null responseXML'),
		open('GET','http://foo.com/xmlexample'),
		send(),
		ok(responseXML, 'responseXML object')
			||diag(status + ' ' + responseText),
		is(responseXML.documentElement.nodeName, 'root',
			'various...'),
		is(responseXML.documentElement.childNodes.length, 5,
			'    parts of'),
		is(responseXML.documentElement.childNodes[1].nodeName,
			'item1',
			'    the XML'),
		is(responseXML.documentElement.childNodes[0].nodeName,
			'#text',
			'    DOM tree'),
		// If those pass, I think we can trust it’s working.

		open('GET','http://foo.com/appxmlexample'),
		is(responseXML, null, 'responseXML after open'),
		send(),
		is(responseXML.documentElement.firstChild.nodeValue, 'app',
			'responseXML with application/xml'),
		abort(),
		is(responseXML, null, 'responseXML after abort'),
		open('GET','http://foo.com/+xmlexample'),
		send(),
		is(responseXML.documentElement.firstChild.nodeValue,'+xml',
			'responseXML with any/thing+xml')//,
		//open('GET','http://foo.com/badxml'),
		//send(),
		//ok(responseXML===null, 'invalid XML')
		// ~~~ XML::DOM::Lite is too lenient for this test to mean
		//     anything
EOT6


#----------------------------------------------------------------#
use tests 2; # statusText
defined $m->eval(<<'EOT7') or die;
	with(request)
		open('GET','http://foo.com/eoeoeoeoeo',0),
		send(null),
		ok(statusText === 'Knot found', "404 statusText"),
		open('GET','http://foo.com/echo',0),
		send(null),
		ok(statusText === 'Okey dokes', "200 statusText")
EOT7


#----------------------------------------------------------------#
use tests 8; # get(All)ResponseHeader(s)
defined $m->eval(<<'EOT8') or die;
	with(request) {
		abort()
		try{ getAllResponseHeaders();
		     fail("getAllResponseHeaders before open")
		     fail("getAllResponseHeaders before open") }
		catch(_) {
		 ok(
		  _ instanceof DOMException,
		  "getAllResponseHeaders error b4 open isa DOMException"
		 )
		 is(
		   _.code, DOMException.INVALID_STATE_ERR,
		  'error code after getAllResponseHeaders b4 open'
		 )
		}

		open('GET','http://foo.com/echo',0),
		send(null),
		ok(getAllResponseHeaders().match(
		 /^Content-Type: text\/plain; charset=iso-8859-1\r\n/
		), "getAllResponseHeaders")||diag(getAllResponseHeaders()),
		ok(
		 /^text\/plain;/.test(getResponseHeader('Content-Type')),
			'getResponsHeader');

		open('GET','http://foo.com/echo',0)
		try{ getAllResponseHeaders();
		     fail("getAllResponseHeaders after open")
		     fail("getAllResponseHeaders after open") }
		catch(_) {
		 ok(
		  _ instanceof DOMException,
		  "error from getAllResponseHeaders is a DOMException"
		 )
		 is(
		   _.code, DOMException.INVALID_STATE_ERR,
		  'error code after getAllResponseHeaders'
		 )
		}
		try{ getResponseHeader("content-type");
		     fail("getResponseHeader after open")
		     fail("getResponseHeader after open") }
		catch(_) {
		 ok(
		  _ instanceof DOMException,
		  "error from getResponseHeader is a DOMException"
		 )
		 is(
		   _.code, DOMException.INVALID_STATE_ERR,
		  'error code after getResponseHeader'
		 )
		}
	}
EOT8


#----------------------------------------------------------------#
use tests 8; # onreadystatechange and readyState
$m->document->error_handler(sub { push @::event_errors, $@ });
defined $m->eval(<<'EOT9') or die;
0,function(){ // the function scope provides us with a var ‘scratch-pad’
	with(new XMLHttpRequest) {
		var mystate = '';
		onreadystatechange = function(){
			mystate += readyState
		}
		ok(readyState === 0, 'readyState of fresh XHR obj')
		open('GET','http://foo.com/htmlexample',0)
		ok(readyState === 1,'readyState after open')
		is(mystate, 1, 'open triggers onreadystatechange')
		send(null)
		ok(readyState === 4, 'readyState after completion')
		is(mystate, '14',
		 'sync orsc is triggered for state 4 but not 1.5 to 3')

		mystate = ''
		open('GET','http://foo.com/htmlexample')
		is(mystate, 1, 'async open triggers onreadystatechange')
		send(null)
		is(mystate, '11234',
		 'async orsc is triggered for all states')

		open('GET','http://foo.com/htmlexample',0)
		onreadystatechange = null
		send()
	}
}()
EOT9
is_deeply join('',@'event_errors), '',
   'no errors are caused by onreadystatechange=null when the event occurs';


#----------------------------------------------------------------#
use tests 5; # unwritability of the properties
defined $m->eval(<<'EOT10') or die;
0,function(){
	var $f = function(){}
	$f.prototype = new XMLHttpRequest
	with(new $f())
		readyState='foo',
		ok(readyState===0,'readyState is read-only'),
		responseText='foo',
		ok(responseText==='','responseText is read-only'),
		readyState='responseXML',
		ok(responseXML===null,'responseXML is read-only'),
		$f.prototype.open('GET','http://foo.com',0),
			$f.prototype.send(),
		ok(status===404,'status is read-only'),
		statusText='foo',
		ok(statusText==='Knot found','statusText is read-only')
}()
EOT10


#----------------------------------------------------------------#
use tests 13; # response encoding
$SRC{'GET http://foo.com/explicit_utf-8.text'}=
	['text/plain; charset=utf-8',"oo\311\237"];
$SRC{'GET http://foo.com/implicit_utf-8.text'} =
	['text/plain',"\311\271aq"];
$SRC{'GET http://foo.com/utf-16be.text'} =
	['text/plain; charset=utf-16be',
	 "\1\335\2\207\2P\2y\0o\2m\2m\1\335\2m\0n\2o\0n\2T\2y\35\t\2T"];
$SRC{'GET http://foo.com/latin-1.text'} =
	['text/plain; charset=iso-8859-1',"\311\271aq"];
$SRC{'GET http://foo.com/greexml'}
 = [
     'application/xml',
     "<?xml encoding='iso-8859-7'?>\xcc\xdf\xe1 "
    ."\xf0\xdc\xf0\xe9\xe1, \xec\xe1 \xf0\xef\xe9\xdc "
    ."\xf0\xdc\xf0\xe9\xe1;"
   ];
$SRC{'GET http://foo.com/greexml.html'}
 = [
     'text/html',
     "<meta http-equiv=content-type "
    ."content='text/html;charset=iso-8859-10'>"
    ."\xcc\xdf\xe1 "
    ."\xf0\xdc\xf0\xe9\xe1, \xec\xe1 \xf0\xef\xe9\xdc "
    ."\xf0\xdc\xf0\xe9\xe1;"
   ];
$SRC{'GET http://foo.com/nontext-utf-32be'}
 = ['application/non-text',"\0\0\xfe\xff\0\0\0 "];
$SRC{'GET http://foo.com/nontext-utf-32le'}
 = ['application/non-text',"\xff\xfe\0\0 \0\0\0"];
$SRC{'GET http://foo.com/nontext-utf-16be'}
 = ['application/non-text',"\xfe\xff\0 "];
$SRC{'GET http://foo.com/nontext-utf-16le'}
 = ['application/non-text',"\xff\xfe \0"];
$SRC{'GET http://foo.com/nontext-utf-8'}
 = ['application/non-text',"\xef\xbb\xbf\xc4\x80"];
$SRC{'GET http://foo.com/nontext-utf-8-without-bomb'}
 = ['application/non-text',"\xc4\x80"];
$SRC{'GET http://foo.com/nontext-invalid-utf-8'}
 = ['application/non-text',"\xc4\x80\xff\xff\xff\xff "];

defined $m->eval(<<'EOT11') or die;
	with(new XMLHttpRequest)
		open('GET','http://foo.com/explicit_utf-8.text',0),
		send(null),
		is(responseText, 'ooɟ','explicit utf-8 header'),
		open('GET','http://foo.com/implicit_utf-8.text',0),
		send(null),
		is(responseText, 'ɹaq','implicit charset'),
		open('GET','http://foo.com/utf-16be.text',0),
		send(null),
		is(responseText, 'ǝʇɐɹoɭɭǝɭnɯnɔɹᴉɔ', 'utf-16be charset'),
		open('GET','http://foo.com/latin-1.text',0),
		send(null),
		is(responseText, 'É¹aq', 'iso-8859-1 for the charset'),
		open('GET','http://foo.com/greexml',0),
		send(null),
		is(
		  responseText,
		 "<?xml encoding='iso-8859-7'?>Μία πάπια, μα ποιά πάπια;",
		 'XML wiith <?xml encoding?>'
		),
		open('GET','http://foo.com/greexml.html',0),
		send(null),
		is(
		   responseText,
		  '<meta http-equiv=content-type '
		 +"content='text/html;charset=iso-8859-10'>"
		 +'Ėßá ðÜðéá, ėá ðïéÜ ðÜðéá;',
		  'HTML with <meta http-equiv=content-type>'
		),
		open('GET','http://foo.com/nontext-utf-32be',0),
		send(null),
		ok(
		  /^\ufeff? $/.test(responseText),
		 'non-text with utf-32be bomb'
		),
		open('GET','http://foo.com/nontext-utf-32le',0),
		send(null),
		ok(
		  /^\ufeff? $/.test(responseText),
		 'non-text with utf-32le bomb'
		),
		open('GET','http://foo.com/nontext-utf-16be',0),
		send(null),
		ok(
		  /^\ufeff? $/.test(responseText),
		 'non-text with utf-16be bomb'
		),
		open('GET','http://foo.com/nontext-utf-16le',0),
		send(null),
		ok(
		  /^\ufeff? $/.test(responseText),
		 'non-text with utf-32le bomb'
		),
		open('GET','http://foo.com/nontext-utf-8',0),
		send(null),
		ok(
		  /^\ufeff?Ā$/.test(responseText),
		 'non-text with utf-8 bomb'
		),
		open('GET','http://foo.com/nontext-utf-8-without-bomb',0),
		send(null),
		is(responseText, 'Ā','non-text with no bomb'),
		open('GET','http://foo.com/nontext-invalid-utf-8',0),
		send(null),
		is(
		 responseText, 'Ā\ufffd ','UTF-8 with invalid sequences'
		)
EOT11


#----------------------------------------------------------------#
use tests 4; # status & statusText exceptions
defined $m->eval(<<'EOT12') or die;
	with(new XMLHttpRequest) {
		try{status;fail('status exception before open')}
		catch($){pass('status exception before open')}
		try{statusText;fail('statusText exception before open')}
		catch($){pass('statusText exception before open')}
		open('GET','http://foo.com//eoeoeoeoeo',0)
		try{status;fail('status exception before send')}
		catch($){pass('status exception before send')}
		try{statusText;fail('statusText exception before send')}
		catch($){pass('statusText exception before send')}
	}
EOT12


#----------------------------------------------------------------#
use tests 1; # file protocol and relative URIs
$SRC{'GET file:///stuff'} = ['text/html','<title>stuff</title><p>'];
$SRC{'GET file:///morestuff'} = ['text/html','<title>morstuff</title><p>'];
$m->get('file:///stuff');
defined $m->eval(<<'EOT1\3') or die;
	with(new XMLHttpRequest) {
		open ("GET", "morestuff")
		send(null)
		ok(responseText.match(/morstuff/),
			'file:// and relative URIs') || diag(responseText)
	}
EOT1\3


#----------------------------------------------------------------#
use tests 29; # s’curity (including redirects) and network errors
$m->get('http://foo.com/htmlexample');
defined $m->eval(<<'EOT14') or die;
	with(new XMLHttpRequest) {
		try{open('GET','http://foo.com:8');
			fail('exception on open with wrong port')
			fail('exception on open with wrong port')}
		catch($){
			ok($ instanceof DOMException,
			 'class of error thrown by open w/wrong port')
			is($.code, 18/*~~~SECURITY_ERR*/,
			  'error code after open w/wrong port')
		}
		try{open('GET','http://www.foo.com/');
			fail('exception on open with wrong host')
			fail('exception on open with wrong host')}
		catch($){
			ok($ instanceof DOMException,
			 'class of error thrown by open w/wrong host')
			is($.code, 18/*~~~SECURITY_ERR*/,
			  'error code after open w/wrong host')
		}
		try{open('GET','ftp://www.foo.com/');
			fail('exception on open with wrong scheme')
			fail('exception on open with wrong scheme')}
		catch($){
			ok($ instanceof DOMException,
			 'class of error thrown by open w/wrong scheme')
			is($.code, 18/*~~~SECURITY_ERR*/,
			  'error code after open w/wrong scheme')
		}
		try{open('GET','ftp://localhost:5432/ooo');
			fail('exception on open with everything wrong')
			fail('exception on open with everything wrong')}
		catch($){
			ok($ instanceof DOMException,
			 'class of err thrown by open w/everything wrong')
			is($.code, 18/*~~~SECURITY_ERR*/,
			  'error code after open w/everything wrong')
		}
	}
EOT14
$SRC{'GET data:text/html,%3Ctitle%3E%3C/title%3E%3Cp%3E'}
	= ['text/html','<title></title><p>'];
$m->get('data:text/html,%3Ctitle%3E%3C/title%3E%3Cp%3E');
defined $m->eval(<<'EOT15') or die;
	try{new XMLHttpRequest().open('GET','data:,Perl%20is%20good');
	    fail('exception on open when neither iri has an ihost part')
	    fail('exception on open when neither iri has an ihost part')}
	catch($){
		ok($ instanceof DOMException,
		 'class of err thrown by open w/two non-ihost paths')
		is($.code, 18/*~~~SECURITY_ERR*/,
		  'error code after open w/two non-ihost paths')
	}
EOT15
{
	no warnings 'redefine';

	$m->get('http://foo.com/htmlexample');

	# Infinite redirect
	local *FakeProtocol::_create_response_object = sub {
		my $request = shift;
		(my $uri = $request->uri->clone)->path('/'.rand);

		my $h = new HTTP::Headers;
		header $h 'Content-Type', 'text/html';
		header $h 'Location', $uri;
		my $r = new HTTP::Response
			(302, "redirect", $h);
		$r, '';
	};

	defined $m->eval(<<'	EOT15a') or die;
		with(XMLHttpRequest) // for constants
		with(request=new XMLHttpRequest) {
			var states=[]
			try{
				open('GET',location,false);
				onreadystatechange
				 = function() { states.push(readyState) }
				send()
				fail('exception on infinite redirect')
				fail('exception on infinite redirect')
			}
			catch($){
				ok($ instanceof DOMException,
				 'class of error thrown by inf redirect')
				is($.code, 19/*~~~NETWORK_ERR*/,
				  'error code after infinite redirect')
			}
			ok(
			 request.getResponseHeader("Content-Type")===null,
			 'error flag is set after infinite redirect'
			)
			ok(
			 request.getAllResponseHeaders()==='',
			 'getAllResponseHeaders is "" after network errors'
			)
			is(
			  readyState, XMLHttpRequest.DONE,
			 'DONE state after infinite redirect'
			)
			unlike(
			 states, '/4/',
			 'inf redirect triggers no orsc when synchronous'
			)
			open('GET',location,true);
			states=[];
			send()
			like(
			 states, '/'+DONE+'/',
			 "inf redirect triggers orsc on network error"
			)
		}
	EOT15a

	# Redirect to another site
	local *FakeProtocol::_create_response_object = sub {
		my $request = shift;

		my $h = new HTTP::Headers;
		header $h 'Content-Type', 'text/html';
		header $h 'Location', "http://we've-not-used-this.yet/";
		my $r = new HTTP::Response
			(302, "redirect", $h);
		$r, '';
	};

	defined $m->eval(<<'	EOT15b') or die;
		with(XMLHttpRequest) // for constants
		with(request) {
		 var states=[]
		 try{
		  open('GET',location,false);
		  onreadystatechange
		   = function() { states.push(readyState) }
		  send()
		  fail('exception on external redirect')
		  fail('exception on external redirect')
		 }
		 catch($){
		  ok($ instanceof DOMException,
		   'class of error thrown by ext redirect')
		  is($.code, 19/*~~~NETWORK_ERR*/,
		    'error code after external redirect')
		  // ~~~ Yes, this is what the spec says. I think it should
		  //     be SECURITY_ERR.
		 }
		 ok(
		  request.getResponseHeader("Content-Type")===null,
		  'error flag is set after external redirect'
		 )
		 is(
		   readyState, XMLHttpRequest.DONE,
		  'DONE state after external redirect'
		 )
		 unlike(
		  states, '/'+DONE+'/',
		  'ext redirect triggers no orsc when synchronous'
		 )
		 open('GET',location,true);
		 states=[];
		 send()
		 like(
		  states, '/'+DONE+'/',
		  "ext redirect triggers orsc on network error"
		 )
		}
	EOT15b

	$m->back();
}
$SRC{'GET http://foo.com/die'} = ['text/plain',sub {die}];
$m->get('http://foo.com/htmlexample');
defined $m->eval(<<'EOT15c') or die;
		with(XMLHttpRequest) // for constants
		with(new XMLHttpRequest) {
		 var states=[]
		 try{
		  open('GET','die',false);
		  onreadystatechange
		   = function() { states.push(readyState) }
		  send()
		  fail('exception on LWP error')
		  fail('exception on LWP error')
		 }
		 catch($){
		  ok($ instanceof DOMException,
		   'class of error thrown by LWP error')
		  is($.code, 19/*~~~NETWORK_ERR*/,
		    'error code after LWP error')
		 }
		 ok(
		  getResponseHeader("Content-Type")===null,
		  'error flag is set after LWP error'
		 )
		 is(
		   readyState, XMLHttpRequest.DONE,
		  'DONE state after LWP error'
		 )
		 unlike(
		  states, '/'+DONE+'/',
		  'LWP error triggers no orsc when synchronous'
		 )
		 open('GET','die',true);
		 states=[];
		 send()
		 like(
		  states, '/'+DONE+'/',
		  "LWP error triggers orsc when asynchronous"
		 )
		}
EOT15c
$m->back();

#----------------------------------------------------------------#
use tests 7; # EventTarget
$m->back();
defined $m->eval(<<'EOT16') or die;
	(function(){
		var events = '';
		var el1 = function(){ events += 1 }
		var el2 = function(){ events += 2 }
		var el3 = function(){ events += 3 }
		var el4 = function(){ events += 4 }
		var el5 = function(){ events += 5 }
		var el6 = function(){ events += 6 }
		with(new XMLHttpRequest) {
			open('GET', location, true)
			is(typeof addEventListener('readystatechange',el1,
				true/*capture*/),
				// There is no capture phase, so this event
				// listener is ignored.
				undefined,
				'retval of addEventListener w/true 3rd arg'
			)
			is( typeof addEventListener('readystatechange',el2)
			  , undefined, 'retval of aEL with 2 args')
			addEventListener('readystatechange',el3)
			addEventListener('readystatechange',el4)
			is(typeof removeEventListener('readystatechange',
				el3), undefined,
				'retval of removeEventListener')
			is(typeof removeEventListener('readystatechange',
				function(){}), undefined,
				'retval of rEL with invalid arg'
			)
			// by this stage, 2 & 4 are assigned
			addEventListener('click', el5) // should do nothing
			onreadystatechange = el6
			var e = document.createEvent()
			e.initEvent('readystatechange')
			ok(dispatchEvent(e) === true,
				'retval of dispatchEvent')
			is(events.split('').sort(),'2,4,6',
				'effect of dispatchEvent')
			send(null)
			is(events.split('').sort(),
				'2,2,2,2,2,4,4,4,4,4,6,6,6,6,6',
				'send triggers event handlers')
		}
	}())
EOT16


#----------------------------------------------------------------#
use tests 5; # Constance
defined $m->eval(<<'EOT17') or die;
	ok(XMLHttpRequest.UNSENT === 0, 'UNSENT')
	ok(XMLHttpRequest. OPENED === 1, 'OPENED')
	ok(XMLHttpRequest. HEADERS_RECEIVED === 2, 'HEADERS_RECEIVED')
	ok(XMLHttpRequest. LOADING === 3, 'LOADING')
	ok(XMLHttpRequest. DONE === 4, 'DONE')
EOT17


#----------------------------------------------------------------#
use tests 19; # open’s idiosyncrasies
{
	my $what = 'method';
	no warnings 'redefine';
	local *FakeProtocol::_create_response_object = sub {
		my $request = shift;
	
		my $h = new HTTP::Headers;
		header $h 'Content-Type', 'text/plain';
		return (new HTTP::Response
			200, "hokkhe", $h), $request->$what;
	};

	defined $m->eval(<<'	EOT17') or die;
		try{ new XMLHttpRequest().open('GET (I think!)')
			fail("open didn't die with an invalid method")
			fail("open didn't die with an invalid method")
		}
		catch($) {
			ok($ instanceof DOMException,
			  'class of error after open w/invalid method')
			is($.code, DOMException.SYNTAX_ERR,
				'open\'s error code (w/ invalid method)')
		}
		with(new XMLHttpRequest){
			open('dELete'),send(),is(responseText,'DELETE',
				'method normalisation (delete)'),
			open('geT'),send(),is(responseText,'GET',
				'method normalisation (get)'),
			open('HeaD'),send(),is(responseText,'HEAD',
				'method normalisation (head)'),
			open('OPTions'),send(),is(responseText,'OPTIONS',
				'method normalisation (options)'),
			open('post'),send(),is(responseText,'POST',
				'method normalisation (post)'),
			open('pUt'),send(),is(responseText,'PUT',
				'method normalisation (put)'),
			open('pLonk'),send(),is(responseText,'pLonk',
				'no method normalisation'
				+'for irregular method names')
			try{open('connect')
			    fail("open doesn't die w/the connect method")
			    fail("open doesn't die w/the connect method")
			}catch(e){
				ok(e instanceof DOMException,
				 'class of error thrown by open w/connect')
				is(e.code, 18/*~~~SECURITY_ERR*/,
				  'error code after open w/connect')
			}
			try{open('trAce')
			    fail("open doesn't die w/the trace method")
			    fail("open doesn't die w/the trace method")
			}catch(e){
				ok(e instanceof DOMException,
				 'class of error thrown by open w/trace')
				is(e.code, 18/*~~~SECURITY_ERR*/,
				  'error code after open w/trace')
			}
			try{open('TRACK')
			    fail("open doesn't die w/the track method")
			    fail("open doesn't die w/the track method")
			}catch(e){
				ok(e instanceof DOMException,
				 'class of error thrown by open w/track')
				is(e.code, 18/*~~~SECURITY_ERR*/,
				  'error code after open w/track')
			}
		}
	EOT17
	$what = 'uri';
	defined $m->eval(<<'	EOT18') or die;
		with(new XMLHttpRequest)
			open('get', location + "#oentu"),
			send(),
			is(responseText, location, 'fragments R stripped')
	EOT18
}
defined $m->eval(<<'EOT18a') or die;
	with(new XMLHttpRequest) {
		open('get', 'echo'),
		setRequestHeader ("Foo", "bar");
		send(),
		open('get', 'echo'),
		is(responseText, '', 'open clears the responseText'),
		is(responseXML, null, 'open clears the response document')
		send()
		ok(!responseText.match(/Foo/),
			'open clears req headers') || diag(responseText)
	}
EOT18a


#----------------------------------------------------------------#
use tests 1; # Base url determination
{
	local *FakeProtocol::_create_response_object = sub {
		my $request = shift;
	
		my $h = new HTTP::Headers;
		header $h 'Content-Type', 'text/html';
		header $h "Content-Base",'httP://foo.com/stuff/';
		return (new HTTP::Response
			200, "hokkhe", $h), "<title></title><p>";
	};
	$m->get('http://foo.com/withbase');
}
$SRC{'GET http://foo.com/stuff/bar'} = ['text/plain', 'stuff/bar'];
defined $m->eval(<<'EOT19') or die;
	with(new XMLHttpRequest)
		open('get','bar'),
		send(null),
		is(responseText, 'stuff/bar', 'base URI')
EOT19


#----------------------------------------------------------------#
use tests 2; # unsupported url scheme
defined $m->eval(<<'EOT20') or die;
	try{
		new XMLHttpRequest().open('get','khochombrilly:boppomp');
		fail('when open encounters an unsupported scheme')
		fail('when open encounters an unsupported scheme')
	}catch(e0){
		ok(e0 instanceof DOMException,
		  'class of error after open w/invalid scheme')
			|| diag("Wha' we have is " + e0)
		is(e0.code, DOMException.NOT_SUPPORTED_ERR,
			'open\'s error code (w/ invalid scheme)')
	}
EOT20


#----------------------------------------------------------------#
use tests 14; # specifics of send
defined $m->eval(<<'EOT21') or die;
0,function(){
with(new XMLHttpRequest) {
	open("GET", '/echo',1);
	
	var statechanges = ''
	onreadystatechange = function(){
		statechanges += readyState
	}
	is(typeof send(), 'undefined', 'send() returns nought')
	is(statechanges, '1234', 'readystatechange events caused by send');

	onreadystatechange = null;
	open('GET', '/echo',0);
	send("all sorts of stuff");
	ok(!responseText.match(/all sorts/), 'get requests are bodiless')
}
with(new XMLHttpRequest) {
	try{ send();
	     fail('send fails to die before open');
	     fail('send fails to die before open');
	}catch(e) {
		ok(e instanceof DOMException,
		 'class of error when send is called b4 open')
		is(e.code, DOMException.INVALID_STATE_ERR,
		  'error code when send is called b4 open')
	}

	open("GET", '/echo',1);

	onreadystatechange = function() {
		try{ send();
		  fail('send fails to die in state ' + readyState);
		  fail('send fails to die in state ' + readyState);
		}catch(e) {
		  ok(e instanceof DOMException,
		   'class of error when send is called in state '
		      + readyState)
		  is(e.code, DOMException.INVALID_STATE_ERR,
		    'error code when send is called in state '
		      + readyState)
		}
	}
	send('stuff')
}
}()
EOT21
{
	no warnings 'redefine';
	local *FakeProtocol::_create_response_object = sub {
		my $request = shift;
		is($request->content, '', 'head requests are bodiless');

		my $h = new HTTP::Headers;
		(new HTTP::Response 200, 'Okey dokes', $h), '';
	};
	defined $m->eval(<<'	EOT21a') or die;
		with(new XMLHttpRequest) {
			open('HEAD', '/echo',0);
			send('this should be ignored')
		}
	EOT21a
}


#----------------------------------------------------------------#
use tests 1; # disabling of scripts
$SRC{'GET http://foo.com/scripts'}=
	['text/html; charset=utf-8','<script>throw"fit"</script>'];
{	
	my $warnings;
	local $SIG{__WARN__} = sub { ++ $warnings };
	defined $m->eval(<<'	EOT22') or die;
		with(new XMLHttpRequest)
			open("GET", '/scripts',0),
			send()
	EOT22
	is $warnings, undef, 'scripts are not run';
}
	

#----------------------------------------------------------------#
use tests 14; # abort

defined $m->eval(<<'EOT23') or die;
!function(){
	with(new XMLHttpRequest){
		var abort_on, rh = '', buffalo = ''
		onreadystatechange=function(){
			buffalo+=readyState
			abort_on == readyState && abort()
			readyState > 1 ? rh = getAllResponseHeaders() :-0
		},

		abort_on = 1
		open('GET','http://foo.com/eoeoeoeoeo',1)
		is(
		  readyState,XMLHttpRequest.UNSENT,
		 'readyState after abort during open'
		)
		is(buffalo, '1', 'abort does not trigger orsc during open')
		is(rh, '', 'no response data after abort during open')

		abort_on = -1, buffalo = ''
		open('GET','http://foo.com/eoeoeoeoeo',1)
		abort_on = 1
		send(null),
		is(
		  readyState,XMLHttpRequest.UNSENT,
		 'readyState after abort during send when only OPENED'
		)
		is(buffalo, '114', 'abort triggers orsc when state is 1.5')
		is(rh, '', 'no response data after abort in state 1.5')

		abort_on = 2, buffalo = ''
		open('GET','http://foo.com/eoeoeoeoeo',1)
		send(null),
		is(
		  readyState,XMLHttpRequest.UNSENT,
		 'readyState after abort when state is 2'
		)
		is(buffalo, '1124', 'abort triggers orsc when state is 2')
		is(rh, '', 'no response data after abort in state 2')

		abort_on = 3, buffalo = ''
		open('GET','http://foo.com/eoeoeoeoeo',1)
		send(null),
		is(
		  readyState,XMLHttpRequest.UNSENT,
		 'readyState after abort when state is 3'
		)
		is(buffalo, '11234', 'abort triggers orsc when state is 3')
		is(rh, '', 'no response data after abort in state 3')

		abort_on = -1
		open('GET','http://foo.com/eoeoeoeoeo',1)
		send(null),
		buffalo = '',
		abort()
		is(
		  readyState,XMLHttpRequest.UNSENT,
		 'readyState after abort when state is 4'
		)
		is(buffalo, '', 'abort triggers no orsc when state is 4')
	}
}()
EOT23

#----------------------------------------------------------------#
use tests 7; # text request encodings

defined $m->eval(<<'EOT24') or die;
	with(new XMLHttpRequest)
	 open('POST','http://foo.com/echo',0),
	 send('ṣṃọẉ'),
	 ok(
	   /á¹£á¹á»áº/.test(responseText),
	  'encoding of text request'
	 ),
	 ok(
	   /^Content-Type: *text\/plain; *charset=utf-8[\r\n]/mi
	    .test(responseText),
	  'content-type header in the request'
	 ),
	 open('POST','http://foo.com/echo',0),
	 setRequestHeader('content-type','text/vanilla'),
	 send('ṣṃọẉ'),
	 ok(
	   /á¹£á¹á»áº/.test(responseText),
	  'encoding of text request with explicit content-type'
	 ),
	 ok(
	   /^Content-Type: *text\/vanilla; *charset=utf-8[\r\n]/mi
	    .test(responseText),
	  'content-type header specified by the user gets a charset added'
	 ),
	 open('POST','http://foo.com/echo',0),
	 setRequestHeader(
	  'content-type',
	  'text/vanilla; charset=iso-8859-2'
	 ),
	 send('Dvořák'),
	 ok(
	   /Dvoøák/.test(responseText),
	  'encoding of text request with explicit charset'
	 ),
	 ok(
	   /^Content-Type: *text\/vanilla; *charset=iso-8859-2[\r\n]/mi
	    .test(responseText),
	  'charset from setRequestHeader is left untouched'
	 ),
	 // Encode 2.39 and earlier have a bug with find_encoding("UTF-8").
	 // It sometimes crashes when passed a reference, and returns the
	 // empty string at other times. find_encoding is only used when
	 // the charset is set explicitly.
	 open('POST','http://foo.com/echo',0),
	 setRequestHeader(
	  'content-type',
	  'text/vanilla; charset=UTF-8'
	 ),
	 send('Dvořák'),
	 ok(
	   /Dvo\xc5\x99\xc3\xa1k/.test(responseText),
	  'encoding of text request with explicit UTF-8 charset'
	 )
EOT24

#----------------------------------------------------------------#
use tests 4; # document requests

defined $m->eval(<<'EOT25') or die;
	with(new XMLHttpRequest)
	 open('GET','http://foo.com/xmlexample',0),
	 send(),
	 doc = responseXML,
	 open('POST','http://foo.com/echo',0),
	 send(doc),
	 ok(
	   /<root>\s*<item1\b/.test(responseText),
	  'XML docs are serialised'
	 ) || diag(responseText),
	 ok(
	   /^Content-Type: *application\/xml; *charset=utf-8[\r\n]/mi
	    .test(responseText),
	  'content-type header in the xml request'
	 ),
	/* ~~~ I’d like to test different HTML charsets, but HTML::DOM
	       doesn’t expose the appropriate attributes yet. */
	 document.innerHTML = "<title>smow</title><p>ctelp",
	 open('POST','http://foo.com/echo',0),
	 send(document),
	 ok(
	   /<title>smow<\/title>[^]*<p>ctelp/i.test(responseText),
	  'HTML docs are cerealised'
	 ) || diag (responseText),
	 ok(
	   /^Content-Type: *text\/html\b/mi
	    .test(responseText),
	  'content-type header for html request'
	 )
EOT25

#----------------------------------------------------------------#
use tests 1; # file: requests with non-ASCII char escapes

# This tests a workaround for a perl bug affecting -e (which
# LWP::Protocol::file uses): The UTF8 flags is completely ignored and the
# internal bytes are used.

SKIP: {
 use File::Temp 'tempdir';
 use File'Spec'Functions 'catfile';

 my $tempdir = tempdir uc cleanup => 1;
 utf8'downgrade my $filename = "\342\200\231"; # ’
 open my $fileh, ">", catfile $tempdir, $filename
  or  skip "Primitive file system? ($!)", 1;
 print $fileh 'psare';
 close $fileh or diag("Cannot close file in $tempdir: $!"),fail,last;

 my $diruri = new_abs URI'file $tempdir;

 $m->get('file:///stuff');
 require LWP::Protocol::file;
 my $impl = LWP'Protocol'implementor('file', 'LWP::Protocol::file');
 defined $m->eval(<<" EOT26") or die;
  // Here’s an apostrophe to make sure this is ‘UTF8’.
  with(new XMLHttpRequest)
   open('GET','$diruri/%E2%80%99',0),
   send(),
   is(responseText, 'psare', 'file URLs are not mangled by -e')
    || diag(status + ' ' + statusText)
 EOT26
 LWP'Protocol'implementor(file => $impl);
}

__END__
	

To add tests for:

third arg for open (once asynchrony is implemented)
