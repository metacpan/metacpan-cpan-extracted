
use strict;
use warnings;
use Test::More tests => 1 ;
use LWP::UserAgent;

diag("Testing for network and proxy.  even passing this, a common reason for failing another test suite is network, network proxy, or network time out issues.  see http://cpantesters.perl.org/show/WWW-Patent-Page.html for failure credibility." ); 
  my $ua = LWP::UserAgent->new;
  $ua->agent("$0/0.1 " . $ua->agent);
  # $ua->agent("Mozilla/8.0") # pretend we are very capable browser
 my $host = 'http://www.google.com/';

 $ua->env_proxy();
  my $req = HTTP::Request->new(GET => $host);
  $req->header('Accept' => 'text/html');

  my $res = $ua->request($req);

if (exists($ENV{'http_proxy'})){
  ok ( $res->is_success , "network access. \$ENV{'http_proxy'} = '$ENV{'http_proxy'}'" );
}
else {ok ( $res->is_success , 'network access.' );}

