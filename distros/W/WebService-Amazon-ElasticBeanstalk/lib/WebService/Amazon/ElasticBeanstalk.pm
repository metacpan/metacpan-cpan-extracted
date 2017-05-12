package WebService::Amazon::ElasticBeanstalk;
use base qw( WebService::Simple );

use 5.006;
use strict;
use warnings FATAL => 'all';

#binmode STDOUT, ":encoding(UTF-8)";

use AWS::Signature4;
use Carp;
use HTTP::Request::Common;
use LWP;
use Params::Validate qw( :all );
use Readonly;
#use Smart::Comments '###';
#use Smart::Comments '###', '####';
#use Smart::Comments '###', '####', '#####';
require XML::Simple;

=encoding utf-8

=head1 NAME

WebService::Amazon::ElasticBeanstalk - Basic interface to Amazon ElasticBeanstalk

=head1 VERSION

Version 0.0.8

=cut

use version;
our $VERSION = version->declare("v0.0.8");

=head1 SYNOPSIS

This module provides a Perl wrapper around Amazon's 
( L<http://aws.amazon.com> ) ElasticBeanstalk API.  You will need 
to be an AWS customer with an ID and Secret which has been provided 
access to Elastic Beanstalk.

B<Note:> Some parameter validation is purposely lax. The API will 
generally fail when invalid params are passed. The errors may not 
be helpful.

=cut

# From: http://docs.aws.amazon.com/general/latest/gr/rande.html#elasticbeanstalk_region
# FIXME: use an array and assemble the URL in the constructor?
Readonly our %REGIONS => (
 'us-east-1'      => 'https://elasticbeanstalk.us-east-1.amazonaws.com',
 'us-west-1'      => 'https://elasticbeanstalk.us-west-1.amazonaws.com',
 'us-west-2'      => 'https://elasticbeanstalk.us-west-2.amazonaws.com',
 'eu-west-1'      => 'https://elasticbeanstalk.eu-west-1.amazonaws.com',
 'eu-central-1'   => 'https://elasticbeanstalk.eu-central-1.amazonaws.com',
 'ap-southeast-1' => 'https://elasticbeanstalk.ap-southeast-1.amazonaws.com',
 'ap-southeast-2' => 'https://elasticbeanstalk.ap-southeast-2.amazonaws.com',
 'ap-northeast-1' => 'https://elasticbeanstalk.ap-northeast-1.amazonaws.com',
 'sa-east-1'      => 'https://elasticbeanstalk.sa-east-1.amazonaws.com'
);

# Global API Version and Default Region
Readonly our $API_VERSION => '2010-12-01';
Readonly our $DEF_REGION  => 'us-east-1';

# some defaults
__PACKAGE__->config(
  base_url => $REGIONS{'us-east-1'},
);

# Global patterns for param validation
Readonly our $REGEX_ID     => '^[A-Z0-9]{20}$';
Readonly our $REGEX_REGION => '^[a-z]{2}-[a-z].*?-\d$';
Readonly our $REGEX_SECRET => '^[A-Za-z0-9/+]{40}$';

Readonly our $REGEX_CONDITIONS => '^(haveAtLeastOneUnapproved|haveAtLeastOneApproved|haveAtLeastOneTranslated|haveAllTranslated|haveAllApproved|haveAllUnapproved)$';
Readonly our $REGEX_FILETYPES  => '^(android|docx|ios|gettext|html|xlsx|javaProperties|json|pptx|xliff|xlsx|xml|yaml)$';
Readonly our $REGEX_FILEURI    => '^\S+$';
Readonly our $REGEX_INT        => '^\d+$';
Readonly our $REGEX_RETYPE     => '^(pending|published|pseudo)$';
Readonly our $REGEX_URL        => '^(https?|ftp|file)://.+$';
# From: http://www.pelagodesign.com/blog/2009/05/20/iso-8601-date-validation-that-doesnt-suck/
Readonly our $REGEX_DATE_ISO8601 => '^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6])))([T\s]((([01]\d|2[0-3])((:?)[0-5]\d)?|24\:?00)([\.,]\d+(?!:))?)?(\17[0-5]\d([\.,]\d+)?)?([zZ]|([\+-])([01]\d|2[0-3]):?([0-5]\d)?)?)?)?$';

=head1 INTERFACE

=head2 new

Inherited from L<WebService::Simple>, and takes all the same arguments. 
You B<must> provide the Amazon required arguments of B<id>, and B<secret> 
in the param hash:

   my $ebn = WebService::Amazon::ElasticBeanstalk->new( param => { id     => $AWS_ACCESS_KEY_ID,
                                                                   region => 'us-east-1',
                                                                   secret => $AWS_ACCESS_KEY_SECRET } );

=over 4

=item B<Parameters>

=item id B<(required)>

You can find more information in the AWS docs: 
L<http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/CommonParameters.html>

=item region I<(optional)> - defaults to us-east-1

You can find available regions at: 
L<http://docs.aws.amazon.com/general/latest/gr/rande.html#elasticbeanstalk_region>

=item secret B<(required)>

You can find more information in the AWS docs: 
L<http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/CommonParameters.html>

=back

=cut

#   apiKey             => { type => SCALAR, regex => qr/$REGEX_APIKEY/, },
#   approved           => { type => SCALAR, },
#   callbackUrl        => { type => SCALAR, regex => qr/$REGEX_URL/, },
#   conditions         => { type => ARRAYREF },
#   file               => { type      => SCALAR,
#                           callbacks => {
#                             'readable file' => sub { my( $f ) = shift(); return "$f" ne "" && -r "$f" },
#                             'less than 5MB' => sub { my( $f ) = shift(); return "$f" ne "" && -r "$f" && (sprintf( "%.2f", (-s "$f") / 1024 / 1024) < 5 ); };
#                             },
#                           untaint => 1
#                         },
#   fileType           => { type => SCALAR, regex => qr/$REGEX_FILETYPES/, },
#   fileTypes          => { type => ARRAYREF, regex => qr/$REGEX_FILETYPES/, },
#   fileUri            => { type => SCALAR, regex => qr/$REGEX_FILEURI/, },
#   lastUploadedAfter  => { type => SCALAR, regex => qr/$REGEX_DATE_ISO8601/, },
#   lastUploadedBefore => { type => SCALAR, regex => qr/$REGEX_DATE_ISO8601/, },
#   limit              => { type => SCALAR, regex => qr/$REGEX_INT/, },
#   locale             => { type => SCALAR, regex => qr/$REGEX_FILEURI/, },
#   newFileUri         => { type => SCALAR, regex => qr/$REGEX_FILEURI/, },
#   offset             => { type => SCALAR, regex => qr/$REGEX_INT/, },
#   projectId          => { type => SCALAR, regex => qr/$REGEX_PROJID/, },
#   retrievalType      => { type => SCALAR, regex => qr/$REGEX_RETYPE/, },
#   uriMask            => { type => SCALAR, },
# );

our( %API_SPEC );

$API_SPEC{'new'} = { 
  id     => { type => SCALAR, regex => qr/$REGEX_ID/, },
  region => { type => SCALAR, regex => qr/$REGEX_REGION/, optional => 1, default => $DEF_REGION, },
  secret => { type => SCALAR, regex => qr/$REGEX_SECRET/, },
};

# #################################################################################################
# 
# Override WebService::Simple methods
#

# Override valid options, set API version and create XML parser
sub new {
  ### Enter: (caller(0))[3]
  my( $class, %args ) = @_;
  my $self = $class->SUPER::new(%args);
  
  # this is silly, but easier for validation
  my( @temp_params ) = %{ $self->{basic_params} };
  my %params = validate( @temp_params, $API_SPEC{'new'} );
  ##### %params
  
  # set our API version
  $self->{api_version} = $API_VERSION;
  
  # for parsing the responses
  $self->{xs} = XML::Simple->new();
  
  # store a request signer for later
  $self->{signer} = AWS::Signature4->new( -access_key => $self->{basic_params}{id},
                                          -secret_key => $self->{basic_params}{secret} );

  # store a user agent for later
  $self->{ua} = LWP::UserAgent->new( agent => "$class/$VERSION" );
  
  # change the endpoint for the requested region
  if ( $params{region} && $REGIONS{$params{region}} ) {
    $self->{base_url} = $REGIONS{$params{region}};
  }
  elsif ( $params{region} && !$REGIONS{$params{region}} ) {
    carp( "Unknown region: $params{region}; using $DEF_REGION...")
  }
  ### Exit: (caller(0))[3]
  return bless($self, $class);
}

# override parent get to perform the required AWS signatures
sub _get {
  ### Enter: (caller(0))[3]
  my( $self ) = shift;
  my( %args ) = @_;
  #my $self = $class->SUPER::new(%args);
  
  ##### $self

  ### %args
  if ( !$args{params} ) {
    carp( "No parameter provided for request!" );
    return undef;
  }
  else {
    $args{params}{Version} = $self->{api_version};
  }

  my $uri = URI->new( $self->{base_url} );
  $uri->query_form( $args{params} );
  #### $uri

  # This gives a signed URL that can be fetched by a browser
  my $url = $self->{signer}->signed_url($uri);
  #### $url
  # This doesn't quite work (it wants path and args only)
  #my $response = $self->SUPER::get( $url ); 
  my $response = $self->{ua}->get($url);
  ##### $response
  if ( $response->is_success ) {
    ### Exit: (caller(0))[3]
    return $self->{xs}->XMLin( $response->decoded_content );
  }
  else {
    carp( join( $/, $response->decoded_content, $response->status_line ) );
    ### Exit: (caller(0))[3]
    return undef;
  }
  ### Exit: (caller(0))[3]
}

# override parent post to perform the required AWS signatures
# NOTE: unused (API is all GETs)
sub _post {
  my( $self, %args ) = @_;

  ### %args
  if ( !$args{params} ) {
    carp( "No parameter provided for request!" );
    return undef;
  }
  else {
    $args{params}{Version} = $self->{api_version};
  }
  
  # set custom HTTP request header fields
  my $req = HTTP::Request->new( POST => $self->{base_url} );
  
  # this is not quite right
  $req->content( %args );
  
  $self->{signer}->sign( $req );
  my $response = $self->{ua}->request( $req );
  ##### $response
  if ( $response->is_success ) {
     return $self->{xs}->XMLin( $response->decoded_content );
  }
  else {
    carp( join( $/, $response->decoded_content, $response->status_line ) );
    return undef;
  }
}

# implement a general way to configure repeated options to match the API
sub _handleRepeatedOptions {
  ### Enter: (caller(0))[3]
  my( $self ) = shift;
  my( $repeat, %params ) = @_;
  #### %params

  if ( $params{$repeat} && ref( $params{$repeat} ) eq "ARRAY" ) {
    my( $i ) = 1;
    foreach my $t ( @{ $params{$repeat} } ) {
      $params{"${repeat}.member.${i}"} = $t;     
      $i++; 
    }
    delete( $params{$repeat} );
  }
  
  #### %params
  ### Exit: (caller(0))[3]
  return %params;
}

# most of the calls can do this
sub _genericCallHandler {
  ### Enter: (caller(0))[3]
  my( @st ) = split( /::/, (caller(1))[3] );
  my( $op ) = pop( @st );
  ### Operation: $op
  my( $self )        = shift;
  my %params         = validate( @_, $API_SPEC{$op} );
  $params{Operation} = $op;
  ### %params
  
  # handle ARRAY / repeated options
  foreach my $opt ( keys( %{ $API_SPEC{$op} } ) ) {
    ### Checking opt: $opt
    if ( $API_SPEC{$op}->{$opt}->{type} == ARRAYREF ) {
      ### Found a repeatable option: $opt
      ( %params ) = $self->_handleRepeatedOptions( $opt, %params );       
    }
  }
  
  ### %params
  my( $rez ) = $self->_get( params => \%params );
  ### Exit: (caller(0))[3]
  return $rez->{"${op}Result"};
}

# #################################################################################################
# 
# API Methods Below
#

## CheckDNSAvailability

=head2 CheckDNSAvailability( CNAMEPrefix => 'the-thing-to-check' )

Returns a list of the available solution stack names.

Refer to L<http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API_CheckDNSAvailability.html>

=over 4

=item B<Parameters>

=item CNAMEPrefix B<(required scalar)>

The prefix used when this CNAME is reserved.

=item B<Returns: result from API call>

=back

=cut

$API_SPEC{'CheckDNSAvailability'} = {
  CNAMEPrefix => { type => SCALAR, regex => qr/^[A-Z0-9_-]{4,63}$/i, }
};

sub CheckDNSAvailability {
  ### Enter: (caller(0))[3]
  my( $rez ) = _genericCallHandler( @_ );
  ### Exit: (caller(0))[3]
  return $rez;
}

# #################################################################################################
# CreateApplication

=head2 CreateApplication( )

   Unimplimented (for now)

=cut

# #################################################################################################
# CreateApplicationVersion

=head2 CreateApplicationVersion( )

   Unimplimented (for now)

=cut

# #################################################################################################
# CreateConfigurationTemplate

=head2 CreateConfigurationTemplate( )

   Unimplimented (for now)

=cut

# #################################################################################################
# CreateEnvironment

=head2 CreateEnvironment( )

   Unimplimented (for now)

=cut

# #################################################################################################
# CreateStorageLocation

=head2 CreateStorageLocation( )

   Unimplimented (for now)

=cut

# #################################################################################################
# DeleteApplication

=head2 DeleteApplication( )

   Unimplimented (for now)

=cut

# #################################################################################################
# DeleteApplicationVersion

=head2 DeleteApplicationVersion( )

   Unimplimented (for now)

=cut

# #################################################################################################
# DeleteConfigurationTemplate

=head2 DeleteConfigurationTemplate( )

   Unimplimented (for now)

=cut

# #################################################################################################
# DeleteEnvironmentConfiguration

=head2 DeleteEnvironmentConfiguration( )

   Unimplimented (for now)

=cut

# #################################################################################################
# DescribeApplicationVersions

=head2 DescribeApplicationVersions( )

Returns a list of the available solution stack names.

Refer to L<http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API_DescribeApplicationVersions.html>

=over 4

=item B<Parameters>

=item ApplicationName I<(optional scalar)>

If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include ones that are associated with the specified application.

=item VersionLabels I<(optional array)>

If specified, AWS Elastic Beanstalk restricts the returned versions to only include those with the specified names.

=item B<Returns: result from API call>

=back

=cut

$API_SPEC{'DescribeApplicationVersions'} = { 
  ApplicationName => { type => SCALAR,   optional => 1, regex => qr/^[A-Z0-9_-]{4,63}$/i, },
  VersionLabels   => { type => ARRAYREF, optional => 1 },
};

sub DescribeApplicationVersions {
  ### Enter: (caller(0))[3]
  my( $rez ) = _genericCallHandler( @_ );
  ### Exit: (caller(0))[3]
  return $rez;
}

# #################################################################################################
# DescribeApplications

=head2 DescribeApplications( )

Returns a list of the available solution stack names.

Refer to L<http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API_DescribeApplications.html>

=over 4

=item B<Parameters>

=item ApplicationNames I<(optional array)>

If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.

=item B<Returns: result from API call>

=back

=cut

$API_SPEC{'DescribeApplications'} = {
  ApplicationNames => { type => ARRAYREF, optional => 1 }
};
                          
sub DescribeApplications {
  ### Enter: (caller(0))[3]
  my( $rez ) = _genericCallHandler( @_ );
  ### Exit: (caller(0))[3]
  return $rez;
}

# #################################################################################################
# DescribeConfigurationOptions

=head2 DescribeConfigurationOptions( )

Returns a list of the available solution stack names.

Refer to L<http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API_DescribeConfigurationOptions.html>

=over 4

=item B<Parameters>

=item ApplicationName I<(optional string)>

The name of the application associated with the configuration template or environment. Only needed if you want to describe the configuration options associated with either the configuration template or environment.

=item EnvironmentName I<(optional string)>

The name of the environment whose configuration options you want to describe.

=item Options I<(optional array)>

If specified, restricts the descriptions to only the specified options.

=item SolutionStackName I<(optional string)>

The name of the solution stack whose configuration options you want to describe.

=item TemplateName I<(optional string)>

The name of the configuration template whose configuration options you want to describe.

=item B<Returns: result from API call>

=back

=cut

$API_SPEC{'DescribeConfigurationOptions'} = { 
  ApplicationName   => { type => SCALAR,   regex => qr/^[A-Z0-9_-]{1,100}$/i, optional => 1 },
  EnvironmentName   => { type => SCALAR,   regex => qr/^[A-Z0-9_-]{4,23}$/i,  optional => 1 },
  Options           => { type => ARRAYREF, optional => 1 },
  SolutionStackName => { type => SCALAR,   regex => qr/^[A-Z0-9_-]{1,100}$/i, optional => 1 },
  TemplateName      => { type => SCALAR,   regex => qr/^[A-Z0-9_-]{1,100}$/i, optional => 1 },
};
                          
sub DescribeConfigurationOptions {
  ### Enter: (caller(0))[3]
  my( $rez ) = _genericCallHandler( @_ );
  ### Exit: (caller(0))[3]
  return $rez;
}

# #################################################################################################
# DescribeConfigurationSettings

=head2 DescribeConfigurationSettings( )

Returns a list of the available solution stack names.

Refer to L<http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API_DescribeConfigurationSettings.html>

=over 4

=item B<Parameters>

=item ApplicationName B<(required string)>

The application for the environment or configuration template.

=item EnvironmentName I(optional string)

The name of the environment to describe.

Condition: You must specify either this or a TemplateName, but not both. If you specify both, AWS Elastic Beanstalk returns an InvalidParameterCombination error. If you do not specify either, AWS Elastic Beanstalk returns MissingRequiredParameter error.

=item TemplateName I(optional string)

The name of the configuration template to describe.

Conditional: You must specify either this parameter or an EnvironmentName, but not both. If you specify both, AWS Elastic Beanstalk returns an InvalidParameterCombination error. If you do not specify either, AWS Elastic Beanstalk returns a MissingRequiredParameter error.

=item B<Returns: result from API call>

=back

=cut

$API_SPEC{'DescribeConfigurationSettings'} = {
  ApplicationName => { type => SCALAR,   regex => qr/^[A-Z0-9_-]{1,100}$/i,
                       callbacks => {
                        'other_params' => sub { 
                          my( $me, $others ) = @_;
                          if ( !$others->{'EnvironmentName'} && !$others->{'TemplateName'} ) {
                            croak( "Provide one of EnvironmentName or TemplateName" );
                            return 0;
                          }

                          if ( $others->{'EnvironmentName'} && $others->{'TemplateName'} ) {
                            croak( "Provide only one of EnvironmentName or TemplateName" );
                            return 0;
                          }
                          return 1;
                        }
                      }
                    },
  EnvironmentName => { type => SCALAR, regex => qr/^[A-Z0-9_-]{4,23}$/i, optional => 1 },
  TemplateName    => { type => SCALAR, regex => qr/^[A-Z0-9_-]{4,23}$/i, optional => 1 },
};

sub DescribeConfigurationSettings {
  ### Enter: (caller(0))[3]
  my( $rez ) = _genericCallHandler( @_ );
  ### Exit: (caller(0))[3]
  return $rez;
}

# #################################################################################################
# DescribeEnvironmentResources

=head2 DescribeEnvironmentResources( )

Returns a list of the available solution stack names.

Refer to L<http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API_DescribeApplications.html>

=over 4

=item B<Parameters>

=item ApplicationNames I<(optional array)>

If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.

=item B<Returns: result from API call>

=back

=cut

$API_SPEC{'DescribeEnvironmentResources'} = {
  ApplicationNames => { type => ARRAYREF, optional => 1 }
};
                          
sub DescribeEnvironmentResources {
  ### Enter: (caller(0))[3]
  my( $rez ) = _genericCallHandler( @_ );
  ### Exit: (caller(0))[3]
  return $rez;
}

# #################################################################################################
# DescribeEnvironments

=head2 DescribeEnvironments( )

Returns a list of the available solution stack names.

Refer to L<http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API_DescribeEnvironments.html>

=over 4

=item B<Parameters>

=item ApplicationName I<(optional string)>

If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that are associated with this application.

=item EnvironmentIds I<(optional array)>

If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that have the specified IDs.

=item EnvironmentNames I<(optional array)>

If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that have the specified names.

=item IncludeDeleted I<(optional boolean)>

Indicates whether to include deleted environments:

true: Environments that have been deleted after IncludedDeletedBackTo are displayed.
false: Do not include deleted environments.

=item IncludedDeletedBackTo I<(optional date)>

If specified when IncludeDeleted is set to true, then environments deleted after this date are displayed.

=item VersionLabel I<(optional string)>

If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that are associated with this application version.

=item B<Returns: result from API call>

=back

=cut

$API_SPEC{'DescribeEnvironments'} = { 
  ApplicationName       => { type => SCALAR,   optional => 1 },
  EnvironmentId         => { type => ARRAYREF, optional => 1 },
  EnvironmentNames      => { type => ARRAYREF, optional => 1 },
  IncludeDeleted        => { type => BOOLEAN,  optional => 1 },
  IncludedDeletedBackTo => { type => SCALAR,   optional => 1 },
  VersionLabel          => { type => SCALAR,   optional => 1 },
};
                          
sub DescribeEnvironments {
  ### Enter: (caller(0))[3]
  my( $rez ) = _genericCallHandler( @_ );
  ### Exit: (caller(0))[3]
  return $rez;
}

# #################################################################################################
# DescribeEvents

=head2 DescribeEvents( )

Returns list of event descriptions matching criteria up to the last 6 weeks.

Refer to L<http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API_DescribeEvents.html>

=over 4

=item B<Parameters>

=item ApplicationNames I<(optional array)>

If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.

=item B<Returns: result from API call>

=back

=cut

$API_SPEC{'DescribeEvents'} = {
  ApplicationNames => { type => ARRAYREF, optional => 1 }
};
                          
sub DescribeEvents {
  ### Enter: (caller(0))[3]
  my( $rez ) = _genericCallHandler( @_ );
  ### Exit: (caller(0))[3]
  return $rez;
}

# #################################################################################################
## ListAvailableSolutionStacks

=head2 ListAvailableSolutionStacks( )

Returns a list of the available solution stack names.

Refer to L<http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API_ListAvailableSolutionStacks.html>

=over 4

=item B<Parameters>

B<none>

=item B<Returns: result from API call>

=back

=cut

$API_SPEC{'ListAvailableSolutionStacks'} = { };

sub ListAvailableSolutionStacks {
  ### Enter: (caller(0))[3]
  my( $rez ) = _genericCallHandler( @_ );
  ### Exit: (caller(0))[3]
  return $rez;
}

# RebuildEnvironment

=head2 RebuildEnvironment( )

   Unimplimented (for now)

=cut

# RequestEnvironmentInfo

=head2 RequestEnvironmentInfo( )

   Unimplimented (for now)

=cut

# RestartAppServer

=head2 RestartAppServer( )

   Unimplimented (for now)

=cut

# #################################################################################################
# RetrieveEnvironmentInfo

=head2 RetrieveEnvironmentInfo( )

Retrieves the compiled information from a RequestEnvironmentInfo request.

Refer to L<http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API_RetrieveEnvironmentInfo.html>

=over 4

=item B<Parameters>

=item EnvironmentId I<(optional string)>

The ID of the data's environment.

If no such environment is found, returns an InvalidParameterValue error.

Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns MissingRequiredParameter error.

=item EnvironmentName I<(optional string)>

The name of the data's environment.

If no such environment is found, returns an InvalidParameterValue error.

Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns MissingRequiredParameter error.

Type: String

Length constraints: Minimum length of 4. Maximum length of 23.

Required: No

=item InfoType B<(required string)>

The type of information to retrieve.

Type: String

Valid Values: tail

Required: Yes

=item B<Returns: result from API call>

=back

=cut

$API_SPEC{'RetrieveEnvironmentInfo'} = {
  InfoType => { type => SCALAR, optional => 1, default => 'tail',
                callbacks => {
                  'other_params' => sub { 
                    my( $me, $others ) = @_;
                    if ( !$others->{'EnvironmentId'} && !$others->{'EnvironmentName'} ) {
                      croak( "Provide one of EnvironmentId or EnvironmentName" );
                      return 0;
                    }
                    return 1;
                  }
                }
              },
  EnvironmentId   => { type => SCALAR, regex => qr/^[A-Z0-9_-]{4,23}$/i, optional => 1 },
  EnvironmentName => { type => SCALAR, regex => qr/^[A-Z0-9_-]{4,23}$/i, optional => 1 },
};

sub RetrieveEnvironmentInfo {
  ### Enter: (caller(0))[3]
  my( $rez ) = _genericCallHandler( @_ );
  ### Exit: (caller(0))[3]
  return $rez;
}

# #################################################################################################
# SwapEnvironmentCNAMEs

=head2 SwapEnvironmentCNAMEs( )

   Unimplimented (for now)

=cut

# #################################################################################################
# TerminateEnvironment

=head2 TerminateEnvironment( )

   Unimplimented (for now)

=cut

# #################################################################################################
# UpdateApplication

=head2 UpdateApplication( )

   Unimplimented (for now)

=cut

# #################################################################################################
# UpdateApplicationVersion

=head2 UpdateApplicationVersion( )

   Unimplimented (for now)

=cut

# #################################################################################################
# UpdateConfigurationTemplate

=head2 UpdateConfigurationTemplate( )

   Unimplimented (for now)

=cut

# #################################################################################################
# UpdateEnvironment

=head2 UpdateEnvironment( )

   Unimplimented (for now)

=cut

# #################################################################################################
# ValidateConfigurationSettings

=head2 ValidateConfigurationSettings( )

Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.

This action returns a list of messages indicating any errors or warnings associated with the selection of option values.

Refer to L<http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API_ValidateConfigurationSettings.html>

=over 4

=item B<Parameters>

=item ApplicationName B<(required string)>

The name of the application that the configuration template or environment belongs to.

=item EnvironmentName I<(optional string)>

The name of the environment to validate the settings against.

Condition: You cannot specify both this and a configuration template name.

=item OptionSettings I<(required array)>

A list of the options and desired values to evaluate.

=item TemplateName I<(optional string)>

The name of the configuration template to validate the settings against.

Condition: You cannot specify both this and an environment name.

=item B<Returns: result from API call>

=back

=cut

$API_SPEC{'ValidateConfigurationSettings'} = {
  ApplicationName => { type => SCALAR,  regex => qr/^[A-Z0-9_-]{1,100}$/i,
                      callbacks => {
                        'other_params' => sub { 
                          my( $me, $others ) = @_;
                          if ( !$others->{'EnvironmentName'} && !$others->{'TemplateName'} ) {
                            croak( "Provide one of EnvironmentName or TemplateName" );
                            return 0;
                          }

                          if ( $others->{'EnvironmentName'} && $others->{'TemplateName'} ) {
                            croak( "Provide only one of EnvironmentName or TemplateName" );
                            return 0;
                          }
                          return 1;
                        }
                      }
                    },
  EnvironmentName => { type => SCALAR,  regex => qr/^[A-Z0-9_-]{4,23}$/i, optional => 1 },
  OptionSettings  => { type => ARRAYREF },
  TemplateName    => { type => SCALAR,  regex => qr/^[A-Z0-9_-]{4,23}$/i, optional => 1 },
};

sub ValidateConfigurationSettings {
  ### Enter: (caller(0))[3]
  my( $rez ) = _genericCallHandler( @_ );
  ### Exit: (caller(0))[3]
  return $rez;
}

# #################################################################################################

=head1 AUTHOR

Matthew Cox C<< <mcox at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-amazon-elasticbeanstalk at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Amazon-ElasticBeanstalk>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Amazon::ElasticBeanstalk

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Amazon-ElasticBeanstalk>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Amazon-ElasticBeanstalk>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Amazon-ElasticBeanstalk>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Amazon-ElasticBeanstalk/>

=back

=head1 SEE ALSO

perl(1), L<WebService::Simple>, L<XML::Simple>, L<HTTP::Common::Response>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Matthew Cox.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of WebService::Amazon::ElasticBeanstalk
__END__
