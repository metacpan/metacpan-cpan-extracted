use strictures;

package WebService::GoogleAPI::Client::Discovery;

our $VERSION = '0.24';    # VERSION

# ABSTRACT: Google API discovery service


use Moo;
use Carp;
use WebService::GoogleAPI::Client::UserAgent;
use List::Util qw/uniq reduce/;
use List::SomeUtils qw/pairwise/;
use Data::Dump qw/pp/;
use CHI;

has ua => (
  is      => 'rw',
  default => sub { WebService::GoogleAPI::Client::UserAgent->new }
);
has debug => (is => 'rw', default => 0);
has 'chi' => (
  is      => 'rw',
  default => sub { CHI->new(driver => 'File', namespace => __PACKAGE__) },
  lazy    => 1
);    ## i believe that this gives priority to param if provided ?
has 'stats' => is => 'rw',
  default   => sub { { network => { get => 0 }, cache => { get => 0 } } };


sub get_with_cache {
  my ($self, $key, $force, $authorized) = @_;

  my $expiration = $self->chi->get_expires_at($key) // 0;

  my $will_expire = $expiration - time();
  if ($will_expire > 0 && not $force) {
    carp "discovery_data cached data expires in $will_expire seconds"
      if $self->debug > 2;
    my $ret = $self->chi->get($key);
    croak 'was expecting a HASHREF!' unless ref $ret eq 'HASH';
    $self->stats->{cache}{get}++;
    return $ret;
  } else {
    my $ret;
    if ($authorized) {
      $ret = $self->ua->validated_api_query($key);
      $self->stats->{network}{authorized}++;
    } else {
      $ret = $self->ua->get($key)->res;
    }
    if ($ret->is_success) {
      my $all = $ret->json;
      $self->stats->{network}{get}++;
      $self->chi->set($key, $all, '30d');
      return $all;
    } else {
      if ($ret->code == 403 && !$authorized) {
        return $self->get_with_cache($key, $force, 1);
      }
      croak $ret->message;
    }
  }
  return {};
}


sub discover_key { 'https://www.googleapis.com/discovery/v1/apis' }

sub discover_all {
  my $self = shift;
  $self->get_with_cache($self->discover_key, @_);
}

#TODO- double triple check that we didn't break anything with the
#hashref change


#TODO- maybe cache this on disk too?
my $available;

sub _invalidate_available {
  $available = undef;
}

sub available_APIs {

  #cache this crunch
  return $available if $available;

  my ($self) = @_;
  my $d_all = $self->discover_all;
  croak 'no items in discovery data' unless defined $d_all->{items};

  #grab only entries with the four keys we want
  #and strip other keys
  my @keys = qw/name version documentationLink discoveryRestUrl/;
  my @relevant;
  for my $i (@{ $d_all->{items} }) {
    next unless @keys == grep { exists $i->{$_} } @keys;
    push @relevant, { %{$i}{@keys} };
  }

  my $reduced = reduce {
    for my $key (qw/version documentationLink discoveryRestUrl/) {
      $a->{ $b->{name} }->{$key} //= [];
      push @{ $a->{ $b->{name} }->{$key} }, $b->{$key};
    }
    $a;
  }
  {}, @relevant;

  #store it away globally
  $available = $reduced;
}


sub augment_discover_all_with_unlisted_experimental_api {
  my ($self, $api_spec) = @_;
  carp <<DEPRECATION;
This lengthy function name (augment_discover_all_with_unlisted_experimental_api)
will be removed soon.  Please use 'augment_with' instead.
DEPRECATION
  $self->augment_with($api_spec);
}

sub augment_with {
  my ($self, $api_spec) = @_;

  my $all = $self->discover_all();

  ## fail if any of the expected fields are not provided
  for my $field (
    qw/version title description id kind documentationLink
    discoveryRestUrl name/
  ) {
    if (not defined $api_spec->{$field}) {
      carp("required $field in provided api spec missing");
    }
  }

  push @{ $all->{items} }, $api_spec;
  $self->chi->set($self->discover_key, $all, '30d');
  $self->_invalidate_available;
  return $all;
}



