use strictures;

package WebService::GoogleAPI::Client::Discovery;
$WebService::GoogleAPI::Client::Discovery::VERSION = '0.11';

# ABSTRACT: Google API discovery service


use Moo;
use Carp;
use WebService::GoogleAPI::Client::UserAgent;
use List::Util qw/uniq/;
use Hash::Slice qw/slice/;
use Data::Dumper;
use CHI;    # Caching .. NB Consider reviewing https://metacpan.org/pod/Mojo::UserAgent::Role::Cache


has 'ua' => ( is => 'rw', default => sub { WebService::GoogleAPI::Client::UserAgent->new }, lazy => 1 );    ## typically shared with parent instance of Client which sets on new
has 'debug' => ( is => 'rw', default => 0, lazy => 1 );
has 'chi' => ( is => 'rw', default => sub { CHI->new( driver => 'File', namespace => __PACKAGE__ ) }, lazy => 1 );


sub get_api_discovery_for_api_id
{
  my ( $self, $params ) = @_;
  ## TODO: warn if user doesn't have the necessary scope .. no should stil be able to examine
  ## TODO: consolidate the http method calls to a single function - ie - discover_all - simplistic quick fix -  assume that if no param then endpoint is as per discover_all


  $params = { api => $params } if ref( $params ) eq '';    ## scalar parameter not hashref - so assume is intended to be $params->{api}
  ## trim any resource, method or version details in api id
  if ( $params->{ api } =~ /([^:]+):(v\d+)/ixsm )
  {
    $params->{ api }     = $1;
    $params->{ version } = $2;
  }
  if ( $params->{ api } =~ /^(.*?)\./xsm )
  {
    $params->{ api } = $1;
    ## TODO: split version if is in name:v3 format
  }


  croak( "get_api_discovery_for_api_id called with api param undefined" . Dumper $params) unless defined $params->{ api };
  $params->{ version } = $self->latest_stable_version( $params->{ api } ) unless defined $params->{ version };

  croak( "get_api_discovery_for_api_id called with empty api param defined" . Dumper $params)     if $params->{ api } eq '';
  croak( "get_api_discovery_for_api_id called with empty version param defined" . Dumper $params) if $params->{ version } eq '';

  my $aapis = $self->available_APIs();


  my $api_verson_urls = {};
  for my $api ( @{ $aapis } )
  {
    for ( my $i = 0; $i < scalar @{ $api->{ versions } }; $i++ )
    {
      $api_verson_urls->{ $api->{ name } }{ $api->{ versions }[$i] } = $api->{ discoveryRestUrl }[$i];
    }
  }
  croak( "Unable to determine discovery URI for any version of $params->{api}" ) unless defined $api_verson_urls->{ $params->{ api } };
  croak( "Unable to determine discovery URI for $params->{api} $params->{version}" ) unless defined $api_verson_urls->{ $params->{ api } }{ $params->{ version } };
  my $api_discovery_uri = $api_verson_urls->{ $params->{ api } }{ $params->{ version } };

  #carp "get_api_discovery_for_api_id requires data from  $api_discovery_uri" if $self->debug;
  if ( my $dat = $self->chi->get( $api_discovery_uri ) )    ## clobbers some of the attempted thinking further on .. just return it for now if it's there
  {
    #carp Dumper $dat;
    return $dat;
  }

  if ( my $expires_at = $self->chi->get_expires_at( $api_discovery_uri ) )    ## maybe this isn't th ebest way to check if get available.
  {
    carp "CHI '$api_discovery_uri' cached data with root = " . $self->chi->root_dir . "expires  in ", scalar( $expires_at ) - time(), " seconds\n" if $self->debug;

    #carp "Value = " . Dumper $self->chi->get( $api_discovery_uri ) if  $self->debug ;
    return $self->chi->get( $api_discovery_uri );

  }
  else
  {
    carp "'$api_discovery_uri' not in cache - fetching it" if $self->debug;
    ## TODO: better handle failed response - if 403 then consider adding in the auth headers and trying again.
    #croak("Huh $api_discovery_uri");
    my $ret = $self->ua->validated_api_query( $api_discovery_uri );    # || croak("Failed to retrieve $api_discovery_uri");;
    if ( $ret->is_success )
    {
      my $dat = $ret->json || croak( "failed to convert $api_discovery_uri return data in json" );

      #carp("dat1 = " . Dumper $dat);
      $self->chi->set( $api_discovery_uri, $dat, '30 days' );
      return $dat;

      #my $ret_data = $self->chi->get( $api_discovery_uri );
      #carp ("ret_data = " . Dumper $ret_data) unless ref($ret_data) eq 'HASH';
      #return $ret_data;# if ref($ret_data) eq 'HASH';
      #croak();
      #$self->chi->remove( $api_discovery_uri ) unless eval '${^TAINT}'; ## if not hashref then assume is corrupt so delete it
    }
    else
    {
      ## TODO - why is this failing for certain resources ?? because the urls contain a '$' ? because they are now authenticated?
      carp( "Fetching resource failed - $ret->message" );    ## was croaking
      carp( Dumper $ret );
      return {};                                             #$ret;
    }
  }
  croak( "something went wrong in get_api_discovery_for_api_id key = '$api_discovery_uri' - try again to see if data corruption has been flushed for " . Dumper $params);

  #return $self->chi->get( $api_discovery_uri );
  #croak('never gets here');
}



