use Test::More tests => 17;

use WWW::Twitpic::Fetch;

my $twitpic = WWW::Twitpic::Fetch->new;

ok $twitpic;

{ local $@;
	eval { $twitpic->photo_info; };
	ok $@;
}
{ local $@;
	eval { $twitpic->photo_info('invalid_id'); };
	ok $@;
}

package UA1;
use Moose;
use Test::More;
use HTTP::Response;

sub get
{
	my (undef, $uri) = @_;
	is $uri, "http://twitpic.com/1bc34x";
	HTTP::Response->new(404);
}

package main;

$twitpic->ua(UA1->new);
ok !defined $twitpic->photo_info('1bc34x');

package UA2;
use Moose;
use Test::More;
use HTTP::Response;

sub get
{
	my (undef, $uri) = @_;
	is $uri, "http://twitpic.com/1bc34x";
	my $r = HTTP::Response->new(200);
	$r->content(<<EOS);
<html>
<head>
</head>
<body>
	
<div id="view-photo-main">
	<div id="photo" style="position:relative;">
		<div id="photo-content-wrap">
							
							<div id="photo-controls" style="display:none;position:absolute;width:600px;height:50px;background-image: url('/images/hud-bg.png');z-index:10000;">		
	<div style="padding:15px;">
				<img src="/images/hud-img-arrow.png" alt="arrow"/> <a class="nav-link" id="rotate-image" href="#" onclick="TP.ui.rotate_photo()" style="color:#ffffff;">Rotate photo</a> &nbsp;&nbsp; 
		<img src="/images/hud-img-plus.png" alt="plus"/> <a class="nav-link" href="/2f2du7/full" style="color:#ffffff;">View full size</a>

	</div>
</div>

<div id="photo-wrap" style="margin: auto;width:560px;height:560px;">
	<img class="photo" id="photo-display" src="http://example.com/example-scaled.jpg?AWSAccessKeyId=DEADBEEF&Expires=1234567890&Signature=DeadBeef%3D" alt="TEST MESSAGE" />
	
	<div id="photo-location" style="display:none;width:560px;height:560px;"></div>
		
		<div id="photo-tagger-wrap" style="display: none">
			<img src="/images/photo_tag_arrow.png" alt="arrow" />
			<div id="photo-tagger">
				<p class="photo-tagger-label">name</p>

				<input id="photo-tagger-name" type="text" />
			
				<p class="photo-tagger-label">twitter username</p>
				<input id="photo-tagger-username" type="text" value="@" />
				
				<input type="checkbox" id="photo-tagger-reply" name="photo-tagger-reply" checked="true" disabled="true" /> <label for="photo-tagger-reply">\@reply to tagged user</label>
				<div id="photo-tagger-controls">
					<input id="photo-tagger-submit" type="button" value="Save" onclick="TP.faces.save_tag()" disabled="true" />
					<input type="button" value="Cancel" onclick="TP.faces.hide_tagger()" />

				</div>
			</div>
		</div>
		
			</div>
	
	<div id="hide-map-wrap" style="display:none">
		<span id="hide-map" onclick="TP.locations.toggle_photo_map()">Hide map and return to photo</span>
	</div>
	
		<div id="facetag_list_wrap">		
	    <div id="facetag_finish" style="display:none">

	    	<p>Click anywhere on the image to tag someone, then fill in their name and/or Twitter username. When finished tagging face, <b>remember to click the Done Tagging button</b> below or else your changes will not be saved!</p>
	    	<div style="text-align: right"><input class="fancy-button" type="button" onclick="TP.faces.end_tagging()" value="Done Tagging" /></div>
	    </div>
	    <span id="facetags"><span style="color: #555555;">In this photo (<a class="nav-link" id="addeditfaces" href="#">Add/Edit Faces</a>):</span> <span id="facetag_list"></span></span>
	</div>

						</div>
		
		<div id="view-photo-caption">
			TEST MESSAGE
		</div>
	</div>

<div class="photo-comment">
	<div class="photo-comment-avatar">
		<img class="avatar" width="48" height="48" src="avator.jpg" />
	</div>
	<div class="photo-comment-body">
		<div class="photo-comment-info" style="float:left;width:400px;">
		<a class="nav" href="/photos/hoge">hoge</a> <span class="photo-comment-date" style="">on June 22, 2009</span>
		</div>
						<div class="photo-comment-message" style="clear:both;">
		TEST COMMENT
	</div>
</div>
<div id="view-photo-views">
	<div style="font-size:14px;"><b>Views</b> 34</div>

</div>
<div id="view-photo-tags">
		<span><a class="nav-link" style="font-size:12px;" href="/tag/tag1">tag1</a></span>
		<span><a class="nav-link" style="font-size:12px;" href="/tag/tag2">tag2</a></span>
</div>
</body>
</html>
EOS
	$r;
}

package main;

$twitpic->ua(UA2->new);

my $res = $twitpic->photo_info("1bc34x");

ok $res;

is_deeply $res, { 
	url => "http://example.com/example-scaled.jpg?AWSAccessKeyId=DEADBEEF&Expires=1234567890&Signature=DeadBeef%3D",
	message => "TEST MESSAGE",
	views => 34,
	comments => [{
		avatar => "avator.jpg",
		username => "hoge",
		date => "on June 22, 2009",
		comment => "TEST COMMENT",
	}],
	tags => [qw/tag1 tag2/],
};

package UA3;
use Moose;
use Test::More;
use HTTP::Response;

sub get
{
	my (undef, $uri) = @_;
	is $uri, "http://twitpic.com/1bc34x/full";
	my $r = HTTP::Response->new(200);
	$r->content(<<EOS);
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
    "http://www.w3.org/TR/html4/loose.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8"/>
<title>TEST on Twitpic </title>
<link rel="stylesheet" type="text/css" href="/css/main.css" />
<style type="text/css">
body { background-position-y: 0px !important; }
</style>
<body style="margin:20px;">
<div style="padding-top:8px;padding-bottom:20px;"><a class="nav-link" href="/1bc34x">< Back to photo page</a></div>
<div style="padding-bottom:10px;"><img src="/images/logo-main.png"></div>

	<img src="http://example.com/example.jpg?AWSAccessKeyId=DEADBEEF&Expires=123456789&Signature=CafeBabe%3D" alt="TEST">

</body>
</html>
EOS
	$r;
}

package main;

$twitpic->ua(UA3->new);

$res = $twitpic->photo_info("1bc34x", 1);

ok $res;

is_deeply $res, { 
	url => "http://example.com/example.jpg?AWSAccessKeyId=DEADBEEF&Expires=123456789&Signature=CafeBabe%3D",
};

$res = $twitpic->photo_info("http://twitpic.com/1bc34x", 1);

ok $res;

is_deeply $res, { 
	url => "http://example.com/example.jpg?AWSAccessKeyId=DEADBEEF&Expires=123456789&Signature=CafeBabe%3D",
};

$res = $twitpic->photo_info("http://www.twitpic.com/1bc34x/full", 1);

ok $res;

is_deeply $res, { 
	url => "http://example.com/example.jpg?AWSAccessKeyId=DEADBEEF&Expires=123456789&Signature=CafeBabe%3D",
};


