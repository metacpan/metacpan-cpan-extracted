package WebService::Google::Client;
our $VERSION = '0.06';

# ABSTRACT: Server-side client library for any Google App API. Based on Moose

use Data::Dumper;
use Moose;
use WebService::Google::UserAgent;
use Log::Log4perl::Shortcuts qw(:all);

has 'client' => (
    is      => 'ro',
    default => sub { WebService::Google::UserAgent->new() },
    handles => [qw(access_token user auth_storage do_autorefresh api_query)],
    lazy    => 1
);
has 'util' => (
    is      => 'ro',
    default => sub {
        require WebService::Google::Client::Util;
        WebService::Google::Client::Util->new();
    },
    handles => [qw(substitute_placeholders)],
    lazy    => 1
);
has 'discovery' => (
    is      => 'ro',
    default => sub {
        require WebService::Google::Client::Discovery;
        WebService::Google::Client::Discovery->new();
    },
    handles => [qw(getMethodMeta)],
    lazy    => 1
);

has 'log_level' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'error',
    trigger => \&_set_ll
);

sub request {
    my ( $self, $caller, $params ) = @_;

    # my $caller = (caller(0))[3];
    logd( $caller, 'request_caller' );
    logd( $params, 'request_parameters' );

    my $api_q_data = $self->getMethodMeta($caller);
    $api_q_data->{options} = $params->{options};
    delete $params->{options};

    #warn 'API query data: ' . Dumper $api_q_data if ( $self->debug );

    # get $params from $caller object
    # proxying $self->Service->Resource attributes

    $api_q_data->{path} =
      $self->substitute_placeholders( $api_q_data->{path}, $params );    # util
         #warn 'API query data: ' . Dumper $api_q_data if ( $self->debug );
    $self->api_query($api_q_data);    # path, httpMethod
}

sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;
    my $unknown_resource =
      ( split( /::/, $AUTOLOAD ) )[-1];    # $unknown_method_name = API
         #    warn $unknown_resource if ( $self->debug );
    logd($unknown_resource);
    require WebService::Google::Client::Services;
    my $a = WebService::Google::Client::Services->new;

    #$a->debug( $self->debug );
    $a->generate_one( $self, lcfirst $unknown_resource );
    $self->$unknown_resource;
}

sub _set_ll {
    my $s = shift;
    set_log_level( $s->log_level );
}




1;

__END__

=pod

=head1 NAME

WebService::Google::Client - Server-side client library for any Google App API. Based on Moose

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    use WebService::Google::Client;

    my $gapi = WebService::Google::Client->new(log_level => 'debug');
    # my $gapi = WebService::Google::Client->new(access_token => '');
    my $user = 'resource_owner@gmail.com'; # full gmail

    $gapi->auth_storage->setup({type => 'jsonfile', path => '/path' }); # by default
    # $gapi->auth_storage->setup({ type => 'dbi', path => 'DBI object' });  # NOT IMPLEMENTED YET
    # $gapi->auth_storage->setup({ type => 'mongodb', path => 'details' }); # NOT IMPLEMENTED YET

    $gapi->user($user);
    $gapi->do_autorefresh(1);

    my $r1 = $gapi->Calendar->Events->list({ calendarId => 'primary' })->json;
    warn scalar @{$r1->{items}};

To create authorization file with tokens in current folder run I<goauth> CLI tool

See unit test in xt folder for more examples

=head1 DESCRIPTION

This module, still undergoing heavy development, provides an OAuth 2.0
server-side web application flow to all of the Google API services.

=head1 GETTING STARTED

To develop with this module, you must have a user account with Google as well as
a developer account both of which can be obtained from Google after acceoptance
of their terms and conditions. Consult Google for more information on
establishing these accounts.