sub discover_all
{

  my ( $self, $force ) = @_;

  if ( my $expires_at = $self->chi->get_expires_at( 'https://www.googleapis.com/discovery/v1/apis' ) && not $force )
  {
    #carp "discovery_data cached data expires in ", scalar($expires_at) - time(), " seconds\n" if  ($self->debug > 2);
    return $self->chi->get( 'https://www.googleapis.com/discovery/v1/apis' );
  }
  else    ##
  {
    #return $self->chi->get('https://www.googleapis.com/discovery/v1/apis') if ($self->chi->get('https://www.googleapis.com/discovery/v1/apis'));
    my $ret = $self->ua->validated_api_query( 'https://www.googleapis.com/discovery/v1/apis' );
    if ( $ret->is_success )
    {
      my $all = $ret->json;
      $self->chi->set( 'https://www.googleapis.com/discovery/v1/apis', $all, '30d' );
      return $self->chi->get( 'https://www.googleapis.com/discovery/v1/apis' );
    }
    else
    {

      carp( "$ret->message" );    ## should probably croak
      return {};
    }
  }
  return {};
}



sub augment_discover_all_with_unlisted_experimental_api
{
  my ( $self, $api_spec ) = @_;

  my $all = $self->discover_all();

#warn Dumper $all;
  ## fail if any of the expected fields are not provided
  foreach my $field ( qw/version title description id kind documentationLink discoveryRestUrl name/ )    ## icons preferred
  {
    if ( not defined $api_spec->{ $field } )
    {
      carp( "required $field in provided experimental api spec in not defined - returning without augmentation" );
      return $all;
    }

  }


  ## warn and return existing data if entry appears to already exist
  foreach my $i ( @{ $all->{ items } } )
  {
    if ( ( $i->{ name } eq $api_spec->{ name } ) && ( $i->{ version } eq $api_spec->{ version } ) )
    {
      carp( "There is already an entry with name = $i->{name} and version = $i->{version} - no modifications saved" );
      return $all;
    }
    if ( $i->{ id } eq $api_spec->{ id } )
    {
      carp( "There is already an entry with id = $i->{id} - no modifications saved" );
      return $all;
    }
  }
  push @{ $all->{ items } }, $api_spec;
  $self->chi->set( 'https://www.googleapis.com/discovery/v1/apis', $all, '30d' );
  return $self->chi->get( 'https://www.googleapis.com/discovery/v1/apis' );

}



sub available_APIs
{
  my ( $self ) = @_;
  my $all = $self->discover_all()->{ items };

  #print Dumper $all;
  for my $i ( @$all )
  {
    $i = { map { $_ => $i->{ $_ } } grep { exists $i->{ $_ } } qw/name version documentationLink discoveryRestUrl/ };
  }
  my @subset = uniq map { $_->{ name } } @$all;    ## unique names
                                                   # carp scalar @$all;
                                                   # carp scalar @subset;
                                                   # carp Dumper \@subset;
                                                   # my @a = map { $_->{name} } @$all;

  my @arr;
  for my $s ( @subset )
  {
    #print Dumper $s;
    my @v               = map      { $_->{ version } } grep           { $_->{ name } eq $s } @$all;
    my @doclinks        = uniq map { $_->{ documentationLink } } grep { $_->{ name } eq $s } @$all;
    my @discovery_links = map      { $_->{ discoveryRestUrl } } grep  { $_->{ name } eq $s } @$all;

    # carp "Match! :".Dumper \@v;
    # my $versions = grep
    push @arr, { name => $s, versions => \@v, doclinks => \@doclinks, discoveryRestUrl => \@discovery_links };
  }

  #carp Dumper \@arr;
  #exit;
  return \@arr;

  # return \@a;
}


