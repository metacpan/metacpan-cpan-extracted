###############################################################################
# XML::Template::Base
#
# Copyright (c) 2002-2003 Jonathan A. Waxman <jowaxman@bbl.med.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it 
# under the same terms as Perl itself.
###############################################################################
package XML::Template::Base;

use strict;
use XML::Template::Config;


my $SOURCE = {};

=pod

=head1 NAME

XML::Template::Base - Base class for XML::Template modules.

=head1 SYNOPSIS

  use base qw(XML::Template::Base);
  use XML::Template::Base;

=head1 DESCRIPTION

This module is the XML::Template base class.  It implements common
functionality for many other XML::Template modules, including construction
and error handling.

=head1 CONSTRUCTOR

XML::Template::Base provides a common constructor for XML::Template
modules.  The constructor creates a new self and calls an initialization
method.  If the derived class does not have its own initialization
subroutine, XML::Template::Base provides one that simply returns true.

The following named configuration parameters are supported:

=over 4

=item Debug

Set to true to turn on printing debug information.  Not really supported.

=item HTTPHost

The hostname of the requesting server.  The default value is set to the
environment variable C<HTTP_HOST>.  If this is not set (for instance, if
running on the command line), the default is C<localhost>.

=item Config

A reference to an XML::GDOME object that contains XML::Template
configuration information.  See L<XML::Template::Config>.

=back 4

=cut

sub new {
  # Due to the force of karma, we take rebirth.
  my $proto = shift;

  # Due to ignorance, a self is fabricated.
  my $self  = {};

  # Due to karmic imprints on our consciousness, name and form arise.
  my $class = ref ($proto) || $proto;
  bless ($self, $class);

  # There is contact between the sense organs and consciousness.
  my %params = @_;

  # Contact is the basis for feelings.
  $self->{_debug} = $params{Debug} if defined $params{Debug};
  $self->{_hostname} = $params{HTTPHost}
    || $ENV{HTTP_HOST}
    || XML::Template::Config->hostname
    || return $proto->error (XML::Template::Config->error);
  $self->{_config} = $params{Config}
    || XML::Template::Config->config
    || return $proto->error (XML::Template::Config->error);
  $self->{_source} = $SOURCE;

  # We become attached to what feels good; attachment and craving lead 
  # to becoming and birth.
  return $self->_init (%params) ? $self

  # Eventually we grow old and die.
                                : $proto->error ($self->error);
}

=pod

=head1 PRIVATE METHODS

=head2 _init

XML::Template::Base provides an initialization function that simply
returns 1. This is required for modules that use XML::Template::Base as a
base class, but do not require an initialization function.

=cut

sub _init {
  my $self = shift;

  return 1;
}

=pod

=head1 PUBLIC METHODS

=head2 error

  return $self->error ($type, $error);
  my ($type, $error) = $self->error;
  print $self->error;

XML::Template::Base provides the method C<error> to do simple error
handling.  If no parameters are given, the currently stored error type and 
message are returned.  If parameters for the error type and message are 
given, they are stored as the current error.

