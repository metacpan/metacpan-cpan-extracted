=head1 DESCRIPTION

there was a bug that we wouldn't apply complex tests in the case where
the protocol wasn't supported.  this tests that we do.

=cut

our ($loaded, $verbose);

$verbose = 0 unless defined $verbose;

BEGIN {print "1..2\n"}
END {print "not ok 1\n" unless $loaded;}

use warnings;
use strict;

sub nogo {print "not "}
sub ok {my $t=shift; print "ok $t\n";}

use HTTP::Response;
use WWW::Link;
use WWW::Link::Tester::Adaptive;
use Data::Dumper;

$loaded=1;

ok(1);

my $fake="this is not a user agent";
my $tester=new WWW::Link::Tester::Adaptive \$fake;

my $link = bless
  ( {
     'long_reliability' => '-0.4','testcount' => 10,
     'breakcount' => '20','check-method' => 2048,
     'last_fail' => 1008405256,'last_test' => 1008405256,
     'check-method-change-time' => 1006696655,
     'test_hist' =>
     [ [bless( {'_headers' => bless( {}, 'HTTP::Headers' ),
		'_rc' => 498, '_msg' => undef, '_content' => ''
	       }, 
	       'HTTP::Response' ),
	1010961252, 'WWW::Link::Tester::Adaptive',2]
     ],
     'status' => 14, 
     'test-cookie' => 
     bless( {'settings' => 0,'test_consistency' => []}
	    , 'WWW::Link::Tester::Adaptive::Cookie' ),
     'short_reliability' => '-0.8', 'url' => 'news:uk.rec.climbing',
     'status-change-time' => 1007534050,'last_refresh' => 1011162121}, 
    'WWW::Link' );

my $res = bless
  ( {'_headers' => bless( {}, 'HTTP::Headers' ),
     '_rc' => 498,'_msg' => undef,'_content' => ''},
    'HTTP::Response' );

print STDERR "before\n\n", Dumper($link) if $verbose;

$WWW::Link::Tester::Adaptive::Cookie::verbose=0xFFF if $verbose;
$tester->verbose(0xFFFF) if $verbose;

my $mode=2;
$tester->handle_response($link,$mode,$res);

print STDERR "after\n\n", Dumper($link) if $verbose;

$link->is_unsupported() or nogo;

ok(2);
