#!/usr/bin/perl 

use strict;
use warnings;

use Test::More;

use Test::Mock::LWP::Dispatch;
use LWP::UserAgent;
use HTTP::Response;
use HTTP::Headers;

use Ouch qw(:traditional);

#Setup Expected Responses
my $malformed_json = '{ baz: ==';

my $oembed_res = '{"provider_url": "http://www.youtube.com/", "description": "CGRtrailers, from Classic Game Room\u00ae, presents the \"Rhino\" trailer for THE AMAZING SPIDER-MAN from Beenox, Activision and Marvel Entertainment. This game featuring everyones favorite webslinging superhero is inspired/based upon the upcoming summer movie. Enjoy!", "title": "THE AMAZING SPIDER-MAN Rhino Trailer", "url": "http://www.youtube.com/watch?v=I8CSt7a7gWY", "html": "<iframe width=\"640\" height=\"360\" src=\"http://www.youtube.com/embed/I8CSt7a7gWY?fs=1&feature=oembed\" frameborder=\"0\" allowfullscreen></iframe>", "author_name": "CGRtrailers", "height": 360, "width": 640, "thumbnail_url": "http://i2.ytimg.com/vi/I8CSt7a7gWY/hqdefault.jpg", "thumbnail_width": 480, "version": "1.0", "provider_name": "YouTube", "type": "video", "thumbnail_height": 360, "author_url": "http://www.youtube.com/user/CGRtrailers"}';

my $oembed_multi_res = '[{"provider_url": "http://www.youtube.com/", "description": "CGRtrailers, from Classic Game Room\u00ae, presents the New York Comic Con (NYCC) trailer, the high def version, for THE AMAZING SPIDER-MAN from Beenox, Activision and Marvel Entertainment. This game featuring everyone favorite webslinging superhero is inspired/based upon the upcoming summer movie. Enjoy!", "title": "THE AMAZING SPIDER-MAN New York Comic Con Trailer", "url": "http://www.youtube.com/watch?v=I8CSt7a7gWY", "html": "<iframe width=\"640\" height=\"360\" src=\"http://www.youtube.com/embed/I8CSt7a7gWY?fs=1&feature=oembed\" frameborder=\"0\" allowfullscreen></iframe>", "author_name": "CGRtrailers", "height": 360, "width": 640, "thumbnail_url": "http://i2.ytimg.com/vi/I8CSt7a7gWY/hqdefault.jpg", "thumbnail_width": 480, "version": "1.0", "provider_name": "YouTube", "type": "video", "thumbnail_height": 360, "author_url": "http://www.youtube.com/user/CGRtrailers"}, {"provider_url": "http://yfrog.com", "description": "Click on the photo to comment, share or view other great photos", "title": "Yfrog - photo - Uploaded by eijkb", "url": "http://img844.imageshack.us/img844/1410/41306327.jpg", "author_name": "eijkb", "height": 2592, "width": 3872, "thumbnail_url": "http://img844.imageshack.us/img844/1410/41306327.th.jpg", "thumbnail_width": 150, "version": "1.0", "provider_name": "YFrog", "type": "photo", "thumbnail_height": 101, "author_url": "http://yfrog.com/froggy.php?username=eijkb"}]';


my $preview_res = <<EOF;
{
 "provider_url": "http://www.youtube.com/",
 "object": {
  "width": 550,
  "html": "<iframe width=\\"550\\" height=\\"309\\" src=\\"http://www.youtube.com/embed/I8CSt7a7gWY?fs=1&feature=oembed\\" frameborder=\\"0\\" allowfullscreen></iframe>",
  "type": "video",
  "height": 309
 },
 "description": "CGRtrailers, from Classic Game Room®, presents the \\"Rhino\\" trailer for THE AMAZING SPIDER-MAN from Beenox, Activision and Marvel Entertainment. This game featuring everyone's favorite webslinging superhero is inspired/based upon the upcoming summer movie. Enjoy!",
 "original_url": "http://youtu.be/I8CSt7a7gWY",
 "url": "http://www.youtube.com/watch?v=I8CSt7a7gWY",
 "images": [
  {
   "url": "http://i2.ytimg.com/vi/I8CSt7a7gWY/hqdefault.jpg",
   "width": 480,
   "size": 22841,
   "height": 360
  }
 ],
 "safe": true,
 "provider_display": "www.youtube.com",
 "author_name": "CGRtrailers",
 "content": null,
 "favicon_url": "http://s.ytimg.com/yt/favicon-refresh-vfldLzJxy.ico",
 "place": {},
 "author_url": "http://www.youtube.com/user/CGRtrailers",
 "embeds": [],
 "title": "THE AMAZING SPIDER-MAN Rhino Trailer",
 "provider_name": "YouTube",
 "cache_age": 40952,
 "type": "html",
 "event": {}
}
EOF

