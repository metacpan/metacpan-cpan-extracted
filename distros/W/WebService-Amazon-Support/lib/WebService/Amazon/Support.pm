package WebService::Amazon::Support;
use base qw( WebService::Simple );

use 5.006;
use strict;
use warnings;

use AWS::Signature4;
use Carp;
use HTTP::Request::Common;
use JSON;
use LWP;
use Params::Validate qw( :all );
use Readonly;
#use Smart::Comments '###';
#use Smart::Comments '###', '####';
#use Smart::Comments '###', '####', '#####';

=encoding utf-8

=head1 NAME

WebService::Amazon::Support - The great new WebService::Amazon::Support!

=head1 VERSION

Version 0.0.4

=cut

use version;
our $VERSION = version->declare("v0.0.4");

=head1 SYNOPSIS

This module provides a Perl wrapper around Amazon's Support API 
( L<http://docs.aws.amazon.com/awssupport/latest/APIReference/Welcome.html> ).  You will need 
to be an AWS customer with an ID and Secret which has been provided 
access to Support.

B<Note:> Some parameter validation is purposely lax. The API will 
generally fail when invalid params are passed. The errors may not 
be helpful.

    use WebService::Amazon::Support;

    my $sup = WebService::Amazon::Support->new( param => { id     => $AWS_ACCESS_KEY_ID,
                                                           secret => $AWS_ACCESS_KEY_SECRET } );
    ...

=cut

# From: http://docs.aws.amazon.com/general/latest/gr/rande.html#awssupport_region
# FIXME: use an array and assemble the URL in the constructor?
Readonly our %REGIONS => ( 'us-east-1'      => 'https://support.us-east-1.amazonaws.com' );

# Global API Version and Default Region
Readonly our $API_VERSION => '2013-04-15';
Readonly our $DEF_REGION  => 'us-east-1';
Readonly our $DEF_LANG    => 'en';
Readonly our $TARGET_PRE  => 'AWSSupport_20130415';

# some defaults
__PACKAGE__->config(
  base_url => $REGIONS{'us-east-1'},
);

# Global patterns for param validation
Readonly our $REGEX_ID     => '^[A-Z0-9]{20}$';
Readonly our $REGEX_REGION => '^[a-z]{2}-[a-z].*?-\d$';
Readonly our $REGEX_SECRET => '^[A-Za-z0-9/+]{40}$';

=head1 INTERFACE

=head2 new

Inherited from L<WebService::Simple>, and takes all the same arguments. 
You B<must> provide the Amazon required arguments of B<id>, and B<secret> 
in the param hash:

    my $sup = WebService::Amazon::Support->new( param => { id     => $AWS_ACCESS_KEY_ID,
                                                           secret => $AWS_ACCESS_KEY_SECRET } );

=over 4

=item B<Parameters>

=item id B<(required)>

You can find more information in the AWS docs: 
L<http://docs.aws.amazon.com/general/latest/gr/aws-security-credentials.html>

=item secret B<(required)>

You can find more information in the AWS docs: 
L<http://docs.aws.amazon.com/general/latest/gr/aws-security-credentials.html>

=back

=cut

# HASH to hold API call specifications
our( %API_SPEC );

# #################################################################################################
# 
# Override WebService::Simple methods
#

$API_SPEC{'new'} = { 
  id     => { type => SCALAR, regex => qr/$REGEX_ID/, },
  region => { type => SCALAR, regex => qr/$REGEX_REGION/, optional => 1, default => $DEF_REGION, },
  secret => { type => SCALAR, regex => qr/$REGEX_SECRET/, },
};

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
  $self->{js} = JSON->new->allow_nonref;
  
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
  my $signer = AWS::Signature4->new( -access_key => $self->{basic_params}{id},
                                     -secret_key => $self->{basic_params}{secret} );

  my $ua = LWP::UserAgent->new();

  ### %args
  if ( !$args{params} ) {
    carp( "No paramerter provided for request!" );
    return undef;
  }
  else {
    $args{params}{Version} = $self->{api_version};
  }

  my $uri = URI->new( $self->{base_url} );
  $uri->query_form( $args{params} );
  #### $uri

  my $url = $signer->signed_url($uri); # This gives a signed URL that can be fetched by a browser
  #### $url
  # This doesn't quite work (it wants path and args onyl)
  #my $response = $self->SUPER::get( $url ); 
  my $response = $ua->get($url);
  ##### $response
  if ( $response->is_success ) {
    ### Exit: (caller(0))[3]
    return $self->{xs}->XMLin( $response->decoded_content );
  }
  else {
    carp( $response->status_line );
    ### Exit: (caller(0))[3]
    return undef;
  }
  ### Exit: (caller(0))[3]
}

