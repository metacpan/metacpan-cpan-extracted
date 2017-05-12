#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin . "/../lib";

use Test::More tests => 2;
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

my $review = WebService::ReviewBoard::ReviewRequest->new( 'http://demo.review-board.org' );
$review->login( 'jay', 'password' );
$review->create( repository_id => 1 );

$review->add_diff( $FindBin::Bin . "/files/foo.patch", '/trunk/reviewboard/' );
$review->set_description( "this is a description" );
$review->set_summary( "this is the summary" );

$review->set_bugs( 1728212, 1723823  );
$review->set_reviewers( qw( jaybuff ) );
$review->publish();

my $id = $review->get_id();
ok( $review->submit_review_request, "setting review to submit status");
ok( $review->discard_review_request, "discarding review");
