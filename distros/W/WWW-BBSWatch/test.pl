use strict;

BEGIN {
  $| = 1;
  use vars qw/$loaded/;
  $loaded = 0;
  print "Running tests 1..2\n";
}

END {
  print "not ok 1\n" unless $loaded;
}

use WWW::BBSWatch;
$main::loaded = 1;
print "ok 1\n";

# The main interesting thing to test isn't even BBSWatch-specific. We just need
# to see if we can get to the internet.
my $ua = LWP::UserAgent->new;
$ua->env_proxy;
my $res = $ua->request(HTTP::Request->new('GET', "http://www.perl.org"));
if ($res->is_error) {
  print STDERR $res->error_as_HTML, "\n";
  print "not ok 2\n";
} else {
  print "ok 2\n";
}