sub service_exists
{
  my ( $self, $api ) = @_;
  return 0 unless $api;
  my $apis_all = $self->available_APIs();
  return grep { $_->{ name } eq $api } @$apis_all;    ## 1 iff an equality is found with keyed name
}


sub supported_as_text
{
  my ( $self ) = @_;
  my $ret = '';
  for my $api ( @{ $self->available_APIs() } )
  {
    croak( 'doclinks key defined but is not the expected arrayref' ) unless ref $api->{ doclinks } eq 'ARRAY';
    croak( 'array of apis provided by available_APIs includes one without a defined name' ) unless defined $api->{ name };

    my @clean_doclinks = grep { defined $_ } @{ $api->{ doclinks } };    ## was seeing undef in doclinks array - eg 'surveys'causing warnings in join

    ## unique doclinks using idiom from https://www.oreilly.com/library/view/perl-cookbook/1565922433/ch04s07.html
    my %seen = ();
    my $doclinks = join( ',', ( grep { !$seen{ $_ }++ } @clean_doclinks ) ) || '';    ## unique doclinks as string

    $ret .= $api->{ name } . ' : ' . join( ',', @{ $api->{ versions } } ) . ' : ' . $doclinks . "\n";
  }
  return $ret;
}


sub available_versions
{
  my ( $self, $api ) = @_;
  return [] unless $api;
  my @api_target = grep { $_->{ name } eq $api } @{ $self->available_APIs() };
  return [] if scalar( @api_target ) == 0;
  return $api_target[0]->{ versions };
}


sub latest_stable_version
{
  my ( $self, $api ) = @_;
  return '' unless $api;
  return '' unless $self->available_versions( $api );
  return '' unless @{ $self->available_versions( $api ) } > 0;
  my $versions = $self->available_versions( $api );    # arrayref
  if ( $versions->[-1] =~ /beta/ )
  {
    return $versions->[0];
  }
  else
  {
    return $versions->[-1];
  }
}


########################################################
sub api_verson_urls
{
  my ( $self ) = @_;
  ## transform structure to be keyed on api->versionRestUrl
  my $aapis           = $self->available_APIs();
  my $api_verson_urls = {};
  for my $api ( @{ $aapis } )
  {
    for ( my $i = 0; $i < scalar @{ $api->{ versions } }; $i++ )
    {
      $api_verson_urls->{ $api->{ name } }{ $api->{ versions }[$i] } = $api->{ discoveryRestUrl }[$i];
    }
  }
  return $api_verson_urls;
}
########################################################



########################################################
sub extract_method_discovery_detail_from_api_spec
{
  my ( $self, $tree, $api_version ) = @_;
  ## where tree is the method in format from _extract_resource_methods_from_api_spec() like projects.models.versions.get
  ##   the root is the api id - further '.' sep levels represent resources until the tailing label that represents the method
  return {} unless defined $tree;
  my @nodes = split /\./smx, $tree;
  croak( "tree structure '$tree' must contain at least 2 nodes including api id, [list of hierarchical resources ] and method - not " . scalar( @nodes ) )
    unless scalar( @nodes ) > 1;

  my $api_id = shift( @nodes );    ## api was head
  my $method = pop( @nodes );      ## method was tail

  ## handle incorrect api_id
  if ( $self->service_exists( $api_id ) == 0 )
  {
    carp( "unable to confirm that '$api_id' is a valid Google API service id" );
    return {};
  }

  $api_version = $self->latest_stable_version( $api_id ) unless $api_version;
  ## TODO: confirm that spec available for api version
  my $api_spec = $self->get_api_discovery_for_api_id( { api => $api_id, version => $api_version } );
  ## TODO - check for failure?
  my $all_api_methods = $self->_extract_resource_methods_from_api_spec( $api_id, $api_spec );
  if ( defined $all_api_methods->{ $tree } )
  {
    return $all_api_methods->{ $tree };
  }
  else
  {
    carp( "Unable to find method detail for '$tree' within Google Discovery Spec for $api_id version $api_version" ) if $self->debug;
    return {};
  }
}
########################################################

