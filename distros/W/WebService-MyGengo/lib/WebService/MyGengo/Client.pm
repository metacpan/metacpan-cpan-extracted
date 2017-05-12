package WebService::MyGengo::Client;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;

extends qw(WebService::MyGengo::Base);

use LWP::UserAgent;
use Scalar::Util qw(blessed);
use URI;

use WebService::MyGengo;
use WebService::MyGengo::Account;
use WebService::MyGengo::Job;

use WebService::MyGengo::Comment;
use WebService::MyGengo::Feedback;
use WebService::MyGengo::Revision;

use WebService::MyGengo::Language;
use WebService::MyGengo::LanguagePair;

use WebService::MyGengo::RequestFactory;
use WebService::MyGengo::Response;
use WebService::MyGengo::Exception;

=head1 NAME

WebService::MyGengo::Client - Client for interacting with the myGengo API

=head1 DESCRIPTION

A perl library for accessing the MyGengo (L<http://mygengo.com>) API.

=head1 SYNOPSIS

    use WebService::MyGengo::Client;
    my $client = WebService::MyGengo::Client->new({
        public_key      => 'pubkey'
        , private_key   => 'privkey'
        , use_sandbox   => 1
        });

    # Alternative constructor syntax
    $client = WebService::MyGengo::Client->new('pubkey', 'privkey', $use_sandbox);

    # A WebService::MyGengo::Job
    my $job = $client->get_job( 123 );

    # Seeing what went wrong by inspecting the `last_response`
    unless ( $job = $client->get_job( "BLARGH!" ) ) {
        MyApp::Exception->throw({ message => "Oops: ".$client->last_response->message });
    }

=head1 ATTRIBUTES

All attributes are read-only unless otherwise specified.

If you need a Client with different parameters, just create a new one :)

=head2 public_key (Str)

Your public API key.

=cut
has public_key => (
    is => 'rw'
    , isa => 'Str'
    , required => 1
    , trigger => sub { shift->clear_request_factory }
    );

=head2 private_key (Str)

Your private API key.

=cut
has private_key => (
    is => 'ro'
    , isa => 'Str'
    , required => 1
    , trigger => sub { shift->clear_request_factory }
    );

=head2 use_sandbox (Bool)

A boolean flag that determines whether to use the API sandbox or the live site.

=cut
has use_sandbox => (
    is => 'ro'
    , isa => 'Bool'
    , default => 1
    , trigger => sub {
        my ( $self, $val ) = ( shift, @_ );
        $self->clear_request_factory;
        my $url = $val
                ? 'http://api.sandbox.mygengo.com/v1.1'
                : 'http://api.mygengo.com/v1.1'
                ;
        $self->_set_root_uri( URI->new( $url ) );
        }
    );

=head2 root_uri (L<URI>)

The L<URI> to be used as the base for all API endpoints.

This value is set automatically according to the L<use_sandbox> attribute.

eg, 'http://api.sandbox.mygengo.com/v1.1'

=cut
has root_uri => (
    is => 'rw'
    , isa => 'URI'
    , init_arg => undef
    , writer => '_set_root_uri'
    );

=head2 DEBUG (Bool)

A read-write flag indicating whether to dump debugging information to STDERR.

=cut
has DEBUG => (
    is          => 'rw'
    , isa       => 'Bool'
    , default   => 0
    );

=head2 _user_agent (L<LWP::UserAgent>)

This is a semi-private attribute, as most people won't use it.

You can use _set_user_agent to supply your own UserAgent object to be used
for API calls, eg L<LWPx::ParanoidAgent>.

The agent must pass the `->isa('LWP::UserAgent')` test.

In DEBUG mode, a request_send and request_done handler will be registered
with the agent to dump raw requests and responses.

=cut
has _user_agent => (
    is          => 'rw'
    , writer    => '_set_user_agent' # Semi-private
    , isa       => 'LWP::UserAgent'
    , lazy      => 1
    , builder   => '_build__user_agent'
    , init_arg  => undef
    );
