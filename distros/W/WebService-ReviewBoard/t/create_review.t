#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin . "/../lib";

use Test::More tests => 11;
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

use WebService::ReviewBoard;

ok( my $rb = WebService::ReviewBoard->new( 'http://demo.review-board.org' ), "created new WebService::ReviewBoard object" );
ok( $rb->login( 'jay', 'password' ), 'logged in' );
ok( my $review = WebService::ReviewBoard::Review->create( { review_board => $rb }, [ repository_id => 1 ] ), "created review");


ok( $review->get_id() =~ /^\d+$/, "review has an id that is a number" );

ok( $review->add_diff( $FindBin::Bin . "/files/foo.patch", '/trunk/reviewboard/' ), "adding a new diff" );

ok( $review->set_description( "this is a description" ), "setting the description" );
ok( $review->set_summary( "this is the summary" ), "set the description" );

ok( $review->set_bugs( 1728212, 1723823  ), "setting bugs");
ok( $review->set_reviewers( qw( jaybuff ) ), "setting reviewers");
ok( $review->set_groups( qw(reviewboard) ), "setting groups");
ok( $review->publish(), "publish" );

$review->discard_review_request;

