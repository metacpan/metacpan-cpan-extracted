package WebService::MyGengo::Test::Mock::LWP;

use Moose;
use MooseX::NonMoose;

extends 'LWP::UserAgent';

use WebService::MyGengo::Job;
use WebService::MyGengo::Comment;
use WebService::MyGengo::Revision;

use URI::Escape;
use JSON;
use Data::Dumper;

=head1 NAME

WebService::MyGengo::Test::Mock::LWP - A mock LWP for testing the WebService::MyGengo API

=head1 DESCRIPTION

Sending too many requests to the myGengo sandbox results in account throttling.

Luckily, we don't really have to interact with the real Sandbox to use
automated testing!

This mock library accepts an L<HTTP::Request> object from L<WebService::MyGengo::Client>
and returns success or failure responses based on certain flags in the request.

=head1 SYNOPSIS

Also see L<WebService::MyGengo::Test::Util::Client> in the t/lib directory.

    # t/001-blah.t
    use WebService::MyGengo::Client;
    use WebService::MyGengo::Test::Mock::LWP;

    # Your normal testing configuration
    my $config = {
        public_key      => 'real-pubkey"
        , private_key   => 'real-privkey'
        , use_sandbox   => 1
        };

    my $client = WebService::MyGengo::Client->new( $config );
    my $ua = WebService::MyGengo::Test::Mock::LWP->new();
    $client->_set_user_agent( $ua ); # For testing purposes only

    # A mocked WebService::MyGengo::Account object
    my $acct = $client->get_account();

    # From here on out, any subsequent calls will return a successful response
    $client->public_key( 'OK' );

    # From here on out, any subsequent calls will return API errors
    $client->public_key( 'APIFAIL' );

    # From here on out, any subsequent calls will return Internal server errors
    $client->public_key( 'SERVFAIL' );

    # To revert to normal functioning, build a fresh client
    $client = WebService::MyGengo::Client->new( $config );

=head1 public_key FLAG

Some methods do not accept any parameters, so their responses must be
managed using the value of the public_key as a flag (as in the synopsis.)

Because the public key is passed in cleartext in API requests, we can
capture and evaluate it here to determine what kind of response
to return.

The default is "OK".

=over

=item OK = A valid API response.

=item APIFAIL = Failure at the API level. Returns a valid API response with the
'opstat' parameter set to 'error' and an API error code in the response body.

=item SERVFAIL = Failure at the server level. Returns an HTTP 500 response for
now.

=back

B<Don't forget to check the pubkey value before troubleshooting other failing
tests!>

=head1 ATTRIBUTES

=head2 DEBUG (Bool)

Set to true to enable (verbose and oogly) debugging to STDERR

=cut
has DEBUG => ( is => 'rw', isa => 'Bool', default => 0 );

=head2 next_job_id (Int)

Used to increment the IDs of new Jobs.

Starts at 1.

=cut
has _last_job_id => ( is => 'rw', isa => 'Int', default => 0 );
sub next_job_id {
    my ( $self ) = ( shift );
    my $id = $self->_last_job_id + 1;
    return $self->_last_job_id( $id );
}

=head2 next_group_id (Int)

Used to increment the IDs of new Job groups.

Starts at 1.

=cut
has _last_group_id => ( is => 'rw', isa => 'Int', default => 0 );
sub next_group_id {
    my ( $self ) = ( shift );
    my $id = $self->_last_group_id + 1;
    return $self->_last_group_id( $id );
}

=head2 _jobs (HashRef)

Houses Jobs that have been POSTed so we can return them later

Provides jobs, get_jobs( \@keys ) and delete_jobs(\@keys) methods.

Also see L<add_job> method.

=cut
has '_jobs' => (
    traits => ['Hash']
    , is => 'ro'
    , isa => 'HashRef[WebService::MyGengo::Job]'
    , lazy       => 1
    , init_arg => undef
    , default => sub { {} }
    , handles => {
        jobs                => 'values'
        , get_jobs          => 'get'
        , _set_jobs         => 'set' # use public add_job instead
        , delete_jobs       => 'delete'
        }
    );

=head2 _responses (HashRef)

Houses the various response structures for use in creating suitable
L<HTTP::Response> objects for each API call.

