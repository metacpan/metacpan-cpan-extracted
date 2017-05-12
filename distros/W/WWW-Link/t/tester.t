#!/usr/bin/perl -w

=head1 NAME

tester - test the testers

=head1 SYNOPSYS

tester.t

=head1 DESCRIPTION

In order to test the testers, we write our own fake user agent..

=cut

our $loaded;

BEGIN {print "1..66\n"}
END {print "not ok 1\n" unless $loaded;}

use warnings;
use strict;

sub nogo {print "not "}
sub ok {my $t=shift; print "ok $t\n";}

package LWP::FakeAgent;
use HTTP::Request;
use HTTP::Response;
use HTTP::Status;
use WWW::Link::Tester; #import response codes to this package
use Carp;

sub new {
  my $class=shift;
  my $self=bless {}, $class;
  return $self;
}

sub is_protocol_supported { 
    my($self, $scheme) = @_;
    if (ref $scheme) {
	# assume we got a reference to an URI object
	$scheme = $scheme->scheme;
    } else {
	Carp::croak("Illegal scheme '$scheme' passed to is_protocol_supported")
	    if $scheme =~ /\W/;
	$scheme = lc $scheme;
    }
    return 1 if $scheme =~ m/^http$/;
    return 0;
}

sub simple_request {
  my $self=shift;
  my $request=shift;
  my $uri=$request->uri();
  my $uri_str=$uri->as_string;
  my $response;
 CASE: foreach ($uri_str) {
    m,^http://www.broken.com, && do {
      $response=new HTTP::Response (RC_NOT_FOUND, "Simulated broken page");
      last;
    };
    m,^http://www.okay.com, && do {
      $response=new HTTP::Response (RC_OK, "Simulated working page");
      last;
    };
    m,^http://www.redirected.com, && do {
      $response=new HTTP::Response (RC_TEMPORARY_REDIRECT,
			"Simulated redirect");
      $response->push_header( Location => 'http://www.target.com/hi.there' );
      last;
    };
    m,^http://www.target.com/hi.there, && do {
      $response=new HTTP::Response (RC_OK, "Simulated working page");
      last;
    };
    m,^http://www.indefinite.com, && do {
      $response=new HTTP::Response (RC_TEMPORARY_REDIRECT,
				    "Simulated redirect");
      m,^http://www.indefinite.com.*[^/]$, and $uri_str .= '/';
      $response->push_header( Location => $uri_str . 'l/' );
      last;
    };
    m,^http://www.paranoid.com, && do {
      $response=new HTTP::Response (RC_FORBIDDEN,
				    "Simulated robots.txt exclusion");
      last;
    };
    m,^whoop:wozzisprogogogl, && do {
	die "unsupported protocol allowed through to testing";
      $response=new HTTP::Response (RC_PROTOCOL_UNSUPPORTED,
				    "Simulated unsupported protocol");
      last;
    };
    die "unknown request $_";
  }
  return $response;
}

package main;

use WWW::Link;
use WWW::Link::Tester;
use WWW::Link::Tester::Adaptive;
use WWW::Link::Tester::Simple;
use WWW::Link::Tester::Complex;
ok(1);
$loaded=1;
use vars qw($simplet $complext $adaptivet);

our ($working_link,  $broken_link,  $redirected_link, $infinite_link,
     $robot_blocked_link, $unsupported_link, $mailto_link, $news_link,
     $ua);

$working_link = new WWW::Link "http://www.okay.com";
$broken_link = new WWW::Link "http://www.broken.com";
$redirected_link=new WWW::Link "http://www.redirected.com";
$infinite_link=new WWW::Link "http://www.indefinite.com";
$robot_blocked_link=new WWW::Link "http://www.paranoid.com/deepwithin.html";
$unsupported_link=new WWW::Link "whoop:wozzisprogogoglisnoideawozzoever";
$mailto_link=new WWW::Link "mailto:test\@example.com";
$news_link=new WWW::Link "news:uk.rec.climbing";

$ua=new LWP::FakeAgent;

$simplet=new WWW::Link::Tester::Simple $ua;
$simplet->verbose(0xFFF) if $::verbose;

$simplet->test_link($working_link);
ok(2);
nogo unless ($working_link->is_okay());
ok(3);
$simplet->test_link($broken_link);
nogo if ($broken_link->is_okay());
ok(4);
$simplet->test_link($redirected_link);
ok(5);
nogo unless ($redirected_link->is_okay());
ok(6);
nogo unless ($redirected_link->is_redirected());
ok(7);
$simplet->test_link($infinite_link);
nogo if ($infinite_link->is_okay());
ok(8);
$simplet->test_link($unsupported_link);
nogo unless ($unsupported_link->is_unsupported());
ok(9);
nogo if ($unsupported_link->is_okay());
ok(10);
nogo if ($unsupported_link->is_broken());
ok(11);
$simplet->test_link($robot_blocked_link);
nogo unless ($robot_blocked_link->is_disallowed());
ok(12);
nogo if ($robot_blocked_link->is_okay());
ok(13);
nogo if ($robot_blocked_link->is_broken());
ok(14);
$simplet->test_link($mailto_link);
ok(15);
nogo unless ($mailto_link->is_unsupported());
ok(16);
nogo if ($mailto_link->is_broken());
ok(17);
nogo if ($mailto_link->is_okay());
ok(18);
$simplet->test_link($news_link);
ok(19);
nogo unless ($news_link->is_unsupported());
ok(20);
nogo if ($news_link->is_broken());
ok(21);
nogo if ($news_link->is_okay());
ok(22);

