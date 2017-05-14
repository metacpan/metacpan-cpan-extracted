###############################################################################
# XML::Template::Config
#
# Copyright (c) 2002-2003 Jonathan A. Waxman <jowaxman@bbl.med.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
###############################################################################
package XML::Template::Config;
use base qw(XML::Template::Base);

use strict;
use vars qw($AUTOLOAD $BASEDIR $CONFIGDIR $CONFIGFILE $PROCESS $CACHE 
            $FILE_CACHE $HANDLER $VARS $STRING $SUBROUTINE $HOSTNAME 
            $CACHE_SLOTS $CACHE_DIR_SLOTS $CACHE_DIR $ADMINDIR);
use File::Spec;
use XML::Template::Base;
use XML::GDOME;

use constant PACKAGE	=> 0;
use constant VAR	=> 1;


my $CONFIG;


=pod

=head1 NAME

XML::Template::Config - Configuration module for XML::Template modules.

=head1 SYNOPSIS

  use base qw(XML::Template::Base);
  use XML::Template::Base;

=head1 DESCRIPTION

This module is the XML::Template configuration module.  It contains 
the default values of many configuration variables used by 
many XML::Template modules.

=head1 CONFIGURATION VARIABLES

Configuration variables and their default values are defined at the top of
C<XML/Template/Config.pm>.  The variable name must be all uppercase.  
Variable values are actually anonymous array tuples.  The first element is
the type of configuration variable (C<VAR> or C<PACKAGE>), and the second
element is the value.  For instance,

  $CONFIGFILE	= [VAR, '/usr/local/xml-template/xml-template.conf'];
  $PROCESS	= [PACKAGE, 'XML::Template::Process'];

A configuration variable value is obtained by a calls to an
XML::Template::Config subroutine that has the same name as the
configuration variable but is lowercase.  For instance, to get the values
of the configuration variables above,

  my $configfile = XML::Template::Config->configfile;
  my $process    = XML::Template::Config->process (%params);

For configuration variables of the type VAR, the value is simply returned.  
If the type is PACKAGE, the module given by the configuration variable
value is required, and an object is instantiated and returned.  
Parameters passed to the XML::Template::Config subroutine are passed to
the module constructor.

=head2 General Configuration Variables

=over 4

=item BASEDIR

The base installation directory for XML::Template.  This directory
typically contains the system-wide configuration file, a directory
containing the siteadmin templates, and other system-wide templates.

=item ADMINDIR

The directory containing the siteadmin templates, typically 
C<$BASEDIR/admin>.

=item CONFIGDIR

The directory containing the system-wide configuration file, 
typically C<$BASEDIR>.

=item CONFIGFILE

The name of the system-wide configuration file, typically 
C<xml-template.conf>.

=item HOSTNAME

The default name of the host if none is given.

=back

=head2 C<XML::Template> Configuration Variables

=over 4

=item PROCESS

The default document processing module, typically 
L<XML::Template::Process>.

=back

=head2 L<XML::Template::Process> Configuration Variables

=over 4

=item HANDLER

The name of default the SAX parser handler module, typically
L<XML::Template::Parser>.

=item SUBROUTINE

The name of the default module that contains methods implementing
XML::Template subroutines, typically L<XML::Template::Subroutine>.

=item CACHE

The default document memory caching module, typically
L<XML::Template::Cache>.

=item FILE_CACHE

The default document file caching module, typically L<XML::Cache::File>.

=item VARS

The default module that implements XML::Template variables, typically
L<XML::Template::Vars>.

=back

=head2 L<XML::Template::Cache> Configuration Variables.

=over 4

=item CACHE_SLOTS

The size of the cache array.

=back

=head2 L<XML::Template::Cache::File> Configuration Variables

=over 4

=item CACHE_DIR

The directory where cached template document files are stored, typically 
C</tmp/xml-template>.

=back

=head2 L<XML::Template::Parser> Configuration Variables

=over 4

=item STRING

The default module that parses XML::Template strings (attribute values and 
content).

=back

=cut

