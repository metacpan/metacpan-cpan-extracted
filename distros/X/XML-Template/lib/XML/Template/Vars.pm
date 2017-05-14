###############################################################################
# XML::Template::Vars
#
# Copyright (c) 2002-2003 Jonathan A. Waxman <jowaxman@law.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
###############################################################################
package XML::Template::Vars;
use base qw(XML::Template::Base);

use strict;
use XML::Template::Config;
use Data::Dumper;


=pod

=head1 NAME

XML::Template::Vars - Module for handling XML::Template variables.

=head1 SYNOPSIS

This module is used for handling the various XML::Template data types and 
variables.  It is used to create and remove variable contexts and get, 
set, and unset scalar, array, nested, and XPath variables.

=head1 CONSTRUCTOR

A constructor method C<new> is provided by L<XML::Template::Base>.  A list
of named configuration parameters may be passed to the constructor.  The
constructor returns a reference to a new parser object or under if an
error occurred.  If undef is returned, you can use the method C<error> to
retrieve the error.  For instance:

  my $parser = XML::Template::Vars->new (%config)
    || die XML::Template::Vars->error;

=head1 PRIVATE METHODS

=head2 _init

This method is the internal initialization function called from
L<XML::Template::Base> when a new vars object is created.

=cut

sub _init {
  my $self   = shift;
  my %params = @_;

  print ref ($self) . "->_init\n" if $self->{_debug};

  $self->{_contexts}   = [];
  $self->{_xpath_objs} = {};

  # Create global context.
  $self->create_context ();

  # Add configuration XPath variable to global context.
  $self->set (Config => '');
  $self->{_xpath_objs}->{Config} = XML::Template::Config->config ();

  return 1;
}

=pod

=head2 _set

  $self->_set ($context, %vars);

This is the internal method for setting variables.  The first parameter 
specifies the variable context in which the variables will be set.  The 
remaining parameters comprise a hash of variable name/value pairs to 
set.  The variable names are in the format of actual XML::Template 
variable names (e.g., C<hash.varname[2]/xpath>).

=cut

sub _set {
  my $self = shift;
  my ($context, %vars) = @_;

  # Set the given variables.
  while (my ($var, $value) = each (%vars)) {
    my $hash = $context;
    my $i = 1;

    my @varparts = split (/(?<!\\)\./, $var);
    @varparts = map { $_ =~ s/\\\./\./g; $_ } @varparts;
    foreach my $varpart (@varparts) {
      my $index;
      if ($varpart =~ /\[\d+\]$/) {
        $varpart =~ s/\[(\d+)\]$//;
        $index = $1;
      }

      if ($i == scalar (@varparts)) {
        if (defined $index) {
          $hash->{$varpart}->[$index] = $value;
        } else {
          $hash->{$varpart} = $value;
        }
      } else {
        if (defined $hash->{$varpart}) {
          if (defined $index) {
            $hash = $hash->{$varpart}->[$index];
          } else {
            $hash = $hash->{$varpart};
          }
        } else {
          if (defined $index) {
            $hash = $hash->{$varpart}->[$index] = {};
          } else {
            $hash = $hash->{$varpart} = {};
          }
        }
      }
      $i++;
    }

    # Remove any cached XPath object for this variable.
    $var =~ /^([^\/]+)/;
    delete $self->{_xpath_objs}->{$1};
  }

  return 1;
}

=pod

=head2 _unset

  $self->_unset ($context, @varparts);

This method is the internal method for unsetting (deleting) variables.  
The first parameter is the context in which to remove variables.  The 
remaining parameters are the individual parts of a nested variable.  For 
instance to remove the variable C<hash1.hash2.varname>, do

  $self->_unset ($context, 'hash1', 'hash2', 'varname');

=cut

sub _unset {
  my $self = shift;
  my ($hash, @varparts) = @_;

  my $varpart;
  while (scalar (@varparts)) {
    $varpart = shift (@varparts);

    if (defined $hash->{$varpart}) {
      last if ref ($hash->{$varpart}) ne 'HASH';
      $hash = $hash->{$varpart};
    } else {
      return;
    }
  }
  delete $hash->{$varpart};
}

=pod

=head2

  my $value = $self->_get ($var);

This method is the internal method for getting variables.  The only
parameter names the variable to get.  The name of the variable is in the
format of an XML::Template variable name.

=cut

sub _get {
  my $self = shift;
  my $var  = shift;

#  $var =~ s/'([^"]*)'/backdot ($1)/gem;
  my @varparts = split (/(?<!\\)\./, $var);
  @varparts = map { $_ =~ s/\\\./\./g; $_ } @varparts;

  # Look for the variable starting at the top of the context stack.
  my $value;
  foreach my $context (@{$self->{_contexts}}) {
    $value = $context;
    foreach my $tvarpart (@varparts) {
      my $varpart = $tvarpart; # xxx
      my ($index, $xpath);
      if ($varpart =~ m[(?<!\\)/]) {
        $varpart =~ s[(?<!\\)/(.*)][];
        $xpath = "/$1";
      }
#      $varpart =~ s/^'//; $varpart =~ s/'$//;
      $varpart =~ s[\\/][/]g;
      if ($varpart =~ /\[\d+\]$/) {
        $varpart =~ s/\[(\d+)\]$//;
        $index = $1;
      }
      if (exists $value->{$varpart}) {
        if (defined $index) {
          $value = $value->{$varpart}->[$index];
        } else {
          $value = $value->{$varpart};
        }
        if (defined $xpath && defined $value) {
          # Get the XPath object from the cache or create a new one.
          my $xp;
          if (ref ($value) =~ /^XML::GDOME/) {
            $xp = $value;
            $xpath =~ s[^/][]; # Relativize xpath statement.
          } else {
            $var =~ /^([^\/]+)/;
            my $fullvar = $1;

            if (exists $self->{_xpath_objs}->{$fullvar}) {
              $xp = $self->{_xpath_objs}->{$fullvar};
            } else {
              my $parser = XML::GDOME->new ();
              $xp = $parser->parse_string ($value);
              $self->{_xpath_objs}->{$fullvar} = $xp;
            }
          }

          my @nodes = $xp->findnodes ($xpath);
          $value = scalar (@nodes) > 1 ? \@nodes : $nodes[0];
        }
      } else {
        undef $value;
        last;
      }
    }
    last if defined $value;
  }

  return ($value);
}

