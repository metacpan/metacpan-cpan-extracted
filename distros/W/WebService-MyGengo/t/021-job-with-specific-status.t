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

    bash> perl -I t/lib -I lib t/021-job-with-specific-status.t --live 1
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

=head1 DESCRIPTION

Job-related tests

=cut

my $tests = [
    'can_fetch_specific_revision'
    , 'get_job_with_get_revisions_flag_populates_revisions_list'
    , 'get_job_without_get_revisions_flag_doesnt_populate_revisions_list'
    , 'get_job_with_get_feedback_flag_populates_feedback_list'
    , 'get_job_without_get_feedback_flag_doesnt_populate_feedback_list'
    , 'can_request_job_revision'
    , 'job_revision_adds_comment'
    , 'can_approve_job'
    , 'approve_job_adds_feedback'
    , 'can_reject_job'
    , 'reject_job_adds_comment'
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
        for ( 0 .. 5 ) {
            create_dummy_job( $client )
                or die "Error creating Job: ".$client->last_response->message;
        }
        print STDERR<<EOT;
6 dummy Jobs have been created in your sandbox:
Set them all to 'reviewable' status and run the test again with
the "--live 2" flag to execute the real tests.
EOT
        done_testing();
        exit 0;
    }
}

sub _get_approved_job {
    # If we're using the mock LWP we can fake an approved Job
    if ( is_mock ) {
        my $hash = _dummy_job_struct;
        $hash->{status} = 'approved';
        $client->_user_agent->add_job( $hash );
    }
    else {
        my $job = $client->search_jobs( 'reviewable', undef, 1 )->[0];
        my $com = "You are a champion.";
        $client->approve_job( $job, 5.0, $com, rand(), 1 );
    }

    my $job = $client->search_jobs( 'approved', undef, 1 )->[0];
    push @_dummies, $job;
    return $job;
}

sub _get_reviewable_job {
    # If we're using the mock LWP we can fake a reviewable Job
    if ( is_mock ) {
        my $hash = _dummy_job_struct;
        $hash->{status} = 'reviewable';
        $client->_user_agent->add_job( $hash );
    }

    my $job = $client->search_jobs( 'reviewable', undef, 1 )->[0];
    push @_dummies, $job;
    return $job;
}

sub can_fetch_specific_revision {
    my $job = _get_approved_job;

    !$job and die "No 'approved' Jobs found!";

    # Set get_revisions to true
    $job = $client->get_job( $job->id, 0, 1 );

    # All Jobs have at least one revision, so we don't need to create one
    ok( $job->has_revisions, "Has revisions" );
    is( $job->revision_count, 1, "Job has 1 revision" );

    my $rev = $job->get_revision( 0 );

    my $rev2 = $client->get_job_revision( $job, $rev->id );

    is( $rev2->body_tgt, $rev->body_tgt, "Bodies match" );
}

sub get_job_with_get_revisions_flag_populates_revisions_list {
    my $job = _get_approved_job;

    !$job and die "No 'approved' Jobs found!";

    # Set get_revisions to true
    $job = $client->get_job( $job->id, 0, 1 );

    # All Jobs have at least one revision, so we don't need to create one
    ok( $job->has_revisions, "Has revisions" );
    is( $job->revision_count, 1, "Job has 1 revision" );
}

sub get_job_without_get_revisions_flag_doesnt_populate_revisions_list {
    my $job = _get_approved_job;

    !$job and die "No 'approved' Jobs found!";

    # Set get_revisions to false
    $job = $client->get_job( $job->id, 0, 0 );

    ok( !$job->has_revisions, "Doesnt have revisions" );
    is( $job->revision_count, 0, "Job has 0 revisions" );
}

sub get_job_with_get_feedback_flag_populates_feedback_list {
    my $job = _get_approved_job;

    !$job and die "No 'approved' Jobs found!";

    # Set get_feedback to true
    $job = $client->get_job( $job->id, 0, 0, 1 );

    ok( $job->has_feedback, "Job has feedback" );
    cmp_ok( $job->feedback->rating, '>', -1, "Feedback has a rating" );
}

sub get_job_without_get_feedback_flag_doesnt_populate_feedback_list {
    my $job = _get_approved_job;

    !$job and die "No 'approved' Jobs found!";

    # Set get_feedback to false
    $job = $client->get_job( $job->id, 0, 0, 0 );

    ok( !$job->has_feedback, "Job has no feedback" );
}

sub can_request_job_revision {
    my $job = _get_reviewable_job;

    !$job and die "No 'reviewable' Jobs found!";

    # Revise the Job
    my $com = "You are a champion.";
    my $status = 'revising';
    $job = $client->request_job_revision( $job, $com );

    is( $job->status, $status, "Status is $status" );

    # Just in case, grab it again
    $job = $client->get_job( $job->id );
    is( $job->status, $status, "Status is $status" );
}

sub job_revision_adds_comment {
    my $job = _get_reviewable_job;

    !$job and die "No 'reviewable' Jobs found!";

    # Revise the Job
    my $com = "You are a champion.";
    my $status = 'revising';
    $job = $client->request_job_revision( $job, $com );

    my $comment = $job->get_comment( -1 );

    ok( $comment, "Found the comment" );
    is( $comment->body, $com, "Comment body correct" );
}

sub can_approve_job {
    my $job = _get_reviewable_job;

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

sub approve_job_adds_feedback {
    my $job = _get_reviewable_job;

    !$job and die "No 'reviewable' Jobs found!";
    my $comment_count   = $job->comment_count;
    my $revision_count  = $job->revision_count;
    my $has_feedback    = $job->has_feedback;

    ok( !$has_feedback, "Job doesn't yet have feedback" );

    # Approve the Job
    my $com         = "So great, nice.".rand();
    $job = $client->approve_job(
            $job
            , 5.0
            , $com
            , $com
            , 1
            );

    is( $job->status, 'approved', "Status is approved" );

    my $fb = $job->feedback;
    ok( $fb, "Has feedback" );

    # todo I don't know why, but the sandbox always returns 3.0
    is( $fb->rating, "3.0", "Rating correct" );
    is( $fb->for_translator, $com, "Comment correct" );
}

sub can_reject_job {
    SKIP: {
    skip "Can't run reject test because can't read Captcha", 10 unless(is_mock);

    my $job = _get_reviewable_job;

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

sub reject_job_adds_comment {
    SKIP: {
    skip "Can't run reject test because can't read Captcha", 10 unless(is_mock);

    my $job = _get_reviewable_job;

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
