#!/usr/bin/perl -w

BEGIN {print "1..4\n"}
END {print "not ok 1\n" unless $loaded;}

sub nogo {print "not "}
sub ok {my $t=shift; print "ok $t\n";}

my $redirect=bless
  ({
    '_protocol' => 'HTTP/1.1',
    '_request' => bless
    ({
      '_method' => 'HEAD',
      '_headers' => bless
      ({
	'user-agent' => 'LinkController/0.0',
	'from' => 'mikedlr@scotclimb.org.uk'
       }, 'HTTP::Headers' ),
      '_uri' => bless
      ([
	bless
	(do{\(my $o = 'http://www.esoterica.pt/esoterica/')}, 'URI::http' ),
       undef
      ], 'URI::URL' ),
     '_content' => ''
   }, 'HTTP::Request' ),
   '_headers' => bless
   ({
     'location' => 'http://www.via-net-works.pt/esoterica/',
     'client-peer' => '195.22.0.147:80',
     'content-type' => 'text/html',
     'connection' => 'close',
     'date' => 'Tue, 30 Oct 2001 18:34:25 GMT',
     'server' => 'Apache/1.3.11 (Unix)',
     'client-date' => 'Tue, 30 Oct 2001 18:34:20 GMT'
    }, 'HTTP::Headers' ),
   '_msg' => 'Found',
   '_rc' => '302',
   '_content' => ''
 }, 'HTTP::Response' );


use HTTP::Response;

use WWW::Link::Reporter::Text;
use WWW::Link;

$loaded = 1;
ok(1);

my $reporter =  WWW::Link::Reporter::Text->new();
my $link=WWW::Link->new("http://www.example.com");
my $tempfile="/tmp/test-temp.$$";


ok(2);

$link->redirects( [ $redirect ] );

open ( SAVEOUT, ">&STDOUT" ) || die "couldn't duplicate stdout";
open ( STDOUT, "> $tempfile" ) || die "couldn't open tempfile to write";

$reporter->redirections($link);

close ( STDOUT ) || die "couldn't close tempfile";
open ( STDOUT, ">&SAVEOUT" ) || die "couldn't recover stdout";

open ( TEMPFILE, "< $tempfile" ) || die "couldn't open tempfile to read";
my $found=0;
while (<TEMPFILE>) {
  $found=1 if m,http://www.via-net-works.pt/esoterica/,;
}
close ( TEMPFILE ) || die "couldn't close tempfile";

nogo unless $found;

ok(3);

$link->redirects( [ "http://www.whilgo.com/frood/" ] );

open ( SAVEOUT, ">&STDOUT" ) || die "couldn't duplicate stdout";
open ( STDOUT, "> $tempfile" ) || die "couldn't open tempfile to write";

$reporter->redirections($link);

close ( STDOUT ) || die "couldn't close tempfile";
open ( STDOUT, ">&SAVEOUT" ) || die "couldn't recover stdout";

open ( TEMPFILE, "< $tempfile" ) || die "couldn't open tempfile to read";
$found=0;
while (<TEMPFILE>) {
  $found=1 if m,http://www.whilgo.com/frood/,;
}
close ( TEMPFILE ) || die "couldn't close tempfile";

nogo unless $found;

ok(4);