=pod

=head1 PUBLIC METHODS

=head2 create_context

  $vars->create_context ();

This method creates a new variable context.  Any variables added to this 
context will shadow variables with the same name in previous contexts.

=cut

sub create_context {
  my $self = shift;

  # Push a new context onto the context stack.
  my %context = ();
  unshift (@{$self->{_contexts}}, \%context);

  return (\%context);
}

=pod

=head2 delete_context

  $vars->delete_context ()

This method deletes the current variable context.

=cut

sub delete_context {
  my $self = shift;

  # Pop the context stack.
  my $context = shift (@{$self->{_contexts}});

  return $context;
};

=pod

=head2 set

  $vars->set ('hash.varname[2]' => 'blah', 'varname2' => 'ick');

This method is used to set variables in the current variable context.  
The parameters comprise a hash of variable name/value pairs.  The variable
names are in the format of actual XML::Template variable names.

=cut

sub set {
  my $self = shift;
  my %vars = @_;

  # Get the current context, or create one if there are none.
  $self->_set ($self->{_contexts}->[0], %vars);

  return 1;
}

=pod

=head2 set_global

  $vars->set_global ('hash.varname[2]' => 'blah', varname2 => 'ick');

This method sets global variables by setting them in the topmost variable
contest.  The parameters comprise a hash containing variable name/value
pairs to set.  The variable names are in the format of actual
XML::Template variable names.

=cut

sub set_global {
  my $self = shift;
  my %vars = @_;

  my $top = scalar (@{$self->{_contexts}});
  my $context = $self->{_contexts}->[$top - 1];

  $self->_set ($context, %vars);

  return 1;
}

=pod

=head2 unset

  $vars->unset ('hash.varname', 'varname2');

This method unsets (deletes) variables in the current variable context.  
The parameters comprise an array containing the names of variables to
delete.  The variable names are in the format of actual XML::Template
variable names.

=cut

sub unset {
  my $self = shift;
  my @vars = @_;

  foreach my $var (@vars) {
    foreach my $context (@{$self->{_contexts}}) {
      $self->_unset ($context, split ('\.', $var));
    }
  }

  return ('');
}

=pod

=head2 get

  my $value = $vars->get ('varname');
  my @values = $vars->get ('hash.varname[2]/xpath', 'varname2');

This method is used to get variable values.  The parameters comprise an
array of names of variables to get.  The variable names are in the format
of actual XML::Template variable names.

=cut

sub get {
  my $self = shift;
  my @vars = @_;

  my @values;

  foreach my $var (@vars) {
    my $value = $self->_get ($var);
    push (@values, $value);
  }

  if (wantarray) {
    return (@values);
  } else {
    # This is necessary to return undef properly.
    if (scalar (@values) == 1) {
      return ($values[0]);
    } else {
      return (join (',', @values));
    }
  }
}

=pod

=head2 get

  my $value = $vars->get ('varname');
  my @values = $vars->get ('hash.varname[2]/xpath', 'varname2');

Like C<get>, this method is used to get variable values.  However, this
method is XPath aware.  That is, if a value is a GDOME object, it will be
converted to text.  Currently, only GDOME is supported.  I need to
implement a way to handle arbitrary XML parsers.  The parameters comprise
an array of names of variables to get.  The variable names are in the
format of actual XML::Template variable names.

=cut

sub get_xpath {
  my $self = shift;

  if (wantarray) {
    return $self->get (@_);
  } else {
    my $value = $self->get (@_);
    if (ref ($value) =~ /^XML::GDOME/) {
      if (ref ($value) eq 'XML::GDOME::Attr') {
        $value = $value->string_value ();
      } else {
        $value = $value->toString ();
      }
    }
    return $value;
  }
}

sub backslash {
  my $self = shift;
  my ($patt, $text) = @_;

  $text =~ s/(?<!\\)([$patt])/\\$1/g;
  return $text;
}

sub push {
  my $self = shift;
  my %vars = @_;

  while (my ($var, $push_values) = each (%vars)) {
    my $value = $self->_get ($var);
    if (ref ($value) eq 'ARRAY') {
      CORE::push (@$value, @$push_values);
    } else {
      $self->set ($var => $push_values);
    }
  }

  return '';
}

sub pop {
  my $self = shift;
  my $var  = shift;

  my $value = $self->_get ($var);
  if (ref ($value) eq 'ARRAY') {
    return (CORE::pop (@$value));
  } else {
    return '';
  }
}

sub dump {
  my $self = shift;

  my $i = 0;
  foreach my $context (@{$self->{_contexts}}) {
    print "Context $i:<br>\n";
    while (my ($var, $value) = each (%$context)) {
      print "$var: " . Dumper ($value);
    }
    $i++;
  }
}

=pod

=head1 AUTHOR

Jonathan Waxman
jowaxman@bbl.med.upenn.edu

=head1 COPYRIGHT

Copyright (c) 2002-2003 Jonathan A. Waxman
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


1;
