#!perl -w

BEGIN { $^P |= 0x100 }

use WWW::Scripter;
$w = new WWW::Scripter;

use Test::More tests => 2;

sub TIESCALAR {bless[]}
tie $_, ""; # Having no FETCH or STORE method, this variable will explode
            # when touched.

# Part of target.t which used to die:
$w->get(
  q|data:text/html,<iframe src="|
 . q|data:text/html,<iframe name=crelp>|
 .q|"></iframe><a target=crelp href="data:text/html,">|
);
$w->follow_link(url_regex=>qr/data:/);
$w->frames->[0]->get('about:blank');
for my $l($w->document->links->[0]) {
 $l->href("data:text/html,czeen");
 $l->click;
}

pass('tied $_ is left alone when pages are fetched');


# Set up a cookie-producing protocol, to make sure we don’t choke on
# HTTP::Date’s local($_) when extracting cookies from the response.
use LWP'Protocol;
{
 my $year_plus_one = (localtime)[5] + 1900 + 1;
 package __;
 @ISA = LWP'Protocol;
 LWP'Protocol'implementor $'_ => __ for 'http';
 sub request {
  my($self,undef,undef,$arg) = @'_;
  my $response = new HTTP::Response 200, 'OK', [
   Content_Length=>0,
   Content_Type  =>'text/html',
                            # We use hyphens in the date to force
                            # HTTP::Date::str2time to resort to parse_date,
                            # which does local($_).
   Set_Cookie  =>"foo=bar;expires=Thu, 15-Dec-$year_plus_one 04:25:23 GMT",
  ];

  $self->collect($arg, $response, sub {\''});
 }
}

$w->request(
 # not our fault
 do { local *_; new HTTP::Request GET => 'http://www.example.com/' }
);
pass('tied $_ is left alone when pages are fetched with ->request');