my $objectify_res = <<EOF;
{
 "embeds": [],
 "provider_url": "http://www.youtube.com/",
 "description": "CGRtrailers, from Classic Game Room®, presents the trailer for THE AMAZING SPIDER-MAN from Beenox, Activision and Marvel Entertainment. This game featuring everyone's favorite webslinging superhero is inspired/based upon the upcoming summer movie. Enjoy!",
 "original_url": "http://youtu.be/I8CSt7a7gWY",
 "url": "http://www.youtube.com/watch?v=I8CSt7a7gWY",
 "images": [
  {
   "url": "http://i2.ytimg.com/vi/I8CSt7a7gWY/hqdefault.jpg",
   "width": 480,
   "size": 22841,
   "height": 360
  }
 ],
 "safe": true,
 "provider_display": "www.youtube.com",
 "event": {},
 "microformats": {
  "author": [
   {
    "href": "http://www.youtube.com/user/CGRtrailers",
    "name": "CGRtrailers"
   }
  ]
 },
 "favicon_url": "http://s.ytimg.com/yt/favicon-refresh-vfldLzJxy.ico",
 "meta": {
  "oembeds": [
   {
    "type": "application/json+oembed",
    "href": "http://www.youtube.com/oembed?url=http%3A//www.youtube.com/watch?v%3DI8CSt7a7gWY&format=json",
    "tag": "link",
    "rel": "alternate",
    "title": "THE AMAZING SPIDER-MAN Rhino Trailer"
   },
   {
    "type": "text/xml+oembed",
    "href": "http://www.youtube.com/oembed?url=http%3A//www.youtube.com/watch?v%3DI8CSt7a7gWY&format=xml",
    "tag": "link",
    "rel": "alternate",
    "title": "THE AMAZING SPIDER-MAN Rhino Trailer"
   }
  ],
  "description": "CGRtrailers, from Classic Game Room®, presents the trailer for THE AMAZING SPIDER-MAN from Beenox, Activision and Marvel Entertainment. This game fea...",
  "title": "THE AMAZING SPIDER-MAN Rhino Trailer",
  "shortcut_icon": "http://s.ytimg.com/yt/favicon-refresh-vfldLzJxy.ico",
  "shortlink": "http://youtu.be/I8CSt7a7gWY",
  "keywords": [
   "videogame",
   "videogames",
   "video game",
   "video games",
   "trailer",
   "trailers",
   "teaser",
   "teasers",
   "preview",
   "previews",
   "first",
   "look",
   "sneak",
   "peek",
   "coming",
   "soon",
   "film",
   "movie",
   "a..."
  ],
  "open_search": [
   {
    "type": "application/opensearchdescription+xml",
    "href": "http://www.youtube.com/opensearch?locale=en_US",
    "tag": "link",
    "rel": "search",
    "title": "YouTube Video Search"
   }
  ],
  "canonical": "http://www.youtube.com/watch?v=I8CSt7a7gWY",
  "icon": "http://s.ytimg.com/yt/favicon-refresh-vfldLzJxy.ico"
 },
 "oembed": {
  "provider_url": "http://www.youtube.com/",
  "description": "CGRtrailers, from Classic Game Room®, presents the trailer for THE AMAZING SPIDER-MAN from Beenox, Activision and Marvel Entertainment. This game featuring everyone's favorite webslinging superhero is inspired/based upon the upcoming summer movie. Enjoy!",
  "title": "THE AMAZING SPIDER-MAN Rhino Trailer",
  "url": "http://www.youtube.com/watch?v=I8CSt7a7gWY",
  "html": "<iframe width=550 height=309 src=http://www.youtube.com/embed/I8CSt7a7gWY?fs=1&feature=oembed frameborder=0 allowfullscreen></iframe>",
  "author_name": "CGRtrailers",
  "height": 309,
  "width": 550,
  "thumbnail_url": "http://i2.ytimg.com/vi/I8CSt7a7gWY/hqdefault.jpg",
  "thumbnail_width": 480,
  "provider_name": "YouTube",
  "type": "video",
  "thumbnail_height": 360,
  "author_url": "http://www.youtube.com/user/CGRtrailers"
 },
 "place": {},
 "entry": {},
 "open_graph": {
  "site_name": "YouTube",
  "description": "CGRtrailers, from Classic Game Room®, presents the trailer for THE AMAZING SPIDER-MAN from Beenox, Activision and Marvel Entertainment. This game fea...",
  "title": "THE AMAZING SPIDER-MAN Rhino Trailer",
  "url": "http://www.youtube.com/watch?v=I8CSt7a7gWY",
  "image": "http://i2.ytimg.com/vi/I8CSt7a7gWY/hqdefault.jpg",
  "image_width": 480,
  "video_height": 224,
  "image_height": 360,
  "video": "http://www.youtube.com/v/I8CSt7a7gWY?version=3&autohide=1",
  "image_size": 22841,
  "video_width": 398,
  "type": "video"
 },
 "title": "THE AMAZING SPIDER-MAN Rhino Trailer",
 "provider_name": "YouTube",
 "cache_age": 40847,
 "type": "html",
 "payload": {
  "video": {
   "data": {
    "uploaded": "2012-02-16T17:25:04.000Z",
    "category": "Entertainment",
    "updated": "2012-02-17T01:48:05.000Z",
    "rating": 4.111111,
    "description": "CGRtrailers, from Classic Game Room®, presents the  trailer for THE AMAZING SPIDER-MAN from Beenox, Activision and Marvel Entertainment. This game featuring everyone's favorite webslinging superhero is inspired/based upon the upcoming summer movie. Get more Classic Game Room on Facebook at http://www.facebook.com/ClassicGameRoom",
    "title": "THE AMAZING SPIDER-MAN Rhino Trailer",
    "aspectRatio": "widescreen",
    "id": "I8CSt7a7gWY",
    "tags": [
     "videogame",
     "videogames",
     "video game",
     "video games",
     "trailer",
     "trailers",
     "teaser",
     "teasers",
     "preview",
     "previews",
     "first",
     "look",
     "sneak",
     "peek",
     "coming",
     "soon",
     "film",
     "movie",
     "Amazing Spider-Man",
     "spider-man",
     "spiderman",
     "amazing",
     "rhino",
     "Beenox",
     "Activision",
     "Marvel",
     "Comics",
     "comic",
     "books",
     "official",
     "classic game room",
     "cgr trailers"
    ],
    "likeCount": "7",
    "content": {
     "1": "rtsp://v8.cache8.c.youtube.com/CiILENy73wIaGQlmgbu2t5LAIxMYDSANFEgGUgZ2aWRlb3MM/0/0/0/video.3gp",
     "5": "http://www.youtube.com/v/I8CSt7a7gWY?version=3&f=videos&app=youtube_gdata",
     "6": "rtsp://v8.cache1.c.youtube.com/CiILENy73wIaGQlmgbu2t5LAIxMYESARFEgGUgZ2aWRlb3MM/0/0/0/video.3gp"
    },
    "player": {
     "default": "http://www.youtube.com/watch?v=I8CSt7a7gWY&feature=youtube_gdata_player",
     "mobile": "http://m.youtube.com/details?v=I8CSt7a7gWY"
    },
    "accessControl": {
     "comment": "allowed",
     "list": "allowed",
     "videoRespond": "moderated",
     "rate": "allowed",
     "syndicate": "allowed",
     "embed": "allowed",
     "commentVote": "allowed",
     "autoPlay": "allowed"
    },
    "uploader": "cgrtrailers",
    "ratingCount": 9,
    "duration": 59,
    "commentCount": 6,
    "favoriteCount": 4,
    "thumbnail": {
     "hqDefault": "http://i.ytimg.com/vi/I8CSt7a7gWY/hqdefault.jpg",
     "sqDefault": "http://i.ytimg.com/vi/I8CSt7a7gWY/default.jpg"
    },
    "viewCount": 261
   },
   "apiVersion": "2.1"
  }
 }
}
EOF


