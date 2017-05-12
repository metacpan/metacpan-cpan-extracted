#!/usr/bin/perl 

use strict;
use warnings;

use Test::More;

use Test::Mock::LWP::Dispatch;
use LWP::UserAgent;
use HTTP::Response;
use HTTP::Headers;

use Ouch qw(:traditional);


BEGIN { use_ok( 'WebService::Embedly') ; }
use WebService::Embedly;

my $embedly;
my $ua = LWP::UserAgent->new();
my $headers = HTTP::Headers->new(
				 'Content-Type'   => 'application/json',
				 'Server' => 'TornadoServer/2.0'
				);
$headers->date;

#Setup Expected Responses
my $oembed_res = '{"provider_url": "http://www.youtube.com/", "description": "CGRtrailers, from Classic Game Room\u00ae, presents the \"Rhino\" trailer for THE AMAZING SPIDER-MAN from Beenox, Activision and Marvel Entertainment. This game featuring everyones favorite webslinging superhero is inspired/based upon the upcoming summer movie. Enjoy!", "title": "THE AMAZING SPIDER-MAN Rhino Trailer", "url": "http://www.youtube.com/watch?v=I8CSt7a7gWY", "html": "<iframe width=\"640\" height=\"360\" src=\"http://www.youtube.com/embed/I8CSt7a7gWY?fs=1&feature=oembed\" frameborder=\"0\" allowfullscreen></iframe>", "author_name": "CGRtrailers", "height": 360, "width": 640, "thumbnail_url": "http://i2.ytimg.com/vi/I8CSt7a7gWY/hqdefault.jpg", "thumbnail_width": 480, "version": "1.0", "provider_name": "YouTube", "type": "video", "thumbnail_height": 360, "author_url": "http://www.youtube.com/user/CGRtrailers"}';


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

my $oembed2_res = '{"provider_url": "http://www.xinshipu.com", "description": "\u6c34\u716e\u9c7c\u7247\uff0c\u9999\u83c7\u9c7c\u7247\u7ca5\uff0c\u7cdf\u6e9c\u9c7c\u7247\uff0c\u5c0f\u8611\u83c7\u7092\u9c7c\u7247\uff0c\u83b3\u841d\u70e4\u9c7c\u7247\uff0c\u9c9c\u8349\u83c7\u4e1d\u74dc\u9c7c\u7247\u6c64\uff0c\u7cd6\u918b\u9c7c\u7247\uff5e\uff0c\u751f\u9c7c\u7247\u5bff\u53f8\u4fbf\u5f53\uff0c\u8304\u6c41\u9c7c\u7247\uff0c\u756a\u8304\u9c7c\u7247\uff0c\u751f\u6eda\u9c7c\u7247\u7ca5\uff0c\u9178\u83dc\u9c7c\u7247\uff0c\u9999\u7092\u59dc\u8471\u70b8\u9c7c\u7247\uff0c\u8c46\u82b1\u9c7c\u7247\uff0c\u7ea2\u70e7\u9c7c\u7247\u7af9\u8f6e\uff0c\u9c7c\u7247\u8c46\u8150\u6c64 \u964d\u8102\u964d\u7cd6\uff0c\u6cb8\u817e\u9c7c\u7247\uff0c\u7cdf\u7198\u9c7c\u7247\uff0c\u9999\u8fa3\u9c7c\u7247\uff0c\u9999\u8fa3\u6c34\u6ed1\u9c7c\u7247", "title": "\u9c7c\u7247\u7684\u505a\u6cd5\u5927\u5168_\u600e\u4e48\u505a\u9c7c\u7247_\u5fc3\u98df\u8c31", "url": "http://www.xinshipu.com%2F%C3%A5%C2%81%C2%9A%C3%A6%C2%B3%C2%95%2F%C3%A9%C2%B1%C2%BC%C3%A7%C2%89%C2%87%2F", "thumbnail_width": 120, "thumbnail_url": "http://xinshipu.cn/20110909/smallImage2/1315545888948.jpg", "version": "1.0", "provider_name": "Xinshipu", "type": "link", "thumbnail_height": 90}';

$mock_ua->map(
	      'http://api.embed.ly/1/oembed?url=http%3A%2F%2Fwww.xinshipu.com%2F%C3%A5%C2%81%C2%9A%C3%A6%C2%B3%C2%95%2F%C3%A9%C2%B1%C2%BC%C3%A7%C2%89%C2%87%2F&key=test&maxwidth=500',
	      sub {
		my $req = shift;
		my $uri = $req->uri;
		my $content = $oembed2_res;
		$headers->content_length(length($content));
		my $res = HTTP::Response->new(200, 'OK', $headers, $content);
		return $res;
	      },
);


#pass in mock user agent..  IoC testing
$embedly = WebService::Embedly->new({ api_key => 'test',
				      maxwidth => 500,
				      ua => $ua
				    });

isa_ok($embedly, 'WebService::Embedly');
isa_ok($embedly->ua, 'LWP::UserAgent');

my $url;
my $e;

$url = 'http://youtu.be/I8CSt7a7gWY';
$e = try {
  my $oembed_ref = $embedly->oembed($url);
  is ($oembed_ref->{provider_url}, 'http://www.youtube.com/', 'Oembed response' );
};

if (catch_all $e) {
  fail 'Failed oembed request' ;
}

# /%E5%81%9A%E6%B3%95/%E9%B1%BC%E7%89%87/';
$url = 'http://www.xinshipu.com/做法/鱼片/';
  my $oembed_ref = $embedly->oembed($url);
$e = try {
  is ($oembed_ref->{provider_url}, 'http://www.xinshipu.com', 'Oembed response escaped' );
};

if (catch_all $e) {
  diag "$e";
  fail 'Failed oembed request' ;
}


done_testing();
