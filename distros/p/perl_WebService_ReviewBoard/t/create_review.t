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

use WebService::ReviewBoard::ReviewRequest;

ok( my $rr = WebService::ReviewBoard::ReviewRequest->new( 'http://demo.review-board.org' ), "created new object" );
ok( $rr->login( 'jay', 'password' ), 'logged in' );
ok( $rr->create( repository_id => 1 ), "created review");


ok( $rr->get_id() =~ /^\d+$/, "review has an id that is a number" );

ok( $rr->add_diff( $FindBin::Bin . "/files/foo.patch", '/trunk/reviewboard/' ), "adding a new diff" );

ok( $rr->set_description( "this is a description" ), "setting the description" );
ok( $rr->set_summary( "this is the summary" ), "set the description" );

ok( $rr->set_bugs( 1728212, 1723823  ), "setting bugs");
ok( $rr->set_reviewers( qw( jaybuff ) ), "setting reviewers");
ok( $rr->set_groups( qw(reviewboard) ), "setting groups");
ok( $rr->publish(), "publish" );

$rr->discard_review_request;