sub _build__user_agent {
    my ( $self ) = ( shift );

    my $ua = LWP::UserAgent->new(
        agent           => $self->_user_agent_string
        , timeout       => 30
        , max_redirect  => 5
        );

    if ( $self->DEBUG ) {
        $ua->add_handler("request_send",  sub {
            print STDERR "RAW REQUEST:";
            shift->dump( maxlength => 2048 );
            print STDERR "\n";
            return;
            });
        $ua->add_handler("response_done", sub {
            print STDERR "RAW RESPONSE:";
            shift->dump( maxlength => 10000);
            print STDERR "\n";
            return;
            });
    }

    return $ua;
}

#=head2 _user_agent_string (Str)
#
#The User-Agent string reported by the client.
#
#=cut
has _user_agent_string => (
    is          => 'ro'
    , isa       => 'Str'
    , lazy      => 1
    , init_arg  => undef
    , default   => sub {
        __PACKAGE__." ".$WebService::MyGengo::VERSION
        }
    );

=head2 request_factory (L<WebService::MyGengo::RequestFactory>)

A L<WebService::MyGengo::RequestFactory> instance used to generate API requests.

=cut
has request_factory => (
    is => 'ro'
    , isa => 'WebService::MyGengo::RequestFactory'
    , lazy_build => 1
    , init_arg => undef
    );
sub _build_request_factory {
    my ( $self ) = ( shift );

    return WebService::MyGengo::RequestFactory->new({
        public_key      => $self->public_key
        , private_key   => $self->private_key
        , root_uri      => $self->root_uri
        });
}

=head2 last_response (L<WebService::MyGengo::Response>)

The last raw response object received from the API.

=cut
has last_response => (
    is => 'rw'
    , isa => 'WebService::MyGengo::Response'
    , init_arg => undef
    , writer => '_set_last_response'
    );

=head1 METHODS

Unless otherwise specified, all methods will:

=over

=item Return a true value on success

=item Return a false value on failure

=item Throw an exception on bad arguments

=item Make no effort to trap exceptions from the transport layer

=back

You can retrieve the last raw response via the `last_response` attribute to
inspect any specific error conditions. See the L<SYNOPSIS>.

=cut

#=head2 BUILDARGS
#
#Support alternative construction syntax.
#
#=cut
around BUILDARGS => sub {
    my ( $orig, $class, $args ) = ( shift, shift, @_ );

    ref($args) eq 'HASH' and return $class->$orig(@_);

    my %args;
    @args{ qw/public_key private_key use_sandbox _user_agent_string/ }
        = @_;

    return \%args;
};

=head2 get_account( )

Returns the L<WebService::MyGengo::Account> associated with your API keys.

Calls L<get_account_stats> and L<get_account_balance> internally to gather
the parameters necessary to construct the Account object.

=cut
sub get_account {
    my ($self) = @_;

    my $stats   = $self->get_account_stats();

    !( $self->last_response->is_success ) and
        WebService::MyGengo::Exception->throw({
            message => "Could not retrieve account stats"
            });

    my $balance = $self->get_account_balance();

    !( $self->last_response->is_success ) and
        WebService::MyGengo::Exception->throw({
            message => "Could not retrieve account balance"
            });

    my %args;
    @args{ keys %$stats } = values %$stats;
    @args{ keys %$balance } = values %$balance;

    return WebService::MyGengo::Account->new( \%args );
}

=head2 get_account_stats( )

Returns a reference to a hash of account statistics.

You may find it easier to simply use L<get_account>.

See: L<http://mygengo.com/api/developer-docs/methods/account-stats-get/>

=cut
sub get_account_stats {
    my ( $self ) = ( shift );
    my $res = $self->_send_request('GET', '/account/stats/');
    return $res->response_struct;
}

=head2 get_account_balance( )

Returns a reference to a hash of account balance information.

You may find it easier to simply use L<get_account>.

See: L<http://mygengo.com/api/developer-docs/methods/account-balance-get/>

