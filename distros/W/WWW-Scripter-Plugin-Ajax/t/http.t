#!perl

# This script checks to see whether the plugin is compatible with
# LWP/Protocol/http.pm. Since it is hard to fake multiple addresses with a
# real test server, test.t implements a fake ‘protocol’, but that means it
# bypasses http.pm, which hid the bug that this script tests for.

use File'Basename;
use File'Spec'Functions 'catfile';
use WWW::Scripter;
use WWW::Scripter::Plugin::JavaScript 0.002; # new init interface

use Test'More;

my $m = new WWW::Scripter;
$m->use_plugin('Ajax'); # Load this before starting the server, in
                        # case it dies.

eval {open $server, '-|', $^X, catfile dirname($0), 'http-test-server'}
 or ++$skip;
chomp($port = <$server>);
$port or ++$skip;

plan $skip ? skip_all :( tests => 1 );

# Lie to WWW::Scripter about what the current URL is, in order to bypass
# the domain-checking
$m->add_handler(
 response_done => sub {
  shift->request->uri("http://localhost:$port/");
  $m->remove_handler(undef, owner => "Jim");
  ()
 },
 owner => "Jim"
);
$m->get("data:text/html,");

is $m->eval('
 with(new XMLHttpRequest)
  open("POST", "mext", false),
  send("ked"),
  responseText
'), 'lext', "posting data via LWP/Protocol/http.pm works";
            # It didn’t in 0.03 and earlier.

# In case the test failed such that the request was not sent, send an
# extra one to make sure the server is dead.
$m->timeout(1);
$m->get("http://localhost:$port/");
