#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/./lib";
use lib "$FindBin::Bin/../lib";
use utf8;

=head1 DESCRIPTION

Tests for single Jobs.

=cut

use WebService::MyGengo::Test::Util::Client;
use WebService::MyGengo::Test::Util::Job;

use Getopt::Long;
use Test::More;

use Data::Dumper;

BEGIN {
    use_ok 'WebService::MyGengo::Job';
    use_ok 'WebService::MyGengo::Comment';
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
sub is_mock { !$LIVE }

my $tests = [
    'can_submit_new_job'
    , 'can_add_job_comments_by_string'
    , 'can_add_job_comments_by_object'
    , 'if_comment_exists_in_new_job_it_is_submitted_with_the_job'
    , 'search_job_with_get_comments_flag_populates_comment_list'
    , 'search_job_without_get_comments_flag_doesnt_populate_comment_list'
    , 'utf8_body_survives_job_creation'
    , 'utf8_body_survives_comment_creation_by_string'
    , 'utf8_body_survives_comment_creation_by_object'
    , 'comments_are_fifo'
    , 'comment_stringifies_to_body'
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
sub can_submit_new_job {
    my $struct = _dummy_job_struct;

    my $job = WebService::MyGengo::Job->new( $struct );
    my $job2 = $client->submit_job( $job );
    push @_dummies, $job2;

    foreach my $attr ( keys %$struct ) {
        # We have no reliable way to verify these
        $attr =~ /^(ctime|eta|credits|status|unit_count|job_id|_comments|slug|body_tgt|mt)$/
            and next;
        is( ''.$job2->$attr, ''.$job->$attr, "Attr. '$attr' matches" );
    }

    ok( $job2->id, "Has an ID" );

    isa_ok( $job2->ctime, "DateTime", "Ctime is a DateTime" );
    is( $job2->ctime->time_zone->name, "UTC", "Ctime is UTC" );

    isa_ok( $job2->eta, "DateTime::Duration", "ETA is a DateTime::Duration" );

    is( $job2->status, 'available', "Status is 'available'" );
}

sub can_add_job_comments_by_string {
    my $job = create_dummy_job($client);
    push @_dummies, $job;
    my $comment_count = $job->comment_count;

    my @comments = ( "Comment1-".rand(), "Comment2-".rand() );
    $job = $client->add_job_comment( $job, $_ )
        foreach ( @comments );

    my $new_comment_count = $job->comment_count;
    cmp_ok( $new_comment_count, '==', $comment_count+2
        , "Comment count incremented" );

    # Jobs are FIFO from the API
    my $com = $job->get_comment( $job->comment_count-2 );
    isa_ok( $com, "WebService::MyGengo::Comment"
        , "Comment is a Comment object" );
    cmp_ok( $com->body, 'eq', $comments[0], "Body matches" );

    $com = $job->get_comment( $comment_count+1 );
    isa_ok( $com, "WebService::MyGengo::Comment"
        , "Comment is a Comment object" );
    cmp_ok( $com->body, 'eq', $comments[1], "Body matches" );
}

sub can_add_job_comments_by_object {
    my $job = create_dummy_job($client);
    push @_dummies, $job;
    my $comment_count = $job->comment_count;

    my @comments = ( "Comment1-".rand(), "Comment2-".rand() );
    $job = $client->add_job_comment($job, WebService::MyGengo::Comment->new($_))
        foreach ( @comments );

    my $new_comment_count = $job->comment_count;
    cmp_ok( $new_comment_count, '==', $comment_count+2
        , "Comment count incremented" );

    # Jobs are FIFO from the API
    my $com = $job->get_comment( $comment_count );
    isa_ok( $com, "WebService::MyGengo::Comment"
        , "Comment is a Comment object" );
    cmp_ok( $com->body, 'eq', $comments[0], "Body matches" );

    $com = $job->get_comment( $comment_count+1 );
    isa_ok( $com, "WebService::MyGengo::Comment"
        , "Comment is a Comment object" );
    cmp_ok( $com->body, 'eq', $comments[1], "Body matches" );
}

sub if_comment_exists_in_new_job_it_is_submitted_with_the_job {
    my $struct = _dummy_job_struct;
    my $initial_comment = "Bongobong!";

    my $job = WebService::MyGengo::Job->new( $struct );
    my $comment_count = $job->comment_count;
    $job->_add_comment( WebService::MyGengo::Comment->new($initial_comment) );
    is( $job->comment_count, $comment_count+1, "Added 1 comment to Job" );

    # Only the latest comment will be submitted for a new Job
    my $job2 = $client->submit_job( $job );
    push @_dummies, $job2;

    is( $job2->comment_count, 1, "Only 1 comment in new Job" );
    cmp_ok( $job2->get_comment(0)->body, 'eq', $initial_comment
        , "Roundtripped comment" );
}

sub search_job_with_get_comments_flag_populates_comment_list {
    create_dummy_job( $client );
    my $job = $client->search_jobs( 'available' )->[0];

    $job = $client->get_job( $job->id, 1 );
    my $comment_count = $job->comment_count;

    !$job and die "No 'available' Jobs found!";

    # Make sure there's a comment
    my $initial_comment = rand()." Comments ahoy";
    $client->add_job_comment( $job, $initial_comment );

    $job = $client->get_job( $job->id, 1 );
    is( $job->comment_count, $comment_count+1, "Comment count OK" );
    cmp_ok( $job->get_comment($comment_count)->body, 'eq', $initial_comment
        , "Roundtripped comment" );
}

sub search_job_without_get_comments_flag_doesnt_populate_comment_list {
    my %struct = %{_dummy_job_struct()};
    delete $struct{comment};
    my $job = WebService::MyGengo::Job->new( \%struct );
    $client->submit_job( $job );

    $job = $client->search_jobs( 'available' )->[0];
    push @_dummies, $job;

    !$job and die "No 'available' Jobs found!";

    # Make sure there's a comment
    $client->add_job_comment( $job, rand()." Comments ahoy" );

    # Specify that we -dont- want to fetch comments
    $job = $client->get_job( $job->id, 0 );

    ok( !$job->fetched_comments, "Didn't fetch comments" );
    is( $job->comment_count, 0, "No comments found in new Job" );
}

sub utf8_body_survives_job_creation {
    my $struct = _dummy_job_struct;
    $struct->{body_src} = "マイゲンゴde日本語";

    my $job = WebService::MyGengo::Job->new( $struct );
    my $job2 = $client->submit_job( $job );
    push @_dummies, $job2;

    is( $job2->body_src, $struct->{body_src}, "Bodies match" );
    ok( utf8::is_utf8($job2->body_src), "Body is UTF8" );
}

sub utf8_body_survives_comment_creation_by_string {
    my $job = create_dummy_job($client);
    push @_dummies, $job;

    my $comment = "辱い。";
    $job = $client->add_job_comment( $job, $comment );

    my $com = $job->get_comment( $job->comment_count-1 );

    is( $com->body, $comment, "Bodies match" );
    ok( utf8::is_utf8($com->body), "Body is UTF8" );
}

sub utf8_body_survives_comment_creation_by_object {
    my $job = create_dummy_job($client);
    push @_dummies, $job;

    my $comment = WebService::MyGengo::Comment->new("辱い。");
    $job = $client->add_job_comment( $job, $comment );

    my $com = $job->get_comment( $job->comment_count-1 );

    is( $com->body, $comment->body, "Bodies match" );
    ok( utf8::is_utf8($com->body), "Body is UTF8" );
}

sub comments_are_fifo {
    my $job = create_dummy_job($client);
    push @_dummies, $job;

    my $comment = "Wouldn't ya like to be a FIFO too?";
    $job = $client->add_job_comment( $job, $comment );

    my $com = $job->get_comment( $job->comment_count-1 );

    is( $com->body, $comment, "Bodies match" );
}

sub comment_stringifies_to_body {
    my $job = create_dummy_job($client);
    push @_dummies, $job;

    my $comment = "Wouldn't ya like to be a FIFO too?";
    $job = $client->add_job_comment( $job, $comment );

    my $com = $job->get_comment( $job->comment_count-1 );

    is( "$com", $comment, "Stringification worked" );
}