=cut
has _responses => (
    is          => 'ro'
    , isa       => 'HashRef'
    , init_arg  => undef
    , lazy      => 1
    , builder   => '_build__responses'
    );
sub _build__responses {
    return {
    404 => { code => 404, message => "Not Found" }
    , SERVFAIL => { code => 500, message => "Internal server error." } # todo
    , APIFAIL => {
        code => 200
        , message => "OK"
        , opstat => 'error'
        , err => {
            code => 2250
            , msg => 'job is not reviewable'
            }
        }
    , OK => {
        "/account/stats" => {
            code => 200
            , message => "OK"
            , opstat => "ok"
            , response => {
                "credits_spent" => "1023.31"
                , "user_since"  => 1234089500
                }
            }
        , "/account/balance" => {
            code => 200
            , message => "OK"
            , opstat => "ok"
            , response => { "credits" => "25.32" }
            }
        , "GET/translate/job" => {
            code => 200
            , message => "OK"
            , opstat => "ok"
            , response => { "job" => {} }
            }
        , "GET/translate/job/comments" => {
            code => 200
            , message => "OK"
            , opstat => "ok"
            , response => { "thread" => [] }
            }
        , "GET/translate/job/revisions" => {
            code => 200
            , message => "OK"
            , opstat => "ok"
            , response => { "revisions" => [] }
            }
        , "GET/translate/job/feedback" => {
            code => 200
            , message => "OK"
            , opstat => "ok"
            , response => { "feedback" => {} }
            }
        , "GET/translate/job/revision" => {
            code => 200
            , message => "OK"
            , opstat => "ok"
            , response => { "revision" => {} }
            }
        , "POST/translate/job" => {
            code => 200
            , message => "OK"
            , opstat => "ok"
            , response => { "job" => {} }
            }
        , "PUT/translate/job" => {
            code => 200
            , message => "OK"
            , opstat => "ok"
            , response => { }
            }
        , "POST/translate/job/comment" => {
            code => 200
            , message => "OK"
            , opstat => "ok"
            , response => {}
            }
        , "DELETE/translate/job" => {
            code => 200
            , message => "OK"
            , opstat => "ok"
            }
        , "GET/translate/jobs" => {
            code => 200
            , message => "OK"
            , opstat => "ok"
            , response => []
            }
        , "GET/translate/jobs/specific" => {
            code => 200
            , message => "OK"
            , opstat => "ok"
            , response => { jobs => [] }
            }
        , "POST/translate/jobs" => {
            code => 200
            , message => "OK"
            , opstat => "ok"
            , response => { "jobs" => [] }
            }
        , "POST/translate/service/quote" => {
            code => 200
            , message => "OK"
            , opstat => "ok"
            , response => { "jobs" => {} }
            }
        , "/translate/service/language_pairs" => {
            code => 200
            , message => "OK"
            , opstat => "ok"
            , response => [
                {"lc_src" => "de", "lc_tgt" => "en", "tier" => "standard", "unit_price" => "0.0500"}
                , {"lc_src" => "de", "lc_tgt" => "en","tier" => "pro", "unit_price" => "0.1000"}
                , {"lc_src" => "de", "lc_tgt" => "en", "tier" => "ultra", "unit_price" => "0.1500"}
                , {"lc_src" => "en", "lc_tgt" => "de", "tier" => "standard", "unit_price" => "0.0500"}
                , {"lc_src" => "en", "lc_tgt" => "de", "tier" => "pro", "unit_price" => "0.1000"}
                , {"lc_src" => "en", "lc_tgt" => "de", "tier" => "ultra", "unit_price" => "0.1500"}
                , {"lc_src" => "en", "lc_tgt" => "de", "tier" => "machine", "unit_price" => "0.0000"}
                , {"lc_src" => "en", "lc_tgt" => "es","tier" => "standard", "unit_price" => "0.0500"}
                ]
            }
        , "/translate/service/languages" => {
            code => 200
            , message => "OK"
            , opstat => "ok"
            , response => [
                {"language" => "English", "localized_name" => "English", "lc" => "en", "unit_type" => "word"}
                , {"language" => "Japanese", "localized_name" => "\u65e5\u672c\u8a9e", "lc" => "ja", "unit_type" => "character"}
                , {"language" => "Spanish (Spain)", "localized_name" => "Espa\u00f1ol", "lc" => "es", "unit_type" => "word"}
                , {"language" => "Chinese (Simplified)", "localized_name" => "\u4e2d\u6587", "lc" => "zh", "unit_type" => "character"}
                , {"language" => "German", "localized_name" => "Deutsch", "lc" => "de", "unit_type" => "word"}
                , {"language" => "French", "localized_name" => "Fran\u00e7ais", "lc" => "fr", "unit_type" => "word"}
                , {"language" => "Italian", "localized_name" => "Italiano", "lc" => "it", "unit_type" => "word"}
                , {"language" => "Portuguese (Brazil)", "localized_name" => "Portugu\u00eas Brasileiro", "lc" => "pt-br", "unit_type" => "word"}
                , {"language" => "Spanish (Latin America)", "localized_name" => "Espa\u00f1ol (Am\u00e9rica Latina)", "lc" => "es-la", "unit_type" => "word"}
                , {"language" => "Portuguese (Europe)", "localized_name" => "Portugu\u00eas Europeu", "lc" => "pt", "unit_type" => "word"}
                ]
            }
        }
    };
}

