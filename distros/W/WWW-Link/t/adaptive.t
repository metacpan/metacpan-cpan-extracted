#!/usr/bin/perl -w

=head1 NAME

adaptive.t - test adaptive link tester

=head1 SYNOPSYS

tester.t

=head1 DESCRIPTION

similar to tester.t.  This tests the adaptive link tester to see that
it's features for handling tricky links work.

=cut

our $loaded;

BEGIN {print "1..3\n"}
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

sub new {
  my $class=shift;
  my $self=bless {}, $class;
  return $self;
}

sub is_protocol_supported { 1;}

sub simple_request {
  my $self=shift;
  my $request=shift;
  my $uri=$request->uri();
  my $uri_str=$uri->as_string;
  my $method=$request->method();
  my $response;
 CASE: foreach ($uri_str) {
    m,^http://www.headbad.com, && do {
      $method eq "HEAD" and do {
	$response=new HTTP::Response (RC_NOT_FOUND, "Broken HEAD response");
	print STDERR "returning broken for head response\n" if $::verbose;
	last;
      };
      $method eq "GET" and do {
	$response=new HTTP::Response (RC_OK, "Working GET response");
	print STDERR "returning working for get response\n" if $::verbose;
      };
      last;
      die "unkown method";
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
use vars qw($adaptivet);

our ($get_only_link, $ua);

$get_only_link = new WWW::Link "http://www.headbad.com";

$ua=new LWP::FakeAgent;

$adaptivet=new WWW::Link::Tester::Adaptive $ua;

$adaptivet->test_link($get_only_link);
nogo if ($get_only_link->is_okay());
ok(2);
for (my $i=1; $i < 20; $i++) {$adaptivet->test_link($get_only_link) };
nogo unless ($get_only_link->is_okay());
ok(3);
