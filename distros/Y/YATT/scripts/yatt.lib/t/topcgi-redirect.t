#!/usr/bin/perl -w
# -*- mode: perl; coding: utf-8 -*-
use strict;
use warnings qw(FATAL all NONFATAL misc);

use FindBin;
use lib "$FindBin::Bin/..";

use YATT::Test;
use YATT::Util qw/default/;

unless (eval {require WWW::Mechanize}) {
  plan skip_all => 'WWW::Mechanized is not installed.'; exit;
}

my $mech = new WWW::Mechanize(agent => "YATT UnitTest by "
			      . (default($ENV{USER}, "(unknown user)")));

# XXX: Hard coded.
# /var/www/html/yatt/cgi-bin
# /var/www/html/yatt/test
unless (-e "/var/www/html/yatt/cgi-bin/yatt.cgi"
	and -d "/var/www/html/yatt/test") {
  plan skip_all => 'yatt.cgi and testapp is not installed.'; exit;
} elsif (not -d "/var/www/manual"
         or not $mech->get(my $man_url = "http://localhost/manual/")) {
  plan skip_all => "Can't get $man_url"; exit;
} else {
  plan qw(no_plan);
}

my $check = sub {
  my ($url, $is, $title) = @_;
  $title ||= $url;
  ok my $res = $mech->get($url)->is_success, "$title - fetch";
  SKIP: {
     skip "Can't fetch.", 1 unless $res;

     my $content = $mech->content;
     # To hide printenv.
     $content =~ s{<table[^>]*>.*</table>\s*}{}xs if $content;

     unless (ref $is) {
       is $content, $is, $title;
     } elsif (ref $is eq 'Regexp') {
       like $content, $is, $title;
     } else {
       die "Unknown";
     }
    }
};

{
  $check->("http://localhost/yatt/cgi-bin/yatt.cgi"
	   , "None of PATH_TRANSLATED and PATH_INFO is given.\n"
	   , "yatt.cgi returns default error message");
}

{
  $check->("http://localhost/yatt/test/y1hello.html"
	   , "<h2>Hello</h2>\nRedirected mode.\n"
	   , "hello");
}

{
  my $sub = sub {
    my ($str) = @_;
    <<END
<html>
  <head>
    <title>hoe<span style="color: red;">moe</span>moe</title>
  </head>
  <body>
    <h2>hoe<span style="color: red;">moe</span>moe</h2>
        <div>$str</div>

  </body>
</html>

END
  };

  $check->("http://localhost/yatt/test/y2.html"
	   , $sub->('')
	   , "y2, noparam");

  $check->("http://localhost/yatt/test/y2.html?foo=bar"
	   , $sub->('bar')
	   , "y2, foo=bar");
}

{
  $check->("http://localhost/yatt/test/y3pathinfo.html/.ht1.xhf"
	   , <<END, "y3, pathinfo");
  name = foo
  value = bar

  name = hoe
  value = moe


END
}
