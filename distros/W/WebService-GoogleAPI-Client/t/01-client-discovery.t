#!perl -T

=head2 USAGE

To run manually in the local directory assuming gapi.json present in source root and in xt/author/calendar directory
  C<prove -I../lib 01-client-discovery.t -w -o -v>

NB: is also run as part of dzil test

=cut

use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;    ## remove this when finish tweaking
use Cwd;
use CHI;

my $dir   = getcwd;
my $DEBUG = 0;        ## to see noise of class debugging


use_ok( 'WebService::GoogleAPI::Client' );    #  || print "Bail out!\n";
use_ok( 'WebService::GoogleAPI::Client::Discovery' );


my $default_file = $ENV{ 'GOOGLE_TOKENSFILE' } || "$dir/../../gapi.json";    ## assumes running in a sub of the build dir by dzil
$default_file = "$dir/../gapi.json" unless -e $default_file;                 ## if file doesn't exist try one level up ( allows to run directly from t/ if gapi.json in parent dir )
my $user = $ENV{ 'GMAIL_FOR_TESTING' } || '';                                ## will be populated by first available if set to '' and default_file exists


subtest 'WebService::GoogleAPI::Client::Discovery class properties' => sub {
  ok(
    ref WebService::GoogleAPI::Client::Discovery->new->ua eq 'WebService::GoogleAPI::Client::UserAgent',
    'ua property (WebService::GoogleAPI::Client::Discovery->new->ua) is of type WebService::GoogleAPI::Client::UserAgent'
  );
  ok(
    ref( WebService::GoogleAPI::Client::Discovery->new->chi ) =~ /^CHI::Driver/xm,
    'chi property (WebService::GoogleAPI::Client::Discovery->new->chi) is of sub-type CHI::Driver::'
  );
  note( "SESSION DEFAULT CHI Root Directory = " . WebService::GoogleAPI::Client::Discovery->new()->chi->root_dir );
  ok( WebService::GoogleAPI::Client::Discovery->new->debug eq '0', 'debug property defaults to 0' );
  ok( WebService::GoogleAPI::Client::Discovery->new( debug => 1 )->debug eq '1', 'debug property when set to 1 on new returns 1' );
};


