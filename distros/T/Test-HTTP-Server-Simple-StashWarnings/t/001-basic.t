#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 8;
use WWW::Mechanize;

my $url = My::Test::Server->new->started_ok("created test server");
ok($url, "got a url: $url");

my $mech = WWW::Mechanize->new;
$mech->get("$url/no_warnings");

$mech->get("/__test_warnings");
my @warnings = My::Test::Server->decode_warnings($mech->content);
is(@warnings, 0, "no warnings yet");

$mech->get("$url/warn");

$mech->get("$url/__test_warnings");
@warnings = My::Test::Server->decode_warnings($mech->content);
is(@warnings, 1, "got a warning!");
like($warnings[0], qr/^We're out of toilet paper sir!/);

$mech->get("$url/warn");
$mech->get("$url/warn");

$mech->get("$url/__test_warnings");
@warnings = My::Test::Server->decode_warnings($mech->content);
is(@warnings, 2, "got two warnings! warnings are cleared after fetching them");
like($warnings[0], qr/^We're out of toilet paper sir!/);
like($warnings[1], qr/^We're out of toilet paper sir!/);

BEGIN {
    package My::Test::Server;
    use base qw/Test::HTTP::Server::Simple::StashWarnings HTTP::Server::Simple::CGI/;

    sub handle_request {
        my $self = shift;
        my $cgi = shift;

        if ($cgi->path_info eq '/warn') {
            warn "We're out of toilet paper sir!";
        }
        print "Here's the content!";
    }

    sub test_warning_path { "/__test_warnings" }
}