=cut
sub get_account_balance { 
    my ( $self ) = ( shift );
    my $res = $self->_send_request('GET', '/account/balance/');
    return $res->response_struct;
}

=head2 get_job( $id, $get_comments=false?, $get_revisions=false?, $get_feedback=false? )

Retrieves a job from myGengo with the specified id.

If $get_comments is true, additional API calls will be made to populate
the Job's `comments` list.

If $get_revisions is true, additional API calls will be made to populate
the Job's `revisions` list.

If $get_feedback is true, an additional API call will be made to populate
the Job's `feedback` attribute.

Returns a L<WebService::MyGengo::Job> or undef if the Job can't be found.

See: L<http://mygengo.com/api/developer-docs/methods/translate-job-id-get/>

=cut
sub get_job { 
    my ( $self, $id ) = ( shift, shift, @_ );

    my $jobs = $self->get_jobs( [$id], @_ )
        or return undef;

    return $jobs->[0];
}

=head2 get_jobs( @($id) )

=head2 get_jobs( \@($id), $get_comments=false?, $get_revisons=false?, $get_feedback=false? )

Retrieves the given Jobs from the API.

The second form allows control over prefetching of comments, revisions and
feedback for the Jobs.

Returns a reference to an array of L<WebService::MyGengo::Job> objects on
success, undef on failure.  (If no results are found but the request succeeded,
you'll get a reference to an empty array, as expected.)

See: L<http://mygengo.com/api/developer-docs/methods/translate-jobs-ids-get/>

=cut
sub get_jobs {
    my ( $self ) = ( shift, @_ );

    my ( $get_comments, $get_revisions, $get_feedback );
    my @ids;

    # Support multiple calling signatures
    if ( ref($_[0]) eq 'ARRAY' ) {
        @ids = @{shift()};
        ($get_comments, $get_revisions, $get_feedback) = @_;
    }
    else {
        @ids = @_;
    }

    !scalar(@ids) and WebService::MyGengo::Exception->throw({
        message => "Cant get_jobs without an Job ids"
        });

    my $res     = $self->_send_request(
        'GET'
        , '/translate/jobs/'. join(",",@ids)
        );

    $res->is_error and return undef;

    my @jobs = map { WebService::MyGengo::Job->new($_) }
        @{$res->response_struct->{jobs}};

    foreach my $job ( @jobs ) {
        $get_comments and
            $job->_set_comments( $self->get_job_comments( $job ) );

        $get_revisions and
            $job->_set_revisions( $self->get_job_revisions( $job ) );

        $get_feedback and
            $job->_set_feedback( $self->get_job_feedback( $job ) );
    }

    return \@jobs;
}

=head2 search_jobs( $status?, $timestamp_after?, $count? )

Searches the API for Jobs according to several optional filters.

Available filters are:

=over

=item $status - Get only Jobs of status $status (default: no filter)

Legal values: unpaid, available, pending, reviewable, approved, rejected
, canceled

=item $timestamp_after - Get only Jobs created after this epoch time (default:
no filter)

=item $count - Get a maximum of $count Jobs (default: no filter)

=back

Returns a reference to an array of L<WebService::MyGengo::Job>s on success,
undef on failure.  (If no results are found but the request succeeded, you'll
get a reference to an empty array, as expected.)

See: L<http://mygengo.com/api/developer-docs/methods/translate-jobs-get/>

=cut
#todo Support wantarray?
#todo Support get_comments/feedback/revisions
sub search_jobs { 
    my ($self, $status, $timestamp_after, $count) = ( shift, @_ );
    
    my $res = $self->_send_request( 'GET', '/translate/jobs/', {
        status              => $status
        , timestamp_after   => $timestamp_after
        , count             => $count
        } );

    $res->is_error and return undef;

    my @jobs;
    push @jobs, $self->get_job( $_->{job_id} )
        foreach ( @{ $res->response_struct->{elements} } );

    return \@jobs;
}

=head2 get_job_comments( $WebService::MyGengo::Job|$id )

Returns a reference to an array of L<WebService::MyGengo::Comment> objects.

You may find it easier to simply use L<get_job> with the $get_comments flag.

See: L<http://mygengo.com/api/developer-docs/methods/translate-job-id-comments-get/>

=cut
#todo Support wantarray?
sub get_job_comments { 
    my ( $self, $job ) = ( shift, @_ );

    my $job_id = blessed($job) ? $job->id : $job;

    !defined($job_id) and WebService::MyGengo::Exception->throw({
        message => "Cannot get_job_comments without a Job"
        });

    my $res = $self->_send_request(
        'GET'
        , '/translate/job/'.$job_id.'/comments'
        );

    $res->is_error and return undef;

    my @comments = map { WebService::MyGengo::Comment->new($_) }
        @{ $res->response_struct->{thread} };

    return \@comments;
}

=head2 get_job_revision( $WebService::MyGengo::Job|$id, $revision_id )

Gets a specific revision for the given Job.

Returns an L<WebService::MyGengo::Revision> object.

See L<http://mygengo.com/api/developer-docs/methods/translate-job-id-revision-rev-id-get/>

=cut
sub get_job_revision {
    my ( $self, $job, $rev_id ) = ( shift, @_ );

    my $job_id = blessed($job) ? $job->id : $job;

    !( defined($job_id) && defined($rev_id) ) and
        WebService::MyGengo::Exception->throw({
            message => "Cannot get_job_revision without a Job and Revision ID"
            });

    my $res = $self->_send_request('GET'
        , '/translate/job/'.$job_id.'/revision/'.$rev_id);
    $res->is_error and return undef;

    # We don't get the rev_id back in the struct
    my $struct = $res->response_struct->{revision};
    $struct->{rev_id} = $rev_id;

    return WebService::MyGengo::Revision->new( $struct );
}

=head2 get_job_revisions( $WebService::MyGengo::Job|$id )

Gets all revisions for the given job

Revisions are created each time a translator or Senior Translator updates the
job.

Returns a reference to an array of L<WebService::MyGengo::Revision> objects.

You may find it easier to simply use L<get_job> with the $get_revisions flag.

See: L<http://mygengo.com/api/developer-docs/methods/translate-job-id-revisions-get/>

=cut
#todo Support wantarray?
sub get_job_revisions { 
    my ( $self, $job ) = ( shift, @_ );

    my $job_id = blessed($job) ? $job->id : $job;

    !defined($job_id) and WebService::MyGengo::Exception->throw({
        message => "Cannot get_job_revisions without a Job"
        });

    my $res = $self->_send_request('GET'
        , '/translate/job/'.$job_id.'/revisions');

    $res->is_error and return undef;

    my @revs = map { $self->get_job_revision( $job_id, $_->{rev_id} ) }
        @{ $res->response_struct->{revisions} };

    return \@revs;
}

=head2 get_job_feedback( $WebService::MyGengo::Job|$id )

Gets feedback for the given Job.

Returns an L<WebService::MyGengo::Feedback> object.

You may find it easier to simply use L<get_job> with the $get_feedback flag.

B<Note:> Even for Jobs without feedback, the API will still return one with
a 'rating' of 3.0 and an empty 'for_translator' attribute. This client
makes no attempt to handle this situation.

See L<http://mygengo.com/api/developer-docs/methods/translate-job-id-feedback-get/>

=cut
sub get_job_feedback { 
    my ( $self, $job ) = ( shift, @_ );

    my $job_id = blessed($job) ? $job->id : $job;

    !defined($job_id) and WebService::MyGengo::Exception->throw({
        message => "Cannot get_job_feedback without a Job"
        });

    my $res = $self->_send_request('GET'
        , '/translate/job/'.$job_id.'/feedback');

    $res->is_error and return undef;

    return WebService::MyGengo::Feedback->new(
        $res->response_struct->{feedback}
        );
}

=head2 determine_translation_cost( $WebService::MyGengo::Job|\@(WebService::MyGengo::Job) )

Given a single Job, or a reference to a list of Jobs, determines the cost to
translate them. The Jobs are not saved to myGengo and the user is not charged
for them.

The only Job fields required to determine cost are: lc_src, lc_tgt, tier and
body_src. (However, this method makes no effort to ensure you have set
them on each Job.)

Returns a reference to an array of Jobs with the 'unit_count' and 'credits'
attributes set.

See: L<http://mygengo.com/api/developer-docs/methods/translate-service-quote-post/>

=cut
#todo Proper Job cloning. We might lose comments/etc. as-is, although people probably won't be passing in fully-composed Jobs anyhow.
sub determine_translation_cost { 
    my ( $self, $jobs ) = ( shift, @_ );

    !( $jobs ) and
        WebService::MyGengo::Exception->throw({
            message => "Cannot determine_translation_cost without a Job."
            });

    ref($jobs) ne 'ARRAY' and $jobs = [$jobs];

    my $i = 0;
    my $res = $self->_send_request('POST', '/translate/service/quote', {
        jobs        => {map { "job_".++$i => $_->to_hash } @$jobs}
        });

    $res->is_error and return undef;

    # Assuming the API always returns Jobs in the order in which we provided
    #   them
    $i = 0;
    my $struct = $res->response_struct;
    my @jobs;
    foreach my $job ( @$jobs ) {
        # todo Real cloning. MooseX::Clone?
        push @jobs, WebService::MyGengo::Job->new(
            %{$job->to_hash([])}, %{$struct->{jobs}->{"job_".++$i}}
            );
    }

    return \@jobs;
}

=head2 submit_job( $WebService::MyGengo::Job|\%job )

Submits a new translation Job.

Returns the full L<WebService::MyGengo::Job> fetched from the API on success.

Will cowardly refuse to submit a Job without a body_src, lc_src, lc_tgt
and tier by throwing an Exception.

See: L<http://mygengo.com/api/developer-docs/methods/translate-job-post/>

=cut
sub submit_job {
    my ( $self, $job ) = ( shift, @_ );

    my $hash = ref($job) eq 'HASH' ? $job : $job->to_hash;

    foreach ( qw/body_src lc_src lc_tgt tier/ ) {
        !length($hash->{$_}) and
        WebService::MyGengo::Exception->throw({
            message => "Cannot submit_job without a body_src, lc_src"
                        . ", lc_tgt and tier"
            });
    }

    my $res = $self->_send_request('POST', '/translate/job/', {
        job => $hash
        });
    $res->is_error and return undef;

    my $new_job = WebService::MyGengo::Job->new(
        $res->response_struct->{job}
        );

    # If there was a comment submitted with the new Job then make sure
    #   we fetch it back from the API
    exists($hash->{comment}) and
        $new_job->_set_comments( $self->get_job_comments( $new_job ) );

    return $new_job;
}

=head2 submit_jobs( \@(WebService::MyGengo::Job), $as_group=false? )

Submit multiple Jobs to the API in one call.

If you would like to specify that a single translator work on all of the Jobs,
set $as_group to a true value.

Returns a reference to an array of L<WebService::MyGengo::Job> objects from the
API on success, undef on failure.

B<Note:> There are some restrictions on what Jobs can be grouped; this client
makes no attempt to validate these conditions for you.

See: L<http://mygengo.com/api/developer-docs/methods/translate-jobs-post/>

=cut
sub submit_jobs {
    my ( $self, $jobs, $as_group ) = ( shift, @_ );

    $as_group   //= 0;

    !( ref($jobs) eq 'ARRAY' and scalar(@$jobs) )
        and WebService::MyGengo::Exception->throw({
            message => "Cannot submit jobs without a list of Jobs."
            });

    # todo Should to_hash be done in the Request layer?
    my @jobs_to_submit = map { blessed($_) ? $_->to_hash : $_ } @$jobs;

    my $res = $self->_send_request('POST', '/translate/jobs', {
        jobs        => \@jobs_to_submit
        , as_group  => $as_group
    });

    $res->is_error and return undef;

    my $struct = $res->response_struct;
    my @jobs;
    foreach ( @{$struct->{jobs}} ) {
        # todo For some reason, the API returns an arrayref for element 0
        #   instead of a hashref, and the subsequent hashrefs are keyed
        #   unnecessarily by increment ID.
        #   This is actually in the raw JSON string...
        my $args =
            ref($_) eq 'ARRAY'
            ? $_->[0]
            : $_->{ (keys %$_)[0] };

        $struct->{group_id} and $args->{group_id} = $struct->{group_id};

        push @jobs, WebService::MyGengo::Job->new($args);
    }

    return \@jobs;
}

=head2 add_job_comment( $WebService::MyGengo::Job|$id, $WebService::MyGengo::Comment|$body )

Adds a comment to the specified Job.

Returns the Job with the `comments` collection refreshed on success,
undef on error.

See: L<http://mygengo.com/api/developer-docs/methods/translate-job-id-comment-post/>

=cut
sub add_job_comment { 
	my ( $self, $job, $comment ) = ( shift, @_ );
	
    my $job_id  = blessed($job) ? $job->id : $job;
    my $body    = blessed($comment) ? $comment->body : $comment;

    !( defined($job_id) && defined($body) ) and
        WebService::MyGengo::Exception->throw({
            message => "Cannot add_job_comment without a Job and comment body"
            });

    my $res = $self->_send_request(
        'POST'
        , '/translate/job/'.$job->id.'/comment'
        , { body => $body }
        );

    $res->is_error and return undef;

    # 1 flag is to force comment refresh
    return $self->get_job( $job->id, 1 );
}

=head2 delete_job( $WebService::MyGengo::Job|$id )

=head2 cancel_job( $WebService::MyGengo::Job|$id )

Deletes (cancels) a Job.

Returns true on success, false on failure.

B<Note:> You can only cancel a Job if it has not yet been started by a
translator.

See: L<http://mygengo.com/api/developer-docs/methods/translate-job-id-delete/>

=cut
sub cancel_job { shift->delete_job( @_ ) }
sub delete_job {
    my ( $self, $job ) = ( shift, @_ );

    my $job_id = blessed($job) ? $job->id : $job;

    !defined($job_id) and WebService::MyGengo::Exception->throw({
        message => "Cannot delete_job without a Job"
        });

    my $res = $self->_send_request('DELETE', '/translate/job/'.$job_id);
    return $res->is_success;
}

=head2 UNIMPLEMENTED delete_jobs( \@jobs )

=head2 UNIMPLEMENTED cancel_jobs( \@jobs )

Deletes (cancels) several Jobs in one API call.

You can only cancel a Job if it has not yet been started by a translator.

Returns true on success, false on failure.

B<Note:> This endpoint is documented at the link below, but every calling method
I've tried yields a 500 error from the sandbox.

See: L<http://mygengo.com/api/developer-docs/methods/translate-jobs-delete/> 

=cut
sub cancel_jobs { shift->delete_jobs( @_ ) }
sub delete_jobs {
    my ( $self, $jobs ) = ( shift, @_ );

    die "Unimplemented.";

    ref($jobs) ne 'ARRAY'  and WebService::MyGengo::Exception->throw({
        message => "Cannot delete_jobs without a list of Jobs"
        });

    my @ids = map { blessed($_) ? $_->id : $_ } @$jobs;

    my $res = $self->_send_request(
        'DELETE'
        , '/translate/jobs'
        , { job_ids => \@ids }
        );

    return $res->is_success;
}

=head2 request_job_revision( $WebService::MyGengo::Job|id, $comment )

Requests a revision to the given Job.

Instructions for the translator must be provided in $comment.

Returns the Job, updated from the API, on success.

B<Note:> Synonym `revise_job` is provided for convenience, although it
does not accurately describe the action performed.

See L<http://mygengo.com/api/developer-docs/methods/translate-job-id-put/>

=cut
#todo Making these specialized requests into subclasses, or using roles/traits, would make things nicer. The client shouldnt have to know this much about the guts of a request.
sub revise_job { shift->request_job_revision(@_) }
sub request_job_revision {
    my ( $self, $job, $comment ) = ( shift, @_ );

    my $job_id = blessed($job) ? $job->id : $job;

    !( $job_id && $comment ) and
        WebService::MyGengo::Exception->throw({
            message => "Cannot request_job_revision without a Job and comment"
            });

    my $res = $self->_update_job( $job_id, {
        action      => 'revise'
        , comment   => $comment
        } );
    $res->is_error and return undef; 

    # Revisions add comments, so fetch them as well
    return $self->get_job( $job_id, 1 );
}

=head2 approve_job( $WebService::MyGengo::Job|id, $rating, $comment_for_translator?, $comment_for_mygengo?, $public_comments? )

Approves the most recent translation of the given Job.

A rating is required and must be between 1 (poor) and 5 (excellent.)

Feedback for the translator or for myGengo are optional. If the
$public_comments flag is true your feedback may be shared publicly by myGengo.

Returns the Job, updated from the API, on success.

See L<http://mygengo.com/api/developer-docs/methods/translate-job-id-put/>

=cut
#todo Making these specialized requests into subclasses, or using roles/traits, would make things nicer. The client shouldnt have to know this much about the guts of a request.
sub approve_job {
    my ( $self, $job, $rating, $for_translator, $for_mygengo, $public_comment)
        = ( shift, @_ );

    my $job_id = blessed($job) ? $job->id : $job;

    !( $job_id && $rating && ( $rating > 0 && $rating < 6 ) ) and
        WebService::MyGengo::Exception->throw({
            message => "Cannot approve_job without a Job and rating between 1 and 5"
            });

    my $res = $self->_update_job( $job_id, {
        action      => 'approve'
        , rating    => $rating
        , defined($for_translator) ? (for_translator => $for_translator) : ()
        , defined($for_mygengo) ? (for_mygengo => $for_mygengo) : ()
        , defined($public_comment) ? (public => $public_comment) : ()
        } );
    $res->is_error and return undef; 

    # Approvals add comments, revisions and feedback, so fetch them as well
    return $self->get_job( $job_id, 1, 1, 1 );
}

=head2 reject_job( $WebService::MyGengo::Job|id, $reason, $comment, $captcha, $follow_up=requeue? )

Rejects the given Job.

A reason for the rejection is required and must be one of: quality, incomplete, other

A comment regarding the rejection and the human-readable text from the image
refered to in the Job's `captcha_url` attribute are also required.

You may supply an optional follow-up action for the Job. Legal values are:
requeue (re-submit the Job for translation automatically), cancel (cancel the
Job outright)

Returns the Job, updated from the API, on success.

See L<http://mygengo.com/api/developer-docs/methods/translate-job-id-put/>

=cut
#todo Making these specialized requests into subclasses, or using roles/traits, would make things nicer. The client shouldnt have to know this much about the guts of a request.
sub reject_job {
    my ( $self, $job, $reason, $comment, $captcha, $follow_up ) = ( shift, @_ );

    my $job_id = blessed($job) ? $job->id : $job;

    !( $job_id && $reason && ( $reason =~ /quality|incomplete|other/ )
        && $comment && $captcha )
    and
        WebService::MyGengo::Exception->throw({
            message => "Cannot reject_job without a Job, reason, comment"
                        . " and captcha text"
            });

    my $res = $self->_update_job( $job_id, {
        action      => 'reject'
        , reason    => $reason
        , comment   => $comment
        , captcha   => $captcha
        , defined($follow_up) ? (follow_up => $follow_up) : ()
        } );
    $res->is_error and return undef; 

    # Rejection adds comments, so fetch them as well
    return $self->get_job( $job_id, 1 );
}

#=head2 _update_job( $WebService::MyGengo::Job|id, \%parameters )
#
#Internal method to updates Job status.
#
#Different statuses accept different parameters.
#
#See the individual revise|approve|reject_job methods for details.
#
#=cut
sub _update_job { 
    my ( $self, $job, $params ) = ( shift, @_ );

    my $job_id = blessed($job) ? $job->id : $job;

    return $self->_send_request('PUT', '/translate/job/'.$job_id, $params);
}

=head2 get_service_language_pairs( $source_language_code? )

Returns supported translation language pairs, tiers, and credit prices.

$source_language_code is the ISO 2-character code. If provided, only language
pairs with that source language will be returned.

Returns a refernece to an array of L<WebService::MyGengo::LanguagePair> objects.

See: L<http://mygengo.com/api/developer-docs/methods/translate-service-language-pairs-get/>

=cut
#todo Support wantarray?
sub get_service_language_pairs { 
    my ( $self, $lc_src ) = ( shift, @_ );
    
    my $res = $self->_send_request('GET', '/translate/service/language_pairs', {
        defined($lc_src) ? (lc_src => $lc_src) : ()
        });

    $res->is_error and return undef;

    my @pairs;
    push @pairs, WebService::MyGengo::LanguagePair->new( $_ )
        foreach @{ $res->response_struct->{elements} };

    return \@pairs;
}

=head2 get_service_languages( )

Gets all languages supported by myGengo.

Returns a reference to an array of L<WebService::MyGengo::Language> objects.

See: L<http://mygengo.com/api/developer-docs/methods/translate-service-languages-get/>

=cut
#todo Support wantarray?
sub get_service_languages { 
    my ($self) = @_;

    my $res = $self->_send_request('GET', '/translate/service/languages');

    $res->is_error and return undef;

    my @langs;
    foreach my $lang ( @{ $res->response_struct->{elements} } ) {
        push @langs, WebService::MyGengo::Language->new( $lang );
    }

    return \@langs;
}

#=head2 _send_request( $http_method_name, $api_endpoint, [\%params] )
#
#Internal method that retrieves a request from the `request_factory`, sends
#it via the `_user_agent` and returns a L<WebService::MyGengo::Response> object.
#
#See POD for the individual methods to determine what they will return.
#
#The last raw API response object is stored in the Client's L<last_response>
#attribute.
#
#=cut
sub _send_request {
    my ( $self, @args ) = ( shift, @_ );

    my $req = $self->request_factory->new_request( @args );

    my $res = WebService::MyGengo::Response->new(
        $self->_user_agent->request( $req )
        );

    $self->_set_last_response( $res );

    return $res;
}


__PACKAGE__->meta->make_immutable();
1;

=head1 TODO

 * Add caching support

 * Make fetching of comments/feedback/revisions into global switches

 * Use concurrent requests to fetch jobs/comments/revisions/feedback/etc.

 * Support perl < 5.10? Necessary?

 * I'm not 100% sold on this implementation. I waffle back and forth on whether or not the real API objects should be able to do their own requesting /error handling/etc instead of this client.

=head1 ACKNOWLEDGEMENTS

Portions of this library are based on the original myGengo.pm library, available
here: L<https://github.com/myGengo/mygengo-perl-new>.

That library is Copyright (c) 2011 myGengo, Inc. (L<http://mygengo.com>) and
is available under the
L<http://mygengo.com/services/api/dev-docs/mygengo-code-license/> New BSD
License.

At the time of this writing the above link is broken. If any portion of this
library is in violation of the myGengo license please notify me.

=head1 SEE ALSO

myGengo API documentation: L<http://mygengo.com/api/developer-docs/>

This module on GitHub: L<https://github.com/nheinric/WebService--MyGengo>

=head1 AUTHOR

Nathaniel Heinrichs

=head1 LICENSE

Copyright (c) 2011, Nathaniel Heinrichs <nheinric-at-cpan.org>.
All rights reserved.

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
