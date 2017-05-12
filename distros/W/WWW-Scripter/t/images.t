#!perl -w

use lib 't';

use utf8;

use URI;
use WWW::Scripter;

sub data_url {
	my $u = new URI 'data:';
	$u->media_type('text/html');
	$u->data(shift);
	$u
}

{ package ScriptHandler;
  sub new { shift; bless [@_] }
  sub eval { my $self = shift; $self->[0](@_) }
  sub event2sub { my $self = shift; $self->[1](@_) }
}

use tests 3; # images
{
	my $m = new WWW::Scripter;
	my $url = data_url <<'END';
	  <title>A page</title><p>
	    <img name=link1 src=one.html width=1 height=2 alt='Dis '>
	    <input name=link2 src=two.html type=image width=3 height=4
	      alt='a'>
	    <img name=link3 src=tri.html width=6 height=87 alt='target=c>'>
END
	$m->get($url);
#	my $base = $m->base;
# ~~~ We can’t test base for now, because of a URI bug.
	is_deeply [
		map {;
			my $img = $_;
			+{ map +($_ => $img->$_),
				qw[ url tag name height width alt ] }
		} $m->images
	], [
		{ url => 'one.html',
	#	  base => $base,
		  tag  => 'img',
		  name => 'link1',
		  height => 2,
		  width => 1,
		  alt => 'Dis ', },
		{ url => 'two.html',
	#	  base => $base,
		  tag  => 'input',
		  name => 'link2',
		  height => 4,
		  width => 3,
		  alt => 'a', },
		{ url => 'tri.html',
	#	  base => $base,
		  tag  => 'img',
		  name => 'link3',
		  width => 6,
		  height => 87,
		  alt => 'target=c>', },
	], 'images'
	or require Data::Dumper, diag Data::Dumper::Dumper([
		map {;
			my $img = $_;
			+{ map +($_ => $img->$_),
				qw[ url tag name height width alt ] }
		} $m->images
	]);

	my $input = $m->document->find('input');
	$input->parentNode->removeChild($input);

	is_deeply [
		map {;
			my $img = $_;
			+{ map +($_ => $img->$_),
				qw[ url tag name height width alt ] }
		} $m->images
	], [
		{ url => 'one.html',
	#	  base => $base,
		  tag  => 'img',
		  name => 'link1',
		  height => 2,
		  width => 1,
		  alt => 'Dis ', },
		{ url => 'tri.html',
	#	  base => $base,
		  tag  => 'img',
		  name => 'link3',
		  width => 6,
		  height => 87,
		  alt => 'target=c>', },
	], 'images after a modification to the document'
	or require Data::Dumper, diag Data::Dumper::Dumper([
		map {;
			my $img = $_;
			+{ map +($_ => $img->$_),
				qw[ url tag name height width alt ] }
		} $m->images
	]);
	
	my $image = ($m->images)[0];
 	my $dom_img = $m->document->images->[0];
	$dom_img->src("glat");
	is $image->url, 'glat',
	  'images update automatically when their HTML elements change';
}

use tests 6; # fetch_images and image_handler accessors
{
 my $w = new WWW'Scripter;
 $w->fetch_images(1), $w->image_handler(my$sub = sub{});
 ok $w->fetch_images;
 ok $w->fetch_images(0);
 ok !$w->fetch_images;
 is $w->image_handler, $sub;
 is $w->image_handler(my $sub2=sub{}), $sub;
 is $w->image_handler, $sub2;
}

use tests 21; # fetch_images and image_handler in action
{
	package ProtocolThatReturnsReferrer;
	use LWP::Protocol;
	our @ISA = LWP::Protocol::;

	LWP'Protocol'implementor $_ => __PACKAGE__ for qw/ referrer /;

	sub request {
		my($self, $request, $proxy, $arg) = @_;
		new HTTP::Response 200, 'OK', undef, $request->referer
	}
}
{
	package ProtocolThatSetsFoo;
	use LWP::Protocol;
	our @ISA = LWP::Protocol::;

	LWP'Protocol'implementor $_ => __PACKAGE__ for qw/ foo /;

	sub request {
		my($self, $request, $proxy, $arg) = @_;
		$main::Foo = $request->uri;
		new HTTP::Response 200, 'OK'
	}
}
{
 my @__;
 my $w = new WWW'Scripter;
 $w->image_handler(sub { push @__, \@_ });

 $w->get('data:text/html,<img src=data:image/gif,aoeu>'); # corrupt GIF :-)
 is @__, 0, 'image_handler is not called without fetch_images';

 $w-> fetch_images(1);

 $w->get('data:text/html,<img>');
 is @__, 0, 'Parsing <img> with no src does not call image_handler';
 $w->get('data:text/html,<input type=image>');
 is @__, 0, 'Parsing image input with no src does not call image_handler';
 $w->get('data:text/html,<input type=text src=foo>');
 is @__, 0, 'Parsing non-image input does not call image_handler';

 $w->get('data:text/html,<img src=data:image/gif,aoe>');
 is @__, 1, 'Parsing <img src=...> calls image_handler';
 is $__[0][0], $w, 'First arg to image_handler is window';
 is $__[0][1], $w->document->images->[0],
    'Second arg to image_handler is image elem';
 isa_ok $__[0][2], 'HTTP::Response', 'third arg to image_handler';
 is $__[0][2]->content, 'aoe',
   'third arg to image_handler contains the right content';

 undef @__;
 $w->get('data:text/html,<input type=image src=data:image/gif,aaa>');
 is @__, 1, 'Parsing <input type=image src=...> calls image_handler';
 is $__[0][0], $w, 'First arg to image_handler (for input) is window';
 is $__[0][1], $w->document->find('input'),
    'Second arg to image_handler is input elem';
 isa_ok $__[0][2], 'HTTP::Response', 'third arg to image_handler (input)';
 is $__[0][2]->content, 'aaa',
   'third arg to image_handler (for input) contains the right content';

 undef @__;
 $w->get(my $u = 'data:text/html,<img src=referrer://foo>');
 is $__[0][2]->content, new URI ($u),
  'image is fetched with the right referrer';

 $w->image_handler(undef);
 $w->get('data:text/html,<img src=foo:a>');
 is $Foo, 'foo:a', 'image is fetched without image_handler';

 my $i = $w->document->createElement('img');
 $i->src('foo:b');
 is $Foo, 'foo:b',
  'image returned by createElement fetches when src is set';
 $i->src('foo:c');
 is $Foo, 'foo:c',
  'image returned by createElement fetches when src is changed';
 $i = $w->document->createElement('input');
 $i->type('image');
 $i->src('foo:d');
 is $'Foo, 'foo:d', 'image input element fetches when src is set';
 $i->src('foo:e');
 is $'Foo, 'foo:e', 'image input element fetches when src changes';
 $i->type('text');
 $i->src('foo:f');
 is $'Foo, 'foo:e', 'text input does not fetchen when src is set';
}