=head1 METHODS
=cut

#=head2 _get_response_struct( $method, [$type] )
#
#Returns a response structure from the _responses structure.
#
#If $type is supplied, returns that type of response.
#
#Otherwise uses the value of 'api_key' (the public key) from
#`$request->uri->query_form`.
#
#todo Determine $method from caller()
#
#=cut
sub _get_response_struct {
    my ( $self, $method, $type ) = ( shift, @_ );

    # Use copies so we don't destroy shared structures
    my %struct  = $type eq 'OK'
                    ? %{ $self->_responses->{$type}->{$method} }
                    : %{ $self->_responses->{$type} }
                    ;
    $self->_debug("_get_response_struct('$method','$type'): ", %struct);

    my $code    = delete($struct{code});
    my $message = delete($struct{message}) || '';
    my $headers = delete($struct{headers}) || [];
    my $body    = keys %struct ? \%struct : '';

    return ( $code, $message, $headers, $body );
}

=head2 request( $HTTP::Request )

Overrides `request` in L<LWP::UserAgent> to return our mocked responses.

Defaults to returning 'OK' responses.

See L<SYNOPSIS>

=cut
sub request {
    my ( $self, $req ) = ( shift, @_ );

    my $uri     = $req->uri; 
    my $method  = $req->method;
    my $path    = $uri->path;
    my %params  = $uri->query_form; # Clobbers duplicate fields, but we don't care

    # See if the params are in the content, instead
    if ( !exists($params{api_key}) ) {
        use HTTP::Message;
        my $mess = HTTP::Message->new( $req->headers, $req->content );
        my $cont = $mess->decoded_content;

        my $u = URI->new($req->uri."?".$cont);
        %params = $u->query_form;
    }

    my $key     = $params{api_key};
    my $type    = (length($key) > 8 || $key eq 'pubkey') ? "OK" : $key;
    my $data    = $params{data}
                    ? from_json( uri_unescape($params{data}), { utf8 => 1 } )
                    : {};
    @$data{ keys %params } = values %params;

    $self->_debug("request '$uri' '$method' '$path' '$type' ", $data);

    # todo Ugly, but works for now
    if ( $path =~ m#(/account/(stats|balance))# ) {
        return _compose_response( $self->_get_response_struct( $1, $type ) );
    }
    elsif ( $path =~ m#(/translate/service/languages)# ) {
        return _compose_response( $self->_get_response_struct( $1, $type ) );
    }
    elsif ( $path =~ m#(/translate/service/language_pairs)# ) {
        my ($code, $message, $headers, $body)
            = $self->_get_response_struct( $1, $type );
        if ( my $lang = $params{lc_src} ) {
            my @pairs = grep { $_->{lc_src} eq $lang } @{$body->{response}};
            $body->{response} = \@pairs;
        }
        $self->_debug("_process_GET_job_request", $code, $message, $headers, $body);
        return _compose_response( $code, $message, $headers, $body );
    }
    elsif ( $path =~ m#/translate/job/# ) {
        my $meth = $self->can("_process_".$method."_job_request");
        return $self->$meth( $path, $type, $data );
    }
    elsif ( $path =~ m#/translate/jobs/?# ) {
        my $meth = $self->can("_process_".$method."_jobs_request");
        return $self->$meth( $path, $type, $data );
    }
    elsif ( $path =~ m#/translate/service/quote# ) {
        my $meth = $self->can("_process_".$method."_service_quote_request");
        return $self->$meth( $path, $type, $data );
    }
    else {
        $self->_debug("Cannot route request for '$path'");
        return _compose_response( $self->_get_response_struct( '', '404' ) );
    }
}