$working_link = new WWW::Link "http://www.okay.com";
$broken_link = new WWW::Link "http://www.broken.com";
$redirected_link=new WWW::Link "http://www.redirected.com";
$infinite_link=new WWW::Link "http://www.indefinite.com";
$robot_blocked_link=new WWW::Link "http://www.paranoid.com/deep/within.html";
$unsupported_link=new WWW::Link "whoop:wozzisprogogoglisnoideawozzoever";
$mailto_link=new WWW::Link "mailto:test\@example.com";
$news_link=new WWW::Link "news:uk.rec.climbing";

$complext=new WWW::Link::Tester::Complex $ua;
$complext->verbose(0xFFF) if $::verbose;

$complext->test_link($working_link);
ok(23);
nogo unless ($working_link->is_okay());
ok(24);
$complext->test_link($broken_link);
nogo if ($broken_link->is_okay());
ok(25);
$complext->test_link($redirected_link);
ok(26);
nogo unless ($redirected_link->is_okay());
ok(27);
nogo unless ($redirected_link->is_redirected());
ok(28);
$complext->test_link($infinite_link);
nogo if ($infinite_link->is_okay());
ok(29);
nogo if ($infinite_link->is_okay());
ok(30);
$complext->test_link($unsupported_link);
nogo unless ($unsupported_link->is_unsupported());
ok(31);
nogo if ($unsupported_link->is_okay());
ok(32);
nogo if ($unsupported_link->is_broken());
ok(33);
$complext->test_link($robot_blocked_link);
nogo unless ($robot_blocked_link->is_disallowed());
ok(34);
nogo if ($robot_blocked_link->is_okay());
ok(35);
nogo if ($robot_blocked_link->is_broken());
ok(36);
$complext->test_link($mailto_link);
ok(37);
nogo unless ($mailto_link->is_unsupported());
ok(38);
nogo if ($mailto_link->is_broken());
ok(39);
nogo if ($mailto_link->is_okay());
ok(40);
$complext->test_link($news_link);
ok(41);
nogo unless ($news_link->is_unsupported());
ok(42);
nogo if ($news_link->is_broken());
ok(43);
nogo if ($news_link->is_okay());
ok(44);

$working_link = new WWW::Link "http://www.okay.com";
$broken_link = new WWW::Link "http://www.broken.com";
$redirected_link=new WWW::Link "http://www.redirected.com";
$infinite_link=new WWW::Link "http://www.indefinite.com";
$robot_blocked_link=new WWW::Link "http://www.paranoid.com/deep/within.html";
$unsupported_link=new WWW::Link "whoop:wozzisprogogoglisnoideawozzoever";
$mailto_link=new WWW::Link "mailto:test\@example.com";
$news_link=new WWW::Link "news:uk.rec.climbing";

$adaptivet=new WWW::Link::Tester::Adaptive $ua;
$adaptivet->verbose(0xFFF) if $::verbose;

$adaptivet->test_link($working_link);
ok(45);
nogo unless ($working_link->is_okay());
ok(46);
$adaptivet->test_link($broken_link);
nogo if ($broken_link->is_okay());
ok(47);
$adaptivet->test_link($redirected_link);
ok(48);
nogo unless ($redirected_link->is_okay());
ok(49);
nogo unless ($redirected_link->is_redirected());
ok(50);
$adaptivet->test_link($infinite_link);
nogo if ($infinite_link->is_okay());
ok(51);
nogo if ($infinite_link->is_okay());
ok(52);
$adaptivet->test_link($unsupported_link);
nogo unless ($unsupported_link->is_unsupported());
ok(53);
nogo if ($unsupported_link->is_okay());
ok(54);
nogo if ($unsupported_link->is_broken());
ok(55);
$adaptivet->test_link($robot_blocked_link);
nogo unless ($robot_blocked_link->is_disallowed());
ok(56);
nogo if ($robot_blocked_link->is_okay());
ok(57);
nogo if ($robot_blocked_link->is_broken());
ok(58);
$adaptivet->test_link($mailto_link);
ok(59);
nogo unless ($mailto_link->is_unsupported());
ok(60);
nogo if ($mailto_link->is_broken());
ok(61);
nogo if ($mailto_link->is_okay());
ok(62);
$adaptivet->test_link($news_link);
ok(63);
nogo unless ($news_link->is_unsupported());
ok(64);
nogo if ($news_link->is_broken());
ok(65);
nogo if ($news_link->is_okay());
ok(66);