########################################################
sub _extract_resource_methods_from_api_spec
{
  my ( $self, $tree, $api_spec, $ret ) = @_;
  $ret = {} unless defined $ret;
  croak( "ret not a hash - $tree, $api_spec, $ret" ) unless ref( $ret ) eq 'HASH';

  if ( defined $api_spec->{ methods } && ref( $api_spec->{ methods } ) eq 'HASH' )
  {
    foreach my $method ( keys %{ $api_spec->{ methods } } )
    {
      $ret->{ "$tree.$method" } = $api_spec->{ methods }{ $method } if ref( $api_spec->{ methods }{ $method } ) eq 'HASH';
    }
  }
  if ( defined $api_spec->{ resources } )
  {
    foreach my $resource ( keys %{ $api_spec->{ resources } } )
    {
      ## NB - recursive traversal down tree of api_spec resources
      $self->_extract_resource_methods_from_api_spec( "$tree.$resource", $api_spec->{ resources }{ $resource }, $ret );
    }
  }
  return $ret;
}
########################################################



########################################################
## TODO: consider renaming ?
sub methods_available_for_google_api_id
{
  my ( $self, $api_id, $version ) = @_;
  $version = $self->latest_stable_version( $api_id ) unless $version;
  ## TODO: confirm that spec available for api version
  my $api_spec = $self->get_api_discovery_for_api_id( { api => $api_id, version => $version } );
  my $methods = $self->_extract_resource_methods_from_api_spec( $api_id, $api_spec );
  return $methods;
}
########################################################



########################################################
## returns a list of all available API Services
sub list_of_available_google_api_ids
{
  my ( $self ) = @_;
  my $aapis = $self->available_APIs();    ## array of hashes
  my @api_list = map { $_->{ name } } @$aapis;
  return wantarray ? @api_list : join( ',', @api_list );    ## allows to be called in either list or scalar context
                                                            #return @api_list;

}
########################################################


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::GoogleAPI::Client::Discovery - Google API discovery service

=head1 VERSION

version 0.11

=head2 MORE INFORMATION

L<https://developers.google.com/discovery/v1/reference/>

=head2 SEE ALSO

Not using Swagger but it is interesting - 
L<https://github.com/APIs-guru/openapi-directory/tree/master/APIs/googleapis.com> for Swagger Specs.

L<Google::API::Client> - contains code for parsing discovery structures 

includes a chi property that is an instance of CHI using File Driver to cache discovery resources for 30 days

say $client-dicovery->chi->root_dir(); ## provides full file path to temp storage location used for caching

=head2 TODO

* deal with case of service names - either make it case insensitive or lock in a consistent approach - currently smells like case changes on context
* handle 403 ( Daily Limit for Unauthenticated Use Exceeded.) errors when reqeusting a disdovery resource for a resvice 
  but do we have access to authenticated reqeusts?
* consider refactoring this entire module into UserAgent .. NB - this is also included as property of  Services.pm which is the factory for dynamic classes

=head1 METHODS

=head2 get_api_discovery_for_api_id

returns the cached version if avaiable in CHI otherwise retrieves discovery data via HTTP, stores in CHI cache and returns as
a Perl data structure.

  my $hashref = $self->get_api_discovery_for_api_id( 'gmail' );
  my $hashref = $self->get_api_discovery_for_api_id( 'gmail:v3' );

returns the api discovery specification structure ( cached by CHI ) for api id ( eg 'gmail ')

returns the discovery data as a hashref, an empty hashref on certain failing conditions or croaks on critical errors.

=head2 C<discover_all>

TODO: Consider rename to return_fetched_google_v1_apis_discovery_structure

