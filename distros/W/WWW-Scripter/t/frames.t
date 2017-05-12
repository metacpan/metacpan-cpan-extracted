#!perl -w

use lib 't';

use Scalar::Util 1.09 'refaddr';
use URI;
use URI::file;
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

use tests 20; # (i)frames
{
	my $script;
	my $script_scope;
	(my $m = new WWW::Scripter)
	 ->script_handler( default => new ScriptHandler sub {
			($script_scope,$script) = @_;
		}) ;
	my $frame_url = data_url <<'END';
		<script>abcde</script>
END
	my $top_url = data_url <<END;
		<iframe id=i src="$frame_url">
END
	$m->get($top_url);

	my $w = $m;

	is $w->top, $w->window, 'top-level top refers to self';

	is $script, 'abcde', 'scripts in iframes run';
	is $w->frames->{i},
		(my $i = $w->document->getElementsByTagName('iframe')->[0])
		  ->contentWindow,
		'hash keys to access iframes';
	is $script_scope, $i->contentWindow,
	 'window object passed to script handler in iframe';
	is $w->frames->[0], $i->contentWindow, 'array access to iframes';
	is $i->contentDocument,$w->frames->[0]->document,
	 'iframe->contentDocument';
	isn't $w->frames->[0], $w,
		'frames->[0] (the iframe) is not the top-level win';
	isn't $w->document, $i->contentDocument,
		"the iframe's doc is not the top window's doc";
	isn't refaddr +($w->frames)[0]->location, refaddr $w->location,
	 'the main window and the iframe do not share a location object';
	is $w->frames->[0]->top, $w,
	 "iframe's top method returns the main window";
	is $w->length, 1, 'window length when there is an iframe';


	$script = '';
	$top_url = data_url <<END;
		<frame id=the_frame src="$frame_url">
END
	$m->get($top_url);

	is $script, 'abcde', 'scripts in frames run';
	is $w->frames->{the_frame},
		($i = $w->document->getElementsByTagName('frame')->[0])
		  ->contentWindow,
		'hash keys to access frames';
	is $w->frames->[0], $i->contentWindow, 'array access to frames';
	is $i->contentDocument,$w->frames->[0]->document,
	 'frame->contentDocument';
	isn't $w->frames->[0], $w,
		'frames->[0] (the frame) is not the top-level window';
	isn't $w->document, $i->contentDocument,
		"the frame's doc is not the top window's doc";
	is $w->frames->[0]->top, $w,
	 "frame's top method returns the main window";
	is $w->length, 1, 'window length when there is a frame';

	# This test *must* use a non-data URL, at least until
	# URI::data is fixed.
	$w->get(new_abs URI'file 't/empty-iframe.html');
	# In version 0.007, we would never reach this point.
	pass("iframes do not cause infinite recursion");
}

use tests 3; # nested frames
{
	my $script;
	my $m = new WWW::Scripter;
	my $inner_frame_url = data_url "blah blah blah";
	my $outer_frame_url = data_url <<END;
		<iframe id=innerframe src="$inner_frame_url">
END
	my $top_url = data_url <<END;
		<iframe id=outerframe src="$outer_frame_url">
END
	$m->get($top_url);


	is $m->frames->{outerframe}->frames->{innerframe}->top, $m,
	 'top property accessed from nested frame';

	is $m->frames->{outerframe}->frames->{innerframe}->parent,
	 $m->frames->{outerframe},
	 'parent of inner frame';
	is $m->parent, $m, 'top-level window is its own parent';
}

use tests 2; # frames method with non-HTML documents
{            # This used to die before version 0.004
 my $w = new WWW::Scripter;
 $w->get("data:text/plain,");
 is +()=$w->frames, 0, 'frames returns 0 in list context with a text doc';
 is @{ $w->frames }, 0, 'frames collection is empty with a text doc';
}

use tests 1; # frames with relative URLs
{
 my $w = new WWW::Scripter;
 my $url = ''.new_abs URI'file 't/blank.html';
 $url =~ s/(['&])/'&#' . ord($1) . ';'/egg;
 $w->document->write("<iframe src='$url'>");
 $w->document->close;
 for($w->frames->[0]) {
  $_->document->write("<iframe src='#glat'>");
  $_->document->close;
  like $_->frames->[0]->location, qr"blank.html#glat\z",
   'frame URLs are relative to the parent, not the top';
 }
}

use tests 2; # frames in list context
{
 my $w = new WWW::Scripter;
 $w->document->write('<iframe></iframe><iframe></iframe>');
 $w->document->close;
 is +()=$w->frames, 2,
  'frames returns the right number of elements in list context';
 is_deeply
   [ map refaddr $_, $w->frames ],
   [ map refaddr $_, @{ $w->frames }],
  'the elements match what is in the frames collection';
}
