use strict;
BEGIN { 
  unshift @INC, './t';
}

my $localdaemon_ok;

BEGIN { 
  eval "use HTTP::Daemon";
  $localdaemon_ok = !$@;

  eval "use CGI";
  $localdaemon_ok &&= !$@;
}

use Test::Tester;
use Test::More tests =>11;
use Test::WWW::Simple;
use LocalServer;
use WWW::Mechanize;

# Skip 'not-found' tests if DNSAdvantage is 'helping'. :P
my $mech = WWW::Mechanize->new( autocheck => 0 );
$mech->get('http://completely-bogus-fehferuin-doesnt-exist.me');
my $dns_disadvantage =
  $mech->success and $mech->content =~ /search.dnsadvantage.com/ms;

my ($message1, $message2, $message3);
my @results;

my $html = <<HTML;
<html>
<head><title>%s</title></head>
<body>
Wha<i>t</i>ev<blink>e</blink><b>r</b>.
</body>
</html>
HTML

SKIP: {
  skip "Can't run local daemon",5 if ! $localdaemon_ok or $^O eq 'MSWin32';

  my $server = LocalServer->spawn( html => $html );
  isa_ok( $server, "LocalServer" );

  # look for perl on perl.org - should succeed
  @results = run_tests(
      sub {
            text_like($server->url(), qr/Whatever/, "clean text match")
      }
    );
  ok($results[1]->{ok}, 'text_like ok as expected');
  is($results[1]->{diag}, '', 'no diagnostic');

  # 2. Page not like the regex
  $message1 = qr|\s+got: "/ Whatever. "\n|;
  $message2 = qr|\s+length: \d+\n|;
  $message3 = qr|\s+doesn't match .*?Definite|;

  @results = run_tests(
      sub {
          text_like($server->url(), qr/Definite/, "Looking for text not there");
      },
    );
  like($results[1]->{diag}, qr/$message1/, 'message about right');
  like($results[1]->{diag}, qr/$message2/, 'message about right');
  like($results[1]->{diag}, qr/$message3/, 'message about right');
  ok(!$results[1]->{ok}, 'failed as expected');
}


# 3. invalid server
SKIP: {
  skip "DNSAdvantage messes up nonexistent server tests", 2 
    if $dns_disadvantage;
@results = run_tests(
    sub {
        text_like("http://switch-to-python.perl.org", 
                  qr/500 Can't connect to switch-to-python.perl.org:80 /,
                  "this server doesn't exist")
    },
  );
is($results[1]->{diag}, '', "no diag to match");
ok(!$results[1]->{ok}, 'worked as expected');
}


# 4. bad page
@results = run_tests(
    sub {
        text_like("http://perl.org/gack", 
                  qr/Error 404 - Error 404404 - File not foundSorry, we/,
                  "this page doesn't exist")
    },
    {
      ok => 0 # no such page should be a failure
    }
  );
is($results[1]->{diag}, '', "No diag to match");
ok(!$results[1]->{ok}, "worked as expected");
