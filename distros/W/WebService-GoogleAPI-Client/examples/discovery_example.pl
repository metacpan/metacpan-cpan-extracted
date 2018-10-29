#!/usr/bin/perl

use strict;
use warnings;
use WebService::GoogleAPI::Client::Discovery;
use WebService::GoogleAPI::Client;
use Data::Dumper;
use JSON;
use Text::Table;
use JSON::PP::Boolean;
use Carp;
use CHI;
use feature 'say';
use GraphViz::Data::Grapher;    ## see also alterntative use GraphViz::Data::Structure;
use Mojo::Message::Response;

=pod

=head1 discovery_example.pl

=head2 ABSTRACT

This code is being used to explore functionality related to service discovery. 
The intent is to learn about how the current code works and whether it can be 
made to work as advertised. 
Also whether this approach is appropriate and to explore alternative ways of representing
and interfacing with the discovery data structures of services.

=cut


## TESTING THE ABILITY TO MANUALLY CONSTRUCT A Mojo::Message::Response instance
##  with intent to return a "418 I'm a teapot " response as indication that
##  an API request with API level constraints has failed before it was submitted to
##  the server.


my $chi = CHI->new(
  driver   => 'File',
  root_dir => '/var/folders/0f/ps628sj57m90zqh9pqq846m80000gn/T/chi-driver-file',

  #depth          => 3,
  max_key_length => 512
);

say( "CHI Root Directory = " . WebService::GoogleAPI::Client->new( chi => $chi )->discovery->chi->root_dir );
if ( my $x = $chi->get( "https://www.googleapis.com/discovery/v1/apis/gmail/v1/rest" ) )

#if ( my $x = $chi->get('https://www.googleapis.com/discovery/v1/apis') )
{
  #print Dumper $x;
  say $chi->path_to_key( "https://www.googleapis.com/discovery/v1/apis/gmail/v1/rest" );
}
else
{
  #croak('fdfd');
  my $y = WebService::GoogleAPI::Client->new( chi => $chi )->discovery->get_api_discovery_for_api_version( { api => 'gmail', version => 'v1' } );
  $chi->set( "https://www.googleapis.com/discovery/v1/apis/gmail/v1/rest", $y, '30d' );
  say $chi->path_to_key( "https://www.googleapis.com/discovery/v1/apis/gmail/v1/rest" )

    #print Dumper $y;

}

#exit;

## nb - not all calls below use the agent - some are direct class calls
my $gapi_agent = WebService::GoogleAPI::Client->new( debug => 1, chi => $chi, gapi_json => './gapi.json', user => 'peter@shotgundriver.com' );


#$gapi_agent->discovery->extract_method_discovery_detail_from_api_spec('gmail.users.settings');

say "\n\n\n\n";


