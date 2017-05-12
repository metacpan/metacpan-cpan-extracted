#!/usr/bin/perl -w
use strict;
use FindBin;

use lib './inc';
use IO::Catch;
use vars qw( $_STDOUT_ $_STDERR_ );

# pre-5.8.0's warns aren't caught by a tied STDERR.
tie *STDOUT, 'IO::Catch', '_STDOUT_' or die $!;

# Disable all ReadLine functionality
$ENV{PERL_RL} = 0;

use Test::More tests => 6;
SKIP: {

use_ok('WWW::Mechanize::Shell');

eval { require HTTP::Daemon; };
skip "HTTP::Daemon required to test basic authentication",7
  if ($@);

# We want to be safe from non-resolving local host names
delete @ENV{qw(HTTP_PROXY http_proxy CGI_HTTP_PROXY)};

my $user = 'foo';
my $pass = 'bar';

# Now start a fake webserver, fork, and connect to ourselves
open SERVER, qq{"$^X" "$FindBin::Bin/401-server" $user $pass |}
  or die "Couldn't spawn fake server : $!";
sleep 1; # give the child some time
my $url = <SERVER>;
chomp $url;
die "Couldn't decipher host/port from '$url'"
    unless $url =~ m!^http://([^/]+)/!;
my $host = $1;

my $s = WWW::Mechanize::Shell->new( 'test', rcfile => undef, warnings => undef );

# First try with an inline username/password
my $pwd_url = $url;
$pwd_url =~ s!^http://!http://$user:$pass\@!;
$pwd_url .= 'thisshouldpass';
diag "get $pwd_url";
$s->cmd( "get $pwd_url" );
diag $s->agent->res->message
  unless is($s->agent->res->code, 200, "Request with inline credentials gives 200");
is($s->agent->content, "user = 'foo' pass = 'bar'", "Credentials are good");

# Now try without credentials
my $bare_url = $url . "thisshouldfail";
diag "get $bare_url";
$s->cmd( "get $bare_url" );

my $code = $s->agent->response->code;
my $got_url = $s->agent->uri;

if (! ok $code == 401 || $got_url ne $bare_url, "Request without credentials gives 401 (or is hidden by a WWW::Mechanize bug)") {
    diag "Page location : " . $s->agent->uri;
    diag $s->agent->res->as_string;
};

SKIP: {
if ($got_url ne $url) {
    skip "WWW::Mechanize 1.50 has a bug that doesn't give you a 401 page", 1;
} else {
    like($s->agent->content, '/^auth required /', "Content requests authentication")
        or diag $s->agent->res->as_string;
};
};

# Now try the shell command for authentication
$s->cmd( "auth foo bar" );

# WWW::Mechanize breaks the LWP::UserAgent API in a bad, bad way
# it even monkeypatches LWP::UserAgent so we have no better way
# than to hope for the best :-(((

# If it didn't return our expected credentials, we're a victim of
# WWW::Mechanize's monkeypatch :-(
my @credentials = $s->agent->get_basic_credentials();

if ($credentials[0] ne 'foo') {
    SKIP: { 
        skip "WWW::Mechanize $WWW::Mechanize::VERSION has buggy implementation/override of ->credentials", 1;
    };
} else {
    diag "Credentials are @credentials";
    use Data::Dumper;
    my $a = $s->agent;
    @credentials = $a->get_basic_credentials();
    diag "Credentials are @credentials";

    my @real_credentials = LWP::UserAgent::credentials($a,$host,'testing realm');
    SKIP: {
        if ($real_credentials[0] ne $credentials[0]) {
            skip "WWW::Mechanize credentials() patch breaks LWP::UserAgent credentials()", 1;
        } else {
            $s->cmd( "get $url" );
            diag $s->agent->res->message
                unless is($s->agent->res->code, 200, "Request with credentials gives 200");
            is($s->agent->content, "user = 'foo' pass = 'bar'", "Credentials are good");
        };
    };
};

diag "Shutting down test server at $url";
$s->agent->get("${url}exit"); # shut down server

};

END {
  close SERVER; # boom
};
