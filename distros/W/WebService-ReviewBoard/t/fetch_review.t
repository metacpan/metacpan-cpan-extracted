#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin . "/../lib";

use Test::More tests => 9;
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
my $rb = WebService::ReviewBoard->new('http://demo.review-board.org');
$rb->login( 'jay', 'password' );

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

#{
#	my $review
#	  = WebService::ReviewBoard::Review->create( { review_board => $rb }, [ repository_id => 1 ] );
#	$review->set_description( $review_args->{description} );
#	$review->set_summary( $review_args->{summary} );
#	$review->set_bugs( @{ $review_args->{bugs} } );
#	$review->set_reviewers( @{ $review_args->{reviewers} } );
#       $review->set_groups( $review_args->{groups} );
#	$review->add_diff( $FindBin::Bin . "/files/foo.patch", '/trunk/reviewboard/' );
#	$review->publish();
#	$id = $review->get_id();
#}

# now fetch that id
ok(
	my $review = WebService::ReviewBoard::Review->fetch(
		{
			review_board => $rb,
			id           => $id,
		}
	),
	"fetching review request $id"
);

is( $review->get_id(), $id, "id was set" );
is_deeply( $review->get_bugs(),      $review_args->{bugs},      "bugs was set" );
is_deeply( $review->get_reviewers(), $review_args->{reviewers}, "reviewers was set" );
is( $review->get_summary(),     $review_args->{summary},     "summary was set" );
is( $review->get_description(), $review_args->{description}, "description was set" );
is_deeply( $review->get_groups(), $review_args->{groups}, "groups was set" );

ok(
	my @reviews = WebService::ReviewBoard::Review->fetch(
		{
			review_board => $rb,
			from_user    => 'jay',
		}
	),
	"fetching all review requests from user jay"
);

# there are a bunch of these already in that database
ok( scalar @reviews > 5, "fetch from_user returned more than 5 review requests");