# override parent post to perform the required AWS signatures
sub _post {
  my( $self, %args ) = @_;

  ### %args
  if ( !$args{params} ) {
    carp( "No paramerter provided for request!" );
    return undef;
  }
  else {
    $args{params}{Version} = $self->{api_version};
  }
  
  # JSON encode the params
  my( $js ) = $self->{js}->encode( $args{params} );
  ### $js
  
  # set custom HTTP request header fields
  my $req = HTTP::Request->new( POST => $self->{base_url} );
  #
  # NOTE: Shenanigans! Reverse engineered from https://github.com/boto/boto/blob/develop/boto/support/layer1.py#L652
  #
  $req->header( 'X-Amz-Target' => join( '.', $TARGET_PRE, $args{params}{Action} ) );
  $req->header( 'content-type' => 'application/x-amz-json-1.1' );
  
  $req->content( $js );
  ### $req

  $self->{signer}->sign($req);
  #### $req
  my $response = $self->{ua}->request( $req );
  ##### $response
  my( $jsDecode ) = $self->{js}->decode( $response->decoded_content );
  if ( $response->is_success ) {
     return $jsDecode;
  }
  else {
    carp( $self->{js}->pretty->encode( $jsDecode ) . $response->status_line );
    return undef;
  }
}

# implement a general way to configure repeated options to match the API
sub _handleRepeatedOptions {
  ### Enter: (caller(0))[3]
  my( $self ) = shift;
  my( $repeat, %params ) = @_;
  #### Start: %params

  if ( $params{$repeat} && ref( $params{$repeat} ) eq "ARRAY" ) {
    my( $i ) = 1;
    foreach my $t ( @{ $params{$repeat} } ) {
      $params{"${repeat}.member.${i}"} = $t;     
      $i++; 
    }
    delete( $params{$repeat} );
  }
  
  #### End: %params
  ### Exit: (caller(0))[3]
  return %params;
}

# most of the calls can do this
sub _genericCallHandler {
  ### Enter: (caller(0))[3]
  my( $op ) = (split( /::/, (caller(1))[3] ))[-1];
  ### Operation: $op

  my( $self )     = shift;
  my %params      = validate( @_, $API_SPEC{$op} );
  $params{Action} = $op;
  ### %params
  
  # handle ARRAY / repeated options -- this API is JSON: don't do anything
  # foreach my $opt ( keys( %{ $API_SPEC{$op} } ) ) {
  #   ### Checking opt: $opt
  #   if ( $API_SPEC{$op}->{$opt}->{type} == ARRAYREF ) {
  #     ### Found a repeatable option: $opt
  #     ( %params ) = $self->_handleRepeatedOptions( $opt, %params );
  #   }
  # }
  
  ### %params
  my( $rez ) = $self->_post( params => \%params );
  ### Exit: (caller(0))[3]
  return $rez;
}

# #################################################################################################
# 
# API Methods Below
#

# #################################################################################################
## AddAttachmentsToSet

=head2 AddAttachmentsToSet( )

   Unimplimented (for now)

=cut

# #################################################################################################
## AddCommunicationToCase

=head2 AddCommunicationToCase( )

   Unimplimented (for now)

=cut

# #################################################################################################
## CreateCase

=head2 CreateCase( )

   Unimplimented (for now)

=cut

# #################################################################################################
## DescribeAttachment

=head2 DescribeAttachment( )

Returns the attachment that has the specified ID. Attachment IDs are 
generated by the case management system when you add an attachment to 
a case or case communication. Attachment IDs are returned in the 
AttachmentDetails objects that are returned by the 
DescribeCommunications operation.

Refer to L<http://docs.aws.amazon.com/awssupport/latest/APIReference/API_DescribeAttachment.html>

=over 4

=item B<Parameters>

=item attachmentId B<(required string)>

The ID of the attachment to return. Attachment IDs are returned by the DescribeCommunications operation.

=item B<Returns: result from API call>

=back

=cut

$API_SPEC{'DescribeAttachment'} = {
  attachmentId => { type => SCALAR },
};

sub DescribeAttachment {
  ### Enter: (caller(0))[3]
  my( $rez ) = _genericCallHandler( @_ );
  ### Exit: (caller(0))[3]
  return $rez;
}

# #################################################################################################
## DescribeCases

=head2 DescribeCases( )

   Unimplimented (for now)

=cut

# #################################################################################################
## DescribeCommunications

=head2 DescribeCommunications( )

   Unimplimented (for now)

=cut

# #################################################################################################
## DescribeServices

=head2 DescribeServices( )

Returns a list of the available solution stack names.

Refer to L<http://docs.aws.amazon.com/awssupport/latest/APIReference/API_DescribeServices.html>

=over 4

=item B<Parameters>

=item Language I<(optional string)>

The ISO 639-1 code for the language in which AWS provides support. AWS 
Support currently supports English ("en") and Japanese ("ja"). Language 
parameters must be passed explicitly for operations that take them.

