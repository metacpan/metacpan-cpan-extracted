use strict;
use warnings;

use Test::More tests => 6;

use WWW::Twitpic::Fetch;

my $tp = WWW::Twitpic::Fetch->new;

ok $tp;

package UA1;
use Moose;
use Test::More;
use HTTP::Response;

sub get
{
	my (undef, $uri) = @_;

	is $uri, 'http://twitpic.com/public_timeline/';
	HTTP::Response->new(404);
}

package main;

$tp->ua(UA1->new);
ok !defined $tp->public_timeline;

package UA2;
use Moose;
use Test::More;
use HTTP::Response;

sub get
{
	my (undef, $uri) = @_;

	is $uri, 'http://twitpic.com/public_timeline/';
	my $r = HTTP::Response->new(200);
	$r->content(<<EOS);
<html>
<head>
</head>
<body>
<div class="comment">
			<table width="100%">
				<tr>
					<td><img class="avatar" src="avatar1.jpg"></td>
					<td >
										<div ><a class="nav" href="/photos/hoge">hoge</a> <span class="date" style="color:#555555;font-size:12px;"> &nbsp; less than a minute ago from site</span></div>

					<div style="font-size:12px;background-color:#ffffff;padding:10px;">
					<a href="/12345" title="TEST MESSAGE1">
					<img src="example1.jpg" alt="TEST MESSAGE1">
					</a>TEST MESSAGE1<div style="clear:both;"></div>
					</div>
					</td>
				</tr>

			</table>
			</div>

<div class="comment">
			<table width="100%">
				<tr>
					<td><img class="avatar" src="avatar2.jpg"></td>
					<td >
										<div ><a class="nav" href="/photos/hige">hige</a> <span class="date" style="color:#555555;font-size:12px;"> &nbsp; less than a minute ago from site</span></div>

					<div style="font-size:12px;background-color:#ffffff;padding:10px;">
					<a href="/abcde" title="TEST MESSAGE2">
					<img src="example2.jpg" alt="TEST MESSAGE2">
					</a>TEST MESSAGE2<div style="clear:both;"></div>
					</div>
					</td>
				</tr>

			</table>
			</div>

</body>
</html>
EOS
	$r;
}

package main;

$tp->ua(UA2->new);

my $res = $tp->public_timeline;
ok @$res == 2;
is_deeply $res, [{
	avatar => "avatar1.jpg",
	username => "hoge",
	mini => "example1.jpg",
	message => "TEST MESSAGE1",
	id => '12345',
}, {
	avatar => "avatar2.jpg",
	username => "hige",
	mini => "example2.jpg",
	message => "TEST MESSAGE2",
	id => 'abcde',
}];

