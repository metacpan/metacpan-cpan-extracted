package WWW::ORCID::API::v2_0_public;

use strict;
use warnings;

our $VERSION = 0.0401;

use utf8;
use Moo;
use namespace::clean;

with 'WWW::ORCID::API';

sub ops {
    +{
        'activities'           => {orcid => 1, get    => 1},
        'address'              => {orcid => 1, get    => 1, get_pc => 1},
        'biography'            => {orcid => 1, get    => 1},
        'education'            => {orcid => 1, delete => 1, get_pc => 1},
        'education/summary'    => {orcid => 1, get_pc => 1},
        'educations'           => {orcid => 1, get    => 1},
        'email'                => {orcid => 1, get    => 1},
        'employment'           => {orcid => 1, get_pc => 1},
        'employment/summary'   => {orcid => 1, get_pc => 1},
        'employments'          => {orcid => 1, get    => 1},
        'external-identifiers' => {orcid => 1, get    => 1, get_pc => 1},
        'funding'              => {orcid => 1, get_pc => 1},
        'funding/summary'      => {orcid => 1, get_pc => 1},
        'fundings'             => {orcid => 1, get    => 1},
        'keywords'             => {orcid => 1, get    => 1, get_pc => 1},
        'other-names'          => {orcid => 1, get    => 1, get_pc => 1},
        'peer-review'          => {orcid => 1, get_pc => 1},
        'peer-review/summary'  => {orcid => 1, get_pc => 1},
        'peer-reviews'         => {orcid => 1, get    => 1},
        'person'               => {orcid => 1, get    => 1},
        'personal-details'     => {orcid => 1, get    => 1},
        'researcher-urls'      => {orcid => 1, get    => 1, get_pc => 1},
        'work'                 => {orcid => 1, get_pc => 1},
        'work/summary'         => {orcid => 1, get_pc => 1},
        'works'                => {orcid => 1, get    => 1, get_pc_bulk => 1},
    };
}

sub _build_api_url {
    $_[0]->sandbox
        ? 'https://pub.sandbox.orcid.org/v2.0'
        : 'https://pub.orcid.org/v2.0';
}

__PACKAGE__->install_helper_methods;

__END__

=pod

=head1 NAME

WWW::ORCID::API::v2_0_public - A client for the ORCID 2.0 public API

=head1 CREATING A NEW INSTANCE

The C<new> method returns a new L<2.0 public API client|WWW::ORCID::API::v2_0_public>.

Arguments to new:

=head2 C<client_id>

Your ORCID client id (required).

=head2 C<client_secret>

Your ORCID client secret (required).

=head2 C<sandbox>

The client will talk to the L<ORCID sandbox API|https://api.sandbox.orcid.org/v2.0> if set to C<1>.

=head2 C<transport>

Specify the HTTP client to use. Possible values are L<LWP> or L<HTTP::Tiny>. Default is L<LWP>.

=head1 METHODS

=head2 C<client_id>

Returns the ORCID client id used by the client.

=head2 C<client_secret>

Returns the ORCID client secret used by the client.

=head2 C<sandbox>

Returns C<1> if the client is using the sandbox API, C<0> otherwise.

=head2 C<transport>

Returns what HTTP transport the client is using.

=head2 C<api_url>

Returns the base API url used by the client.

=head2 C<oauth_url>

Returns the base OAuth url used by the client.

=head2 C<access_token>

Request a new access token.

    my $token = $client->access_token(
        grant_type => 'client_credentials',
        scope => '/read-public',
    );

=head2 C<authorize_url>

Helper that returns an authorization url for 3-legged OAuth requests.

    # in your web application
    redirect($client->authorize_url(
        show_login => 'true',
        scope => '/person/update',
        response_type => 'code',
        redirect_uri => 'http://your.callback/url',
    ));

See the C</authorize> and C</authorized> routes in the included playground
application for an example.

=head2 C<record_url>