sub service_exists {
  my ($self, $api) = @_;
  return unless $api;
  return $self->available_APIs->{$api};
}


sub available_versions {
  my ($self, $api) = @_;
  return [] unless $api;
  return $self->available_APIs->{$api}->{version} // [];
}


sub latest_stable_version {
  my ($self, $api) = @_;
  return '' unless $api;
  my $versions = $self->available_versions($api);
  return '' unless $versions;
  return '' unless @{$versions} > 0;

  #remove alpha or beta versions
  my @stable = grep { !/beta|alpha/ } @$versions;
  return $stable[-1] || '';
}


sub process_api_version {
  my ($self, $params) = @_;

  # scalar parameter not hashref - so assume is intended to be $params->{api}
  $params = { api => $params } if ref $params eq '';

  croak "'api' must be defined" unless $params->{api};

  ## trim any resource, method or version details in api id
  if ($params->{api} =~ /([^:]+):(v[^\.]+)/ixsm) {
    $params->{api}     = $1;
    $params->{version} = $2;
  }
  if ($params->{api} =~ /^(.*?)\./xsm) {
    $params->{api} = $1;
  }

  unless ($self->service_exists($params->{api})) {
    croak "$params->{api} does not seem to be a valid Google API";
  }

  $params->{version} //= $self->latest_stable_version($params->{api});
  return $params;
}



sub get_api_discovery_for_api_id {
  carp <<DEPRECATION;
This long method name (get_api_discovery_for_api_id) is being deprecated
in favor of get_api_document. Please switch your code soon
DEPRECATION
  shift->get_api_document(@_);
}

sub get_api_document {
  my ($self, $arg) = @_;

  my $params = $self->process_api_version($arg);
  my $apis   = $self->available_APIs();

  my $api = $apis->{ $params->{api} };
  croak "No versions found for $params->{api}" unless $api->{version};

  my @versions = @{ $api->{version} };
  my @urls     = @{ $api->{discoveryRestUrl} };
  my ($url) = pairwise { $a eq $params->{version} ? $b : () } @versions, @urls;

  croak "Couldn't find correct url for $params->{api} $params->{version}"
    unless $url;

  $self->get_with_cache($url);
}

#TODO- HERE - we are here in refactoring
sub _extract_resource_methods_from_api_spec {
  my ($self, $tree, $api_spec, $ret) = @_;
  $ret = {} unless defined $ret;
  croak("ret not a hash - $tree, $api_spec, $ret") unless ref($ret) eq 'HASH';

  if (defined $api_spec->{methods} && ref($api_spec->{methods}) eq 'HASH') {
    foreach my $method (keys %{ $api_spec->{methods} }) {
      $ret->{"$tree.$method"} = $api_spec->{methods}{$method}
        if ref($api_spec->{methods}{$method}) eq 'HASH';
    }
  }
  if (defined $api_spec->{resources}) {
    foreach my $resource (keys %{ $api_spec->{resources} }) {
      ## NB - recursive traversal down tree of api_spec resources
      $self->_extract_resource_methods_from_api_spec("$tree.$resource",
        $api_spec->{resources}{$resource}, $ret);
    }
  }
  return $ret;
}



sub extract_method_discovery_detail_from_api_spec {
  carp <<DEPRECATION;
This rather long method name (extract_method_discovery_detail_from_api_spec)
is being deprecated in favor of get_method_details. Please switch soon
DEPRECATION
  shift->get_method_details(@_);
}