if ( 1 == 0 )
{
  ## DISCOVERY SPECIFICATION - mostly internal - user shouldn't need to use this
  say "keys of api discovery hashref = " . join( ',', sort keys( %{ WebService::GoogleAPI::Client::Discovery->new->discover_all() } ) );
  my $discover_all = WebService::GoogleAPI::Client::Discovery->new->discover_all;
  exit;
  print Dumper $discover_all;
  for my $api ( @{ $discover_all->{ items } } )
  {
    if ( $api->{ preferred } )
    {
      my $key = "$api->{name}/$api->{version}/rest";
      print my $v1 = qq{$api->{preferred} $api->{name} $api->{version} https://www.googleapis.com/discovery/v1/apis/$key \n};
      print my $v2 = qq{$api->{preferred} $api->{name} $api->{version} $api->{discoveryRestUrl}\n};
    }

    #WebService::GoogleAPI::Client::Discovery->new->get_rest({api});
  }
  exit;
}


## AVAILABLE API IDS
if ( 1 == 0 )
{
  my @apis = WebService::GoogleAPI::Client->new->list_of_available_google_api_ids();
  say "AVAILABLE GOOGLE SERVICE IDs = " . join( ", ", @apis );
  say "Total count = " . scalar( @apis );
  exit;
}


my $gmail_api = WebService::GoogleAPI::Client->new->methods_available_for_google_api_id( 'gmail' );

#say "Available api end-points for gmail = \n\t" . join("\n\t", keys %$gmail_api);
say "Available api end-points for gmail = \n\t" . join( ",", keys %$gmail_api ) . "\n\n";
say "Gmail includes a total of " . scalar( keys %$gmail_api ) . ' methods';

#exit;

if ( 1 == 0 )
{
  ## NB - I have now implemented an approach that carps a warning and returns an empty hashref {} if param isn't a valid api endpoint
  my $x = WebService::GoogleAPI::Client->new()->discovery->extract_method_discovery_detail_from_api_spec( 'gmail.users.messages.list-breakme' );

  #print Dumper $x;
  say "empty hashref" if ( keys %$x == 0 );
  say "empty hashref as expected"
    if ( keys %{ WebService::GoogleAPI::Client->new()->discovery->extract_method_discovery_detail_from_api_spec( 'gmail.users.messages.list-breakme' ) } == 0 );
  say join( "\n\t", keys %$x );
  exit;
}


######################################
if ( 'NO     -PULL-ALL-API-SPECS-AND-EXTRACT-METHODS' eq 'YES-PULL-ALL-API-SPECS-AND-EXTRACT-METHODS' )    ## NB - network load unless cached
{
  ## for each service show the available methods
  #my @methods = map { WebService::GoogleAPI::Client->new->methods_available_for_google_api_id( $_ ) } WebService::GoogleAPI::Client->new->list_of_available_google_api_ids();
  #say "Processed a total of " . scalar(@methods) . ' services';

  my $ttl = 0;
  foreach my $service_id ( WebService::GoogleAPI::Client->new( chi => $chi )->list_of_available_google_api_ids() )
  {
    my $service_methods = WebService::GoogleAPI::Client->new( chi => $chi )->methods_available_for_google_api_id( $service_id );

    #print Dumper $service_methods;
    say "$service_id includes  an api endpoint count = " . scalar( keys %$service_methods );
    $ttl += scalar( keys %$service_methods );
  }
  say "Total api endpoint count  = $ttl";
  exit;
}
######################################


######################################
if ( 1 == 0 )    ## sorted - now returns empty hashref as expected
{
  ## how to handle incoorect id parameter to extract_method_discovery_detail_from_api_spec
  my $api_detail2 = $gapi_agent->extract_method_discovery_detail_from_api_spec( 'gmail-not.gnar' );
  say "empty hashref as expected for bad param" if ( keys %$api_detail2 == 0 );

  #print Dumper $api_detail2;
  #TODO explore why getting output
  #get_api_discovery_for_api_id called with empty version param defined$VAR1 = {
  #          'api' => 'agmail',
  #          'version' => ''
  #        };
  # at discovery_example.pl line 99.
  exit;
}
######################################


#if ( keys ( my $x = $gapi_agent->extract_method_discovery_detail_from_api_spec('gmail.users.messages.send')) >0  )
#{
#  print Dumper $x; exit;
#} else { croak "no keys"}

######################################
if ( 1 == 0 )    ## - validate user scope for an api service endpoint string - informed has_scope_to_access_api_endpoint()
{
#  my $scopes = "email profile https://www.googleapis.com/auth/plus.profile.emails.read https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/contacts.readonly https://mail.google.com";

  #my $foo = [split(' ', $scopes )];
  #print Dumper $foo;exit;
  ## list all user scopes configured

  my $configured_scopes = $gapi_agent->get_scopes_as_array();    ## TODO rename to array_ref
  say "Scopes currently configured are: \n * " . join( "\n * ", @$configured_scopes );
  ## transform list into a hash so can do instant lookups

  my %configured_scopes_hash = map { s/\/$//xr, 1 } @$configured_scopes;    ## NB r switch as per https://www.perlmonks.org/?node_id=613280
                                                                            #print Dumper \%configured_scopes_hash;exit;
  my @aapis = $gapi_agent->list_of_available_google_api_ids();              ## nb - actually returns an array .. perhaps make aref standard?
                                                                            #print Dumper \@aapis;

  my $api_spec_scope_counts;                                                ## hashref
                                                                            #foreach my $api ( @aapis  )
  foreach my $api ( qw/gmail/ )
  {
    say "processing  $api Google API discovery specification";

    my $api_methods = $gapi_agent->methods_available_for_google_api_id( $api );
    foreach my $method_spec_key ( keys %$api_methods )
    {
      #say "  method $method_spec_key";
      #say Dumper $api_methods->{$method_spec_key};
      ## permission is available iff any of the available scopes are within the method scopes list
      my $granted = 0;
      foreach my $method_scope ( map {s/\/$//xr}
        @{ $api_methods->{ $method_spec_key }{ scopes } } )    ## as earlier remove trailing '/' - NB r switch as per https://www.perlmonks.org/?node_id=613280
      {                                                        ## NB - could terminate once scope found by using last;
                                                               #$method_scope =~ s/\/$//xsmg; ## remove trailing '/'
        $api_spec_scope_counts->{ $method_scope }{ spec }++;
        $granted = 1 if defined $configured_scopes_hash{ $method_scope };
        $api_spec_scope_counts->{ $method_scope }{ user }++ if $granted;
        last if $granted;    ## breaks out of loop but messes up counts
      }

      #say " method $method_spec_key Permission on currently configured scopes = " . ('Denied','Granted')[$granted] if $granted==1;
      say " method $method_spec_key " . ( 'Denied', 'Granted' )[$granted] if $granted == 1;    ## shorter
      my $library_granted = $gapi_agent->has_scope_to_access_api_endpoint( $method_spec_key );
      print qq{  $granted   $library_granted \n};

      #exit;
      #print Dumper $api_methods;
    }
    print Dumper $api_spec_scope_counts;    ## nb - the set venn gets fubarred by last - also need to really look to interpret these results
  }
  exit;
}
######################################



#print ;exit;
######################################
if ( 1 == 1 )                               ## TODO: - Audit all service method param
{
  $gapi_agent->debug( 0 );                  ## NB - user would expect this to filter through children !
  $gapi_agent->discovery->debug( 0 );
  my @aapis                = $gapi_agent->list_of_available_google_api_ids();
  my $last                 = undef;
  my $meth_spec_variations = {};                                                ## is always path or query
  foreach my $api ( @aapis )
  {
    if ( 1 == 0 )                                                               ## check expected top level fields for pi_discovery_for_api_id of $api_id
    {
      $meth_spec_variations->{ spec } = $gapi_agent->discovery->get_api_discovery_for_api_id( $api );

      $meth_spec_variations->{ spec }{ rest } = '' unless defined $meth_spec_variations->{ spec }{ rest };

      $meth_spec_variations->{ spec }{ canonicalName }     = '' unless defined $meth_spec_variations->{ spec }{ canonicalName };
      $meth_spec_variations->{ spec }{ documentationLink } = '' unless defined $meth_spec_variations->{ spec }{ documentationLink };

      foreach my $expected_key ( qw/title rest ownerName canonicalName version id discoveryVersion revision documentationLink description/ )
      {
        croak( "expected $expected_key to be defined" ) unless defined $meth_spec_variations->{ spec }{ $expected_key };
      }


#      foreach my $rf ( qw/ownerName canonicalName version id discoveryVersion revision documentationLink description/ )
#      {
#        $meth_spec_variations->{spec}{canonicalName} = '' unless defined $meth_spec_variations->{spec}{canonicalName};
#        $meth_spec_variations->{spec}{documentationLink} = '' unless defined $meth_spec_variations->{spec}{documentationLink};
#        croak("expected required field $rf but did not find for $api") unless defined $meth_spec_variations->{spec}{$rf};
#      }
    }
    if ( rand( 20 ) > 18 )
    {
      $meth_spec_variations->{ spec }              = $gapi_agent->discovery->get_api_discovery_for_api_id( $api );
      $meth_spec_variations->{ spec }{ methods }   = 'REMOVED BY PETER';
      $meth_spec_variations->{ spec }{ resources } = 'REMOVED BY PETER';
      $meth_spec_variations->{ spec }{ schemas }   = 'REMOVED BY PETER';
      $meth_spec_variations->{ spec }{ auth }      = 'REMOVED BY PETER';
      ## perform check for keys that are depended on and assumed to exist in all

    }
    ## get all methods for the api
    my $meths_by_id = $gapi_agent->methods_available_for_google_api_id( $api );
    foreach my $meth ( keys %{ $meths_by_id } )
    {
      if ( defined $meths_by_id->{ $meth }{ flatPath } )
      {
        say "+  $meth flatpath = " . $meths_by_id->{ $meth }{ flatPath };
        say "++ $meth path     = $meths_by_id->{$meth}{'path'}";

        #print Dumper $meths_by_id->{$meth};exit;
      }
      else
      {
        say "- $meth - $meths_by_id->{$meth}{'path'}";

        #say "not in $meth";

        #print Dumper $meths_by_id->{$meth};
        #exit;
      }

      if ( rand( 20 ) < 1 )
      {

        $last = $meths_by_id->{ $meth };

      }


      ## parameter_locations
      if ( defined $meths_by_id->{ $meth }{ parameterOrder } && scalar( @{ $meths_by_id->{ $meth }{ parameterOrder } } ) > 0 )
      {
        $meth_spec_variations->{ parameters }{ parameterOrder_ttl_count } += scalar( @{ $meths_by_id->{ $meth }{ parameterOrder } } );
        say Dumper $meths_by_id->{ $meth }{ parameterOrder };
        say Dumper $meths_by_id->{ $meth }{ parameters };

        #exit if (rand(20) < 1);


      }

      foreach my $p ( keys %{ $meths_by_id->{ $meth }{ parameters } } )
      {
        $meth_spec_variations->{ parameters }{ locations }{ $meths_by_id->{ $meth }{ parameters }{ $p }{ location } }++;
        $meth_spec_variations->{ parameters }{ types }{ $meths_by_id->{ $meth }{ parameters }{ $p }{ type } }++;

        # $meth_spec_variations->{meth_keys}{$p}++;
        # push @{$meth_spec_variations->{meth_keys}{$p}}, $meth;
        $meth_spec_variations->{ parameters }{ required }{ $meths_by_id->{ $meth }{ parameters }{ $p }{ required } }++
          if ( defined $meths_by_id->{ $meth }{ parameters }{ $p }{ required } );
        $meth_spec_variations->{ parameters }{ required }{ $meths_by_id->{ $meth }{ parameters }{ $p }{ location } }++
          if ( defined $meths_by_id->{ $meth }{ parameters }{ $p }{ required } );
      }


    }
    ## get method spec for each api method
    ## extract all request uri interpolation variables
    ## extract all uri extra get variables
    ## extract all POST name/value variables with defaults


  }
  print Dumper $last;
  print Dumper $meth_spec_variations;
  croak( 'please stop - all done here' );
}
######################################


######################################
if ( 1 == 0 )    ## TODO: - explore interpolation of variables
{
  #if ( keys ( my $x = WebService::GoogleAPI::Client->new( chi => $chi )->discovery->extract_method_discovery_detail_from_api_spec('gmail.users.messages.send')) >0  )
  if ( keys( my $x = $gapi_agent->extract_method_discovery_detail_from_api_spec( 'gmail.users.messages.send' ) ) > 0 )
  {
    say Dumper $x;
    say method_like_swagger( $x );

    #if ( $x dfdf)
    #{
    #}
  }
  else
  {
    say "Failed!";
  }

  exit;
}
######################################


# my $api_verson_urls = api_version_urls(); ## hash of api discovery urls api->version->url .. bugger deleted this function
#print Dumper $api_verson_urls ;
#my $api = 'appengine'; my $version = 'v1beta5';
#my $api = 'sheets'; my $version = 'v4';
#my $api = 'sheets'; my $version = '';
my $api     = 'gmail';
my $version = 'v1';

#print Dumper $api_verson_urls->{$api};
#exit;
if ( !$version )
{
  $version = WebService::GoogleAPI::Client::Discovery->new->latest_stable_version( $api );
}
print "Version $version\n";    #exit;

if ( 1 == 0 )
{
  print method_like_swagger(
    {
      'scopes' => [
        'https://mail.google.com/',                     'https://www.googleapis.com/auth/gmail.metadata',
        'https://www.googleapis.com/auth/gmail.modify', 'https://www.googleapis.com/auth/gmail.readonly'
      ],
      'parameters' => {
        'userId' => {
          'location'    => 'path',
          'description' => 'The user\'s email address. The special value me can be used to indicate the authenticated user.',
          'type'        => 'string',
          'required'    => bless( do { \( my $o = 1 ) }, 'JSON::PP::Boolean' ),
          'default'     => 'me'
        }
      },
      'request'        => { '$ref' => 'WatchRequest' },
      'httpMethod'     => 'POST',
      'path'           => '{userId}/watch',
      'description'    => 'Set up or update a push notification watch on the given user mailbox.',
      'parameterOrder' => ['userId'],
      'response'       => { '$ref' => 'WatchResponse' },
      'id'             => 'gmail.users.watch'
    },
    'users'
  );
}


my $api_spec = WebService::GoogleAPI::Client::Discovery->new->get_api_discovery_for_api_version( { api => $api, version => $version } );

#print Dumper $api_spec;

#print "Resources = " . join("\n\t - ", (keys $api_spec->{resources})) . "\n";
print "TOP LEVEL KEYS = " . join( "\n\t - ", ( keys $api_spec ) ) . "\n";
print "Resources = " . join( "\n\t - ", ( keys $api_spec->{ resources } ) ) . "\n";
print "Resource keys\n";


exit;

my $ret = WebService::GoogleAPI::Client::Discovery->new( debug => 1 )->get_resource_meta( 'WebService::GoogleAPI::Client::Gmail::Users' );    ## ::CalendarList::delete

#print "ret = " . $ret ."\n";
#print "ref = " . ref( $ret ) . "\n";

print "FINAL RESULT DUMPER = " . Dumper $ret;
exit;
print "FINAL RESULT METHODS = " . join( ',', sort keys %{ $ret->{ methods } } ) . "\n";
print "CHI Namespace = " . WebService::GoogleAPI::Client::Discovery->new()->chi->{ namespace } . "\n";
print "CHI Root = " . WebService::GoogleAPI::Client::Discovery->new()->chi->root_dir . "\n";

#exit;

my $aapis = WebService::GoogleAPI::Client::Discovery->new->available_APIs();


for my $api ( @{ $aapis } )
{
  #print Dumper $api; ## NB doesn't contain discovery link
  my @clean_doclinks = grep { defined $_ } @{ $api->{ doclinks } };                         ## was seeing undef in doclinks array - eg 'surveys'causing warnings in join
  my %seen           = ();
  my $doclinks       = join( ' , ', ( grep { !$seen{ $_ }++ } @clean_doclinks ) ) || '';    ## unique doclinks as string
  print "$api->{ name } - $api->{discoveryRestUrl}[ scalar(@{$api->{discoveryRestUrl}})-1 ] - $doclinks\n";
  ## pull in the discovery url for the latest version of the API into cache and variable

  if ( $api->{ name } =~ /^cloudiot|websecurityscanner$/smg )
  {
    $api->{ version } = 'v1';
    ## skipping as fails
  }

  else
  {
    my $api_spec = WebService::GoogleAPI::Client::Discovery->new->get_api_discovery_for_api_version(
      { api => $api->{ name }, version => $api->{ versions }[scalar( @{ $api->{ discoveryRestUrl } } ) - 1] } );
    print Dumper $api_spec;
  }

}
exit;


print WebService::GoogleAPI::Client::Discovery->new->supported_as_text();
exit;


if ( 1 == 0 )    ## initial play to explore how CHI works and whether could be applied - informed integration of CHI into WebService::GoogleAPI::Client::Discovery
{
  print "Package = " . __PACKAGE__ . "\n";

  #my $x =   discovery_data();
  #say Dumper $x;
  my $cache = CHI->new( driver => 'File', namespace => __PACKAGE__ );
  say $cache->root_dir;
  if ( my $expires_at = $cache->get_expires_at( 'discovery_data' ) )
  {
    say "expires  in ", scalar( $expires_at ) - time(), " seconds";
  }
  else
  {
    $cache->set( 'discovery_data', WebService::GoogleAPI::Client::Discovery->new->discover_all, '10d' );
    say "Sleeping after web fetch - are you feeling the pain sufficiently ? ";
    sleep( 5 );
  }
  my $dd = $cache->get( 'discovery_data' );
  say Dumper $dd;
  say render_services_as_formatted_table( $dd );
  exit;
}


my $d = WebService::GoogleAPI::Client::Discovery->new->discover_all;
say render_services_as_formatted_table( $d );

#exit;


$d = WebService::GoogleAPI::Client::Discovery->new;

#say Dumper $d->get_rest({ api=> 'calendar', version => 'v3' });

my $discovered_api_spec = $d->get_rest( { api => 'gmail', version => 'v1' } );
say Dumper $discovered_api_spec;

#exit;

## GRAPH SCHEMA AS PNG AS WRITE OUT AS json .. nb from command line use: pp_json < filename.json
##  not really very useful but fun anyway
if ( 1 == 0 )
{
  foreach my $schemakey ( keys %{ $discovered_api_spec->{ schemas } } )
  {

    ## GraphViz::Data::Grapher borks on any contained quotes so serialising, removing and restoring
    my $clean_json = to_json( $discovered_api_spec->{ schemas }{ $schemakey } );
    $clean_json =~ s/\\"/'/msxg;
    my $clean = from_json( $clean_json );

    ## nb failure doesn't prevent new returning instance
    my $graph = GraphViz::Data::Grapher->new( $clean )->as_png( "$schemakey.png" );

    open( OF, '>', "$schemakey.json" ) || croak( $! );
    print OF to_json( $discovered_api_spec->{ schemas }{ $schemakey } );
    close( OF );

    #`pp_json < $schemakey.json > $schemakey.json`;
  }
}

exit;


#my $gapi_agent = WebService::GoogleAPI::Client->new( debug => 1, gapi_json=>'./gapi.json', user=> 'peter@shotgundriver.com'  );    # my $gapi = WebService::GoogleAPI::Client->new(access_token => '');
#my $user = 'peter@shotgundriver.com';                              # full gmail
#$gapi_agent->auth_storage->setup( { type => 'jsonfile', path => './gapi.json' } );    # by default - could this be auto on new?
# $gapi->auth_storage->setup({ type => 'dbi', path => 'DBI object' });  ## NOT IMPLEMENTED
# $gapi->auth_storage->setup({ type => 'mongodb', path => 'details' }); ## NOT IMPLEMENTED

#$gapi_agent->user( $user );
#$gapi_agent->do_autorefresh( 1 ); - i think this is redundant as 1 is default value ?

#cal_examples( $gapi_agent );


########################################
sub render_services_as_formatted_table
{
  my ( $d ) = @_;
  ## Render as nicely formatted MD table - https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet


  # wrap into an array of rows for table
  my $rows = [];
  foreach my $r ( @{ $d->{ items } } )
  {
    push @$rows, [$r->{ version }, $r->{ title }, $r->{ description }];    ## documentationLink icon-s->{x32|16}  id discoveryRestUrl

  }
  my $tb = Text::Table->new(    ## currently use Text::Table - perhaps should use Text::MarkdownTable so can put images and links in without bloaring the col lengths
    { is_sep => 1, title => '| ', body => '| ' }, "Version", { is_sep => 1, title => '| ', body => '| ' }, "Title", { is_sep => 1, title => '| ', body => '| ' }, "Description",
    { is_sep => 1, title => '| ', body => '| ' }, "",
  );

  $tb->load( @$rows );
  return $tb;
}
########################################

sub cal_examples
{
  my ( $gapi ) = @_;
  my $r1 = $gapi->Calendar->Events->list( { calendarId => 'primary' } )->json;
  carp scalar @{ $r1->{ items } };
  exit if ( 1 == 1 );
}


=pod
sub method_structure_from_tree_string
{
  my ( $tree ) = @_;
  ## where tree is the method in format from extract_resource_methods_from_api_spec() like projects.models.versions.get
  ##   the root is the api id - further '.' sep levels represent resources until the tailing label that represents the method
  my @nodes = split('.', $tree);
  croak("tree structure '$tree' must contain at least 2 nodes - not " . scalar(@nodes) ) unless scalar(@nodes)>1;

  return {
    api => $nodes[0],
    method => $nodes[ scalar(@nodes)-1 ]
  };
}
=cut


## TODO - extract overview as text for api id spec
## TODO - extract resource definintions for api id spec
########################################################

if ( 1 == 0 )    ## used to info teapot reponse code in Client->api_query
{
  my $res = Mojo::Message::Response->new(
    content_type => 'text/plain',
    code         => 418,
    message      => 'Teapot Error - Reqeust blocked before submitting to server with pre-query validation errors'
  );

  #$res->code(418); ## I'm a teapot
  #$res->message('not so short - quite stout');
  $res->headers->content_type( 'text/plain' );
  $res->body( 'A Valid Google API Service end-point was included in params but the token does not have the required scope' );
  say $res->to_string;


  if ( $res->code eq '418' )
  {
    say "i may be short and stout\n" . $res->default_message;
  }
  exit;
}
########################################################


########################################################
sub method_like_swagger
{
  my ( $ms, $tags ) = @_;

  #print Dumper $ms; ## method spec
  my $ret = '';
  $ms->{ httpMethod } = lc( $ms->{ httpMethod } );
  my $scopes = join( "\n", map {qq{        - Oauth2:\n          - '$_' }} @{ $ms->{ scopes } } );
  my $response = '';
  foreach my $k ( keys %{ $ms->{ response } } )
  {
    $response .= qq{          schema:\n};
    $response .= qq{            $k:  '#/definitions/$ms->{response}{$k}'\n};
  }
  $ret = qq{
  '$ms->{path}':
    parameters:
    $ms->{httpMethod}:
      description: $ms->{description}
      operationId: $ms->{id}
      parameters:

      responses:
        '200':
          description: Successful response
$response
      security:
$scopes
      tags:
        - $tags
};

  #croak('test');
  return $ret;
}
########################################################


############################ ************ #########################
sub api_query
{
  my ( $self, $params ) = @_;
  my @teapot_errors = ();    ## used to collect pre-query validation errors - if set we return a response with 418 I'm a teapot

  ## pre-query validation if api_id parameter is included
  ## push any critical issues onto @teapot_errors
  ## include interpolation and defaults if required because user has ommitted them
  if ( defined $params->{ api_endpoint_id } )
  {

    my $api_discovery_struct = $self->discovery->get_api_discovery_for_api_id( $params->{ api_endpoint_id } );
    print Dumper $api_discovery_struct->{ schemas }{ Message };

    ## if can get discovery data for google api endpoint then continue to perform detailed checks
    my $method_discovery_struct = $self->extract_method_discovery_detail_from_api_spec( $params->{ api_endpoint_id } );
    if ( keys %{ $method_discovery_struct } > 0 )    ## method discovery struct ok
    {
      ## ensure user has required scope access
      push( @teapot_errors, "Client Credentials do not include required scope to access $params->{api_endpoint_id}" )
        unless $self->has_scope_to_access_api_endpoint( $params->{ api_endpoint_id } );
      ## set http method to default if unset
      if ( not defined $params->{ method } )
      {
        $params->{ method } = $method_discovery_struct->{ httpMethod } || croak( "API Endpoint discovered specification didn't include expected httpMethod value" );
      }
      elsif ( $params->{ method } !~ /^$method_discovery_struct->{httpMethod}$/sxim )
      {
        push( @teapot_errors, "method mismatch - you requested a $params->{method} which conflicts with discovery spec requirement for $method_discovery_struct->{httpMethod}" );
      }

      croak( "API Endpoint $params->{api_endpoint_id} discovered specification didn't include expected 'parameters' keyed HASH structure" )
        unless ref( $method_discovery_struct->{ parameters } ) eq 'HASH';

      ## Set default path iff not set by user - NB - will prepend baseUrl later
      $params->{ path } = "$method_discovery_struct->{path}" unless defined $params->{ path };
      carp( "DEBUG: params path = $params->{path}" );
      foreach my $meth_param_spec ( keys %{ $method_discovery_struct->{ parameters } } )
      {
        carp( "DEBUG:testing method param $meth_param_spec" );

        ## set default value if is not provided within $params->{options} - nb technically not required but provides visibility of the params if examining the options when debugging
        $params->{ options }{ $meth_param_spec } = $method_discovery_struct->{ parameters }{ $meth_param_spec }{ default }
          if (
          not defined $params->{ options }{ $meth_param_spec }
          && ( defined $method_discovery_struct->{ parameters }{ $meth_param_spec }{ default }
            && $method_discovery_struct->{ parameters }{ $meth_param_spec }{ location } eq 'query' )
          );

        if ( $params->{ path } =~ /\{.+\}/xms )    ## there are un-interpolated variables in the path - try to fill them for this param if reqd
        {
          carp( "DEBUG: There is  un-interpolated variables in the path" );
          ## interpolate variables into URI if available and not filled
#carp("DEBUG: $method_discovery_struct->{parameters}{$meth_param_spec}{'location'}");
          if ( $method_discovery_struct->{ parameters }{ $meth_param_spec }{ 'location' } eq 'path' )    ## this is a path variable
          {
            carp( "DEBUG: match $params->{path} found for \{$meth_param_spec\} " );
            ## requires interpolations into the URI -- consider && into containing if
            if ( $params->{ path } =~ /\{$meth_param_spec\}/xg )                                         ## eg match {jobId} in 'v1/jobs/{jobId}/reports/{reportId}'
            {
              carp( "OK" );

              ## if provided as an option
              if ( defined $params->{ options }{ $meth_param_spec } )
              {
                $params->{ path } =~ s/\{$meth_param_spec\}/$params->{options}{$meth_param_spec}/xsmg;
                ## TODO - possible source of errors in future - do we need to undefine the option here?
                delete $params->{ options }{ $meth_param_spec };
              }
              ## else if not provided as an option but a default value is provided in the spec
              elsif ( defined $method_discovery_struct->{ parameters }{ $meth_param_spec }{ default } )
              {
                $params->{ path } =~ s/\{$meth_param_spec\}/$method_discovery_struct->{parameters}{$meth_param_spec}{default}/xsmg;
              }
              else    ## otherwise flag as an error - unable to interpolate
              {
                push( @teapot_errors,
                  "$params->{path} requires interpolation value for $meth_param_spec but none provided as option and no default value provided by specification" );
              }
            }
          }
        }
        elsif ( $method_discovery_struct->{ parameters }{ $meth_param_spec }{ 'location' } eq 'query' )    ## check post form variables .. assume not get?
        {
          if ( !defined $params->{ options }{ $meth_param_spec } )
          {
            $params->{ options }{ $meth_param_spec } = $method_discovery_struct->{ parameters }{ $meth_param_spec }{ default }
              if ( defined $method_discovery_struct->{ parameters }{ $meth_param_spec }{ default } );
          }

        }
      }

      ## error now if there remain uninterpolated variables in the path


      ## prepend base if it doesn't match expected base
      #print Dumper $method_discovery_struct;
      $api_discovery_struct->{ baseUrl } =~ s/\/$//sxmg;    ## remove trailing '/'
      $params->{ path } =~ s/^\///sxmg;                     ## remove leading '/'
      carp( "DEBUG: $api_discovery_struct->{baseUrl}/$params->{path}" );
      $params->{ path } = "$api_discovery_struct->{baseUrl}/$params->{path}" unless $params->{ path } =~ /^$api_discovery_struct->{baseUrl}/ixsmg;


      ## if errors - add detail available in the discovery struct for the method and service to aid debugging
      if ( @teapot_errors )
      {
        ## provide defaults for keys to method discovery that are known to be missing in small number of instances
        $method_discovery_struct->{ canonicalName }     = $method_discovery_struct->{ title } unless defined $method_discovery_struct->{ canonicalName };
        $method_discovery_struct->{ documentationLink } = '??'                                unless defined $method_discovery_struct->{ documentationLink };
        $method_discovery_struct->{ rest }              = ''                                  unless defined $method_discovery_struct->{ rest };


        push( @teapot_errors,
          qq{ $method_discovery_struct->{title} $method_discovery_struct->{rest} API into $method_discovery_struct->{ownerName} $method_discovery_struct->{canonicalName} $method_discovery_struct->{version} with id $method_discovery_struct->{id} as described by discovery document version $method_discovery_struct->{discoveryVersion} revision $method_discovery_struct->{revision} with documentation at $method_discovery_struct->{documentationLink} \nDescription $method_discovery_struct->{description}\n}
        );
      }

    }
    else    ## teapot error - cannot can get discovery data for google api endpoint
    {
      push( @teapot_errors, "Checking discovery of $params->{api_endpoint_id} method data failed - is this a valid end point ?" );
    }
    ## prepend the base to the URI path if it looks necessary


    carp Dumper $method_discovery_struct;
    ## confirm that http method is set correctly and set if not defined

    ## todo - interpolate uri params both for endpoint and GET params
    ## todo - populate default for required params that aren't set
    ## todo - confirm that require params are included

  }

  if ( @teapot_errors > 0 )    ## carp and include in 418 response body the teapot errors
  {
    carp( join( "\n", @teapot_errors ) ) if $self->debug;
    return Mojo::Message::Response->new(
      content_type => 'text/plain',
      code         => 418,
      message      => 'Teapot Error - Reqeust blocked before submitting to server with pre-query validation errors',
      body         => join( "\n", @teapot_errors )
    );
  }
  else
  {
    #return $self->ua->api_query( $params );

    carp Dumper $params;
    return $params;
  }

}
############################ ************ #########################


