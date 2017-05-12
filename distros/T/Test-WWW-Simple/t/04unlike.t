use Test::Tester tests=>8;
use Test::WWW::Simple;
use Test::More;
use WWW::Mechanize;

# Skip 'not-found' tests if DNSAdvantage is 'helping'. :P
my $mech = WWW::Mechanize->new( autocheck => 0 );
$mech->get('http://completely-bogus-fehferuin-doesnt-exist.me');
my $dns_disadvantage =
  $mech->success and $mech->content =~ /search.dnsadvantage.com/ms;

my $message;
my @results;

@results = run_tests(
    sub { page_unlike('http://use.perl.org', qr/The Perl Directory/, "page match") },
    {
      ok => 0, # we expect the test to fail
      name => "page match",
    },
    "page really is like regex"
  );
ok($results[1]->{ok}, "succeeded as it should");
is($results[1]->{diag}, '', 'diagnostic ok');

# 2. Page not like the regex
@results = run_tests(
    sub { page_unlike('http://python.org', qr/Perl/, "Perl not found on python.org") },
    {
      ok => 1,
      name => 'Perl not found on python.org',
      diag => "",
    },
    "page not like regex"
  );
ok($results[1]->{ok}, "success as expected");
ok(!$results[1]->{diag}, "no diagnostic as expected");

SKIP: {
    skip "DNSAdvantage messes up nonexistent server tests", 2
      if $dns_disadvantage;
@results= run_tests(
    sub { page_unlike("http://totally.nonexistent.gorkelplatz.freen", 
                      qr/text not there/,
                      "this server doesn't exist") },
    {
      ok => 0,
      name => "this server doesn't exist",
      diag => $message,
    },
    "no such server"
  );

ok(!$results[1]->{ok}, "failed as expected");
ok(!$results[1]->{diag}, "no diagnostic as expected");
}

$message = <<EOF;
         got: ""
      length: 0
    doesn't match '(?-xism:text not there)'
EOF
@results= run_tests(
    sub { page_unlike("http://perl.org/gack", 
                      qr/text not there/,
                      "this page doesn't exist") },
    {
      ok => 0,
      name => "this page doesn't exist",
      diag => $message,
    },
    "no such server"
  );
ok(!$results[1]->{ok}, "failed as expected");
ok(!$results[1]->{diag}, "no diagnostic as expected");
