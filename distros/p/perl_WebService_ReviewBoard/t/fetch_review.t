#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin . "/../lib";

use Test::More tests => 10;
use Test::Exception;

# this requires that demo.review-board.org is set up properly:
# the t/files/foo.patch is against the reviewboard svn itself, so
# repository_id 1 point to the reviewboard svn repo.
#
# the user jay must exist with a password of 'password'
# the user jaybuff must exist and be able to review the patch jay uploads

# uncomment to debug tests
#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

use WebService::ReviewBoard::ReviewRequest;
my $rr = WebService::ReviewBoard::ReviewRequest->new('http://demo.review-board.org');
$rr->login( 'jay', 'password' );

# create a review that we can fetch
my $review_args = {
	description => "this is a description",
	summary     => "this is the summary",
	bugs        => [ 1728212, 1723823 ],
	groups      => ['reviewboard'],
	reviewers   => ['jaybuff'],
};

# avoid creating a bunch of fake reviewrequests... just use one we know
my $id = 876;

#	$rr>create(  repository_id => 1 );
#	$rr->set_description( $review_args->{description} );
#	$rr->set_summary( $review_args->{summary} );
#	$rr->set_bugs( @{ $review_args->{bugs} } );
#	$rr->set_reviewers( @{ $review_args->{reviewers} } );
#   $rr->set_groups( $review_args->{groups} );
#	$rr->add_diff( $FindBin::Bin . "/files/foo.patch", '/trunk/reviewboard/' );
#	$rr->publish();
#	$id = $rr->get_id();

# now fetch that id
ok( $rr->fetch( $id ), "fetching review request $id");

is( $rr->get_id(), $id, "id was set" );
is_deeply( $rr->get_bugs(),      $review_args->{bugs},      "bugs was set" );
is_deeply( $rr->get_reviewers(), $review_args->{reviewers}, "reviewers was set" );
is( $rr->get_summary(),     $review_args->{summary},     "summary was set" );
is( $rr->get_description(), $review_args->{description}, "description was set" );
is_deeply( $rr->get_groups(), $review_args->{groups}, "groups was set" );

ok(
	my @rrs = $rr->fetch_all_from_user( 'jay'),
	"fetching all review requests from user jay"
);

# there are a bunch of these already in that database
ok( scalar @rrs > 5, "fetch from_user returned more than 5 review requests" );
is( ref( $rrs[0] ), 'WebService::ReviewBoard::ReviewRequest', "returned objects are of correct class" );