TODO - handle auth required error and resubmit request with OAUTH headers if response indicates
       access requires auth ( when exceed free access limits )        

  Return details about all Available Google APIs as provided by Google or in CHI Cache

  On Success: Returns HASHREF with keys discoveryVersion,items,kind
  On Failure: Warns and returns empty hashref

    my $d = WebService::GoogleAPI::Client::Discovery->new;
    print Dumper $d;

    WebService::GoogleAPI::Client::Discovery->discover_all();

    $client->discover_all();
    $client->discover_all(1); ## NB if include a parameter that evaluates to true such as '1' then the cache is flushed with a new version

SEE ALSO: available_APIs, list_of_available_google_api_ids

=head2 C<augment_discover_all_with_unlisted_experimental_api>

Allows you to augment the cached stored version of the discovery structure

augment_discover_all_with_unlisted_experimental_api( 
                     {
                       'version' => 'v4',
                       'preferred' => 1,
                       'title' => 'Google My Business API',
                       'description' => 'The Google My Business API provides an interface for managing business location information on Google.',
                       'id' => 'mybusiness:v4',
                       'kind' => 'discovery#directoryItem',
                       'documentationLink' => "https://developers.google.com/my-business/",
                       'icons' => {
                                  "x16": "http://www.google.com/images/icons/product/search-16.gif",
                                  "x32": "http://www.google.com/images/icons/product/search-32.gif"
                                },
                       'discoveryRestUrl' => 'https://developers.google.com/my-business/samples/mybusiness_google_rest_v4p2.json',
                       'name' => 'mybusiness'
                     }  );

if there is a conflict with the existing then warn and return the existing data without modification

on success just returns the augmented structure

=head2 C<available_APIs>

Return arrayref of all available API's (services)

    {
      'name' => 'youtube',
      'versions' => [ 'v3' ]
      documentationLink =>  ,
      discoveryRestUrl =>  ,
    },

Originally for printing list of supported API's in documentation ..

SEE ALSO: 
may be better/more flexible to use client->list_of_available_google_api_ids  
client->discover_all which is delegated to Client::Discovery->discover_all

=head2 C<service_exists>

 Return 1 if Google Service API ID is described by Google API discovery. 
 Otherwise return 0

  print $d->service_exists('calendar');  # 1
  print $d->service_exists('someapi');  # 0

NB - Is case sensitive - all lower is required so $d->service_exists('Calendar') returns 0

=head2 C<supported_as_text>

  No params.
  Returns list of supported APIs as string in human-readible format ( name, versions and doclinks )

=head2 C<available_versions>

  Show available versions of particular API described by api id passed as parameter such as 'gmail'

  $d->available_versions('calendar');  # ['v3']
  $d->available_versions('youtubeAnalytics');  # ['v1','v1beta1']

  Returns arrayref

=head2 C<latest_stable_version>

return latest stable verion of API

  $d->available_versions('calendar');  # ['v3']
  $d->latest_stable_version('calendar');  # 'v3'

  $d->available_versions('tagmanager');  # ['v1','v2']
  $d->latest_stable_version('tagmanager');  # ['v2']

  $d->available_versions('storage');  # ['v1','v1beta1', 'v1beta2']
  $d->latest_stable_version('storage');  # ['v1']

=head2 C<extract_method_discovery_detail_from_api_spec>

$self->extract_method_discovery_detail_from_api_spec( $tree, $api_version )

returns a hashref representing the discovery specification for the method identified by $tree in dotted API format such as texttospeech.text.synthesize

returns an empty hashref if not found

=head2 C<methods_available_for_google_api_id>

Returns a hashref keyed on the Google service API Endpoint in dotted format.
The hashed content contains a structure
representing the corresponding discovery specification for that method ( API Endpoint )

    methods_available_for_google_api_id('gmail.users.settings.delegates.get')

TODO: consider ? refactor to allow parameters either as a single api id such as 'gmail' 
      as well as the currently accepted  hash keyed on the api and version

SEE ALSO:  
  The following methods are delegated through to Client::Discovery - see perldoc WebService::Client::Discovery for detils

  get_method_meta 
  discover_all 
  extract_method_discovery_detail_from_api_spec 
  get_api_discovery_for_api_id

=head2 C<list_of_available_google_api_ids>

Returns an array list of all the available API's described in the API Discovery Resource
that is either fetched or cached in CHI locally for 30 days.

=head1 AUTHOR

Peter Scott <localshop@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2018 by Peter Scott and others.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
