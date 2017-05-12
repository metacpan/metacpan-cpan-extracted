use Test::More tests => 13;

use WWW::Twitpic::Fetch;


my $twitpic = WWW::Twitpic::Fetch->new;

ok $twitpic;
isa_ok $twitpic->ua, 'LWP::UserAgent';

{ local $@;
	eval { $twitpic->list; };
	ok $@;
}
{ local $@;
  eval { $twitpic->list('invalid+username') };
  ok $@;
}

package UA1;
use Moose;
use Test::More;
use HTTP::Response;
sub get
{
	my ($self, $uri, %param) = @_;
	is($uri, "http://twitpic.com/photos/hoge");
	is(scalar(keys %param), 0);
	return HTTP::Response->new(404);
}

package main;

$twitpic->ua(UA1->new);
ok !defined $twitpic->list('hoge');

package UA2;
use Moose;
use Test::More;
use HTTP::Response;

sub get
{
	my ($self, $uri, %param) = @_;
	is ($uri, "http://twitpic.com/photos/hige?page=2");
	is scalar(keys %param), 0;
	my $r = HTTP::Response->new(200);
	$r->content(<<EOS);
<html><head><title>TEST</title></head><body>
<ul id="user-photos">
<li>
<div class="user-photo">
<a href="/a7g60"><img alt="TEST MESSAGE" src="http://example.com/example.jpg" style="width: 150px; height: 150px;" /></a>
</div>
<div class="user-tweet">
<p>TEST MESSAGE</p>
<p class="tweet-meta">
6 days ago from site &bull; viewed 35 times
</p>
<form class="delete" method="post" action="/media/delete" onSubmit="return confirm('Are you sure you want to delete this image? THIS CANNOT BE UNDONE.');">
<input type="hidden" name="media_id" value="6umvj2">
<span><input class="delete-image" type="image" src="/images/icon_trash.gif"> <input type="submit" value="delete" class="delete-button" /></span>
</form>
</div>
</li>

<li>
<div class="user-photo">
<a href="/J89Tt"><img alt="TEST MESSAGE 2nd" src="http://example.com/example.png" style="width: 150px; height: 150px;" /></a>
</div>
<div class="user-tweet">
<p>TEST MESSAGE 2nd</p>
<p class="tweet-meta">
16 days ago from site &bull; viewed 30 times
</p>
<form class="delete" method="post" action="/media/delete" onSubmit="return confirm('Are you sure you want to delete this image? THIS CANNOT BE UNDONE.');">
<input type="hidden" name="media_id" value="6pd7qa">
<span><input class="delete-image" type="image" src="/images/icon_trash.gif"> <input type="submit" value="delete" class="delete-button" /></span>
</form>
</div>
</li>
</ul>
</body>
</html>
EOS
	$r;
}

package main;

$twitpic->ua(UA2->new);
is_deeply($twitpic->list('hige', 2), 
	[
	{id => 'a7g60', message => 'TEST MESSAGE', thumb => 'http://example.com/example.jpg'},
	{id => 'J89Tt', message => 'TEST MESSAGE 2nd', thumb => 'http://example.com/example.png'},
	]
);

package UA3;
use Moose;
use Test::More;
use HTTP::Response;

sub get
{
	my ($self, $uri, %param) = @_;
	is ($uri, "http://twitpic.com/photos/hige?page=3");
	is scalar(keys %param), 0;
	my $r = HTTP::Response->new(200);
	$r->content(<<EOS);
<html><head><title>TEST</title></head><body>
</body>
</html>
EOS
	$r;
}

package main;

$twitpic->ua(UA3->new);
is_deeply($twitpic->list('hige', 3), 
	[
	]
);