my $basedir		= '/usr/local/xml-template';
$BASEDIR		= [VAR, $basedir];
$ADMINDIR		= [VAR, File::Spec->join ($basedir, 'admin')];
$CONFIGDIR		= [VAR, $basedir];
$CONFIGFILE		= [VAR, 'xml-template.conf'];
$HOSTNAME		= [VAR, 'localhost'];

# XML::Template
$PROCESS		= [PACKAGE, 'XML::Template::Process'];

# XML::Template::Process
$HANDLER		= [VAR, 'XML::Template::Parser'];
$SUBROUTINE		= [VAR, 'XML::Template::Subroutine'];
$CACHE			= [PACKAGE, 'XML::Template::Cache'];
$FILE_CACHE		= [PACKAGE, 'XML::Template::Cache::File'];
$VARS           	= [PACKAGE, 'XML::Template::Vars'];

# XML::Template::Cache
$CACHE_SLOTS		= [VAR, 5];

# XML::Template::Cache::File
$CACHE_DIR      	= [VAR, '/tmp/xml-template'];

# XML::Template::Parser
$STRING			= [PACKAGE, 'XML::Template::Parser::String'];

=pod

=head1 PUBLIC METHODS

=head2 config

  my $config = XML::Template::Config->config ($configfile);

This method reference a reference to an XML parser object (currently a
GDOME object) for the parsed XML::Template XML cofiguration document. The
first call to C<config> loads the config file and stores it in the package
global variable C<$CONFIG>.  Subsequent calls to C<config> will simply
return C<$CONFIG>.

An optional parameter may be given naming the config file.  If no
parameter is given, the system-wide configuration file is named by the
configuration variable C<$CONFIGFILE> and is located in the directory
specified by C<$CONFIGDIR>.

If the element C<basedir> is present in the host configuration for the
current host, a host-specific configuration document is loaded from
C<basedir> and its contents appended to the contents of the system-wide
configuration.

=cut

sub config {
  my $self       = shift;
  my $configfile = shift;

  my $config;
  if (defined $CONFIG) {
    $config = $CONFIG;
  } else {
    $configfile = File::Spec->catfile (XML::Template::Config->configdir,
                                       XML::Template::Config->configfile)
      if ! defined $configfile;

    my $parser = XML::GDOME->new ();
    $config = eval { $parser->parse_file ($configfile) };
    return $self->error ('Template', $@) if $@;

    # Load user configuration file.
    my $hostname = $self->hostname;
    my ($node) = eval { $config->findnodes (qq{/xml-template/hosts/host[\@name="$hostname"]/basedir/text()}) };
    return $self->error ('Template', $@) if $@;
    if (defined $node) {
      my $basedir = $node->toString;
      $configfile = File::Spec->catfile ($basedir,
                                         XML::Template::Config->configfile);
      my $config2 = eval { $parser->parse_file ($configfile) };
      if (! $@) {
        my (@nodes) = $config2->findnodes ('/xml-template/*');
        my ($root) = $config->findnodes ("/xml-template");
        foreach my $node (@nodes) {
          my $node2 = $config->importNode ($node, 1);
          $root->appendChild ($node2);
        }
      }
    }

    $CONFIG = $config;
  }

  return $config;
}

=pod

=head2 load

  XML::Template::Config->load ($module)
    || return $self->error (XML::Template::Config->error);

This method requires the module named by the parameter.

=cut

sub load {
  my $self = shift;
  my $module = shift;

  $module =~ s[::][/]g;
  $module .= '.pm';
  eval {require $module};

  return $@ ? $self->error ('Config', "Could not load module '$module': $@") : 1;
}

sub AUTOLOAD {
  my $self   = shift;
  my %params = @_;

  if ($AUTOLOAD !~ /DESTROY$/) {
    my $varname = uc ($AUTOLOAD);
    $varname =~ s/.*:://;

no strict 'refs';
    my $var = $$varname;
use strict;
    if (! defined $var) {
      $self->error ('Config', "No configuration variable for '$varname'.\n");
    } else {
      if ($var->[0] == PACKAGE) {
        if ($self->load ($var->[1])) {
          my $package = $var->[1];
          return $package->new (%params)
                   || $self->error ('Config', "Could not load module '$package': " . $package->error);
        }
      } else {
       return $var->[1];
      }
    }

    return undef;
  }
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