sub get_method_details {
  my ($self, $tree, $api_version) = @_;
  ## where tree is the method in format from _extract_resource_methods_from_api_spec() like projects.models.versions.get
  ##   the root is the api id - further '.' sep levels represent resources until the tailing label that represents the method
  croak 'You must ask for a method!' unless defined $tree;

  my @nodes = split /\./smx, $tree;
  croak(
"tree structure '$tree' must contain at least 2 nodes including api id, [list of hierarchical resources ] and method - not "
      . scalar(@nodes))
    unless @nodes > 1;

  my $api_id = shift(@nodes);    ## api was head
  my $method = pop(@nodes);      ## method was tail

  ## split out version if is defined as part of $tree
  ## trim any resource, method or version details in api id
  ## we have already isolated head from api tree children
  if ($api_id =~ /([^:]+):([^\.]+)$/ixsm) {
    $api_id      = $1;
    $api_version = $2;
  }

  ## handle incorrect api_id
  if ($self->service_exists($api_id) == 0) {
    croak("unable to confirm that '$api_id' is a valid Google API service id");
  }

  $api_version = $self->latest_stable_version($api_id) unless $api_version;


  ## TODO: confirm that spec available for api version
  my $api_spec =
    $self->get_api_document({ api => $api_id, version => $api_version });


  ## we use the schemas to substitute into '$ref' keyed placeholders
  my $schemas = {};
  foreach my $schema_key (sort keys %{ $api_spec->{schemas} }) {
    $schemas->{$schema_key} = $api_spec->{'schemas'}{$schema_key};
  }

  ## recursive walk through the structure in _fix_ref
  ##  substitute the schema keys into the total spec to include
  ##  '$ref' values within the schema structures themselves
  ##  including within the schema spec structures (NB assumes no cyclic structures )
  ##   otherwise would could recursive chaos
  my $api_spec_fix = $self->_fix_ref($api_spec, $schemas)
    ;    ## first level ( '$ref' in the method params and return values etc )
  $api_spec = $self->_fix_ref($api_spec_fix, $schemas)
    ;    ## second level ( '$ref' in the interpolated schemas from first level )

  ## now extract all the methods (recursive )
  my $all_api_methods =
    $self->_extract_resource_methods_from_api_spec("$api_id:$api_version",
    $api_spec);

  unless (defined $all_api_methods->{$tree}) {
    $all_api_methods =
      $self->_extract_resource_methods_from_api_spec($api_id, $api_spec);
  }
  if ($all_api_methods->{$tree}) {

    #add in the global parameters to the endpoint,
    #stored in the top level of the api_spec
    # TODO - why are we mutating the main hash?
    $all_api_methods->{$tree}{parameters} = {
      %{ $all_api_methods->{$tree}{parameters} },
      %{ $api_spec->{parameters} }
    };
    return $all_api_methods->{$tree};
  }

  croak(
"Unable to find method detail for '$tree' within Google Discovery Spec for $api_id version $api_version"
  );
}
########################################################

########################################################
########################################################

#=head2 C<fix_ref>
#
#This sub walks through the structure and replaces any hashes keyed with '$ref' with
#the value defined in $schemas->{ <value of keyed $ref> }
#
#eg
# ->{'response'}{'$ref'}{'Buckets'}
# is replaced with
# ->{response}{ $schemas->{Buckets} }
#
# It assumes that the schemas have been extracted from the original discover for the API
# and is typically applied to the method ( api endpoint ) to provide a fully descriptive
# structure without external references.
#
#=cut

########################################################
sub _fix_ref {
  my ($self, $node, $schemas) = @_;
  my $ret = undef;
  my $r   = ref($node);


  if ($r eq 'ARRAY') {
    $ret = [];
    foreach my $el (@$node) {
      push @$ret, $self->_fix_ref($el, $schemas);
    }
  } elsif ($r eq 'HASH') {
    $ret = {};
    foreach my $key (keys %$node) {
      if ($key eq '$ref') {

        #say $node->{'$ref'};
        $ret = $schemas->{ $node->{'$ref'} };
      } else {
        $ret->{$key} = $self->_fix_ref($node->{$key}, $schemas);
      }
    }
  } else {
    $ret = $node;
  }

  return $ret;
}
########################################################