Helper that returns an orcid record url.

    $client->record_url('0000-0003-4791-9455')
    # returns
    # http://orcid.org/0000-0003-4791-9455
    # or
    # http://sandbox.orcid.org/0000-0003-4791-9455

=head2 C<read_public_token>

Return an access token with scope C</read-public>.

=head2 C<client>

Get details about the current client.

=head2 C<search>

    my $hits = $client->search(q => "johnson");
=head2 C<activities>

    my $rec = $client->activities(token => $token, orcid => $orcid);

Equivalent to:

    $client->get('activities', %opts)

=head2 C<address>

    my $recs = $client->address(token => $token, orcid => $orcid);
    my $rec = $client->address(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->get('address', %opts)

=head2 C<biography>

    my $rec = $client->biography(token => $token, orcid => $orcid);

Equivalent to:

    $client->get('biography', %opts)

=head2 C<education>

    my $rec = $client->education(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->get('education', %opts)

=head2 C<delete_education>

    my $ok = $client->delete_education(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->delete('education', %opts)

=head2 C<education_summary>

    my $rec = $client->education_summary(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->get('education/summary', %opts)

=head2 C<educations>

    my $rec = $client->educations(token => $token, orcid => $orcid);

Equivalent to:

    $client->get('educations', %opts)

=head2 C<email>

    my $rec = $client->email(token => $token, orcid => $orcid);

Equivalent to:

    $client->get('email', %opts)

=head2 C<employment>

    my $rec = $client->employment(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->get('employment', %opts)

=head2 C<employment_summary>

    my $rec = $client->employment_summary(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->get('employment/summary', %opts)

=head2 C<employments>

    my $rec = $client->employments(token => $token, orcid => $orcid);

Equivalent to:

    $client->get('employments', %opts)

=head2 C<external_identifiers>

    my $recs = $client->external_identifiers(token => $token, orcid => $orcid);
    my $rec = $client->external_identifiers(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->get('external-identifiers', %opts)

=head2 C<funding>

    my $rec = $client->funding(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->get('funding', %opts)

=head2 C<funding_summary>

    my $rec = $client->funding_summary(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->get('funding/summary', %opts)

=head2 C<fundings>

    my $rec = $client->fundings(token => $token, orcid => $orcid);

Equivalent to:

    $client->get('fundings', %opts)

=head2 C<keywords>

    my $recs = $client->keywords(token => $token, orcid => $orcid);
    my $rec = $client->keywords(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->get('keywords', %opts)

=head2 C<other_names>

    my $recs = $client->other_names(token => $token, orcid => $orcid);
    my $rec = $client->other_names(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->get('other-names', %opts)

=head2 C<peer_review>

    my $rec = $client->peer_review(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->get('peer-review', %opts)

=head2 C<peer_review_summary>

    my $rec = $client->peer_review_summary(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->get('peer-review/summary', %opts)

=head2 C<peer_reviews>

    my $rec = $client->peer_reviews(token => $token, orcid => $orcid);

Equivalent to:

    $client->get('peer-reviews', %opts)

=head2 C<person>

    my $rec = $client->person(token => $token, orcid => $orcid);

Equivalent to:

    $client->get('person', %opts)

=head2 C<personal_details>

    my $rec = $client->personal_details(token => $token, orcid => $orcid);

Equivalent to:

    $client->get('personal-details', %opts)

=head2 C<researcher_urls>

    my $recs = $client->researcher_urls(token => $token, orcid => $orcid);
    my $rec = $client->researcher_urls(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->get('researcher-urls', %opts)

=head2 C<work>

    my $rec = $client->work(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->get('work', %opts)

=head2 C<work_summary>

    my $rec = $client->work_summary(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->get('work/summary', %opts)

=head2 C<works>

    my $recs = $client->works(token => $token, orcid => $orcid);
    my $recs = $client->works(token => $token, orcid => $orcid, put_code => ['123', '456']);

Equivalent to:

    $client->get('works', %opts)

=head2 C<last_error>

Returns the last error returned by the ORCID API, if any.

=head2 C<log>

Returns the L<Log::Any> logger.

=cut

