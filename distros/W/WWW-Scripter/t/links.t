#!perl -w

use lib 't';

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

use tests 4; # Scripter->links
{
	my $m = new WWW::Scripter ;
	my $url = data_url <<'END';
		<link charset=utf-8 href=not.html>
		<meta http-equiv=refrEsh content='3 ; url = nfr.html'>
		<meta http-equiv=refrEsh content='3;url=ntr.html'>
		<meta http-equiv=refrEsh content='3; url="nto.html"'>
		<meta http-equiv=refresh content="3; url='non.html'">
		<title>A page</title><p>
		  <a name=link1 href=one.html target=a>Dis is link one.</a>
		  <a name=link2 href=two.html target=b>Dis is link two.</a>
		  <a name=link3 href=tri.html target=c>Diss link three.</a>
		  <map><area href=for.html shape=rect></map>
		  <map><area nohref alt='ignore me'></map>
		  <iframe name=j>ignore me</iframe>
		  <iframe name=i src=fyv.html frameborder=1></iframe>
END
	$m->get($url);
#	my $base = $m->base;
# ~~~ We can’t test base for now, because of a URI bug.
	is_deeply [
		map {;
			my $link = $_;
			+{ map +($_ => $link->$_),
				qw[ url text name tag attrs ] }
		} $m->links
	], [
		{ url => 'not.html',
		  text => undef,
		  name => undef,
		  tag  => 'link',
	#	  base => $base,
		  attrs => {
			charset => 'utf-8', href => 'not.html',
		  }, },
		{ url => 'nfr.html',
		  text => undef,
		  name => undef,
		  tag  => 'meta',
	#	  base => $base,
		  attrs => {
		     'http-equiv','refrEsh', content=>'3 ; url = nfr.html',
		  }, },
		{ url => 'ntr.html',
		  text => undef,
		  name => undef,
		  tag  => 'meta',
	#	  base => $base,
		  attrs => {
			'http-equiv','refrEsh', content=>'3;url=ntr.html',
		  }, },
		{ url => 'nto.html',
		  text => undef,
		  name => undef,
		  tag  => 'meta',
	#	  base => $base,
		  attrs => {
		      'http-equiv','refrEsh', content=>'3; url="nto.html"',
		  }, },
		{ url => 'non.html',
		  text => undef,
		  name => undef,
		  tag  => 'meta',
	#	  base => $base,
		  attrs => {
		      'http-equiv','refresh', content=>"3; url='non.html'",
		  }, },
		{ url => 'one.html',
		  text => 'Dis is link one.',
		  name => 'link1',
		  tag  => 'a',
	#	  base => $base,
		  attrs => {
			name => 'link1', href => 'one.html', target => 'a',
		  }, },
		{ url => 'two.html',
		  text => 'Dis is link two.',
		  name => 'link2',
		  tag  => 'a',
	#	  base => $base,
		  attrs => {
			name => 'link2', href => 'two.html', target => 'b',
		  }, },
		{ url => 'tri.html',
		  text => 'Diss link three.',
		  name => 'link3',
		  tag  => 'a',
	#	  base => $base,
		  attrs => {
			name => 'link3', href => 'tri.html', target => 'c',
		  }, },
		{ url => 'for.html',
		  text => undef,
		  name => undef,
		  tag  => 'area',
	#	  base => $base,
		  attrs => {
			href => 'for.html', shape => 'rect',
		  }, },
		{ url => 'fyv.html',
		  text => undef,
		  name => 'i',
		  tag  => 'iframe',
	#	  base => $base,
		  attrs => {
			name => 'i', src => 'fyv.html', frameborder => '1',
		  }, },
	], '$scripter->links'
	or require Data::Dumper, diag Data::Dumper::Dumper([
		map {;
			my $link = $_;
			+[ map +($_ => $link->$_),
				qw[ url text name tag attrs ] ]
		} $m->links
	]);

	my $link = $m->document->links->[1];
	$link->parentNode->removeChild($link);

	is_deeply [
		map {;
			my $link = $_;
			+{ map +($_ => $link->$_),
				qw[ url text name tag attrs ] }
		} $m->links
	], [
		{ url => 'not.html',
		  text => undef,
		  name => undef,
		  tag  => 'link',
	#	  base => $base,
		  attrs => {
			charset => 'utf-8', href => 'not.html',
		  }, },
		{ url => 'nfr.html',
		  text => undef,
		  name => undef,
		  tag  => 'meta',
	#	  base => $base,
		  attrs => {
		     'http-equiv','refrEsh', content=>'3 ; url = nfr.html',
		  }, },
		{ url => 'ntr.html',
		  text => undef,
		  name => undef,
		  tag  => 'meta',
	#	  base => $base,
		  attrs => {
			'http-equiv','refrEsh', content=>'3;url=ntr.html',
		  }, },
		{ url => 'nto.html',
		  text => undef,
		  name => undef,
		  tag  => 'meta',
	#	  base => $base,
		  attrs => {
		      'http-equiv','refrEsh', content=>'3; url="nto.html"',
		  }, },
		{ url => 'non.html',
		  text => undef,
		  name => undef,
		  tag  => 'meta',
	#	  base => $base,
		  attrs => {
		      'http-equiv','refresh', content=>"3; url='non.html'",
		  }, },
		{ url => 'one.html',
		  text => 'Dis is link one.',
		  name => 'link1',
		  tag  => 'a',
	#	  base => $base,
		  attrs => {
			name => 'link1', href => 'one.html', target => 'a',
		  }, },
		{ url => 'tri.html',
		  text => 'Diss link three.',
		  name => 'link3',
		  tag  => 'a',
	#	  base => $base,
		  attrs => {
			name => 'link3', href => 'tri.html', target => 'c',
		  }, },
		{ url => 'for.html',
		  text => undef,
		  name => undef,
		  tag  => 'area',
	#	  base => $base,
		  attrs => {
			href => 'for.html', shape => 'rect',
		  }, },
		{ url => 'fyv.html',
		  text => undef,
		  name => 'i',
		  tag  => 'iframe',
	#	  base => $base,
		  attrs => {
			name => 'i', src => 'fyv.html', frameborder => '1',
		  }, },
	], '$scripter->links after a modification to the document'
	or require Data::Dumper, diag Data::Dumper::Dumper([
		map {;
			my $link = $_;
			+{ map +($_ => $link->$_),
				qw[ url text name tag attrs ] }
		} $m->links
	]);
	
	$link = ($m->links)[5];
 	my $dom_link = $m->document->links->[0];
	$dom_link->href("stred");
	is $link->url, 'stred',
	  'links update automatically when their HTML elements change';

	$url = data_url <<'END';
		<title>A page</title><p>
		<frameset><frame name=framname src=framsrc frameborder=1>
		</frameset>
END
	$m->get($url);
#	my $base = $m->base;
# ~~~ We can’t test base for now, because of a URI bug.
	is_deeply [
		map {;
			my $link = $_;
			+{ map +($_ => $link->$_),
				qw[ url text name tag attrs ] }
		} $m->links
	], [
		{ url => 'framsrc',
		  text => undef,
		  name => 'framname',
		  tag  => 'frame',
	#	  base => $base,
		  attrs => {
			name=>'framname', src=>'framsrc', frameborder=>'1',
		  }, },
	], '$scripter->links includes frames'
	or require Data::Dumper, diag Data::Dumper::Dumper([
		map {;
			my $link = $_;
			+[ map +($_ => $link->$_),
				qw[ url text name tag attrs ] ]
		} $m->links
	]);
}

use tests 6; # follow_link
for(""," with autocheck")
{
 my $w = new WWW'Scripter autocheck => $_;
 $w->script_handler(default => new ScriptHandler sub{},sub {
  my $code = $_[3];
  eval "sub { $code }"
 });
 $w->get(data_url <<'');
  <a href='cleck'
     onclick='shift->target->href("data:text/html,cting")'>frare</a>

 my $res = $w->follow_link(text=>'frare');
 is $w->location, 'data:text/html,cting',
  "follow_link runs event handlers$_";
 is $res, $w->res, "retval of follow_link$_";
 like 
   eval {
    $w->get(data_url "<a href='data:text/html,slext' onclick=0>czon</a>");
    $w->follow_link(text => 'czon');
    join " ", $w->location, $w->history->length
   },
   qr "czon\S+ 3\z",
  "follow_link$_ can be intercepted by event handlers";
}

use tests 1; # find_all_links
# just a simple test to make sure it works with no document
{
 my $w = new WWW'Scripter;
 $w->get('about:oentuheonstue');
 ok eval { $w->find_all_links; 1 },
   'find_all_links does not die with no document [rt.cpan.org #72481]';
}
