###############################################################################
# XML::Template
#
# Copyright (c) 2002-2003 Jonathan A. Waxman <jowaxman@bbl.med.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it 
# under the same terms as Perl itself.
#
# ----------------------------------------------------------------------------
#
# Much of the initial design philosophy (and design) was taken from the
# masterfully written Template Toolkit by Andy Wardley which I use 
# extensively myself.
###############################################################################
package XML::Template;
use base qw(XML::Template::Base);

use strict;
use vars qw($VERSION);
use CGI;
use File::Spec;


$VERSION	= '3.20';

=pod

=head1 NAME

XML::Template - Front end module to XML::Template.

=head1 SYNOPSIS

  use XML::Template;

  my $xml_template = XML::Template->new ($config)
    || die XML::Template->error;
  $xml_template->process ('filename.xhtml', %vars)
    || die $xml_template->error;

=head1 DESCRIPTION

This module provides a front-end interface to XML::Template.

=head1 CONSTRUCTOR

A constructor method C<new> is provided by L<XML::Template::Base>.  A list
of named configuration parameters may be passed to the constructor.  The
constructor returns a reference to a new XML::Template object or undef if
an error occurrs.  If undef is returned, use the method C<error> to
retrieve the error.  For instance:

  my $xml_template = XML::Template->new (%config)
    || die XML::Template->error;

The following named configuration parameters are supported by this 
module:

=over 4

=item ErrorTemplate

If a scalar, the name of the XML::Template document to display when an
exception is raised.  The template variables C<Exception.type> and
C<Exception.info> will be set for the exception type and description,
respectively.

C<ErrorTemplate> may also be a reference to an array in which the first
element is the name of the default error template and the second element
is a hash of exception type/template name pairs.  If the type of the
exception raised in listed in the hash, the associated template will be
displayed.  Otherwise, the default template is displayed.

If no error template is given (the default), XML::Template will die.

=item Process

A reference to a processor object.  This value will override the default
value C<$PROCESS> in L<XML::Template::Config>.  The default process object
is L<XML::Template::Process>.

=back

See L<XML::Template::Base> and L<XML::Template::Config> for additional
options.

=head1 PRIVATE METHODS

=head2 _init

This method is the internal initialization function called from
L<XML::Template::Base> when a new object is created.

=cut

sub _init {
  my $self   = shift;
  my %params = @_;

  print "XML::Template::_init\n" if $self->{_debug};

  $self->{_error_template} = $params{ErrorTemplate};

  # Get processor object.
  $self->{_process} = $params{Process}
    || XML::Template::Config->process (%params)
    || return $self->_handle_error (XML::Template::Config->error);

  return 1;
}

=pod

=head2 _handle_error

  $self->_handle_error ($type, $info);

This method will display the appropriate error template for the exception
type, the first parameter.  The second parameter is the description of the 
exception or error message.

=cut

sub _handle_error {
  my $self = shift;
  my ($type, $info) = @_;

  if (defined $type) {
    if (defined $self->{_error_template}) {
      my %vars = (
           'Exception.type'	=> $type,
           'Exception.info'	=> $info
         );

      my $error_template = $self->{_error_template};
      delete $self->{_error_template};

      if (ref ($error_template)) {
        my $default   = $error_template->[0];
        my $templates = $error_template->[1];
        if (exists $templates->{$type}) {
          $error_template = $templates->{$type};
        } else {
          $error_template = $default;
        }
      }

      select STDOUT;  # In case error inside code has selected another fh.
      if (defined $self->{_process}) {
        $self->{_process}->{_cgi_header} = 1;
        my $success;
        $success = $self->{_process}->process ($error_template, \%vars);
        if (! $success) {
          print CGI->header ();
          print scalar ($self->{_process}->error);
          return undef;
        }
      } else {
        print CGI->header ();
        print "$type: $info";
        return undef;
      }
    } else {
      return $self->error ($type, $info);
    }
  }

  return 1;
}

=pod

=head1 PUBLIC METHODS

=head2 process

  $xml_template->process ($filename, %vars)
    || die $xml_template->error;

This method is used to process an XML file.  The first parameter is the
name of an XML document.  The actual source of the XML depends on the
which loader loads the document first.  (See L<XML::Template::Process>.)  
The second parameter is a reference to a hash containing name/value pairs
of variables to add to the global variable context.

=cut

sub process {
  my $self          = shift;
  my ($name, $vars) = @_;

  print ref ($self) . "::process\n" if $self->{_debug};

  # Put CGI variables in a global hash named Form.
  my $cgi = CGI->new ();
  foreach my $param ($cgi->param) {
    my @values = $cgi->param ($param);
    $vars->{"Form.$param"} = scalar (@values) == 1 ? $values[0] : \@values;
  }

  if (! $self->{_process}->process ($name, $vars)) {
    return $self->_handle_error ($self->{_process}->error ());
  }

  return 1;
}

=pod

=head1 ACKNOWLEDGEMENTS

Much of the initial design philosophy (and design) was taken from or
inspired by the masterfully written Template Toolkit by Andy Wardley which
I use extensively myself.

Thanks to Josh Marcus, August Wohlt, and Kristina Clair for many valuable 
discussions.

=head1 AUTHOR

Jonathan A. Waxman
<jowaxman@bbl.med.upenn.edu>

=head1 COPYRIGHT

Copyright (c) 2002-2003 Jonathan A. Waxman
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


1;
