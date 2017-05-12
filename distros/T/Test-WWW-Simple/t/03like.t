use Test::Tester;
use Test::More tests =>16;
use Test::WWW::Simple;
use WWW::Mechanize;


# Skip 'not-found' tests if DNSAdvantage is 'helping'. :P
my $ua = LWP::UserAgent->new;
$ua->agent("MyApp/0.1 ");

# Create a request
my $req = HTTP::Request->new(POST => 'http://nfrenjfirefreknfjnr.com/no-exist.
html');
$req->content_type('application/x-www-form-urlencoded');
$req->content('query=libwww-perl&mode=dist');

# Pass request to the user agent and get a response back
my $res = $ua->request($req);

# Check the outcome of the response
my $dns_disadvantage = ($res->code != 404);
  

my ($message1, $message2, $message3);
my @results;

# look for perl on perl.org - should succeed
@results = run_tests(
    sub {
          page_like('http://perl.org', qr/The Perl Programming Language - www.perl.org/, "page match")
    }
  );
ok($results[1]->{ok}, 'page_like ok as expected');
is($results[1]->{diag}, '', 'no diagnostic');

# 2. Page not like the regex
$message3 = qr|doesn't match '\(\?.*?Perl\)'|;

@results = run_tests(
    sub {
        page_like('http://python.org', qr/Perl/, "Perl found on python.org")
    },
  );
like($results[1]->{diag}, qr/$message3/sm, 'message about right');
ok(!$results[1]->{ok}, 'failed as expected');

# 3. invalid server
SKIP: {
  skip "DNSAdvantage causes non-existent server tests to fail",2
    if $dns_disadvantage;

@results = run_tests(
    sub {
        page_like("http://switch-to-python.perl.org", 
                  qr/text not there/,
                  "this server doesn't exist")
    },
  );
is($results[1]->{diag}, '', "match skipped");
ok(!$results[1]->{ok}, 'failed as expected');
}

# 4. bad page
@results = run_tests(
    sub {
        page_like("http://perl.org/gack", 
                  qr/text not there/,
                  "this server doesn't exist")
    },
    {
      ok => 0 # no such page should be a failure
    }
  );
is($results[1]->{diag}, '', "match skipped");
ok(!$results[1]->{ok}, "failed as expected");

# look for perl on perl.org - should succeed
@results = run_tests(
    sub {
          page_like_full('http://perl.org', qr/The Perl Programming Language at Perl.org./, "page match")
    }
  );
ok($results[1]->{ok}, 'page_like ok as expected');
is($results[1]->{diag}, '', 'no diagnostic');

# 2. Page not like the regex
$message3 = qr|doesn't match '\(\?.*?Perl\)'$|;

@results = run_tests(
    sub {
        page_like_full('http://python.org', qr/Perl/, "Perl found on python.org")
    },
  );
like($results[1]->{diag}, qr/$message3/sm, 'message about right');
ok(!$results[1]->{ok}, 'failed as expected');

# 3. invalid server
SKIP: {
  skip "DNSAdvantage causes nonexistent server tests to fail", 2
    if $dns_disadvantage;
@results = run_tests(
    sub {
        page_like_full("http://switch-to-python.perl.org",
                  qr/text not there/,
                  "this server doesn't exist")
    },
  );
is($results[1]->{diag}, '', "match skipped");
ok(!$results[1]->{ok}, 'failed as expected');
}


# 4. bad page
@results = run_tests(
    sub {
        page_like_full("http://perl.org/gack",
                  qr/text not there/,
                  "this server doesn't exist")
    },
    {
      ok => 0 # no such page should be a failure
    }
  );
is($results[1]->{diag}, '', "match skipped");
ok(!$results[1]->{ok}, "failed as expected");

