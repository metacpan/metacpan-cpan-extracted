#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/./lib";
use lib "$FindBin::Bin/../lib";

=head1 DESCRIPTION

I split these into a separate class because they require Jobs that are in
a particular status to run.

If you run the test as usual, mock Jobs will be injected for you
into the mock LWP::UserAgent and the tests will run against those.

However, if you want to run these tests against the sanbox, the test will detect
the '--live 1' flag, create some dummy Jobs in your sandbox, and ask you to
modify them through the sandbox website before continuing, as in the L<SYNOPSIS>.

=head1 SYNOPSIS

    bash> perl -I t/lib -I lib t/031-jobs-with-specific-status.t --live 1
    ...
    Submitting test Jobs to the sandbox...
    ...
    6 dummy Jobs have been created in your sandbox:
    Set them all to 'reviewable' status and run the test again with
    the "--live 2" flag to execute the real tests.
    bash>

=cut

use WebService::MyGengo::Test::Util::Client;
use WebService::MyGengo::Test::Util::Job;

use Getopt::Long;
use Test::More;

use Data::Dumper;

BEGIN {
    use_ok 'WebService::MyGengo::Base';
    use_ok 'WebService::MyGengo::Client';
    use_ok 'WebService::MyGengo::Job';
    use_ok 'WebService::MyGengo::Revision';
}

# CLI options
my $DEBUG   = undef;
my $FILTER  = undef;
my $LIVE    = 0;
GetOptions(
    'debug'         => \$DEBUG
    , 'filter=s'    => \$FILTER
    , 'live:i'      => \$LIVE
    );
$LIVE and $ENV{WS_MYGENGO_USE_SANDBOX} = 1;
sub is_mock { !$LIVE };

my $tests = [
    'get_multiple_jobs_no_revisions_without_revisions_flag'
    , 'get_multiple_jobs_has_revisions_with_revisions_flag'
# TODO Disabling these due to API issues on the sandbox
#    , 'can_request_job_revisions'
#    , 'job_revisions_add_comment'
#    , 'can_approve_jobs'
#    , 'approve_jobs_adds_feedback'
#    , 'can_reject_jobs'
#    , 'reject_jobs_adds_comment'
    ];

my $client = client();
if ( $DEBUG ) {
    $client->DEBUG(1);
    is_mock() and $client->_user_agent->DEBUG(1);
}
my @_dummies;

run_tests();
done_testing();
teardown();

################################################################################
sub run_tests {
    _setup();
    foreach ( @$tests ) {
        next if $FILTER && $_ !~ /.*$FILTER.*/;
        $DEBUG and diag "##### Start test: $_";
        no strict 'refs';
        eval { &$_() };
        $@ and fail("Error in test $_: ".Dumper($@));
        $DEBUG and diag "##### End   test: $_";
    }
}

sub teardown {
    $DEBUG and print STDERR "TEARDOWN\n";
    foreach ( @_dummies ) {
        !$_->is_available and next;
        $client->delete_job( $_ ) or
            diag "Error deleting Job ".$_->id . ": "
                    . Dumper($client->last_response);
    }
}

################################################################################
sub _setup {
    if ( $LIVE == 1 ) {
        print STDERR "Submitting test Jobs to the sandbox...\n";
        for ( 0 .. 13 ) {
            create_dummy_job( $client )
                or die "Error creating Job: ".$client->last_response->message;
        }
        print STDERR<<EOT;
14 dummy Jobs have been created in your sandbox:
Set them all to 'reviewable' status and run the test again with
the "--live 2" flag to execute the real tests.
EOT
        done_testing();
        exit 0;
    }
}

sub _get_approved_jobs {
    my ( $count ) = ( shift );

    # If we're using the mock LWP we can fake an approved Job
    if ( is_mock ) {
        my $hash = _dummy_job_struct;
        $hash->{status} = 'approved';
        $client->_user_agent->add_job( $hash )
            for ( 1 .. $count );
    }
    else {
        my $jobs    = $client->search_jobs( 'reviewable', undef, $count );
        my $com     = "You are a champion.";
        $client->approve_job( $_, 5.0, $com, rand(), 1 )
            foreach @$jobs;
    }

    my $jobs = $client->search_jobs( 'approved', undef, $count );
    push @_dummies, $_ foreach @$jobs;
    return $jobs;
}

sub _get_reviewable_jobs {
    my ( $count ) = ( shift );

    # If we're using the mock LWP we can fake an approved Job
    if ( is_mock ) {
        my $hash = _dummy_job_struct;
        $hash->{status} = 'reviewable';
        $client->_user_agent->add_job( $hash )
            for ( 1 .. $count );
    }

    my $jobs = $client->search_jobs( 'reviewable', undef, $count );
    push @_dummies, $_ foreach @$jobs;
    return $jobs;
}

