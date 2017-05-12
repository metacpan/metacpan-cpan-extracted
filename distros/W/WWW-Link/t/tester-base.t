#!/usr/bin/perl -w

=head1 NAME

tester-base - test functions inside Tester.pm

=head1 SYNOPSYS

tester.t

=head1 DESCRIPTION

Test some of the base functions inside tester.

=cut

our $loaded;
our $i;
our $now=time;

BEGIN {print "1..24\n"}
END {print "not ok 1\n" unless $loaded;}

sub nogo {print "not "}
sub ok {my $t=shift; print "ok $t\n";}

use warnings;
use strict;
use HTTP::Response;
use WWW::Link;
use WWW::Link::Tester;

ok(1);
$loaded=1;

my $tester_unsupported=
  bless( {
	   '_headers' => bless( {}, 'HTTP::Headers' ),
	   '_msg' => undef,
	   '_rc' => 498,
	   '_content' => ''
	 }, 'HTTP::Response' ) ;

my $library_unsupported=
  bless
  ( { '_request' => 
     bless
      ( {
	 '_method' => 'HEAD', '_headers' => 
	 bless( { 'user-agent' => 'LinkController/0.023',
		  'from' => 'mikedlr@scotclimb.org.uk'
		}, 'HTTP::Headers' ),
	 '_uri' => 
	 bless( [
		 bless( do{\(my $o = 'mailto:climbing-archive@ed.ac.uk')}, 'URI::mailto' ),
		undef
	      ], 'URI::URL' ),
	'_content' => ''
     }, 'HTTP::Request' ),
    '_headers' => 
    bless
    ( { 'client-date' => 'Thu, 15 Nov 2001 19:34:02 GMT'
      }, 'HTTP::Headers' ),
    '_msg' => 'Library does not allow method HEAD for \'mailto:\' URLs',
    '_rc' => 400,  '_content' => ''
 }, 'HTTP::Response' );


ok(2);
my $link;
my $tester=WWW::Link::Tester->new();
$link = new WWW::Link "http://www.example.com";
ok(3);
$tester->apply_response($link,$tester_unsupported);
ok(4);
nogo unless $link->is_unsupported();
ok(5);
nogo if $link->is_broken();
ok(6);
nogo if $link->is_okay();
ok(7);
nogo unless $link->time_want_test > $now;
ok(8);

$link = new WWW::Link "http://www.example.com";
ok(9);
$tester->apply_response($link,$tester_unsupported);
ok(10);
nogo unless $link->is_unsupported();
ok(11);
nogo if $link->is_broken();
ok(12);
nogo if $link->is_okay();
ok(13);
nogo unless $link->time_want_test > $now;
ok(14);

$link = new WWW::Link "http://www.example.com";
$link->passed_test;
ok(15);
$tester->apply_response($link,$tester_unsupported);
ok(16);
nogo unless $link->is_unsupported();
ok(17);
nogo if $link->is_broken();
ok(18);
nogo if $link->is_okay();
ok(19);

$link = new WWW::Link "http://www.example.com";
$i=10;
$link->failed_test while $i--;
ok(20);
$tester->apply_response($link,$tester_unsupported);
ok(21);
nogo unless $link->is_unsupported();
ok(22);
nogo if $link->is_broken();
ok(23);
nogo if $link->is_okay();
ok(24);