=item ServiceCodeList I<(optional array)>

A JSON-formatted list of service codes available for AWS services.

Length constraints: Minimum of 0 item(s) in the list. Maximum of 100 item(s) in the list.

Required: No

=item B<Returns: result from API call>

=back

=cut

$API_SPEC{'DescribeServices'} = {
  language        => { type => SCALAR, regex => qr/^(en|ja)$/i, optional => 1, default => $DEF_LANG, },
  serviceCodeList => { type => ARRAYREF, optional => 1 },
};

sub DescribeServices {
  ### Enter: (caller(0))[3]
  my( $rez ) = _genericCallHandler( @_ );
  ### Exit: (caller(0))[3]
  return $rez;
}

# #################################################################################################
## DescribeSeverityLevels

=head2 DescribeSeverityLevels( )

Returns the list of severity levels that you can assign to an AWS 
Support case. The severity level for a case is also a field in the 
CaseDetails data type included in any CreateCase request.

Refer to L<http://docs.aws.amazon.com/awssupport/latest/APIReference/API_DescribeSeverityLevels.html>

=over 4

=item B<Parameters>

=item Language I<(optional string)>

The ISO 639-1 code for the language in which AWS provides support. AWS 
Support currently supports English ("en") and Japanese ("ja"). Language 
parameters must be passed explicitly for operations that take them.

=item B<Returns: result from API call>

=back

=cut

$API_SPEC{'DescribeSeverityLevels'} = {
  language => { type => SCALAR, regex => qr/^(en|ja)$/i, optional => 1, default => $DEF_LANG, },
};

sub DescribeSeverityLevels {
  ### Enter: (caller(0))[3]
  my( $rez ) = _genericCallHandler( @_ );
  ### Exit: (caller(0))[3]
  return $rez;
}

# #################################################################################################
## DescribeTrustedAdvisorCheckRefreshStatuses

=head2 DescribeTrustedAdvisorCheckRefreshStatuses( )

Returns the refresh status of the Trusted Advisor checks that have the 
specified check IDs. Check IDs can be obtained by calling DescribeTrustedAdvisorChecks.

Refer to L<http://docs.aws.amazon.com/awssupport/latest/APIReference/API_DescribeTrustedAdvisorCheckRefreshStatuses.html>

=over 4

=item B<Parameters>

=item checkIds B<(required array)>

The IDs of the Trusted Advisor checks.

=item B<Returns: result from API call>

=back

=cut

$API_SPEC{'DescribeTrustedAdvisorCheckRefreshStatuses'} = {
  checkIds => { type => ARRAYREF },
};

sub DescribeTrustedAdvisorCheckRefreshStatuses {
  ### Enter: (caller(0))[3]
  my( $rez ) = _genericCallHandler( @_ );
  ### Exit: (caller(0))[3]
  return $rez;
}

# #################################################################################################
## DescribeTrustedAdvisorCheckResult

=head2 DescribeTrustedAdvisorCheckResult( )

Returns the results of the Trusted Advisor check that has the specified 
check ID. Check IDs can be obtained by calling DescribeTrustedAdvisorChecks.

The response contains a TrustedAdvisorCheckResult object, which contains these three objects:

  TrustedAdvisorCategorySpecificSummary
  TrustedAdvisorResourceDetail
  TrustedAdvisorResourcesSummary

In addition, the response contains these fields:

  Status. The alert status of the check: "ok" (green), "warning" (yellow), "error" (red), or "not_available".
  Timestamp. The time of the last refresh of the check.
  CheckId. The unique identifier for the check.

Refer to L<http://docs.aws.amazon.com/awssupport/latest/APIReference/API_DescribeTrustedAdvisorCheckResult.html>

=over 4

=item B<Parameters>

=item checkIds B<(required string)>

The ID of the Trusted Advisor check.

=item Language I<(optional string)>

The ISO 639-1 code for the language in which AWS provides support. AWS 
Support currently supports English ("en") and Japanese ("ja"). Language 
parameters must be passed explicitly for operations that take them.

=item B<Returns: result from API call>

=back

=cut

$API_SPEC{'DescribeTrustedAdvisorCheckResult'} = {
  checkId  => { type => SCALAR },
  language => { type => SCALAR, regex => qr/^(en|ja)$/i, optional => 1, default => $DEF_LANG, },
};

sub DescribeTrustedAdvisorCheckResult {
  ### Enter: (caller(0))[3]
  my( $rez ) = _genericCallHandler( @_ );
  ### Exit: (caller(0))[3]
  return $rez;
}

# #################################################################################################
## DescribeTrustedAdvisorCheckSummaries

=head2 DescribeTrustedAdvisorCheckSummaries( )

