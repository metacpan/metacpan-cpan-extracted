#!perl

use lib 't';
use warnings;
no warnings qw 'utf8 parenthesis regexp once qw bareword';

use HTTP::Response;
use Scalar::Util 1.09 'refaddr';
use Test::More;
use URI;
use URI'file;
use WWW::Scripter;

# Avoid network activity when playing with the location object:
use LWP'Protocol;
{
 package __;
 @ISA = LWP'Protocol;
 LWP'Protocol'implementor $'_ => __ for <http file>;
 sub request {
  my($self,undef,undef,$arg) = @'_;
  my $response = new HTTP::Response 200, 'OK', [
   Content_Length=>0,
   Content_Type  =>'text/html',
  ];

  $self->collect($arg, $response, sub {\''});
 }
}

sub data_url {
	my $u = new URI 'data:';
	$u->media_type('text/html');
	$u->data(shift);
	$u
}

use tests 1; # document.location
{
	my $m = new WWW::Scripter;
	$m->get(data_url '');
	is refaddr $m->document->location, refaddr $m->location,
		'document->location';
}

use tests 3; # location->hash
{
# This just tests a bug fixed in wmpdom 0.009.
	my $script;
	my $l = (my $m = new WWW::Scripter)->location;
	$m->get('data:text/html,');
	is $l->hash, '', 'location->hash when there is no fragment';
	$m->get('data:text/html,#');
	is $l->hash, '#', 'location->hash when URL ends in #';
	$m->get('data:text/html,#fetvov');
	is $l->hash, '#fetvov','location->hash when URL ends with #...';
	
}

use tests 1; # reload
$w = new WWW::Scripter;
my $response = $w->response;
$w->location->reload;
cmp_ok $w->response, '!=', $response,
 'different response object after calling location->reload';

use tests 7; # replace
{
 my $w = new WWW'Scripter;
 $w->location->replace("data:text/html,");
 is $w->history->length, 1,
  'location->replace before browsing adds a history entry';
 $w->get("data:text/html,2");
 $w->get("data:text/html,3");
 $w->back;
 $w->location->replace('about:blank');
 is $w->uri, 'about:blank', 'location->replace goes to the correct page';
 for($w->history) {
  is $_->length, 3, 'location->replace does not erase the future';
  is $_->index, 1, 'location->replace stays in the same place in history';
 }
 $w->forward;
 like $w->uri, '/3$/', 'future entries are untouched';
 $w->history->go(-2); # back to the beginning
 $w->location->replace("data:text/html,4");
 is $w->history->index, 0,
  'location->replace does not move forward if called from the first page';
 $w->get(my $uri = new_abs URI'file 't/blank.html');
 $w->location->replace('fragments.html');
 $uri =~ s/blank/fragments/;
 is $w->location, $uri, 'location->replace with relative URLs';
}

use tests 24; # generic accessor tests
{             # Copied from HTML::DOM’s html-element.t, these could
              # probably be expanded.
	$w->get("http://fext.gred/clow/blelp");
	my $loc = $w->location;
	is $loc->hash, "", 'hash is blank when missing from URL';
	is $loc->hash("#brun"), '', 'hash retval when setting';
	is $loc->href, "http://fext.gred/clow/blelp#brun",
	 'setting hash modifies href';
	$loc->href("http://fext.gred:1234/clow/blelp");
	is $loc->hostname, "fext.gred",
	 'retval of hostname';
	is $loc->hostname("blen.baise"), 'fext.gred',
	 'retval of hostname when setting';
	is $loc->href, "http://blen.baise:1234/clow/blelp",
	 "setting hostname modifies href";
	$loc->href("http://blan:2323/");
	is $loc->host, "blan:2323", 'host';
	is $loc->host("blan"), 'blan:2323',
	 'retval of host when setting';
	is $loc->href, "http://blan/", 'setting host';
	is $loc->pathname, "/", 'pathname';
	is $loc->pathname("/bal/"), '/', 'pathname retval when setting';
	is $loc->href, "http://blan/bal/", 'setting pathname';
	$loc->href("http://blid:3838/");
	is $loc->port, "3838", "port";
	is $loc->port("3865"), 3838, 'port retval when setting';
	is $loc->href, "http://blid:3865/", 'setting port';
	is $loc->protocol , "http:", 'protocol';
	is $loc->protocol("ftp"), "http:", 'retval when setting protocol';
	is $loc->href, 'ftp://blid:3865/', 'effect of setting protocol';
	is $loc->search, '', 'search is blank when URL contains no ?';
	is $loc->search("?oeet"), '', 'retval of search when setting';
	is $loc->href,'ftp://blid:3865/?oeet', 'result of setting search';
	$loc->search('?');
	is $loc->href,'ftp://blid:3865/?', 'result of setting search to ?';

	is $loc->href("about:blank"),'ftp://blid:3865/?',
	 'retval of href when setting';
	$w = new WWW'Scripter;
	is $w->location->href, 'about:blank',
	 'location->href is about:blank when no browsing has happened';
}

use tests 3; # assign
{
 my $w = new WWW'Scripter;
 $w->get("data:text/html,");
 is +()=$w->location->assign("data:text/html,trow"), 0,
  'assign returneth nought';
 is $w->uri, "data:text/html,trow", 'assign goes to another page';
 is $w->history->index, 1, 'assign adds to history';
}