sub _process_GET_job_request {
    my ( $self, $path, $type, $params ) = ( shift, @_ );

    my @parts   = split "/", $path;
    my $job_id  = $parts[4];
    my $method  = sprintf('GET/%s/%s', @parts[2..3]);

    my $job = $self->get_jobs( $job_id );
    $self->_debug("_process_GET_job_request ", @_);

    $type ne 'OK'
        and return _compose_response( $self->_get_response_struct( $method, $type ) );
    !$job
        and return _compose_response( $self->_get_response_struct($method, 'APIFAIL') );

    # We're GETting a job
    if ( $#parts == 4 ) {
        my ($code, $message, $headers, $body)
            = $self->_get_response_struct( $method, $type );
        my $hash = $job->to_hash( [] );
        delete $hash->{comment};
        $body->{response}->{job} = $hash;
        $self->_debug("_process_GET_job_request", $code, $message, $headers, $body);
        return _compose_response( $code, $message, $headers, $body );
    }
    # We're GETting some Job comments
    elsif ( $parts[5] eq 'comments' ) {
        my $method  = sprintf('GET/%s/%s/%s', @parts[2..3, 5]);
        my ($code, $message, $headers, $body)
            = $self->_get_response_struct( $method, $type );

        $body->{response}->{thread} = [ map { $_->to_hash } $job->comments ];
        $self->_debug("_process_GET_job_request comments", $code, $message, $headers, $body);
        return _compose_response( $code, $message, $headers, $body );
    }
    elsif ( $parts[5] eq 'feedback' ) {
        # It seems like we should need an approved Job,
        #   but in testing the sandbox sent feedback for any
        #   Job we tried.
        my $method  = sprintf('GET/%s/%s/%s', @parts[2..3, 5]);
        my ($code, $message, $headers, $body)
            = $self->_get_response_struct( $method, $type );

        $body->{response}->{feedback} = $job->feedback->to_hash([]);
        $self->_debug("_process_GET_job_request feedback", $code, $message, $headers, $body);
        return _compose_response( $code, $message, $headers, $body );
    }
    # We're GETting some Job revisions
    elsif ( $parts[5] eq 'revisions' && !defined($parts[6]) ) {
        my $method  = sprintf('GET/%s/%s/%s', @parts[2..3, 5]);
        my ($code, $message, $headers, $body)
            = $self->_get_response_struct( $method, $type );

        $body->{response}->{revisions} = [
            map { $_->to_hash( [qw/ctime rev_id/] ) } $job->revisions
            ];
        $self->_debug("_process_GET_job_request revisions", $code, $message, $headers, $body);
        return _compose_response( $code, $message, $headers, $body );
    }
    elsif ( $parts[5] eq 'revision' && defined($parts[6]) ) {
        my $method  = sprintf('GET/%s/%s/%s', @parts[2..3, 5]);
        my ($code, $message, $headers, $body)
            = $self->_get_response_struct( $method, $type );

        $body->{response}->{revision}
            = $job->get_revision($parts[6])->to_hash([qw/ctime body_tgt/]);
        $self->_debug("_process_GET_job_request revision", $code, $message, $headers, $body);
        return _compose_response( $code, $message, $headers, $body );
    }
    else {
        Carp::confess("Bad _process_GET_job_request: ".Dumper(\@_));
    }
#    return $self->_signAndRequest('GET', '/translate/job/'.$id);
#    return $self->_signAndRequest('GET', '/translate/job/'.$id.'/comments');
#    return $self->_signAndRequest('GET', '/translate/job/'.$id.'/feedback');
#    return $self->_signAndRequest('GET', '/translate/job/'.$id.'/revisions');
#    return $self->_signAndRequest('GET', '/translate/job/'.$id.'/revisions/'.$revision_id);
}