## NB - should probably skip tests that will fail when a dependent test fails
subtest 'Naked instance method tests (without Client parent container)' => sub {

  ok( ref( WebService::GoogleAPI::Client->new->api_query() ) eq 'Mojo::Message::Response', "WebService::GoogleAPI::Client->new->api_query() is a 'Mojo::Message::Response'" );
  ok(
    WebService::GoogleAPI::Client::Discovery->new->list_of_available_google_api_ids() =~ /gmail/xm,
    'WebService::GoogleAPI::Client::Discovery->new->list_of_available_google_api_ids()'
  );

  ok( ref( WebService::GoogleAPI::Client::Discovery->new->discover_all() ) eq 'HASH', 'WebService::GoogleAPI::Client::Discovery->new->discover_all() return HASREF' );
  ok(
    ref( WebService::GoogleAPI::Client::Discovery->new->augment_discover_all_with_unlisted_experimental_api() ) eq 'HASH',
    ' WebService::GoogleAPI::Client::Discovery->new->augment_discover_all_with_unlisted_experimental_api() returns HASHREF'
  );
  ok(
    length( WebService::GoogleAPI::Client::Discovery->new->supported_as_text ) > 100,
    'WebService::GoogleAPI::Client::Discovery->new->supported_as_text() returns string > 100 chars'
  );

  ok( ref( WebService::GoogleAPI::Client::AuthStorage->new ) eq 'WebService::GoogleAPI::Client::AuthStorage', 'WebService::GoogleAPI::Client::AuthStorage->new' );
  ok( ref( WebService::GoogleAPI::Client::Discovery->new->api_verson_urls ) eq 'HASH', 'WebService::GoogleAPI::Client::Discovery->new->api_verson_url returns HASHREF' );

# supported_as_text

## not currently caching when running a sudo test so removing - restore for production

=pod


  ok( ref  WebService::GoogleAPI::Client->new( debug => $DEBUG ) eq 'WebService::GoogleAPI::Client' , 'WebService::GoogleAPI::Client new is correct type');
  ok( my $ret = WebService::GoogleAPI::Client::Discovery->new->discover_all, 'WebService::GoogleAPI::Client::Discovery->new->discover_all returns something');
  ## TODO - WebService::GoogleAPI::Client::Discovery->new->discover_all structure as expected
  ## TODO - do some more testing of discovery_all as is foundation for much of the workings
  ok( ref WebService::GoogleAPI::Client::Discovery->new->available_APIs eq 'ARRAY', "WebService::GoogleAPI::Client::Discovery->new->available_APIs returns array ref");
  ok( scalar WebService::GoogleAPI::Client::Discovery->new->available_APIs > 50 , "available_APIs() returns more than 50 elements in arra ref");
  ok ( WebService::GoogleAPI::Client::Discovery->new->service_exists() == 0, 'WebService::GoogleAPI::Client::Discovery->new->service_exists() == 0');
  ok ( WebService::GoogleAPI::Client::Discovery->new->service_exists('gmail') == 1, 'WebService::GoogleAPI::Client::Discovery->new->service_exists("gmail") == 1');
  ok ( WebService::GoogleAPI::Client::Discovery->new->service_exists('calendar') == 1, 'WebService::GoogleAPI::Client::Discovery->new->service_exists("calendar") == 1');
  ## TODO: refactor case of service handling across all code to make consistent - smells bad at the moment
  ok ( WebService::GoogleAPI::Client::Discovery->new->service_exists('Gmail') == 0, 'test case-insensitive failure service_exists("Gmail") == 0');

  ok ( length(WebService::GoogleAPI::Client::Discovery->new->supported_as_text()) > 100 , 'print_supported() returns string longer than 100 characters');
  ok ( ref( WebService::GoogleAPI::Client::Discovery->new->available_versions() ) eq 'ARRAY' && 
       scalar( @{ WebService::GoogleAPI::Client::Discovery->new->available_versions() } ) == 0
       ,'available_versions() no params returns empty array ref');
  ok ( ref( WebService::GoogleAPI::Client::Discovery->new->available_versions('calendar') ) eq 'ARRAY' && 
       scalar( @{ WebService::GoogleAPI::Client::Discovery->new->available_versions('calendar') } ) > 0
       ,'available_versions("calendar") returns at least 1 version');

  ok ( ref( WebService::GoogleAPI::Client::Discovery->new->available_versions('sdfds') ) eq 'ARRAY' && 
       scalar( @{ WebService::GoogleAPI::Client::Discovery->new->available_versions('sdfds') } ) == 0
       ,'available_versions("sdfds") returns empty array ref');

  ok ( ref( WebService::GoogleAPI::Client::Discovery->new->latest_stable_version() ) eq '' && 
        WebService::GoogleAPI::Client::Discovery->new->latest_stable_version() eq ''
       ,'latest_stable_version() no params returns empty string');
  ok ( WebService::GoogleAPI::Client::Discovery->new->latest_stable_version('calendar')  && 
       WebService::GoogleAPI::Client::Discovery->new->latest_stable_version('calendar') =~ /^v\d+/xm 
       ,'latest_stable_version("calendar") returns a string in v\d format');
  ok ( ref( WebService::GoogleAPI::Client::Discovery->new->latest_stable_version('dsfjh') ) eq '' && 
        WebService::GoogleAPI::Client::Discovery->new->latest_stable_version('dsfjh') eq ''
       ,'latest_stable_version("dsfjh")  returns empty string');

  ok ( ref(WebService::GoogleAPI::Client::Discovery->new( debug => 1 )->get_resource_meta('WebService::GoogleAPI::Client::Calendar::Events')) 
       eq 'HASH', 'get_resource_meta(\'WebService::GoogleAPI::Client::Calendar::Events\') returns hashref' );

  ## this is getting pretty ugly - need to parse around abstract class name strings etc .. and that's with simple Calendar Structure

  ok ( ref(WebService::GoogleAPI::Client::Discovery->new( debug => 0 )->get_resource_meta('WebService::GoogleAPI::Client::Calendar::Events')) eq 'HASH' 
        && 
        (keys %{WebService::GoogleAPI::Client::Discovery->new( debug => 0 )->get_resource_meta('WebService::GoogleAPI::Client::Calendar::Events')} == 1
        && 
        defined WebService::GoogleAPI::Client::Discovery->new( debug => 0 )->get_resource_meta('WebService::GoogleAPI::Client::Calendar::Events')->{methods}
        )
       , 'get_resource_meta(\'WebService::GoogleAPI::Client::Calendar::Events\') returns hashref with single key defined - methods' );


  ok ( ref(WebService::GoogleAPI::Client::Discovery->new( debug => 0 )->get_resource_meta('WebService::GoogleAPI::Client::Gmail::Users')) eq 'HASH' 
        && 
        (keys %{WebService::GoogleAPI::Client::Discovery->new( debug => 1 )->get_resource_meta('WebService::GoogleAPI::Client::Gmail::Users')} == 1
        && 
        defined WebService::GoogleAPI::Client::Discovery->new( debug => 0 )->get_resource_meta('WebService::GoogleAPI::Client::Gmail::Users')->{methods}
        )
       , 'get_resource_meta(\'WebService::GoogleAPI::Client::Gmail::Users\') returns hashref with single key defined - methods with keys getProfile,stop,watch' );

=cut


#exit;
#my $ret = WebService::GoogleAPI::Client::Discovery->new( debug => 1 )->get_resource_meta('WebService::GoogleAPI::Client::Calendar::Events'); ## ::CalendarList::delete
## keys $ret->{methods} = update,quickAdd,insert,move,instances,watch,patch,delete,list,import,get

=pod
my $ret = WebService::GoogleAPI::Client::Discovery->new( debug => 1 )->get_resource_meta('WebService::GoogleAPI::Client::Gmail::User'); ## ::CalendarList::delete
print "ret = " . $ret ."\n";
print "ref = " . ref( $ret ) . "\n";

print Dumper $ret;

print join(',',  keys %{$ret->{methods}} ) . "\n";
exit;
=cut

#  my $ret = WebService::GoogleAPI::Client::Discovery->new->available_versions('calendar');

#   my $ret = WebService::GoogleAPI::Client::Discovery->new->available_versions();

  #print ref $ret;
  # my $ret = WebService::GoogleAPI::Client::Discovery->new->
  #print ref $ret;
#   print Dumper $ret; exit;

TODO:
  {
    local $TODO = "tests for each WebService::GoogleAPI::Client::Discovery method";

    #! - REMOVED ok(undef,'get_rest');
    # ok(undef,'discover_all');
    #ok(undef,'available_APIs');
    #ok(undef,'service_exists');
    #ok(undef,'print_supported');
    #ok(undef,'available_versions');
    #ok(undef,'latest_stable_version');
    ok( undef, 'find_APIs_with_diff_vers' );
    ok( undef, 'search_in_services' );
    ok( undef, 'get_method_meta' );
    ok( undef, 'get_resource_meta' );

    #! - REMOVED ok(undef,'list_of_methods');
    ok( undef, 'meta_for_API' );
  }

  #todo('get_rest');
};