Returns the summaries of the results of the Trusted Advisor checks that 
have the specified check IDs. Check IDs can be obtained by calling DescribeTrustedAdvisorChecks.

The response contains an array of TrustedAdvisorCheckSummary objects.

Refer to L<http://docs.aws.amazon.com/awssupport/latest/APIReference/API_DescribeTrustedAdvisorCheckSummaries.html>

=over 4

=item B<Parameters>

=item checkIds B<(required array)>

The IDs of the Trusted Advisor checks.

=item B<Returns: result from API call>

=back

=cut

$API_SPEC{'DescribeTrustedAdvisorCheckSummaries'} = {
  checkId  => { type => ARRAYREF },
};

sub DescribeTrustedAdvisorCheckSummaries {
  ### Enter: (caller(0))[3]
  my( $rez ) = _genericCallHandler( @_ );
  ### Exit: (caller(0))[3]
  return $rez;
}

# #################################################################################################
## DescribeTrustedAdvisorChecks

=head2 DescribeTrustedAdvisorChecks( )

Returns information about all available Trusted Advisor checks, 
including name, ID, category, description, and metadata. You must 
specify a language code; English ("en") and Japanese ("ja") are 
currently supported. 

The response contains a TrustedAdvisorCheckDescription for each check.

Refer to L<http://docs.aws.amazon.com/awssupport/latest/APIReference/API_DescribeTrustedAdvisorChecks.html>

=over 4

=item B<Parameters>

=item Language I<(optional string)>

The ISO 639-1 code for the language in which AWS provides support. AWS 
Support currently supports English ("en") and Japanese ("ja"). Language 
parameters must be passed explicitly for operations that take them.

=item B<Returns: result from API call>

=back

=cut

$API_SPEC{'DescribeTrustedAdvisorChecks'} = {
  language => { type => SCALAR, regex => qr/^(en|ja)$/i, optional => 1, default => $DEF_LANG, },
};

sub DescribeTrustedAdvisorChecks {
  ### Enter: (caller(0))[3]
  my( $rez ) = _genericCallHandler( @_ );
  ### Exit: (caller(0))[3]
  return $rez;
}

# #################################################################################################
## RefreshTrustedAdvisorCheck

=head2 RefreshTrustedAdvisorCheck( )

Requests a refresh of the Trusted Advisor check that has the specified 
check ID. Check IDs can be obtained by calling DescribeTrustedAdvisorChecks.

The response contains a TrustedAdvisorCheckRefreshStatus object, which contains these fields:

   Status. The refresh status of the check: "none", "enqueued", "processing", "success", or "abandoned".
   MillisUntilNextRefreshable. The amount of time, in milliseconds, until the check is eligible for refresh.
   CheckId. The unique identifier for the check.

Refer to L<http://docs.aws.amazon.com/awssupport/latest/APIReference/API_RefreshTrustedAdvisorCheck.html>

=over 4

=item B<Parameters>

=item checkId B<(required string)>

The ID of the Trusted Advisor check.

=item B<Returns: result from API call>

=back

=cut

$API_SPEC{'RefreshTrustedAdvisorCheck'} = {
  checkId => { type => SCALAR }
};

sub RefreshTrustedAdvisorCheck {
  ### Enter: (caller(0))[3]
  my( $rez ) = _genericCallHandler( @_ );
  ### Exit: (caller(0))[3]
  return $rez;
}

# #################################################################################################
# ResolveCase

=head2 ResolveCase( )

Takes a CaseId and returns the initial state of the case along with 
the state of the case after the call to ResolveCase completed.

Refer to L<http://docs.aws.amazon.com/awssupport/latest/APIReference/API_ResolveCase.html>

=over 4

=item B<Parameters>

=item caseId B<(required string)>

CaseId
The AWS Support case ID requested or returned in the call. The case ID 
is an alphanumeric string formatted as shown in this example: 
   case-12345678910-2013-c4c1d2bf33c5cf47

=item B<Returns: result from API call>

=back

=cut

$API_SPEC{'ResolveCase'} = {
  checkId => { type => SCALAR }
};

sub ResolveCase {
  ### Enter: (caller(0))[3]
  my( $rez ) = _genericCallHandler( @_ );
  ### Exit: (caller(0))[3]
  return $rez;
}

# #################################################################################################

=head1 AUTHOR

Matthew Cox, C<< <mcox at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-amazon-support at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Amazon-Support>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Amazon::Support


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Amazon-Support>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Amazon-Support>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Amazon-Support>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Amazon-Support/>

=back


=head1 ACKNOWLEDGEMENTS

=head1 SEE ALSO

perl(1), L<AWS::Signature4>, L<Carp>, L<HTTP::Common::Response>, L<JSON>, L<LWP>, L<Params::Validate>, L<WebService::Simple>

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

1; # End of WebService::Amazon::Support
__END__