sub _process_POST_job_request {
    my ( $self, $path, $type, $params ) = ( shift, @_ );

    my @parts   = split "/", $path;

    $self->_debug("_process_POST_job_request: ", @_);

    # We POSTed a new Job. Store and return it.
    if ( $#parts == 3 ) {
        my $method = sprintf('POST/%s/%s', @parts[2..3]);

        my ($code, $message, $headers, $body) =
            $self->_get_response_struct( $method, $type );

        $type ne 'OK' and
            return _compose_response( $code, $message, $headers, $body );

        my $job = $self->add_job( $params->{job} );

        my $hash = $job->to_hash( [] );
        delete $hash->{comment};
        $body->{response}->{job} = $hash;
        return _compose_response( $code, $message, $headers, $body );
    }
    # POSTing comments doesn't return a response struct
    elsif ( $#parts == 5 ) {
        my $job_id  = $parts[4];
        my $method = sprintf('POST/%s/%s/%s', @parts[2..3, 5]);
        my ($code, $message, $headers, $body) =
            $self->_get_response_struct( $method, $type );
        if ( $type eq 'OK' ) {
            my $comment = WebService::MyGengo::Comment->new({
                body        => $params->{body}
                , author    => 'customer'
                , ctime     => time()
                });
            $self->get_jobs($job_id)->_add_comment( $comment );
        }
        return _compose_response( $code, $message, $headers, $body );
    }
    else {
        Carp::confess("Bad _process_POST_job_request: ".Dumper(\@_));
    }
#    return $self->_signAndSend('POST', '/translate/job/', {job => $job});
#    return $self->_signAndSend('POST', '/translate/job', $jobs);
#    return $self->_signAndSend('POST', '/translate/job/'.$id.'/comment', {
}

sub _process_PUT_job_request {
    my ( $self, $path, $type, $params ) = ( shift, @_ );
    $self->_debug("_process_PUT_job_request: ", @_);

    my @parts   = split "/", $path;
    my $method = sprintf('PUT/%s/%s', @parts[2..3]);
    my $job = $self->get_jobs( $parts[4] );

    $type ne 'OK'
        and return _compose_response( $self->_get_response_struct($method, $type) );
    !( $job && $job->is_reviewable )
        and return _compose_response( $self->_get_response_struct($method, 'APIFAIL') );

    my ($code, $message, $headers, $body) =
        $self->_get_response_struct( $method, $type );

    my $action = $params->{action};

    # todo cloning/modifying a Job is difficult unless we rw some of the attributes...
    my $new_job_hash = $job->to_hash( [] );
    my $new_job;
    if ( $action eq 'revise' ) {
        $new_job_hash->{status} = 'revising';
        $new_job = WebService::MyGengo::Job->new( $new_job_hash );
        $job->has_comments and
            $new_job->_add_comment( $_ ) foreach ( $job->comments );
        $new_job->_add_comment( WebService::MyGengo::Comment->new({
            body => $params->{comment}
            , ctime => time()
            , author => 'customer'
            } ) )
    }
    elsif ( $action eq 'approve' ) {
        $new_job_hash->{status} = 'approved';
        $new_job_hash->{body_tgt} = 'Simulated translation';
        $new_job = WebService::MyGengo::Job->new( $new_job_hash );
        $job->has_comments and
            $new_job->_add_comment( $_ ) foreach ( $job->comments );
        my $fb = $job->feedback;
        $fb = WebService::MyGengo::Feedback->new({
            rating => "3.0", for_translator => $params->{for_translator}
            });
        $new_job->_set_feedback( $fb );
    }
    elsif ( $action eq 'reject' ) {
        $new_job_hash->{status} = 'rejected';
        $new_job = WebService::MyGengo::Job->new( $new_job_hash );

        my @comments  = $job->comments;
        push @comments, WebService::MyGengo::Comment->new( $params->{comment} );
        $new_job->_set_comments( \@comments );
    }
    else {
        Carp::confess("Bad _process_PUT_job_request: ".Dumper(\@_));
    }

    $self->_set_jobs( $job->id, $new_job );

    return _compose_response( $code, $message, $headers, $body );
#    return _signandsend('put', '/translate/job/'.$id, $statusobj);
}

