package WWW::ORCID::API::v2_0;

use strict;
use warnings;

our $VERSION = 0.0401;

use Moo;
use namespace::clean;

with 'WWW::ORCID::MemberAPI';

sub ops {
    +{
        'group-id-record' =>
            {get => 1, add => 1, delete => 1, get_pc => 1, update => 1},
        'activities' => {orcid => 1, get => 1},
        'address'    => {
            orcid  => 1,
            get    => 1,
            add    => 1,
            delete => 1,
            get_pc => 1,
            update => 1
        },
        'biography' => {orcid => 1, get => 1},
        'education' =>
            {orcid => 1, add => 1, delete => 1, get_pc => 1, update => 1},
        'education/summary' => {orcid => 1, get_pc => 1},
        'educations'        => {orcid => 1, get    => 1},
        'email'             => {orcid => 1, get    => 1},
        'employment' =>
            {orcid => 1, add => 1, delete => 1, get_pc => 1, update => 1},
        'employment/summary'   => {orcid => 1, get_pc => 1},
        'employments'          => {orcid => 1, get    => 1},
        'external-identifiers' => {
            orcid  => 1,
            get    => 1,
            add    => 1,
            delete => 1,
            get_pc => 1,
            update => 1
        },
        'funding' =>
            {orcid => 1, add => 1, delete => 1, get_pc => 1, update => 1},
        'funding/summary' => {orcid => 1, get_pc => 1},
        'fundings'        => {orcid => 1, get    => 1},
        'keywords'        => {
            orcid  => 1,
            get    => 1,
            add    => 1,
            delete => 1,
            get_pc => 1,
            update => 1
        },
        'other-names' => {
            orcid  => 1,
            get    => 1,
            add    => 1,
            delete => 1,
            get_pc => 1,
            update => 1
        },
        'peer-review' =>
            {orcid => 1, add => 1, delete => 1, get_pc => 1, update => 1},
        'peer-review/summary' => {orcid => 1, get_pc => 1},
        'peer-reviews'        => {orcid => 1, get    => 1},
        'person'              => {orcid => 1, get    => 1},
        'personal-details'    => {orcid => 1, get    => 1},
        'researcher-urls'     => {
            orcid  => 1,
            get    => 1,
            add    => 1,
            delete => 1,
            get_pc => 1,
            update => 1
        },
        'work' =>
            {orcid => 1, add => 1, delete => 1, get_pc => 1, update => 1},
        'work/summary' => {orcid => 1, get_pc => 1},
        'works'        => {orcid => 1, get    => 1, get_pc_bulk => 1},
    };
}

sub _build_api_url {
    $_[0]->sandbox
        ? 'https://api.sandbox.orcid.org/v2.0'
        : 'https://api.orcid.org/v2.0';
}

__PACKAGE__->install_helper_methods;

__END__

=pod

=head1 NAME

WWW::ORCID::API::v2_0 - A client for the ORCID 2.0 member API

=head1 CREATING A NEW INSTANCE

The C<new> method returns a new L<2.0 member API client|WWW::ORCID::API::v2_0>.

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

=head2 C<read_limited_token>

Return an access token with scope C</read-limited>.

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

=head2 C<add_address>

    $client->add_address($data, token => $token, orcid => $orcid);

Equivalent to:

    $client->add('address', $data, %opts)