Next, you will need to register a project with Google using the Google Developer
Console and create OAuth2 cient ID credentials for the project. This is
accomplished by first setting up a "consent screen." The consent screen is what
allows a resource owner (which will be just you, the developer, at first) to
give your Google project authorization to access their data using Google's API
calls. This consent screen does not have to be verified since it is not public.
Simply supply an "Application name" and hit "Save." Once done, finish the
process by creating an "Other" application type. Finally, you will need to
enable the various APIs and services you want your module to access on behalf of
the resource owners. Consult Google's documentation for more detailed
information on configuring your project and its APIS.

Once your project is set up with the OAuth 2.0 credentials and has APIs enabled,
you now need to ask the resource owner (in this case you) for permission to
access their data. This is done by using the C<goauth> utility in the C<bin>
directory of this module. Before using it, you need to manually configure the
scopes you will ask permission from the user to access. Unfortunately, these
scopes are hard coded into this module at the bottom of the
C<WebService/Google/Client/Server.pm> module in the C<__DATA__>. This will be
improved in the near future. Add your scopes to the C<scope> key. The scope is
a URL and are L<listed here|https://developers.google.com/identity/protocols/googlescopes>.

Once the scopes are added, execute the C<bin/goauth> script. It will prompt you
for the C<client_id> and C<client_secret> both which are available through the
Google console. Once entered, point your browser to C<127.0.0.1:3001> and click
on the "Click here to get Mojo tokens" link. Next log in and/or approve the
request to access your data for the scopes listed. Once the process is complete,
a C<config.json> file will be generated for you in your directory. This JSON
file contains the tokens used by this module to make API requests on behalf of
you, the resource owner.

Once you have verified you have everything working, you can set to work setting
up a public facing consent screen so C<WebService::Google::Client> can get scope
authorization from other resource owners and begin making API requests on their
behalf.

=head1 KEY FEATURES

=over 1

=item Object-oriented calls by API->Resource->method schema. Like $gapi->Calendar->Events->lists

=item Classes are generated dynamically using L<Moose::Meta::Class> based on Google API Discovery Service

=item Different app credentials (client_id, client_secret, users access_token && refresh_token) storage - json file, DBI, MongoDB (u can add your own even)

=item Automatic access_token refresh (if user has refresh_token) and saving refreshed token to storage

=item CLI tool (I<goauth>) with lightweight server for easy OAuth2 authorization and getting access_ and refresh_ tokens

=back