sub _process_DELETE_job_request {
    my ( $self, $path, $type, $params ) = ( shift, @_ );

    my @parts   = split "/", $path;

    $self->_debug("_process_DELETE_job_request: ", @parts);
    if ( $#parts == 4 ) {
        my $method = sprintf('DELETE/%s/%s', @parts[2..3]);

        # Can only cancel 'available' jobs
        my $job = $self->get_jobs( $parts[4] );
        !( $job && $job->is_available ) and $type = 'APIFAIL';

        my ($code, $message, $headers, $body) =
            $self->_get_response_struct( $method, $type );

        $type ne 'OK' and
            return _compose_response( $code, $message, $headers, $body );

        $self->delete_jobs( $job->id );
        return _compose_response( $code, $message, $headers, $body );
    }
    else {
        Carp::confess("Bad _process_DELETE_job_request: ".Dumper(\@_));
    }
#    return _signAndRequest('DELETE', '/translate/job/'.$id);
}

sub _process_GET_jobs_request {
    my ( $self, $path, $type, $params ) = ( shift, @_ );

    my @parts   = split "/", $path;
    my $method  = sprintf('GET/%s/%s', @parts[2..3]);

    my $stat_filter = $params->{status};
    my $ts_filter   = $params->{timestamp_after};
    my $count       = $params->{count};

    $self->_debug("_process_GET_jobs_request ", @parts, $params);

    $type ne 'OK'
        and return _compose_response( $self->_get_response_struct( $method, $type ) );

    # We're searching for Jobs
    if ( $#parts == 3 ) {
        my ($code, $message, $headers, $body)
            = $self->_get_response_struct( $method, $type );

        # todo Is ts filter >=? Or just >?
        # todo Is $count <=? Or <?
        my @jobs = $self->jobs;
        !@jobs and return _compose_response( $code, $message, $headers, $body );

        $stat_filter and @jobs = grep { $_->status eq $stat_filter } @jobs;
        $ts_filter and @jobs = grep { $_->ctime->epoch >= $ts_filter } @jobs;
        $count and @jobs = @jobs[0..($count > $#jobs ? $#jobs : $count)];

        @jobs = sort { $b->{job_id} <=> $a->{job_id} }
                map { { ctime => $_->ctime->epoch, job_id => $_->id } }
                @jobs;
        $body->{response} = \@jobs;
        $self->_debug("_process_GET_jobs_request", $code, $message, $headers, $body);
        return _compose_response( $code, $message, $headers, $body );
    }
    # We're GETting a specific list of Jobs
    elsif ( $#parts == 4 ) {
        $method .= "/specific";
        my @ids = split /,/, $parts[4];

        !scalar(@ids)
            and return _compose_response( $self->_get_response_struct($method, 'APIFAIL') );

        my @jobs = $self->get_jobs( @ids );

        my ($code, $message, $headers, $body)
            = $self->_get_response_struct( $method, $type );

        $body->{response}->{jobs} = [
            map { my $hash = $_->to_hash([]); delete $hash->{comment}; $hash; }
                @jobs
            ];

        $self->_debug("_process_GET_jobs_request", $code, $message, $headers, $body);
        return _compose_response( $code, $message, $headers, $body );
    }
    else {
        Carp::confess("Bad _process_GET_jobs_request: ".Dumper(\@_));
    }
#    return _signAndRequest('GET', '/translate/jobs/', {
#    return _signAndRequest('GET', '/translate/jobs/'.$id);
}

sub _process_POST_jobs_request {
    my ( $self, $path, $type, $params ) = ( shift, @_ );

    my @parts   = split "/", $path;

    $self->_debug("_process_POST_jobs_request: ", @_);

    my $method = sprintf('POST/%s/%s', @parts[2..3]);

    my ($code, $message, $headers, $body) =
        $self->_get_response_struct( $method, $type );

    $type ne 'OK' and
        return _compose_response( $code, $message, $headers, $body );

    my @jobs;
    my $i = 0;
    my $group_id = $params->{as_group} ? $self->next_group_id : undef;
    foreach ( @{ $params->{jobs} } ) {
        my $job = $self->add_job( $_ );

        my $hash = $job->to_hash([]);
        delete $hash->{comment};

        push @jobs, { $i++ => $hash };
    }

    $body->{response}->{jobs} = \@jobs;
    $group_id and $body->{response}->{group_id} = $group_id;
    $self->_debug("_process_POST_jobs_request", $code, $message, $headers, $body);
    return _compose_response( $code, $message, $headers, $body );
#    return _signAndSend('POST', '/translate/jobs', {
}

sub _process_PUT_jobs_request {
    my ( $self, $path, $type, $params ) = ( shift, @_ );
#    return _signAndSend('PUT', '/translate/jobs/', $jobsStatusObj);
}

sub _process_POST_service_quote_request {
    my ( $self, $path, $type, $params ) = ( shift, @_ );

    my @parts   = split "/", $path;

    $self->_debug("_process_POST_service_quote_request: ", @_);

    my $method = sprintf('POST/translate/service/quote', @parts[2..3]);

    my ($code, $message, $headers, $body) =
        $self->_get_response_struct( $method, $type );

    $type ne 'OK' and
        return _compose_response( $code, $message, $headers, $body );

    my $struct;
    foreach my $key ( keys %{ $params->{jobs} } ) {
        $struct->{$key} = { unit_count => 2, credits => 0.1 };
    }

    $body->{response}->{jobs} = $struct;
    $self->_debug("_process_POST_service_quote_request", $code, $message, $headers, $body);
    return _compose_response( $code, $message, $headers, $body );
#    return _signAndSend('POST', '/translate/service/quote', {
}

=head2 add_job( \%params )

Accepts a hashref of Job constructor parameters, creates a new
L<WebService::MyGengo::Job> from them and adds it to the internal _jobs hash
for later retrieval.

If certain values that the real API would set are not present in the
hash of parameters, sensible defaults will be set.

This allows you to create a Job with any parameters you like, while still
ensuring that a well-composed Job will be returned.

=cut
sub add_job {
    my ( $self, $params ) = ( shift, @_ );

    my %job             = %$params;
    $job{job_id}        //= $self->next_job_id;
    $job{ctime}         //= time();
    $job{eta}           //= 45101;
    $job{credits}       //= 10.1;
    $job{status}        //= "available"; # Hasnt been picked up by xlator
    $job{unit_count}    //= () = $job{body_src} =~ /\W/g; # cheap/dirty
    $job{lc_src} eq 'ja' and $job{unit_count} = length($job{body_src});

    my $new_job = WebService::MyGengo::Job->new(\%job);
    $job{comment} and $new_job->_set_comments([
        WebService::MyGengo::Comment->new({
            body        => $job{comment}
            , ctime     => $job{ctime}
            , author    => 'customer'
            })
        ]);

    # All new Jobs have at least 1 revision
    $new_job->_set_revisions([
        WebService::MyGengo::Revision->new({
            body_tgt    => rand()." Revision1"
            , ctime     => time()
            , rev_id    => 0
            })
        ]);

    # All Jobs have one Feedback entry
    $new_job->_set_feedback(
        WebService::MyGengo::Feedback->new({
            rating              => 3.0
            , for_translator    => undef
            })
        );

    $self->_set_jobs( $new_job->id => $new_job );

    return $new_job;
}

=head2 _debug( $message, @(objects)? )

If the DEBUG flag is true, outputs the $message and Data::Dumper output of all
(optionally provided) @objects to STDERR.

=cut
sub _debug {
    my ( $self ) = ( shift );

    return unless $self->DEBUG;
    no warnings 'uninitialized';

    my $msg;
    $msg .= (!(ref($_)) ? "'".$_."'" : Dumper($_))."\n"
        foreach ( @_ );

    print STDERR "$msg\n";
    use warnings 'uninitialized';
}

#=head1 FUNCTIONS
#
#=head2 _compose_response( $http_code, $message, \@headers|\%headers, $body )
#
#Composes an L<HTTP::Response> object.
#
#=cut
sub _compose_response {
    my ( $code, $message, $headers, $body ) = @_;

    my $content = ref($body) ? encode_json( $body || { utf8 => 1 } ) : '';

    return HTTP::Response->new( $code, $message, $headers, $content );
}


__PACKAGE__->meta->make_immutable();
1;

=head1 AUTHOR

Nathaniel Heinrichs

=head1 LICENSE

Copyright (c) 2011, Nathaniel Heinrichs <nheinric-at-cpan.org>.
All rights reserved.

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
