package WWW::SFDC::Metadata;
# ABSTRACT: Interface to the Salesforce.com Metadata API

use 5.12.0;
use strict;
use warnings;

our $VERSION = '0.37'; # VERSION

use Data::Dumper;
use Log::Log4perl ':easy';
use Method::Signatures;
use SOAP::Lite;

use WWW::SFDC::Metadata::DeployResult;

use Moo;
with "WWW::SFDC::Role::SessionConsumer";

has 'uri',
  is => 'ro',
  default => "http://soap.sforce.com/2006/04/metadata";

sub _extractURL {
  return $_[1]->{metadataServerUrl};
}


method listMetadata (@_) {

  INFO "Listing Metadata...\t";

  my @result;
  my @queryData = map {SOAP::Data->new(name => "queries", value => $_)} @_;

  # listMetadata can only handle 3 requests at a time, so we chunk them.
  while (my @items = splice @queryData, 0, 3) {
    push @result, $$_{fileName} for @{$self->_call('listMetadata', @items)->results};
  }

  return @result;
}


# Sets up an asynchronous metadata retrieval request and
# returns just the id, for checking later. Accepts a manifest.

method _startRetrieval ($manifest) {
  INFO "Starting retrieval";

  # These maps basically preserve the structure passed in,
  # translating it to salesforce's special package.xml structure.
  my @queryData = map {
    SOAP::Data->name (
      types => \SOAP::Data->value(
      	map {SOAP::Data->name(members => $_) } @{ $$manifest{$_} },
      	SOAP::Data->name(name => $_ )
       )
     )
    } keys %$manifest;


  return $self->_call(
    'retrieve',
    SOAP::Data->name(
      retrieveRequest => {
      	# a lower value than 31 means no status is retrieved, causing an error.
      	apiVersion => $self->session->apiVersion(),
      	unpackaged => \SOAP::Data->value(@queryData)
      })
   )->result->{id};

}

# Uses the id to request a status update from SFDC, and returns
# undef unless there's something to give back, in which case it
# returns the base64 encoded zip file from the response.

method _checkRetrieval ($id) {

  my $result = $self->_call(
    'checkRetrieveStatus',
    SOAP::Data->name("asyncProcessId" => $id)
   )->result;

  INFO "Status:" . $$result{status};

  return $result->{zipFile} if $$result{status} eq "Succeeded";
  return if $$result{status} =~ /Pending|InProgress/;
  LOGDIE "Check Retrieve had an unexpected result: ".$$result{message};
}


method retrieveMetadata ($manifest) {

  my $requestId = $self->_startRetrieval($manifest);
  my $result;

  do { $self->_sleep() } until $result = $self->_checkRetrieval($requestId);

  return $result;

}


#Check up on an async deployment request. Returns 1 when complete.
method _checkDeployment ($id, $previous?) {

  my $callResult = $self->_call(
      'checkDeployStatus',
      SOAP::Data->name("id" => $id),
      SOAP::Data->name("includeDetails" => "true")
    )->result;

  my $result = WWW::SFDC::Metadata::DeployResult->new(
    result => $callResult
  );

  if (scalar (my @errors = (
    $result->componentFailuresSince($previous),
    $result->testFailuresSince($previous)
  ))) {
    WARN Dumper \@errors;
  }

  return $result
}

method deployMetadata ($zip, $deployOptions?) {

  my $result = $self->_call(
    'deploy',
    SOAP::Data->name( zipfile => $zip),
    (
      $deployOptions
        ? SOAP::Data->name(DeployOptions=>$deployOptions)
        : ()
    )
   )->result;

  INFO "Deployment ID: $$result{id}";

  my $returnValue;

  #do..until guarantees that sleep() executes at least once.
  $self->_sleep()
    until (
      $returnValue = $self->_checkDeployment($$result{id}, $returnValue)
    )->complete;

  return $returnValue;
}


method deployRecentValidation ($id) {
  chomp $id;

  return WWW::SFDC::Metadata::DeployResult->new(
    result => $self->_call(
      'deployRecentValidation',
      SOAP::Data->name(validationID => $id)
    )->result
  );
}


method describeMetadata {
  return $self->_call(
    'describeMetadata',
    SOAP::Data->name(apiVersion => $self->session->apiVersion)
   )->result;
}

1;

__END__

=pod

=head1 NAME

WWW::SFDC::Metadata - Interface to the Salesforce.com Metadata API

=head1 VERSION

version 0.37

=head1 SYNOPSIS

 my $client = WWW::SFDC->new(
   username => 'foo',
   password => 'bar',
   url => 'https://login.salesforce.com'
 )->Metadata;

 my $manifest = $client->listMetadata(
   {type => "CustomObject"},
   {type => "Report", folder => "FooReports"}
 );

 my $base64zipstring = $client->retrieveMetadata(
   $manifest
 );

 $client->deployMetadata(
   $base64zipstring,
   {checkOnly => 'true'}
 );

For more in-depth examples, see t/WWW/SFDC/Metadata.t

=head1 METHODS

=head2 listMetadata(@queries)

Accepts a list of types and folders, such as

$session->Metadata->listMetadata(
   {type => "CustomObject"},
   {type => "Report", folder => "FooReports"}
);

and generates a list of file names suitable for turning into a WWW::SFDC::Manifest.

=head2 retrieveMetadata($manifest)

Sets up a retrieval from then checks it until done. Returns the
same data as checkRetrieval. Requires a manifest of the form:

 my $manifest = {
   "ApexClass" => ["MyApexClass"],
   "CustomObject" => ["*", "Account", "User", 'Opportunity"],
   "Profile" => ["*"]
  };

This method handles starting the retrieval, and polls until it completes, then
returns the a string which is the base64 encoded .zip file containing the
data.

=head2 deployMetadata $zipString, \%deployOptions

Takes a base64 zip file and deploys it. Deploy options will be
passed verbatim into the request; see the metadata developer
guide for a description.

Returns a WWW::SFDC::Metadata::DeployResult containing the result of the
operation. You must manually check whether this succeeded!

=head2 deployRecentValidation $id

Calls deployRecentValidation with your successfully-validated deployment.

=head2 describeMetadata

Returns a describeMetadataResult hashref as specified by Salesforce.com.
L<WWW::SFDC::Constants> consumes this object to provide utility methods.

=head1 BUGS

Please report any bugs or feature requests at L<https://github.com/sophos/WWW-SFDC/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::SFDC::Metadata

You can also look for information at L<https://github.com/sophos/WWW-SFDC>

=head1 AUTHOR

Alexander Brett <alexander.brett@sophos.com> L<http://alexander-brett.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Sophos Limited L<https://www.sophos.com/>.

This is free software, licensed under:

  The MIT (X11) License

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