#Start Testing

BEGIN { use_ok( 'WebService::Embedly') ; }

use WebService::Embedly;
can_ok('WebService::Embedly', 'new');

my $embedly;
eval {
  $embedly = WebService::Embedly->new();
};
ok($@, "Auth_key Needed");

eval {
  $embedly = WebService::Embedly->new({ api_key => 'test'});
};
isa_ok($embedly, 'WebService::Embedly');
isa_ok($embedly->ua, 'LWP::UserAgent');

my $ua = LWP::UserAgent->new();

#And this is how dependency injection should happen

my $headers = HTTP::Headers->new(
				 'Content-Type'   => 'application/json',
				 'Server' => 'TornadoServer/2.0'
				);
$headers->date;


#oembed
$mock_ua->map(
	      'http://api.embed.ly/1/oembed?url=http%3A%2F%2Fyoutu.be%2FI8CSt7a7gWY&key=test&maxwidth=500',
	      sub {
		my $req = shift;
		my $uri = $req->uri;
		my $content = $oembed_res;
		$headers->content_length(length($content));
		my $res = HTTP::Response->new(200, 'OK', $headers, $content);
		return $res;
	      },
);

#basic checks for options params
my @param_urls = qw(http://api.embed.ly/1/oembed?url=http%3A%2F%2Fyoutu.be%2FI8CSt7a7gWY&key=test&maxwidth=500&maxheigth=300 http://api.embed.ly/1/oembed?url=http%3A%2F%2Fyoutu.be%2FI8CSt7a7gWY&key=test&maxwidth=500&maxheigth=300&width=200 http://api.embed.ly/1/oembed?url=http%3A%2F%2Fyoutu.be%2FI8CSt7a7gWY&key=test&maxwidth=500&maxheigth=300&width=200&format=xml  http://api.embed.ly/1/oembed?url=http%3A%2F%2Fyoutu.be%2FI8CSt7a7gWY&key=test&maxwidth=500&maxheigth=300&width=200&format=xml&callback=jsonpcallback http://api.embed.ly/1/oembed?url=http%3A%2F%2Fyoutu.be%2FI8CSt7a7gWY&key=test&maxwidth=500&maxheigth=300&width=200&format=xml&callback=jsonpcallback&wmode=window http://api.embed.ly/1/oembed?url=http%3A%2F%2Fyoutu.be%2FI8CSt7a7gWY&key=test&maxwidth=500&maxheigth=300&width=200&format=xml&callback=jsonpcallback&wmode=window&allowscripts=true http://api.embed.ly/1/oembed?url=http%3A%2F%2Fyoutu.be%2FI8CSt7a7gWY&key=test&maxwidth=500&maxheigth=300&width=200&format=xml&callback=jsonpcallback&wmode=window&allowscripts=true&nostyle=true http://api.embed.ly/1/oembed?url=http%3A%2F%2Fyoutu.be%2FI8CSt7a7gWY&key=test&maxwidth=500&maxheigth=300&width=200&format=xml&callback=jsonpcallback&wmode=window&allowscripts=true&nostyle=true&autoplay=true http://api.embed.ly/1/oembed?url=http%3A%2F%2Fyoutu.be%2FI8CSt7a7gWY&key=test&maxwidth=500&maxheigth=300&width=200&format=xml&callback=jsonpcallback&wmode=window&allowscripts=true&nostyle=true&autoplay=true&videosrc=true http://api.embed.ly/1/oembed?url=http%3A%2F%2Fyoutu.be%2FI8CSt7a7gWY&key=test&maxwidth=500&maxheigth=300&width=200&format=xml&callback=jsonpcallback&wmode=window&allowscripts=true&nostyle=true&autoplay=true&videosrc=true&words=40 http://api.embed.ly/1/oembed?url=http%3A%2F%2Fyoutu.be%2FI8CSt7a7gWY&key=test&maxwidth=500&maxheigth=300&width=200&format=xml&callback=jsonpcallback&wmode=window&allowscripts=true&nostyle=true&autoplay=true&videosrc=true&words=40&chars=400);

foreach my $p_url (@param_urls) {
  $mock_ua->map(
		$p_url,
		sub {
		  my $req = shift;
		  my $uri = $req->uri;
		  my $content = $oembed_res;
		  #TODO content should be different per param...
		  $headers->content_length(length($content));
		  my $res = HTTP::Response->new(200, 'OK', $headers, $content);
		  return $res;
		},
	       );
}

#oembed multi url 
$mock_ua->map(
	      'http://api.embed.ly/1/oembed?urls=http%3A%2F%2Fyoutu.be%2FI8CSt7a7gWY,http%3A%2F%2Fyfrog.com%2Fng41306327j&key=test&maxwidth=500',
	      sub {
		my $req = shift;
		my $uri = $req->uri;
		my $content = $oembed_multi_res;
		$headers->content_length(length($content));

		my $res = HTTP::Response->new(200, 'OK', $headers, $content);

		return $res;
	      },
);


#preview
$mock_ua->map(
	      'http://api.embed.ly/1/preview?url=http%3A%2F%2Fyoutu.be%2FI8CSt7a7gWY&key=test&maxwidth=500',
	      sub {
		my $req = shift;
		my $uri = $req->uri;
		my $content = $preview_res;
		$headers->content_length(length($content));

		my $res = HTTP::Response->new(200, 'OK', $headers, $content);

		return $res;
	      },
);



#objectify
$mock_ua->map(
	      'http://api.embed.ly/1/objectify?url=http%3A%2F%2Fyoutu.be%2FI8CSt7a7gWY&key=test&maxwidth=500',
	      sub {
		my $req = shift;
		my $uri = $req->uri;
		my $content = $objectify_res;
		$headers->content_length(length($content));

		my $res = HTTP::Response->new(200, 'OK', $headers, $content);

		return $res;
	      },
);

#oembed bad json
$mock_ua->map(
	      'http://api.embed.ly/1/oembed?url=http%3A%2F%2Fyoutu.be%2Fmallformed_json&key=test&maxwidth=500',
	      sub {
		my $req = shift;
		my $uri = $req->uri;
		my $content = $malformed_json;
		$headers->content_length(length($content));

		my $res = HTTP::Response->new(200, 'OK', $headers, $content);

		return $res;
	      },
);

#Bad API calls
#400
my $url400 = 'http://youtu.be/400';
$mock_ua->map(
	      'http://api.embed.ly/1/oembed?url=http%3A%2F%2Fyoutu.be%2F400&key=test&maxwidth=500',
	      sub {
		my $req = shift;
		my $uri = $req->uri;
		my $content = '<html><title>400: Bad Request</title><body>400: Bad Request</body></html>';
		$headers->content_type('text/html; charset=UTF-8');
		$headers->content_length(length($content));

		my $res = HTTP::Response->new(400, 'Bad Request', $headers, $content);

		return $res;
	      },
);
#401
my $url401 = 'http://youtu.be/401';
$mock_ua->map(
	      'http://api.embed.ly/1/oembed?url=http%3A%2F%2Fyoutu.be%2F401&key=test&maxwidth=500',
	      sub {
		my $req = shift;
		my $uri = $req->uri;
		my $content = '<html><title>401: Unauthorized - Invalid `key` provided: ppp_test_ppp please contact: support@embed.ly</title><body>401: Unauthorized - Invalid `key` provided: ppp_test_ppp please contact: support@embed.ly</body></html>';
		$headers->content_type('text/html; charset=UTF-8');
		$headers->content_length(length($content));

		my $res = HTTP::Response->new(401, 'Unauthorized', $headers, $content);

		return $res;
	      },
);



#500
my $url500 = 'http://youtu.be/500';
$mock_ua->map(
	      'http://api.embed.ly/1/oembed?url=http%3A%2F%2Fyoutu.be%2F500&key=test&maxwidth=500',
	      sub {
		my $req = shift;
		my $uri = $req->uri;
		my $content = '<html><title>500: Server issues</title><body>500: Server issues</body></html>';
		$headers->content_type('text/html; charset=UTF-8');
		$headers->content_length(length($content));

		my $res = HTTP::Response->new(500, 'Server issues', $headers, $content);

		return $res;
	      },
);

#test param passing
$embedly = WebService::Embedly->new({ api_key => 'test',
			       maxwidth => 600,
			     });
is ($embedly->maxwidth, 600, "maxwidth set");
$embedly->maxwidth(500);
is ($embedly->maxwidth, 500, "maxwidth altered");

my $url = 'http://youtu.be/I8CSt7a7gWY';
my $e;

$e = try {
  my $oembed_ref = $embedly->oembed($url);
  is ($oembed_ref->{provider_url}, 'http://www.youtube.com/', 'Oembed response w/maxwidth' );
};
if (catch_all $e) {
  fail "Param did not set";
}

$e = try {
  $embedly->maxwidth('400px');
};

if (catch_all $e) {
  like ($e, qr/400px/, 'Must use Integer exception Success');
}

$embedly->maxheight(300);
is ($embedly->maxheight, 300, "maxheight set");

$e = try {
  my $oembed_ref = $embedly->oembed($url);
  is ($oembed_ref->{provider_url}, 'http://www.youtube.com/', 'Oembed response w/maxheight' );
};
if (catch_all $e) {
  fail "maxheight param did not set";
}


$embedly->width(200);
is ($embedly->width, 200, "Width set");

$e = try {
  my $oembed_ref = $embedly->oembed($url);
  is ($oembed_ref->{provider_url}, 'http://www.youtube.com/', 'Oembed response w/width' );
};
if (catch_all $e) {
  fail "width param did not set";
}


$embedly->format('xml');
is ($embedly->format, 'xml', "format set");

$e = try {
  my $oembed_ref = $embedly->oembed($url);
  is ($oembed_ref->{provider_url}, 'http://www.youtube.com/', 'Oembed response w/format' );
};
if (catch_all $e) {
  fail "format param did not set";
}


$embedly->callback("jsonpcallback");
is ($embedly->callback, 'jsonpcallback', "Callback set");

$e = try {
  my $oembed_ref = $embedly->oembed($url);
  is ($oembed_ref->{provider_url}, 'http://www.youtube.com/', 'Oembed response w/callback' );
};
if (catch_all $e) {
  fail "callback param did not set";
}


$embedly->wmode('window');
is ($embedly->wmode, 'window', "window set");

$e = try {
  my $oembed_ref = $embedly->oembed($url);
  is ($oembed_ref->{provider_url}, 'http://www.youtube.com/', 'Oembed response w/wmode' );
};
if (catch_all $e) {
  fail "wmode param did not set";
}


$embedly->allowscripts('true'); #or the more perlish way just make the value true ->(1)
is ($embedly->allowscripts, 'true', "allowscripts set");

$e = try {
  my $oembed_ref = $embedly->oembed($url);
  is ($oembed_ref->{provider_url}, 'http://www.youtube.com/', 'Oembed response w/allowscripts' );
};
if (catch_all $e) {
  fail "allowscripts param did not set";
}

$embedly->nostyle('true'); #or the more perlish way just make the value true ->(1)
is ($embedly->nostyle, 'true', "nostyle set");

$e = try {
  my $oembed_ref = $embedly->oembed($url);
  is ($oembed_ref->{provider_url}, 'http://www.youtube.com/', 'Oembed response w/nostyle' );
};
if (catch_all $e) {
  fail "nostyle param did not set";
}

$embedly->autoplay('true'); #or the more perlish way just make the value true ->(1)
is ($embedly->autoplay, 'true', "autoplay set");

$e = try {
  my $oembed_ref = $embedly->oembed($url);
  is ($oembed_ref->{provider_url}, 'http://www.youtube.com/', 'Oembed response w/autoplay' );
};
if (catch_all $e) {
  fail "autoplay param did not set";
}

$embedly->videosrc('true'); #or the more perlish way just make the value true ->(1)
is ($embedly->videosrc, 'true', "videosrc set");

$e = try {
  my $oembed_ref = $embedly->oembed($url);
  is ($oembed_ref->{provider_url}, 'http://www.youtube.com/', 'Oembed response w/videosrc' );
};
if (catch_all $e) {
  fail "videosrc param did not set";
}

$embedly->words(40); #or the more perlish way just make the value true ->(1)
is ($embedly->words, 40, "words set");

$e = try {
  my $oembed_ref = $embedly->oembed($url);
  is ($oembed_ref->{provider_url}, 'http://www.youtube.com/', 'Oembed response w/words' );
};
if (catch_all $e) {
  fail "words param did not set";
}

$embedly->chars(400); #or the more perlish way just make the value true ->(1)
is ($embedly->chars, 400, "chars set");

$e = try {
  my $oembed_ref = $embedly->oembed($url);
  is ($oembed_ref->{provider_url}, 'http://www.youtube.com/', 'Oembed response w/chars' );
};
if (catch_all $e) {
  fail "chars param did not set";
}


#pass in mock user agent..  IoC testing
$embedly = WebService::Embedly->new({ api_key => 'test',
			       maxwidth => 500,
			       ua => $ua
			     });

isa_ok($embedly, 'WebService::Embedly');
isa_ok($embedly->ua, 'LWP::UserAgent');

#test oembed method
my $oembed_base = $embedly->oembed_base_uri;
is ($oembed_base, 'http://api.embed.ly/1/oembed', 'Base of V1 of embed.ly');

#http://api.embed.ly/1/oembed?key=:key&url=:url&maxwidth=:maxwidth&maxheight=:maxheight&format=:format&callback=:callback

$e = try {
  my $oembed_ref = $embedly->oembed($url);
  is ($oembed_ref->{provider_url}, 'http://www.youtube.com/', 'Oembed response' );
};

if (catch_all $e) {
  fail 'Failed oembed request' ;
}


$e = try {
  my $preview_ref = $embedly->preview($url);
  is ($preview_ref->{provider_url}, 'http://www.youtube.com/', 'Preview response' );
};

if (catch_all $e) {
  fail 'Failed preview request' ;
}


$e = try {
  my $objectify_ref = $embedly->objectify($url);
  is ($objectify_ref->{provider_url}, 'http://www.youtube.com/', 'Objectify response' );

};

if (catch_all $e) {
  fail 'Failed preview request' ;
}


#go through known errors

#pass in more then 20 URLS
my @urls = qw(http://youtu.be/I8CSt7a7gWY http://yfrog.com/ng41306327j http://www.slideshare.net/doina/happy-easter-from-holland-slideshare http://www.scribd.com/doc/13994900/Easter http://screenr.com/t9d http://www.5min.com/Video/How-to-Decorate-Easter-Eggs-with-Decoupage-142076462 http://www.howcast.com/videos/220110-The-Meaning-Of-Easter http://tweetphoto.com/16044847 http://www.flickr.com/photos/sunnybrook100/4471526636/ http://twitpic.com/1cm8us http://post.ly/Zhg0 http://twitgoo.com/1w5 http://www.qwantz.com/index.php?comic=1019 http://www.justin.tv/easterfraud http://qik.com/video/1445299 http://www.twitvid.com/902B9 http://www.break.com/index/a-very-sexy-easter-video.html http://www.metacafe.com/watch/4374339/easter_eggs/ http://blip.tv/file/770127 ip.tv/file/770127 http://www.liveleak.com/view?i=451_1188059885);

$e = try {
  $embedly->oembed(\@urls);
};

if (catch 400, $e) {
  like ($e, qr/Cannot/, '>20 urls per request err Success');
}
else {
  fail "should have been an >20 urls exception";
}

#get rid of the 21st url
pop(@urls);

$e = try {
  $embedly->oembed(\@urls);
};

if (catch 400, $e) {
  like ($e, qr/formatted/, 'malformed url lookup err Success');
}
else {
  fail "should have been a malformed url exception";
}


$e = try {
  my $oembed_ref = $embedly->oembed(['http://youtu.be/I8CSt7a7gWY', 'http://yfrog.com/ng41306327j']);
  is ($oembed_ref->[0]->{provider_url}, 'http://www.youtube.com/', 'Oembed multi response' );
};

if (catch_all $e) {
  fail 'Failed oembed request' ;
}

#bad json back form server
my $malformed_json_url = 'http://youtu.be/mallformed_json';
$e = try {
  $embedly->oembed($malformed_json_url);
};

if (catch 500, $e) {
  like ($e, qr/JSON/, 'JSON exception Success');
}
else {
  fail "should have been an JSON exception";
}

#400 bad request
$e = try {
  my $res = $embedly->oembed($url400);
};

if (catch 400, $e) {
  like ($e, qr/Bad/, 'Bad Request 400 exception Success');
}
elsif (catch_all $e) {
  fail "should have been a 400 exception: " . $e;
}
else {
  fail "should have been a 400 exception";
}


#401 unauthorized
$e = try {
  my $res = $embedly->oembed($url401);
};

if (catch 401, $e) {
  like ($e, qr/Unauthorized/, 'Unauthorized 401 exception Success');
}
elsif (catch_all $e) {
  fail "should have been a 401 exception: " . $e;
}
else {
  fail "should have been a 401 exception";
}

#500 Internal Server Error
$e = try {
  my $res = $embedly->oembed($url500);
};

if (catch 500, $e) {
  like ($e, qr/Server/, 'Server Internal Error 500 exception Success');
}
elsif (catch_all $e) {
  fail "should have been a 500 exception: " . $e;
}
else {
  fail "should have been a 500 exception";
}




#http://api.embed.ly/1/oembed?key=:key&urls=:url1,:url2,:url3&maxwidth=:maxwidth&maxheight=:maxheight&format=:format&callback=:callback



done_testing();