C<error> may be called as a package method (e.g.,
C<XML::Template::Module-E<gt>error ($error);> or as an object method
(e.g., C<$xml_template-E<gt>error ($error);>.  If it is called as a
package method, the error is stored as a package variable.  If it is
called as an object method, the error is stored as a private variable.

=cut

sub error {
  my $self = shift;
  my ($type, $error) = @_;

  # If an error given, set it in the object or package.
  # Otherwise, return the error from the object or package.
  if (defined $type) {
    ref ($self) ? $self->{_error} = [$type, $error]
                : $self::_error = [$type, $error];
    return undef;
  } else {
    if (wantarray) {
      return ref ($self) ? @{$self->{_error}} : @{$self::_error};
    } else {
      if (ref ($self)) {
        return defined $self->{_error}->[0]
                 ? "$self->{_error}->[0]: $self->{_error}->[1]"
                 : undef;
      } else {
        return defined $self::_error->[0]
                 ? "$self::_error->[0]: $self::_error->[1]"
                 : undef;
      }
    }
  }
}

=pod

=head2 get_info

  my $host_info = $self->get_info ("/xml-template/hosts/host[\@name='$name']",
                                   'basedir', 'domain');  

This method returns a hash containing name/value pairs from the
XML::Template configuration file.  The first parameter is an XPath query
that returns the XML subtree containing the desired configuration
information.  The remaining parameters name the child elements of the
configuration subtree whose values you wish returned in the hash.  This
method is wrapped by more specific subroutines, for instance,
get_host_info, get_subroutine_info, get_namespace_info, etc.  See
L<XML::Template::Config> for more details on the XML::Template
configuration file.

=cut
  
sub get_info {
  my $self = shift;
  my ($query, @elements) = @_;

  my ($node) = $self->{_config}->findnodes ($query);
  if (defined $node) {
    my (%info, @info);
    foreach my $el (@elements) {
      my @nodes = $self->{_config}->findnodes ("$query/$el");
      if (scalar (@nodes) == 1) {
        if (wantarray) {
          push (@info, $nodes[0]->string_value);
        } else {
          $info{$el} = $nodes[0]->string_value;
        }
      } elsif (scalar (@nodes) > 1) {
        my @values;
        foreach my $node (@nodes) {
          push (@values, $node->string_value);
        }
        if (wantarray) {
          push (@info, \@values);
        } else {
          push (@{$info{$el}}, \@values);
        }
      }
    }

    return wantarray ? @info : \%info;
  }

  return undef;
}

=pod

=head2 get_host_info

  my $host_info = $self->get_host_info ($hostname);
  my $host_info = $self->get_host_info ($hostname, 'domain');

This method returns a hash of name/value pairs of hostname information
from the XML::Template configuration file.  The first parameter is the
name of the host for which information is desired.  The remaining
parameters name the configuration elements to include in the hash.  If no
such parameters are given, all host configuration elements are included.  
Currently, this includes C<basedir> and C<domain>.

=cut

sub get_host_info {
  my $self = shift;
  my ($name, @elements) = @_;

  @elements = qw(basedir domain) if ! scalar (@elements);
  return $self->get_info (
           "/xml-template/hosts/host[\@name='$name']",
           @elements);  
}

=pod

=head2 get_source_mapping_info

  my $get_source_mapping_info = $self->get_source_mapping_info (
                                  namespace	=> $namespace);
  my $get_source_mapping_info = $self->get_source_mapping_info (
                                  namespace	=> $namespace,
                                  'source');

This method returns a hash of name/value pairs of source mapping
two parameters give the resource type and name of the source mapping for
which information is desired.  The remaining parameters name the
configuration elements to include in the hash.  If no such parameters are
given, all source mapping configuration elements are included.  
Currently, this includes C<source>, C<table>, C<keys>, and C<relation>.  
The element C<relation> is a hash of related namespace name/table pairs.

=cut

sub get_source_mapping_info {
  my $self = shift;
  my ($type, $name, @elements) = @_;

  my @telements = qw(source table keys) if ! scalar (@elements);
  my $source_info = $self->get_info (
                      "/xml-template/source-mappings/source-mapping[\@$type='$name']",
                      @telements);

  my %elements = map { $_ => 1 } @elements;
  if (! scalar (@elements) || $elements{relation}) {
    my @nodes = $self->{_config}->findnodes (
                  "/xml-template/source-mappings/source-mapping[\@$type='$name']/relation/\@namespace");
    foreach my $node (@nodes) {
      my $namespace = $node->string_value;
      $source_info->{relation}->{$namespace} = $self->get_info (
        "/xml-template/source-mappings/source-mapping[\@$type='$name']/relation[\@namespace='$namespace']",
        'table');
    }
  }

  return $source_info;
}

=pod

=head2 get_source_info

  my $source_info = $self->get_source_info ($sourcename);
  my $source_info = $self->get_source_info ($sourcename, 'module');

This method returns a hash of name/value pairs of source information from
the XML::Template configuration file.  The first parameter is the name of
the source for which information is desired.  The remaining parameters
name the configuration elements to include in the hash.  If no such
parameters are given, all host configuration elements are included.
Currently, this includes C<module>, C<dsn>, C<user>, and C<pwdfile>.

=cut

sub get_source_info {
  my $self = shift;
  my ($name, @elements) = @_;

  @elements = qw(module dsn user pwdfile) if ! scalar (@elements);
  return $self->get_info (
           "/xml-template/sources/source[\@name='$name']",
           @elements);
}

=pod

=head2 get_source

  my $source = $self->get_source ($sourcename);

This method returns the data source named by the parameter from the 
XML::Template configuration file.

Data source references are stored in a cache.  If a requested data source
has already been loaded, the cached reference to it is returned.

=cut

sub get_source {
  my $self = shift;
  my $sourcename = shift;

  my $source;
  if (defined $sourcename) {
    # If source already requested, return stored reference.
    if (defined $self->{_source}->{$sourcename}) {
      $source = $self->{_source}->{$sourcename};

    # Create and return a reference to a source object.
    } else {
      my $sourceinfo = $self->get_source_info ($sourcename, 'module');
      if (defined $sourceinfo) {
        # Load the source module.
        my $module = $sourceinfo->{module};
        XML::Template::Config->load ($module)
          || return $self->error (XML::Template::Config->error);

        # Create a new data source object.
        $source = $module->new ($sourcename)
          || return $self->error ('Source', scalar ($module->error ()));

        # Cache the data source object.
        $self->{_source}->{$sourcename} = $source;

      } else {
        return $self->error ('Source', "Source '$sourcename' not defined.");
      }
    }
  }

  return $source;
}

=pod

=head2 get_subroutine_info

  my $subroutine_info = $self->get_subroutine_info ($subname);
  my $subroutine_info = $self->get_subroutine_info ($subname, 'module');

This method returns a hash of name/value pairs of subroutine information
from the XML::Template configuration file.  The first parameter is the
name of the subroutine for which information is desired.  The remaining
parameters name the configuration elements to include in the hash.  If no
such parameters are given, all host configuration elements are included.
Currently, this include C<description> and C<module>.

=cut

sub get_subroutine_info {
  my $self = shift;
  my ($name, @elements) = @_;

  @elements = qw(description module) if ! scalar (@elements);
  return $self->get_info (
           "/xml-template/subroutines/subroutine[\@name='$name']",
           @elements);
}

=pod

=head2 get_namespace_info

  my $namespace_info = $self->get_namespace_info ($namespace);
  my $namespace_info = $self->get_namespace_info ($namespace, 'title');

This method returns a hash of name/value pairs of namespace information
from the XML::Template configuration file.  The first parameter is the
name of the namespace for which information is desired.  The remaining
parameters name the configuration elements to include in the hash.  If no
such parameters are given, all host configuration elements are included.
Currently, this include C<prefix>, C<title>, C<decsritpion>, and
C<module>.

=cut

sub get_namespace_info {
  my $self = shift;
  my ($name, @elements) = @_;

  @elements = qw(prefix title description module) if ! scalar (@elements);
  return $self->get_info (
           "/xml-template/namespaces/namespace[\@name='$name']",
           @elements);
}
=pod

=head2 get_element_info

  my $element_info = $self->get_element_info ($namespace, $element);
  my $element_info = $self->get_element_info ($namespace, $element,
                                              'content');

This method returns a hash of name/value pairs of element information from
the XML::Template configuration file.  The first two parameters,
respectively, are the name of the namespace in which the element resides
and the name of the element for which information is desired.  The
remaining parameters name the configuration elements to include in the
hash.  If no such parameters are given, all host configuration elements
are included. Currently, this include C<content> and C<nestedin>.

=cut

sub get_element_info {
  my $self = shift;
  my ($namespace, $name, @elements) = @_;

  @elements = qw(content nestedin) if ! scalar (@elements);
  return $self->get_info (
           "/xml-template/namespaces/namespace[\@name='$namespace']/element[\@name='$name']",
           @elements);
}

=pod

=head2 get_attribs

  my $attribs = $self->get_attribs ($namespace, $element, $attrib);

This method returns an array of attribute names for an element.  The first 
parameter specifies the namespace in which the element resides.  The 
second parameter is the name of the element.

=cut

sub get_attribs {
  my $self = shift;
  my ($namespace, $element) = @_;

  my @attribs;
  my @nodes = $self->{_config}->findnodes ("/xml-template/namespaces/namespace[\@name='$namespace']/element[\@name='$element']/attrib/\@name");
  foreach my $node (@nodes) {
    push (@attribs, $node->string_value);
  }
  return @attribs;

  return undef;
}

=pod

=head2 get_attrib_info

  my $attrib_info = $self->get_attrib_info ($namespace, $element, $attrib);
  my $attrib_info = $self->get_attrib_info ($namespace, $element, $attrib,
                                            'parse');

This method returns a hash of name/value pairs of attribute information
from the XML::Template configuration file.  The first three parameters,
respectively, are the namespace in which the associated element resides,
the attribute's associated element, and the name of the attribute for
which information is desired.  The remaining parameters name the
configuration elements to include in the hash.  If no such parameters are
given, all host configuration elements are included. Currently, this
include C<requires>, C<parse>, C<parser>, and C<type>.

=cut

sub get_attrib_info {
  my $self = shift;
  my ($namespace, $element, $name, @elements) = @_;

  @elements = qw(required parse parser type) if ! scalar (@elements);
  return $self->get_info (
           "/xml-template/namespaces/namespace[\@name='$namespace']/element[\@name='$element']/attrib[\@name='$name']",
           @elements);
}

=pod

=head1 AUTHOR

Jonathan Waxman
<jowaxman@bbl.med.upenn.edu>

=head1 COPYRIGHT

Copyright (c) 2002-2003 Jonathan A. Waxman
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


1;
