use Test::More tests => 10;

use WWW::Twitpic::Fetch;

my $tp = WWW::Twitpic::Fetch->new;

ok $tp;
can_ok $tp, qw/tagged/;

{ local $@;
	eval { $tp->tagged; };
	ok $@;
}

package UA1;
use Moose;
use HTTP::Response;
use Test::More;

sub get
{
	my (undef, $uri, @rest) = @_;

	is scalar(@rest), 0;
	is $uri, "http://twitpic.com/tag/cat";
	HTTP::Response->new(302);
}

package main;

$tp->ua(UA1->new);
ok !defined $tp->tagged('cat');

package UA2;
use Moose;
use HTTP::Response;
use Test::More;

sub get
{
	my (undef, $uri, @rest) = @_;

	is scalar(@rest), 0;
	is $uri, "http://twitpic.com/tag/cat";
	my $r = HTTP::Response->new(200);
	$r->content(<<EOS);
<!DOCTYPE html>
<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<title> Twitpic - Share photos and videos on Twitter </title>
<link rel="stylesheet" type="text/css" href="/css/main.css?127446345" />
<link type="text/css" rel="stylesheet" href="/js/uploadify/uploadify.css" />


<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js" type="text/javascript"></script>
<script src="http://platform.twitter.com/anywhere.js?id=FeB4w6iaI2ICGtL1ZE0jQ&v=1" type="text/javascript"></script>
<script type="text/javascript" src="http://maps.google.com/maps/api/js?sensor=false"></script>

<!--[if lte IE 7]>
<script src="/js/json2.js" type="text/javascript"></script>
<![endif]-->

<script src="/js/twitpic.package.min.js" type="text/javascript"></script>

<!-- VideoJS -->
<script type="text/javascript" src="/js/video-js/video.js"></script>
<link type="text/css" rel="stylesheet" href="/js/video-js/video-js.css" />
<link type="text/css" rel="stylesheet" href="/js/video-js/skins/vim.css" />
<!-- End VideoJS -->

<!-- Uploadify -->
<link type="text/css" rel="stylesheet" href="/js/uploadify/uploadify.css" />
<script src="/js/uploadify/swfobject.js" type="text/javascript"></script>
<script src="/js/uploadify/jquery.uploadify.min.js" type="text/javascript"></script>

<script type="text/javascript">
$(document).ready(function () {
	TP.upload.set_session('1sqe713fc9t4dh2kbuqdffs0q4');
});
</script>
<!-- End Uploadify -->



</head>
<body>

<!--
<div style="background-color: black;width:100%;padding: 5px 0;">
  <p style="text-align:center;font-size:13px;"><a href="http://heello.com" style="color:white;text-decoration:none;font-weight:bold;">If you like TwitPic, come check out Heello.com!</a></p>
</div>
-->

<div id="header-wrap">
	<div id="header">
		<div id="logo">
		    <a href="/"><img src="/images/logo-main.png"></a>

		</div>
		<div id="nav-container">

		    		    	<div id="nav-auth">
	<div id="nav-upload">
		<a href="/upload"><img src="/images/upload-button-large.png" alt="upload" /></a>
	</div>
	<div id="nav-user">
		<div id="nav-user-avatar">

			<img src="http://a0.twimg.com/profile_images/1296590985/tmp_normal.png" alt="turugina" />
		</div>
		<div id="nav-links">
			<h1>\@turugina</h1>
			<a class="nav-link" href="/photos/turugina">Home</a>
			<a class="nav-link" href="/public_timeline/">Public Timeline</a>
			<a class="nav-link" href="/account/settings">Settings</a>

			<a class="nav-link" href="/logout.do">Logout</a>
		</div>
	</div>
</div>		    
		</div>
		<div style="clear:both;"></div>
	</div>
</div>

<div style="clear:both"></div>

<div id="container">

    <div id="arrow-spacer"></div>

    <div id="content">
    	<div id="content-standard-pad">
	<div id="tag-name" style="font-size:22px;margin-bottom:20px;">Photos tagged with <span style="font-weight:bold;font-style:italic;">cat</span></div>
	<center><div id="tagged-photos" style="width:800px;">
	
		
		<div style="margin: 10px 0;font-size: 18px;">

						
			<div style="float: right;"><a class="nav-link" href="/tag/cat?page=2">Next Page</a></div>
			<div style="clear:both;"></div>
		</div>
	
				<div style="float:left;width:160px;"><a href="/abcde"><img src="http://example.com/example1.jpg"></a></div>
						<div style="float:left;width:160px;"><a href="/12345"><img src="http://example.com/example2.jpg"></a></div>
				<div style="clear:both;">&nbsp;</div>
						<div style="float:left;width:160px;"><a href="/ABCDE"><img src="http://example.com/example3.jpg"></a></div>
				<div style="clear:both;">&nbsp;</div>
						
		<div style="clear:both"></div>
		
		<div style="margin-top: 10px;font-size: 18px;">

						
			<div style="float: right;"><a class="nav-link" href="/tag/cat?page=2">Next Page</a></div>
			<div style="clear:both;"></div>
		</div>
	
		</div></center>
</div>    </div>

    <div id="footer">
    	<div id="footer-tag">
    	&copy;2011 Twitpic Inc, All Rights Reserved
    	</div>

    	<div id="footer-links">
    		<a class="footer-link" href="/">Home</a> &nbsp; <a class="footer-link" href="/search">Search</a> &nbsp; <a class="footer-link" href="/faq.do">Faq</a> &nbsp; <a class="footer-link" href="/contact.do">Contact</a>  &nbsp; <a class="footer-link" href="http://dev.twitpic.com/">API</a> &nbsp; <a class="footer-link" href="/terms.do">Terms</a> &nbsp; <a class="footer-link" href="/privacy.do">Privacy</a>

    	</div>
    	<div style="clear:both;height:25px;">&nbsp;</div>
    </div>

</div>

	<script type="text/javascript">
	var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
	document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
	</script>
	<script type="text/javascript">
	var pageTracker = _gat._getTracker("UA-1618034-6");
	pageTracker._initData();
	pageTracker._trackPageview();
	</script>

	<!-- Start Quantcast tag -->

	<script type="text/javascript">
	_qoptions={
	qacct:"p-28dQY-2rVKMYI"
	};
	</script>
	<script type="text/javascript" src="//secure.quantserve.com/quant.js"></script>
	<noscript>
	<img src="//secure.quantserve.com/pixel/p-28dQY-2rVKMYI.gif" style="display: none;" border="0" height="1" width="1" alt="Quantcast"/>
	</noscript>
	<!-- End Quantcast tag -->

	<!-- FM Tracking Pixel -->
	<script type='text/javascript' src='http://static.fmpub.net/site/twitpic'></script>

	<!-- FM Tracking Pixel -->

	<script type="text/javascript">
			 var m6_sid = 56;
			 var m6_cid = "";
			 var m6_ot = "2";
	</script>

	<script src="http://cdn.media6degrees.com/static/tw2431.js" type="text/javascript"></script>

    <iframe name="_rlcdn" width=0 height=0 frameborder=0 src="http://ei.rlcdn.com/50394.html?es=68&xu=17289a2fe0c3eaf7&c=bf-cbc&v=56b98e2c4fc42686"></iframe>
<!-- Generated by web23 -->

</body>

</html>
EOS
	$r;
}

package main;

$tp->ua(UA2->new);
my $list = $tp->tagged('cat');
ok $list;
is_deeply $list, 
[
{ id => 'abcde',
	mini => 'http://example.com/example1.jpg',
},
{ id => '12345',
	mini => 'http://example.com/example2.jpg',
},
{ id => 'ABCDE',
	mini => 'http://example.com/example3.jpg',
},
];