sub get_multiple_jobs_no_revisions_without_revisions_flag {
    my $jobs1 = _get_approved_jobs( 2 );

    $#$jobs1 < 1 and die "No 'approved' Jobs found!";

    my $jobs2 = $client->get_jobs( map { $_->id } @$jobs1 );

    foreach my $job ( @$jobs2 ) {
        ok( !$job->has_feedback, "Job doesnt have feedback" )
            or diag explain $job;
    }
}

sub get_multiple_jobs_has_revisions_with_revisions_flag {
    my $jobs1 = _get_approved_jobs( 2 );

    $#$jobs1 < 1 and die "No 'approved' Jobs found!";

    my $jobs2 = $client->get_jobs( [map { $_->id } @$jobs1], 0, 1, 0 );

    foreach my $job ( @$jobs2 ) {
        ok( $job->fetched_revisions, "Fetched revisions" );
        ok( $job->has_revisions, "Has revisions" );
    }
}

sub can_request_job_revisions {
    TODO: {
    local $TODO = "Issues with PUT /translate/jobs on sandbox.";
    my $jobs1 = _get_reviewable_jobs( 2 );

    $#$jobs1 < 1 and die "No 'reviewable' Jobs found!";

    !scalar($jobs1) and die "No 'reviewable' Jobs found!";

    # Revise the Job
    my $com = "You are a champion.";
    my $status = 'revising';
    my $jobs2 = $client->request_job_revisions( $jobs1, $com );

    foreach my $job ( $jobs2 ) {
        is( $job->status, $status, "Status is $status" );
    
        # Just in case, grab it again
        $job = $client->get_job( $job->id );
        is( $job->status, $status, "Status is $status" );
    }
    }
}

sub job_revisions_add_comment {
    TODO: {
    local $TODO = "Issues with PUT /translate/jobs on sandbox.";
    my $jobs1 = _get_reviewable_jobs( 2 );

    $#$jobs1 < 1 and die "No 'reviewable' Jobs found!";

    # Revise the Job
    my $com = "You are a champion.";
    my $status = 'revising';
    my $jobs2 = $client->request_job_revisions( $jobs1, $com );

    foreach my $job ( $jobs2 ) {
        my $comment = $job->get_comment( -1 );

        is( $comment->body, $com, "Found the $status comment" );
    }
    }
}

sub can_approve_jobs {
    TODO: {
    local $TODO = "Issues with PUT /translate/jobs on sandbox.";
    my $job = _get_reviewable_jobs(1);

    !$job and die "No 'reviewable' Jobs found!";

    # Approve the Job
    my $com = "You are a champion.";
    $job = $client->approve_job(
            $job
            , 5.0
            , $com
            , rand()
            , 1
            );

    is( $job->status, 'approved', "Status is approved" );

    # Just in case, grab it again
    $job = $client->get_job( $job->id );
    is( $job->status, 'approved', "Status is approved" );
    }
}

sub approve_jobs_adds_feedback {
    TODO: {
    local $TODO = "Issues with PUT /translate/jobs on sandbox.";
    my $job = _get_reviewable_jobs(1);

    !$job and die "No 'reviewable' Jobs found!";
    my $comment_count   = $job->comment_count;
    my $revision_count  = $job->revision_count;
    my $has_feedback    = $job->has_feedback;

    ok( !$has_feedback, "Job doesn't yet have feedback" );

    # Approve the Job
    my $for_xlator  = "You are a champion.";
    my $for_mygengo = "He is a champion.";
    my $com         = "So great, nice.".rand();
    $job = $client->approve_job(
            $job
            , 5.0
            , $for_xlator
            , $for_mygengo
            , $com
            );

    is( $job->status, 'approved', "Status is approved" );

    my $fb = $job->feedback;
    ok( $fb, "Has feedback" );

    # todo I don't know why, but the sandbox always returns 3.0
    is( $fb->rating, "3.0", "Rating correct" );
    is( $fb->for_translator, $for_xlator, "Comment correct" );
    }
}

sub can_reject_jobs {
    SKIP: {
    skip "Can't run reject test because can't read Captcha", 10 unless(is_mock);

    my $job = _get_reviewable_jobs(1);

    !$job and die "No 'reviewable' Jobs found!";

    # Reject the Job
    my $com = "'Native speaker' was an overstatement.";
    $job = $client->reject_job(
            $job
            , "quality"
            , $com
            , "ABC123"
            , 'cancel'
            );

    is( $job->status, 'rejected', "Status is rejected" );
    }
}

sub reject_jobs_adds_comment {
    SKIP: {
    skip "Can't run reject test because can't read Captcha", 10 unless(is_mock);

    my $job = _get_reviewable_jobs(1);

    !$job and die "No 'reviewable' Jobs found!";

    # Reject the Job
    my $com = "'Native speaker' was an overstatement.";
    $job = $client->reject_job(
            $job
            , "quality"
            , $com
            , "ABC123"
            , 'cancel'
            );

    my $comment = $job->get_comment( -1 );
    is( $comment->body, $com, "Found the reject comment" );
    }
}