=head1 SUPPORTED APIs

    SERVICE                     VERSIONS                                   DOCUMENTATION
    abusiveexperiencereport     v1                                         https://developers.google.com/abusive-experience-report/
    acceleratedmobilepageurl    v1                                         https://developers.google.com/amp/cache/
    adexchangebuyer             v1.2, v1.3, v1.4                           https://developers.google.com/ad-exchange/buyer-rest
    adexchangebuyer2            v2beta1                                    https://developers.google.com/ad-exchange/buyer-rest/reference/rest/
    adexperiencereport          v1                                         https://developers.google.com/ad-experience-report/
    admin                       datatransfer_v1, directory_v1, reports_v1  https://developers.google.com/admin-sdk/data-transfer/, https://developers.google.com/admin-sdk/directory/, https://developers.google.com/admin-sdk/reports/
    adsense                     v1.4                                       https://developers.google.com/adsense/management/
    adsensehost                 v4.1                                       https://developers.google.com/adsense/host/
    analytics                   v2.4, v3                                   https://developers.google.com/analytics/
    analyticsreporting          v4                                         https://developers.google.com/analytics/devguides/reporting/core/v4/
    androiddeviceprovisioning   v1                                         https://developers.google.com/zero-touch/
    androidenterprise           v1                                         https://developers.google.com/android/work/play/emm-api
    androidmanagement           v1                                         https://developers.google.com/android/management
    androidpublisher            v1, v1.1, v2, v3                           https://developers.google.com/android-publisher
    appengine                   v1alpha, v1beta, v1, v1beta4, v1beta5      https://cloud.google.com/appengine/docs/admin-api/
    appsactivity                v1                                         https://developers.google.com/google-apps/activity/
    appstate                    v1                                         https://developers.google.com/games/services/web/api/states
    bigquery                    v2                                         https://cloud.google.com/bigquery/
    bigquerydatatransfer        v1                                         https://cloud.google.com/bigquery/
    binaryauthorization         v1beta1                                    https://cloud.google.com/binary-authorization/
    blogger                     v2, v3                                     https://developers.google.com/blogger/docs/2.0/json/getting_started, https://developers.google.com/blogger/docs/3.0/getting_started
    books                       v1                                         https://developers.google.com/books/docs/v1/getting_started
    calendar                    v3                                         https://developers.google.com/google-apps/calendar/firstapp
    chat                        v1                                         https://developers.google.com/hangouts/chat
    civicinfo                   v2                                         https://developers.google.com/civic-information
    classroom                   v1                                         https://developers.google.com/classroom
    cloudasset                  v1beta1                                    https://console.cloud.google.com/apis/api/cloudasset.googleapis.com/overview
    cloudbilling                v1                                         https://cloud.google.com/billing/
    cloudbuild                  v1alpha1, v1                               https://cloud.google.com/cloud-build/docs/
    clouddebugger               v2                                         https://cloud.google.com/debugger
    clouderrorreporting         v1beta1                                    https://cloud.google.com/error-reporting/
    cloudfunctions              v1, v1beta2                                https://cloud.google.com/functions
    cloudiot                    v1, v1beta1                                https://cloud.google.com/iot
    cloudkms                    v1                                         https://cloud.google.com/kms/
    cloudprofiler               v2                                         https://cloud.google.com/profiler/
    cloudresourcemanager        v1, v1beta1, v2, v2beta1                   https://cloud.google.com/resource-manager
    cloudshell                  v1alpha1, v1                               https://cloud.google.com/shell/docs/
    cloudtasks                  v2beta2, v2beta3                           https://cloud.google.com/tasks/
    cloudtrace                  v2alpha1, v1, v2                           https://cloud.google.com/trace
    composer                    v1, v1beta1                                https://cloud.google.com/composer/
    compute                     alpha, beta, v1                            https://developers.google.com/compute/docs/reference/latest/
    container                   v1, v1beta1                                https://cloud.google.com/container-engine/
    content                     v2sandbox, v2                              https://developers.google.com/shopping-content
    customsearch                v1                                         https://developers.google.com/custom-search/v1/using_rest
    dataflow                    v1b3                                       https://cloud.google.com/dataflow
    dataproc                    v1, v1beta2                                https://cloud.google.com/dataproc/
    datastore                   v1, v1beta1, v1beta3                       https://cloud.google.com/datastore/
    deploymentmanager           alpha, v2beta, v2                          https://cloud.google.com/deployment-manager/, https://developers.google.com/deployment-manager/
    dfareporting                v2.8, v3.0, v3.1, v3.2                     https://developers.google.com/doubleclick-advertisers/
    dialogflow                  v2, v2beta1                                https://cloud.google.com/dialogflow-enterprise/
    digitalassetlinks           v1                                         https://developers.google.com/digital-asset-links/
    discovery                   v1                                         https://developers.google.com/discovery/
    dlp                         v2                                         https://cloud.google.com/dlp/docs/
    dns                         v1, v1beta2, v2beta1                       https://developers.google.com/cloud-dns
    doubleclickbidmanager       v1                                         https://developers.google.com/bid-manager/
    doubleclicksearch           v2                                         https://developers.google.com/doubleclick-search/
    drive                       v2, v3                                     https://developers.google.com/drive/
    file                        v1beta1                                    https://cloud.google.com/filestore/
    firebasedynamiclinks        v1                                         https://firebase.google.com/docs/dynamic-links/
    firebaserules               v1                                         https://firebase.google.com/docs/storage/security
    firestore                   v1, v1beta1, v1beta2                       https://cloud.google.com/firestore
    fitness                     v1                                         https://developers.google.com/fit/rest/
    fusiontables                v1, v2                                     https://developers.google.com/fusiontables
    games                       v1                                         https://developers.google.com/games/services/
    gamesConfiguration          v1configuration                            https://developers.google.com/games/services
    gamesManagement             v1management                               https://developers.google.com/games/services
    genomics                    v1alpha2, v2alpha1, v1                     https://cloud.google.com/genomics
    gmail                       v1                                         https://developers.google.com/gmail/api/
    groupsmigration             v1                                         https://developers.google.com/google-apps/groups-migration/
    groupssettings              v1                                         https://developers.google.com/google-apps/groups-settings/get_started
    iam                         v1                                         https://cloud.google.com/iam/
    iamcredentials              v1                                         https://cloud.google.com/iam/docs/creating-short-lived-service-account-credentials
    iap                         v1beta1                                    https://cloud.google.com/iap
    identitytoolkit             v3                                         https://developers.google.com/identity-toolkit/v3/
    indexing                    v3                                         https://developers.google.com/search/apis/indexing-api/
    jobs                        v3p1beta1, v2, v3                          https://cloud.google.com/talent-solution/job-search/docs/
    kgsearch                    v1                                         https://developers.google.com/knowledge-graph/
    language                    v1, v1beta1, v1beta2                       https://cloud.google.com/natural-language/
    licensing                   v1                                         https://developers.google.com/google-apps/licensing/
    logging                     v2, v2beta1                                https://cloud.google.com/logging/docs/
    manufacturers               v1                                         https://developers.google.com/manufacturers/
    mirror                      v1                                         https://developers.google.com/glass
    ml                          v1                                         https://cloud.google.com/ml/
    monitoring                  v3                                         https://cloud.google.com/monitoring/api/
    oauth2                      v1, v2                                     https://developers.google.com/accounts/docs/OAuth2
    oslogin                     v1alpha, v1beta, v1                        https://cloud.google.com/compute/docs/oslogin/rest/
    pagespeedonline             v1, v2, v4                                 https://developers.google.com/speed/docs/insights/v1/getting_started, https://developers.google.com/speed/docs/insights/v2/getting-started, https://developers.google.com/speed/docs/insights/v4/getting-started
    partners                    v2                                         https://developers.google.com/partners/
    people                      v1                                         https://developers.google.com/people/
    playcustomapp               v1                                         https://developers.google.com/android/work/play/custom-app-api
    plus                        v1                                         https://developers.google.com/+/api/
    plusDomains                 v1                                         https://developers.google.com/+/domains/
    poly                        v1                                         https://developers.google.com/poly/
    proximitybeacon             v1beta1                                    https://developers.google.com/beacons/proximity/
    pubsub                      v1beta1a, v1, v1beta2                      https://cloud.google.com/pubsub/docs
    redis                       v1, v1beta1                                https://cloud.google.com/memorystore/docs/redis/
    replicapool                 v1beta1                                    https://developers.google.com/compute/docs/replica-pool/
    replicapoolupdater          v1beta1                                    https://cloud.google.com/compute/docs/instance-groups/manager/#applying_rolling_updates_using_the_updater_service
    reseller                    v1                                         https://developers.google.com/google-apps/reseller/
    runtimeconfig               v1, v1beta1                                https://cloud.google.com/deployment-manager/runtime-configurator/
    safebrowsing                v4                                         https://developers.google.com/safe-browsing/
    script                      v1                                         https://developers.google.com/apps-script/api/
    searchconsole               v1                                         https://developers.google.com/webmaster-tools/search-console-api/
    servicebroker               v1alpha1, v1, v1beta1                      https://cloud.google.com/kubernetes-engine/docs/concepts/add-on/service-broker
    serviceconsumermanagement   v1                                         https://cloud.google.com/service-consumer-management/docs/overview
    servicecontrol              v1                                         https://cloud.google.com/service-control/
    servicemanagement           v1                                         https://cloud.google.com/service-management/
    servicenetworking           v1beta, v1                                 https://cloud.google.com/service-infrastructure/docs/service-networking/reference/rest/
    serviceusage                v1, v1beta1                                https://cloud.google.com/service-usage/
    serviceuser                 v1                                         https://cloud.google.com/service-management/
    sheets                      v4                                         https://developers.google.com/sheets/
    siteVerification            v1                                         https://developers.google.com/site-verification/
    slides                      v1                                         https://developers.google.com/slides/
    sourcerepo                  v1                                         https://cloud.google.com/source-repositories/docs/apis
    spanner                     v1                                         https://cloud.google.com/spanner/
    speech                      v1, v1beta1                                https://cloud.google.com/speech-to-text/docs/quickstart-protocol
    sqladmin                    v1beta4                                    https://cloud.google.com/sql/docs/reference/latest
    storage                     v1, v1beta1, v1beta2                       https://developers.google.com/storage/docs/json_api/
    storagetransfer             v1                                         https://cloud.google.com/storage/transfer
    streetviewpublish           v1                                         https://developers.google.com/streetview/publish/
    surveys                     v2                                         unavailable
    tagmanager                  v1, v2                                     https://developers.google.com/tag-manager/api/v1/, https://developers.google.com/tag-manager/api/v2/
    tasks                       v1                                         https://developers.google.com/google-apps/tasks/firstapp
    testing                     v1                                         https://developers.google.com/cloud-test-lab/
    texttospeech                v1, v1beta1                                https://cloud.google.com/text-to-speech/
    toolresults                 v1beta3                                    https://firebase.google.com/docs/test-lab/
    tpu                         v1alpha1, v1                               https://cloud.google.com/tpu/
    translate                   v2                                         https://code.google.com/apis/language/translate/v2/getting_started.html
    urlshortener                v1                                         https://developers.google.com/url-shortener/v1/getting_started
    vault                       v1                                         https://developers.google.com/vault
    videointelligence           v1p1beta1, v1, v1beta2                     https://cloud.google.com/video-intelligence/docs/
    vision                      v1p1beta1, v1p2beta1, v1                   https://cloud.google.com/vision/
    webfonts                    v1                                         https://developers.google.com/fonts/docs/developer_api
    webmasters                  v3                                         https://developers.google.com/webmaster-tools/
    websecurityscanner          v1alpha, v1beta                            https://cloud.google.com/security-scanner/
    youtube                     v3                                         https://developers.google.com/youtube/v3
    youtubeAnalytics            v1, v1beta1, v2                            http://developers.google.com/youtube/analytics/, https://developers.google.com/youtube/analytics
    youtubereporting            v1                                         https://developers.google.com/youtube/reporting/v1/reports/

=head1 BUGS AND LIMITATIONS

On 2018-10-03, this project was forked from the L<Moo::Google> project which
stagnated and has apparently been abandoned. As designed, this module does not
function with all possible Google API calls but will work with simpler API
calls.  However, to our knowledge, all API calls with the exception of batch API
calls, can be made via the lower level C<api_aquery> method. This is documented
here:

L<https://www.perlmonks.org/?node_id=1219833>

=head1 CONTRIBUTIONS AND BUG REPORTS

Please visit our L<GitHub project home
page|https://github.com/sdondley/WevService-Google-Client> to report bugs and
make contributions.

More thorough documentation on how to contribute is in the works.

=head1 SEE ALSO

L<API::Google> - my old lib

L<Google::API::Client> - source of inspiration

=head1 AUTHOR

Steve Dondley <s@dondley.com>

=head1 CONTRIBUTORS

=for stopwords Pavel Serikov dafinder

=over 4

=item *

Pavel Serikov <pavelsr@cpan.org>

=item *

Pavel Serikov <pavel.p.serikov@gmail.com>

=item *

dafinder <mattdw@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Steve Dondley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