=head2 C<update_address>

    $client->update_address($data, token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->update('address', $data, %opts)

=head2 C<delete_address>

    my $ok = $client->delete_address(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->delete('address', %opts)

=head2 C<biography>

    my $rec = $client->biography(token => $token, orcid => $orcid);

Equivalent to:

    $client->get('biography', %opts)

=head2 C<education>

    my $rec = $client->education(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->get('education', %opts)

=head2 C<add_education>

    $client->add_education($data, token => $token, orcid => $orcid);

Equivalent to:

    $client->add('education', $data, %opts)

=head2 C<update_education>

    $client->update_education($data, token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->update('education', $data, %opts)

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

=head2 C<add_employment>

    $client->add_employment($data, token => $token, orcid => $orcid);

Equivalent to:

    $client->add('employment', $data, %opts)

=head2 C<update_employment>

    $client->update_employment($data, token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->update('employment', $data, %opts)

=head2 C<delete_employment>

    my $ok = $client->delete_employment(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->delete('employment', %opts)

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

=head2 C<add_external_identifiers>

    $client->add_external_identifiers($data, token => $token, orcid => $orcid);

Equivalent to:

    $client->add('external-identifiers', $data, %opts)

=head2 C<update_external_identifiers>

    $client->update_external_identifiers($data, token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->update('external-identifiers', $data, %opts)

=head2 C<delete_external_identifiers>

    my $ok = $client->delete_external_identifiers(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->delete('external-identifiers', %opts)

=head2 C<funding>

    my $rec = $client->funding(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->get('funding', %opts)

=head2 C<add_funding>

    $client->add_funding($data, token => $token, orcid => $orcid);

Equivalent to:

    $client->add('funding', $data, %opts)

=head2 C<update_funding>

    $client->update_funding($data, token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->update('funding', $data, %opts)

=head2 C<delete_funding>

    my $ok = $client->delete_funding(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->delete('funding', %opts)

=head2 C<funding_summary>

    my $rec = $client->funding_summary(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->get('funding/summary', %opts)

=head2 C<fundings>

    my $rec = $client->fundings(token => $token, orcid => $orcid);

Equivalent to:

    $client->get('fundings', %opts)

=head2 C<group_id_record>

    my $recs = $client->group_id_record(token => $token);
    my $rec = $client->group_id_record(token => $token, put_code => '123');

Equivalent to:

    $client->get('group-id-record', %opts)

=head2 C<add_group_id_record>

    $client->add_group_id_record($data, token => $token);

Equivalent to:

    $client->add('group-id-record', $data, %opts)

=head2 C<update_group_id_record>

    $client->update_group_id_record($data, token => $token, put_code => '123');

Equivalent to:

    $client->update('group-id-record', $data, %opts)

=head2 C<delete_group_id_record>

    my $ok = $client->delete_group_id_record(token => $token, put_code => '123');

Equivalent to:

    $client->delete('group-id-record', %opts)

=head2 C<keywords>

    my $recs = $client->keywords(token => $token, orcid => $orcid);
    my $rec = $client->keywords(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->get('keywords', %opts)

=head2 C<add_keywords>

    $client->add_keywords($data, token => $token, orcid => $orcid);

Equivalent to:

    $client->add('keywords', $data, %opts)

=head2 C<update_keywords>

    $client->update_keywords($data, token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->update('keywords', $data, %opts)

=head2 C<delete_keywords>

    my $ok = $client->delete_keywords(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->delete('keywords', %opts)

=head2 C<other_names>

    my $recs = $client->other_names(token => $token, orcid => $orcid);
    my $rec = $client->other_names(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->get('other-names', %opts)

=head2 C<add_other_names>

    $client->add_other_names($data, token => $token, orcid => $orcid);

Equivalent to:

    $client->add('other-names', $data, %opts)

=head2 C<update_other_names>

    $client->update_other_names($data, token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->update('other-names', $data, %opts)

=head2 C<delete_other_names>

    my $ok = $client->delete_other_names(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->delete('other-names', %opts)

=head2 C<peer_review>

    my $rec = $client->peer_review(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->get('peer-review', %opts)

=head2 C<add_peer_review>

    $client->add_peer_review($data, token => $token, orcid => $orcid);

Equivalent to:

    $client->add('peer-review', $data, %opts)

=head2 C<update_peer_review>

    $client->update_peer_review($data, token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->update('peer-review', $data, %opts)

=head2 C<delete_peer_review>

    my $ok = $client->delete_peer_review(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->delete('peer-review', %opts)

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

=head2 C<add_researcher_urls>

    $client->add_researcher_urls($data, token => $token, orcid => $orcid);

Equivalent to:

    $client->add('researcher-urls', $data, %opts)

=head2 C<update_researcher_urls>

    $client->update_researcher_urls($data, token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->update('researcher-urls', $data, %opts)

=head2 C<delete_researcher_urls>

    my $ok = $client->delete_researcher_urls(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->delete('researcher-urls', %opts)

=head2 C<work>

    my $rec = $client->work(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->get('work', %opts)

=head2 C<add_work>

    $client->add_work($data, token => $token, orcid => $orcid);

Equivalent to:

    $client->add('work', $data, %opts)

=head2 C<update_work>

    $client->update_work($data, token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->update('work', $data, %opts)

=head2 C<delete_work>

    my $ok = $client->delete_work(token => $token, orcid => $orcid, put_code => '123');

Equivalent to:

    $client->delete('work', %opts)

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

