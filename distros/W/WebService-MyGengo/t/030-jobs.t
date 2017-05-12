#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/./lib";
use lib "$FindBin::Bin/../lib";

=head1 DESCRIPTION

Tests for code affecting multiple Jobs.

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
    'can_submit_multiple_jobs'
    , 'can_retrieve_multiple_jobs'
    , 'no_comments_without_comments_flag'
    , 'has_comments_with_comments_flag'
    , 'no_revisions_without_revisions_flag'
    , 'has_revisions_with_revisions_flag'
    , 'can_submit_job_group'
    # Appears to be unimplemented in the sandbox. See Client.pm's delete_jobs
    , 'can_delete_multiple_jobs_in_one_call'
    , 'jobs_submitted_as_group_have_same_group_id'
    , 'can_determine_translation_cost'
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
sub can_submit_multiple_jobs {
    my %struct = %{_dummy_job_struct()};

    my $job0 = WebService::MyGengo::Job->new( %struct );
    my $job1 = WebService::MyGengo::Job->new( %struct, body_src => rand() );
    my $jobs1 = [$job0, $job1];

    my $jobs2 = $client->submit_jobs( $jobs1 )
        or diag explain $client->last_response;
    push @_dummies, $_ foreach @$jobs2;

    is( $#$jobs2, $#$jobs1, "Job count matches" );

    for ( my $i = 0; $i <= $#$jobs1; $i++ ) {
        my $j1 = $jobs1->[$i];
        my $j2 = $jobs2->[$i];

        ok( $j2->id, "Has ID" );
        ok( $j2->ctime, "Has ctime" );
        is( $j2->body_src, $j1->body_src, "body_src matches" );
    }
}

sub can_retrieve_multiple_jobs {
    my %struct = %{_dummy_job_struct()};

    my $job0 = WebService::MyGengo::Job->new( %struct );
    my $job1 = WebService::MyGengo::Job->new( %struct, body_src => rand() );
    my $jobs1 = [$job0, $job1];

    my $jobs2 = $client->submit_jobs( $jobs1 )
        or diag explain $client->last_response;
    push @_dummies, $_ foreach @$jobs2;

    my $jobs3 = $client->get_jobs( map { $_->id } @$jobs2 );
    is( $#$jobs3, $#$jobs2, "Job count matches" );

    for ( my $i = 0; $i <= $#$jobs2; $i++ ) {
        my $j1 = $jobs2->[$i];
        my $j2 = $jobs3->[$i];

        is( $j2->id, $j1->id, "id matches" );
        is( $j2->body_src, $j1->body_src, "body_src matches" );
    }
}

sub no_comments_without_comments_flag {
    my %struct = %{_dummy_job_struct()};

    my $job0 = WebService::MyGengo::Job->new( %struct );
    my $job1 = WebService::MyGengo::Job->new( %struct, body_src => rand() );
    my $jobs1 = [$job0, $job1];

    my $jobs2 = $client->submit_jobs( $jobs1 )
        or diag explain $client->last_response;
    push @_dummies, $_ foreach @$jobs2;

    my $jobs3 = $client->get_jobs( map { $_->id } @$jobs2 );

    foreach my $job ( @$jobs3 ) {
        ok( !$job->fetched_comments, "Didnt fetch comments" )
            or diag explain $job;
    }
}

sub has_comments_with_comments_flag {
    my %struct = %{_dummy_job_struct()};

    my $job0 = WebService::MyGengo::Job->new( %struct );
    my $job1 = WebService::MyGengo::Job->new( %struct, body_src => rand() );
    my $jobs1 = [$job0, $job1];

    my $jobs2 = $client->submit_jobs( $jobs1 )
        or diag explain $client->last_response;
    push @_dummies, $_ foreach @$jobs2;

    my $jobs3 = $client->get_jobs( [map { $_->id } @$jobs2], 1 );

    foreach my $job ( @$jobs3 ) {
        ok( $job->has_comments, "Has comments" );
        ok( $job->comment_count, "Has comment count" );
    }
}

sub no_revisions_without_revisions_flag {
    my %struct = %{_dummy_job_struct()};

    my $job0 = WebService::MyGengo::Job->new( %struct );
    my $job1 = WebService::MyGengo::Job->new( %struct, body_src => rand() );
    my $jobs1 = [$job0, $job1];

    my $jobs2 = $client->submit_jobs( $jobs1 )
        or diag explain $client->last_response;
    push @_dummies, $_ foreach @$jobs2;

    my $jobs3 = $client->get_jobs( map { $_->id } @$jobs2 );

    foreach my $job ( @$jobs3 ) {
        ok( !$job->has_revisions, "Job doesnt have revisions" )
            or diag explain $job;
    }
}

sub has_revisions_with_revisions_flag {
    my %struct = %{_dummy_job_struct()};

    my $job0 = WebService::MyGengo::Job->new( %struct );
    my $job1 = WebService::MyGengo::Job->new( %struct, body_src => rand() );
    my $jobs1 = [$job0, $job1];

    my $jobs2 = $client->submit_jobs( $jobs1 )
        or diag explain $client->last_response;
    push @_dummies, $_ foreach @$jobs2;

    my $jobs3 = $client->get_jobs( [map { $_->id } @$jobs2], 0, 1 );

    foreach my $job ( @$jobs3 ) {
        ok( $job->has_revisions, "Job has revisions" );
    }
}

sub can_submit_job_group {
    my %struct = %{_dummy_job_struct()};

    my $job0 = WebService::MyGengo::Job->new( %struct );
    my $job1 = WebService::MyGengo::Job->new( %struct, body_src => rand() );
    my $jobs1 = [$job0, $job1];

    my $jobs2 = $client->submit_jobs( $jobs1, 1 )
        or diag explain $client->last_response;
    push @_dummies, $_ foreach @$jobs2;

    is( $#$jobs2, $#$jobs1, "Job count matches" );

    for ( my $i = 0; $i <= $#$jobs1; $i++ ) {
        my $j1 = $jobs1->[$i];
        my $j2 = $jobs2->[$i];

        ok( $j2->id, "Has ID" );
        ok( $j2->ctime, "Has ctime" );
        ok( $j2->group_id, "Has group_id" );
        is( $j2->body_src, $j1->body_src, "body_src matches" );
    }
}

sub jobs_submitted_as_group_have_same_group_id {
    my %struct = %{_dummy_job_struct()};

    my $job0 = WebService::MyGengo::Job->new( %struct );
    my $job1 = WebService::MyGengo::Job->new( %struct, body_src => rand() );
    my $jobs1 = [$job0, $job1];

    my $jobs2 = $client->submit_jobs( $jobs1, 1 )
        or diag explain $client->last_response;
    push @_dummies, $_ foreach @$jobs2;

    is( $jobs2->[0]->group_id, $jobs2->[1]->group_id, "Group IDs match" );
}

sub can_delete_multiple_jobs_in_one_call {
    TODO: {
    local $TODO = "Appears to be unimplemented in the sandbox. See Client.pm's"
                    . " delete_jobs.";
    return fail();
    }
    my %struct = %{_dummy_job_struct()};

    my $job0 = WebService::MyGengo::Job->new( %struct );
    my $job1 = WebService::MyGengo::Job->new( %struct, body_src => rand() );
    my $jobs1 = [$job0, $job1];

    my $jobs2 = $client->submit_jobs( $jobs1 )
        or diag explain $client->last_response;

    my $res = $client->delete_jobs( $jobs2 );
    ok( $res->is_success, "Delete request successful" );

    foreach ( @$jobs2 ) {
        is( $client->get_job( $_->id ), undef, "Job deleted" );
    }
}

sub can_determine_translation_cost {
    my %struct = %{_dummy_job_struct()};
    my $job0 = WebService::MyGengo::Job->new( \%struct );
    my $job1 = WebService::MyGengo::Job->new( \%struct );

    my $jobs = $client->determine_translation_cost([ $job0, $job1 ]);

    my $job = $jobs->[0];
    is( $job->body_src, $job0->body_src, "Body src matches" );
    is( $job->comment_count, $job0->comment_count, "Comment count matches" );
    ok( $job->unit_count, "Has unit count" );
    ok( $job->credits, "Has credits" );

    $job = $jobs->[1];
    is( $job->body_src, $job1->body_src, "Body src matches" );
    is( $job->comment_count, $job1->comment_count, "Comment count matches" );
    ok( $job->unit_count, "Has unit count" );
    ok( $job->credits, "Has credits" );
}
