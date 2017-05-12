package WWW::SFDC::Constants;
# ABSTRACT: Data about SFDC Metadata Components.

use 5.12.0;
use strict;
use warnings;

our $VERSION = '0.37'; # VERSION

use List::Util 'first';
use Log::Log4perl ':easy';

use Moo;
with "WWW::SFDC::Role::SessionConsumer";

has '+session',
  is => 'ro',
  required => 0;

has 'uri',
  is => 'ro',
  default => "urn:partner.soap.sforce.com";

sub _extractURL { return $_[1]->{serverUrl} }


has 'TYPES',
  is => 'ro',
  lazy => 1,
  default => sub {
    my $self = shift;
    +{
      map {
        $_->{directoryName} => $_;
      } @{$self->session->Metadata->describeMetadata->{metadataObjects}}
    }
  };

has '_subcomponents',
  is => 'ro',
  lazy => 1,
  default => sub {
    my $self = shift;
    [map {
      exists $_->{childXmlNames}
        ? ref $_->{childXmlNames} eq 'ARRAY'
          ?  @{$_->{childXmlNames}}
          : $_->{childXmlNames}
        : ()
    } values $self->TYPES];
  };

  
my %_SUBCOMPONENTS = (
  actionOverrides => 'ActionOverride',
  alerts => 'WorkflowAlert',
  businessProcesses => 'BusinessProcess',
  fieldSets => 'FieldSet',
  fieldUpdates => 'WorkflowFieldUpdate',
  fields => 'CustomField',
  flowActions => 'WorkflowFlowAction',
  listViews => 'ListView',
  outboundMessages => 'WorkflowOutboundMessage',
  recordTypes => 'RecordType',
  rules => 'WorkflowRule',
  tasks => 'WorkflowTask',
  validationRules => 'ValidationRule',
  webLinks => 'WebLink'
);
    

sub needsMetaFile {
  my ($self, $type) = @_;
  return $self->TYPES->{$type} && exists $self->TYPES->{$type}->{metaFile}
    ? $self->TYPES->{$type}->{metaFile} eq 'true'
    : LOGDIE "$type is not a recognised type";
}


sub hasFolders {
  my ($self, $type) = @_;
  return $self->TYPES->{$type} && exists $self->TYPES->{$type}->{inFolder}
    ? $self->TYPES->{$type}->{inFolder} eq 'true'
    : LOGDIE "$type is not a recognised type";
}


sub getEnding {
  my ($self, $type) = @_;
  LOGDIE "$type is not a recognised type" unless $self->TYPES->{$type};
  return $self->TYPES->{$type}->{suffix}
    ? ".".$self->TYPES->{$type}->{suffix}
    : undef;
}


sub getDiskName {
  my ($self, $query) = @_;
  return first {$self->TYPES->{$_}->{xmlName} eq $query} keys %{$self->TYPES};
}


sub getName {
  my ($self, $type) = @_;
  return $_SUBCOMPONENTS{$type} if grep {/$type/} keys %_SUBCOMPONENTS;
  LOGDIE "$type is not a recognised type" unless $self->TYPES->{$type};
  return $self->TYPES->{$type}->{xmlName};
}


sub getSubcomponentsXMLNames {
  return keys %_SUBCOMPONENTS;
}

1;

__END__

=pod

=head1 NAME

WWW::SFDC::Constants - Data about SFDC Metadata Components.

=head1 VERSION

version 0.37

=head1 SYNOPSIS

Provides the methods required for translating on-disk file names and component
names to forms that the metadata API recognises, and vice-versa.

  WWW::SFDC::Constants->new(
    session => $session
  );

OR

  WWW::SFDC::Constants->new(
    TYPES => $types
  );

=head1 ATTRIBUTES

=head2 TYPES

A hashref containing the result of the metadataObjects member of a
describeMetadata result. If this is populated, Constants will not send any API
calls, so setting this in the constructor with a cached version provides
offline functionality. If you specify a session, this attribute is optional.

=head1 METHODS

=head2 needsMetaFile

=head2 hasFolders

=head2 getEnding

=head2 getDiskName

=head2 getName

When provided with the disk (folder) name for a component type or the node name of a subcomponent,
provides the Metadata API name for that type.

=head2 getSubcomponentsXMLNames

Returns a list of XML node names for subcomponents.

=head1 AUTHOR

Alexander Brett <alexander.brett@sophos.com> L<http://alexander-brett.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Sophos Limited L<https://www.sophos.com/>.

This is free software, licensed under:

  The MIT (X11) License

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