#TODO: consider ? refactor to allow parameters either as a single api id such as 'gmail'
#      as well as the currently accepted  hash keyed on the api and version
#
#SEE ALSO:
#  The following methods are delegated through to Client::Discovery - see perldoc WebService::Client::Discovery for detils
#
#  get_method_meta
#  discover_all
#  extract_method_discovery_detail_from_api_spec
#  get_api_discovery_for_api_id

########################################################
#TODO- give short name and deprecate
sub methods_available_for_google_api_id {
  my ($self, $api_id, $version) = @_;

  $version = $self->latest_stable_version($api_id) unless $version;
  ## TODO: confirm that spec available for api version
  my $api_spec = $self->get_api_discovery_for_api_id(
    { api => $api_id, version => $version });
  my $methods =
    $self->_extract_resource_methods_from_api_spec($api_id, $api_spec);
  return $methods;
}
########################################################



sub list_of_available_google_api_ids {
  carp <<DEPRECATION;
This rather long function name (list_of_available_google_api_ids)
is being deprecated in favor of the shorter list_api_ids. Please
update your code accordingly.
DEPRECATION
  shift->list_api_ids;
}
## returns a list of all available API Services
sub list_api_ids {
  my ($self) = @_;
  my @api_list = keys %{ $self->available_APIs };
  return wantarray ? @api_list : join(',', @api_list);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::GoogleAPI::Client::Discovery - Google API discovery service

=head1 VERSION

version 0.24

=head2 MORE INFORMATION

L<https://developers.google.com/discovery/v1/reference/>

=head2 SEE ALSO

Not using Swagger but it is interesting - 
L<https://github.com/APIs-guru/openapi-directory/tree/master/APIs/googleapis.com> for Swagger Specs.

L<WebService::GoogleAPI::Client> - contains code for parsing discovery structures 

includes a chi property that is an instance of CHI using File Driver to cache discovery resources for 30 days

say $client-dicovery->chi->root_dir(); ## provides full file path to temp storage location used for caching

=head1 METHODS

=head2 get_with_cache

  my $hashref = $disco->get_with_cache($url, $force, $authenticate)

Retrieves the given API URL, retrieving and caching the returned
JSON. If it gets a 403 Unauthenticated error, then it will try
again using the credentials that are save on this instances 'ua'.

If passed a truthy value for $force, then will not use the cache.
If passed a truthy value for $authenticate, then will make the
request with credentials.

=head2 C<discover_all>

  my $hashref = $disco->discover_all($force, $authenticate)

Return details about all Available Google APIs as provided by Google or in CHI Cache.
Does the fetching with C<get_with_cache>, and arguments are as above.

On Success: Returns HASHREF with keys discoveryVersion,items,kind
On Failure: dies a horrible death. You probably don't want to continue in that case.

SEE ALSO: available_APIs, list_of_available_google_api_ids

=head2 C<available_APIs>

Return hashref keyed on api name, with arrays of versions, links to 
documentation, and links to the url for that version's API document.

    {
      youtube => {
        version           => [ 'v3', ... ]
        documentationLink => [ ...,  ... ] ,
        discoveryRestUrl  => [ ...,  ... ] ,
      },
      gmail => {
        ...
      } 
    }

Used internally to pull relevant discovery documents.

=head2 C<augment_with>

Allows you to augment the cached stored version of the discovery structure

    $augmented_document = $disco->augment_with({
      'version'   => 'v4',
      'preferred' => 1,
      'title'     => 'Google My Business API',
      'description' => 'The Google My Business API provides an interface for managing business location information on Google.',
      'id'                => 'mybusiness:v4',
      'kind'              => 'discovery#directoryItem',
      'documentationLink' => "https://developers.google.com/my-business/",
      'icons'             => {
        "x16" => "http://www.google.com/images/icons/product/search-16.gif",
        "x32" => "http://www.google.com/images/icons/product/search-32.gif"
      },
      'discoveryRestUrl' => 'https://developers.google.com/my-business/samples/mybusiness_google_rest_v4p2.json',
      'name' => 'mybusiness'
    });

This can also be used to overwrite the cached structure.

Can also be called as C<augment_discover_all_with_unlisted_experimental_api>, which is
being deprecated for being plain old too long.

=head2 C<service_exists>

Return 1 if Google Service API ID is described by Google API discovery. 
Otherwise return 0

  print $disco->service_exists('calendar');  # 1
  print $disco->service_exists('someapi');  # 0

Note that most Google APIs are fully lowercase, but some are camelCase. Please
check the documentation from Google for reference.

=head2 C<available_versions>

  Show available versions of particular API described by api id passed as parameter such as 'gmail'

  $disco->available_versions('calendar');  # ['v3']
  $disco->available_versions('youtubeAnalytics');  # ['v1','v1beta1']

  Returns arrayref

=head2 C<latest_stable_version>

return latest stable verion of API

  $d->available_versions('calendar');  # ['v3']
  $d->latest_stable_version('calendar');  # 'v3'

  $d->available_versions('tagmanager');  # ['v1','v2']
  $d->latest_stable_version('tagmanager');  # ['v2']

  $d->available_versions('storage');  # ['v1','v1beta1', 'v1beta2']
  $d->latest_stable_version('storage');  # ['v1']

=head2 C<process_api_version>

  my $hashref = $disco->process_api_version('gmail')   
     # { api => 'gmail', version => 'v1' }
  my $hashref = $disco->process_api_version({ api => 'gmail' })   
     # { api => 'gmail', version => 'v1' }
  my $hashref = $disco->process_api_version('gmail:v2') 
     # { api => 'gmail', version 'v2' }

Takes a version string and breaks it into a hashref. If no version is 
given, then default to the latest stable version in the discover document.

=head2 get_api_document

returns the cached version if avaiable in CHI otherwise retrieves discovery data via HTTP, stores in CHI cache and returns as
a Perl data structure.

    my $hashref = $self->get_api_document( 'gmail' );
    my $hashref = $self->get_api_document( 'gmail:v3' );
    my $hashref = $self->get_api_document( 'gmail:v3.users.list' );
    my $hashref = $self->get_api_document( { api=> 'gmail', version => 'v3' } );

NB: if deeper structure than the api_id is provided then only the head is used
so get_api_document( 'gmail' ) is the same as get_api_document( 'gmail.some.child.method' )
returns the api discovery specification structure ( cached by CHI ) for api id (eg 'gmail')
returns the discovery data as a hashref, an empty hashref on certain failing conditions or croaks on critical errors.

Also available as get_api_discovery_for_api_id, which is being deprecated.

=head2 C<get_method_details>

    $disco->get_method_details($tree, $api_version)

returns a hashref representing the discovery specification for the
method identified by $tree in dotted API format such as
texttospeech.text.synthesize

Dies a horrible death if not found.

Also available as C<extract_method_discovery_detail_from_api_spec>, but the long name is being
deprecated in favor of the more compact one.

=head2 C<methods_available_for_google_api_id>

Returns a hashref keyed on the Google service API Endpoint in dotted format.
The hashed content contains a structure
representing the corresponding discovery specification for that method ( API Endpoint )

    methods_available_for_google_api_id('gmail.users.settings.delegates.get');

    methods_available_for_google_api_id('gmail.users.settings.delegates.get', 'v1');

=head2 C<list_api_ids>

Returns an array list of all the available API's described in the API Discovery Resource
that is either fetched or cached in CHI locally for 30 days.

    my $r = $agent->list_api_ids();
    print "List of API Services ( comma separated): $r\n";

    my @list = $agent->list_api_ids();

Formerly was list_of_available_google_api_ids, which will now give a deprecation warning
to switch to list_api_ids.

=head1 AUTHORS

=over 4

=item *

Veesh Goldman <veesh@cpan.org>

=item *

Peter Scott <localshop@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2021 by Peter Scott and others.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