subtest 'Discovery methods with User Configuration' => sub {
  plan( skip_all => 'No service configuration - set $ENV{GOOGLE_TOKENSFILE} or create gapi.json in dzil source root directory' ) unless -e $default_file;


  ## Create a local instance to extract default user
#ok( my $gapi = WebService::GoogleAPI::Client->new( debug => $DEBUG ), 'Creating test session instance of WebService::GoogleAPI::Client');
#ok( $gapi->auth_storage->setup( { type => 'jsonfile', path => $default_file } ) || croak( $! ), "Load '$default_file'");
#ok( ref $gapi->auth_storage->setup( { type => 'jsonfile', path => $default_file } ) eq 'WebService::GoogleAPI::Client::AuthStorage', 'auth_storage returns WebService::GoogleAPI::Client::AuthStorage');

  ok( my $gapi = WebService::GoogleAPI::Client->new( debug => $DEBUG, gapi_json => $default_file ), 'Creating test session instance of WebService::GoogleAPI::Client' );
  ok( my $aref_token_emails = $gapi->auth_storage->storage->get_token_emails_from_storage, 'Load token emails from config' );
  if ( !$user )    ## default to the first user in config file if none defined yet
  {
    ok( $user = $aref_token_emails->[0], "setting test user to first configured entry in config - '$user'" );
  }

  #note("ENV CONFIG SETS $ENV{'GMAIL_FOR_TESTING'} WITHIN $ENV{'GOOGLE_TOKENSFILE'} ");

  if ( -e $default_file && $user )
  {
    note( "Running tests with user '$user' using '$default_file' credentials" );

    ok( $gapi->user( $user ) eq $user, "\$gapi->user('$user') eq '$user'" );

#$ENV{CHI_FILE_PATH} = $ENV{TMPDIR};
    plan( skip_all => 'Skipping network impacting tests unless ENV VAR CHI_FILE_PATH is set' ) unless defined $ENV{ CHI_FILE_PATH };


    ok(
      my $chi = CHI->new(
        driver         => 'File',
        root_dir       => $ENV{ CHI_FILE_PATH },    #'/var/folders/0f/ps628sj57m90zqh9pqq846m80000gn/T/chi-driver-file',
                                                    #depth          => 3,
        max_key_length => 512
      ),
      'CREATE testing CHI File using path from $ENV{CHI_FILE_PATH}'
    );                                              ## so don't do network requests unless we have taken the extra step and are more likely to know the impact
    ok(
      $gapi = WebService::GoogleAPI::Client->new( debug => $DEBUG, chi => $chi, gapi_json => $default_file ),
      'Creating test session instance of WebService::GoogleAPI::Client using customised CHI'
    );


    ok( $gapi->discovery->service_exists( 'gmail' ) == 1,    'WebService::GoogleAPI::Client::Discovery->new->service_exists("gmail") == 1' );
    ok( $gapi->discovery->service_exists( 'calendar' ) == 1, 'WebService::GoogleAPI::Client::Discovery->new->service_exists("calendar") == 1' );
    ok( $gapi->discovery->service_exists( '' ) == 0,         'WebService::GoogleAPI::Client::Discovery->new->service_exists("") == 0' );
    ok( $gapi->discovery->service_exists( 'Gmail' ) == 0,    'WebService::GoogleAPI::Client::Discovery->new->service_exists("Gmail") == 0 because of case mismatch' );

    #$gapi->discovery->{chi} = $chi;

    ## The reasoning behind not running doscovery tests without valid auth'd credentials is to
    ##  ensure that tests don't fail when Google blocks discovery requests for unauthenticated users
    ##  due to exceeding access limits.

    ## DISCOVERY ALL - RETURNS THE DESCIVOERY STRUCTURE DESCRIBING ALL GOOGLE SERVICE API ID's (gmail,calendar etc)
   #ok( my $ret = WebService::GoogleAPI::Client->new( chi => $chi )->discovery->new->discover_all, 'WebService::GoogleAPI::Client::Discovery->new->discover_all returns something');
    ok( ref( $gapi->discover_all ) eq 'HASH', 'Client->discover_all returns HASHREF' );
    ok( join( ',', sort keys( %{ WebService::GoogleAPI::Client::Discovery->new->discover_all() } ) ) eq 'discoveryVersion,items,kind',
      'Client->discover_all returns HASHREF with keys of discoveryVersion,items,kind' );

    ## list_of_available_google_api_ids - when just need a list not the entire top level discovery structure
#  ok ( my @list =  $gapi->list_of_available_google_api_ids() > 120, 'WebService::GoogleAPI::Client->list_of_available_google_api_ids() returned an ARRAY with more than 120 Google Service API IDs');
#  ok ( scalar( grep {/^gmail$/xmg} $gapi->list_of_available_google_api_ids() ) ==1, 'WebService::GoogleAPI::Client->list_of_available_google_api_ids() returned ARRAY includes "gmail"');


    ok( $gapi->discovery->get_api_discovery_for_api_id( 'gmail' ), "WebService::GoogleAPI::Client->discovery->get_api_discovery_for_api_id('gmail') returns something" );
    ok( scalar( $gapi->methods_available_for_google_api_id( 'gmail' ) ) > 10,
      'WebService::GoogleAPI::Client->methods_available_for_google_api_id("gmail") returns count of more than 10 ' );

    ok(
      my $api_detail = $gapi->discovery->extract_method_discovery_detail_from_api_spec( 'gmail.users.settings' ),
      "WebService::GoogleAPI::Client->extract_method_discovery_detail_from_api_spec('gmail.users.settings') returns something"
    );
    ok(
      keys %{ $gapi->extract_method_discovery_detail_from_api_spec( 'gmail.us.dummy-illegal-param-test' ) } == 0,
      "WebService::GoogleAPI::Client->extract_method_discovery_detail_from_api_spec('gmail.us.dummy') returns empty hashref"
    );
    ok( keys %{ $gapi->extract_method_discovery_detail_from_api_spec( 'not-a-google-service.list' ) } == 0,
      "WebService::GoogleAPI::Client->extract_method_discovery_detail_from_api_spec('not-a-google-service.list') returns empty hashref" );

    ok( scalar( [$gapi->get_scopes_as_array()] ) > 0, 'more than 0 scopes returned from config' );
    ok(
      $gapi->has_scope_to_access_api_endpoint( "gmail.users.messages.send" ) =~ /^0|1$/xmg,
      'has_scope_to_access_api_endpoint("gmail.users.messages.send") returns either 0 or 1'
    );    #

    cmp_ok( my $permission = $gapi->has_scope_to_access_api_endpoint( "sheets.spreadsheets.get" ),
      '>=', 0, 'has_scope_to_access_api_endpoint("sheets.spreadsheets.get") returns >= 0 ' );    #
                                                                                                 #ok ( $permission =~ /^0|1$/xmg , "permission of $permission is 0 or 1 ");
    if ( $permission == 0 )
    {
      note( "No Credential scope for sheets.spreadsheets.get so looking for teapot return when try to access it" );
      ok(
        $gapi->api_query( { api_endpoint_id => 'sheets.spreadsheets.get' } )->code() eq '418',
        "Access to service without scope permission returns expected HTTP 418 error - I'm a teapot"
      );
    }

    cmp_ok( $permission = $gapi->has_scope_to_access_api_endpoint( "gmail.users.messages.send" ),
      '>=', 0, 'has_scope_to_access_api_endpoint("gmail.users.messages.send") returns >= 0 ' );    #
    note( "permission value = $permission" );


=pod

THIS BLOCK HAS BEEN DISABLED BECAUSE IT FAILS WHEN TAIN MODE IS ENABLED - SO ALHTOUGH THE CODE WORKS FINE AS FAR AS I CAN 
TELL - IT IS NOT BEING ALLOWED TO RUN WITHIN THE TEST HARNESS 
MORE INVESTIGATION REQUIRED

=cut

    if ( $permission == 1 && defined $ENV{ TEST_SEND_EMAIL } )    ## user config has granted email send scope - if modules available to construct an email will send email to self
    {
      note( "attempting to send email from $user to $user" );
      use Test::Needs;
      subtest 'send email to self through api' => sub {
        test_needs 'Email::Simple';
        test_needs 'MIME::Base64';
        use Email::Simple;                                        ## RFC2822 formatted messages
        use MIME::Base64;
        note( "Send test email from $user to $user " );

        ok(
          $gapi->api_query( {
            api_endpoint_id => 'gmail.users.messages.send',
            options         => {
              raw => encode_base64(
                Email::Simple->create( header => [To => $user, From => $user, Subject => "Test email from user",], body => "This is the body of email from user to user", )
                  ->as_string
              )
            },
          } ),
          ' Send email to self'
        );

# Same as above but check return value
#                cmp_ok( $gapi->api_query( {
#                        api_endpoint_id => 'gmail.users.messages.send',
#                        options    => { raw => encode_base64( Email::Simple->create( header => [To => $user, From => $user, Subject =>"Test email from $user",], body => "This is the body of email from $user to $user", )->as_string ) },
#                })->code,'==', 200, "Send email to self");
      };
    }


=pod
        TODO: {
            local $TODO = "tests for each WebService::GoogleAPI::Client::Discovery method with a valid user configuration";
            # ! - REMOVED ok(undef,'get_rest');
            #ok(undef,'discover_all');
            ok(undef,'available_APIs');
            ok(undef,'service_exists');
            ok(undef,'print_supported');
            ok(undef,'available_versions');
            ok(undef,'latest_stable_version');
            #ok(undef,'find_APIs_with_diff_vers');
            ok(undef,'search_in_services');
            ok(undef,'get_method_meta');
            ok(undef,'get_resource_meta');
            #! - REMOVED ok(undef,'list_of_methods');
            ok(undef,'meta_for_API');
        }
=cut

  }
};    ## END 'Test with User Configuration' SUBTEST


#note("Testing WebService::GoogleAPI::Client $WebService::GoogleAPI::Client::VERSION, Perl $], $^X");

done_testing();
