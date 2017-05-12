package SrcParser;

# This file is part of the build tools for Win32::GUI
# It encapsulates a set of functions to parse and retrieve
# documentation from within the source files.
#
# Author: Robert May , rmay@popeslane.clara.co.uk, 20 June 2005
# $Id: SrcParser.pm,v 1.6 2008/02/09 08:51:27 robertemay Exp $

use strict;
use warnings;

our $VERSION = "0.01";
our $DEBUG = 0;

# parse(@files)
# parses each file passed and "fixes" alternates that are found - see fix_alternates()
# return 1 on success
sub parse
{
  for my $file (@_) {
    parse_file($file);
  }

  fix_alternates();

  return 1;
}

# parse_file($file)
# parses the file, performing rudimentary error checking, and adding any documentation
# found to the stored data.
# dies on errors to force the documentation to be fixed
# returns 1 on success.

my %PACKAGES;
my %EVENTS;

sub parse_file
{
  my($file) = @_;
  print STDERR "Parsing file: '$file'\n" if $DEBUG;

  my $package;

  open(my $FILE, "<$file") or die "Can't open $file: $!";
  while(<$FILE>) {

    # Look for packages
    if(/\(\@\)PACKAGE:\s*(.*\S)\s*$/) {
      $package = $1;
      print STDERR "Found package: '$package'\n" if $DEBUG;

      # initialise packages structure if we haven't already seen the package
      if(not exists $PACKAGES{$package}) {
        $PACKAGES{$package} = {
                                files       => [],
                                methods     => {},
                                abstract    => '',
                                description => '',
                              };
      }

      # store the filename and linenumber where we found this package definition
      push @{$PACKAGES{$package}->{files}}, $file . "[$.]";

      # extract the package abstract and description
      # The abstract is on the line immediately following the package definition;
      # any remaining lines are package description;  We need to be careful, as
      # packages can be defined in multiple places.  Authors should take care to
      # only document the package once.  If there are multiple options, then
      # GUI.pm should be the preferred location
      my $abstract = <$FILE>;                # look at the next line
      if($abstract =~ s/^\s*(#|\*(\/)?)+\s*//) {  # if it looks like documentation, then store the abstact and description
        if($abstract) {
          die "Package $package (${file} [$.]) found a second abstract" if length $PACKAGES{$package}->{abstract} > 0;

          $PACKAGES{$package}->{abstract} = $abstract;

          # find the description:
          while(<$FILE>) {
            if( s/^\s*(#|\*(\/)?)+\s?// ) {  # if it looks like documentation, then store the description
              $PACKAGES{$package}->{description} .= ($_ eq '' ? "\n" : $_);
            }
            else {
              last;
            }
          }
        }
      }
    }

    # Look for methods
    elsif(/\(\@\)METHOD:\s*(.*\S)\s*$/) {
      my $method = $1;
      $method =~ s/\((.*)\)//;  # strip the prototype
      my $methodprototype = $1; # and store it
      $method =~ s/\s+.*//;     # strip anything after the first space - copes with "new Win32::GUI::Thing(args)
      my $methoddescr = '';
      my @alternates;

      # We have an error if there's no current package
      die "Method $method (${file} [$.]) not in a package" if not defined $package;
      print STDERR "Found method: '${package}::${method}'\n\tPrototype: $methodprototype\n" if $DEBUG;

      # We have an error if the method has already been defined
      die "Method $method (${file} [$.]) already defined in package $package"
            if exists $PACKAGES{$package}->{methods}->{$method};

      # Look at the method description
      while(<$FILE>) {

        if(/\(\@\)METHOD:\s*(.*\S)\s*$/) {
          my $alternate = $1;
          $alternate =~ s/\(.*\)//;  # remove prototype
          $alternate =~ s/\s+.*//;
          push @alternates, $alternate;
          print STDERR "\tFound alternate method in package $package: '${alternate}'\n" if $DEBUG;
        }
        elsif( s/^\s*(#|\*(\/)?)+\s?// ) {
          $methoddescr .= ($_ eq '' ? "\n" : $_);
        }
        else {
          # store the method details:
          $PACKAGES{$package}->{methods}->{$method} = {
                                                        prototype   => $methodprototype,
                                                        description => $methoddescr,
                                                        alternates  => \@alternates,
                                                      };
          last;
        }
      }
    }

    #Look for events
    elsif(/\(\@\)EVENT:\s*(.*\S)\s*$/) {
      my $event = $1;
      $event =~ s/\((.*)\)//;
      my $eventprototype = $1;
      $event =~ s/\s+.*//;
      my $eventdescr = '';
      my @packages;
      print STDERR "Found event: '$event'\n\tPrototype: $eventprototype\n" if $DEBUG;

      while(<$FILE>) {
        if(/\(\@\)APPLIES_TO:\s*(.*\S)\s*$/) {
          my $applies = $1;
          @packages = split(/\s*,\s*/, $applies);
          print STDERR "\tApplies to: $applies\n" if $DEBUG;
        }
        elsif( s/^\s*(#|\*(\/)?)+\s?// ) {
          $eventdescr .= ($_ eq '' ? "\n" : $_);
        }
        else {
          # Store the event information
          if(scalar @packages == 0) {
            die "Event $event ($file) found that applies to no packages";
          }

          # store the event against each package it applies to
          else {
            for my $pack (@packages) {
              $pack = "Win32::GUI::" . $pack unless $pack eq '*';

              # The same event has multiple legitimate definitions in different packages
              # for the same package:
              # for example, Terminate() is described in both  Window.xs and MDI.xs,
              # applying to Win32::GUI::Window package in each case.  This is nasty to
              # document, but this is my best attempt:
              # - if the defining package and applies to package are the same store under
              #   the name of the event only.
              # - if they are not, append the defining package to the hash key so that there
              #   is no collision.
              my $frompackage = defined $package ? $package : $pack;

              my $tmpevent = $event;
              if ($frompackage ne $pack) {
                $tmpevent .= " ($frompackage)";
              }

              # it's an error if we've already seen the event
              die "Event $event (${file} [$.]) alredy defined in package($pack)" if exists $EVENTS{$pack}->{$tmpevent};

              # store the event info
              $EVENTS{$pack}->{$tmpevent} = {
                                            name        => $event,
                                            prototype   => $eventprototype,
                                            description => $eventdescr,
                                            file        => $file . "[$.]",
                                         };

            }
          }
          last;
        }
      }
    }

  }
  close($FILE);

  return 1;
}

# get_package_list()
# returns a sorted list of all the packages
sub get_package_list
{
  my @tmp = sort { uc $a cmp uc $b } keys %PACKAGES;
  # Extra @tmp copy needed on perl 5.6.1 to avoid error
  # 'sort routine did not return numeric value'
  return @tmp;
}

# get_package_abstract(package)
# returns the abstract for a package
sub get_package_abstract
{
  my $package = shift;

  return $PACKAGES{$package}->{abstract};
}

# get_package_description(package)
# returns the description for a package
sub get_package_description
{
  my $package = shift;

  return $PACKAGES{$package}->{description};
}

# get_package_method_list(package)
# returns a sorted list of all the methods in a package
sub get_package_method_list
{
  my $package = shift;

  return sort newfirst keys %{$PACKAGES{$package}->{methods}};
}

# helper to sort methods: new method first, then alpha
sub newfirst
{
    return ($a =~ /^new/) ? -1 :
           ($b =~ /^new/) ? 1 : uc($a) cmp uc($b);
}

# get_package_method_prototype(package, method)
# returns the prototype of a method in a package
sub get_package_method_prototype
{
  my $package = shift;
  my $method = shift;

  return $PACKAGES{$package}->{methods}->{$method}->{prototype};
}

# get_package_method_description(package, method)
# returns the description of a method in a package
sub get_package_method_description
{
  my $package = shift;
  my $method = shift;

  return $PACKAGES{$package}->{methods}->{$method}->{description};
}

# get_common_events_list()
# returns a sorted list of all the global events
sub get_common_event_list
{
  return get_package_event_list('*');
}

# get_package_events_list(package)
# returns a sorted list of all the events associated with a package
sub get_package_event_list
{
  my $package = shift;

  return sort { lc $a cmp lc $b } keys %{$EVENTS{$package}};
}

# get_common_event_name(event)
# returns the name for the given common event
sub get_common_event_name
{
  my $event = shift;

  return get_package_event_name('*', $event);
}

# get_package_event_name(package, event)
# returns the name of a given event in a package
sub get_package_event_name
{
  my $package = shift;
  my $event = shift;

  return $EVENTS{$package}->{$event}->{name};
}

# get_common_event_prototype(event)
# returns the prototype for the given common event
sub get_common_event_prototype
{
  my $event = shift;

  return get_package_event_prototype('*', $event);
}

# get_package_event_prototype(package, event)
# returns the prototype of a given event in a package
sub get_package_event_prototype
{
  my $package = shift;
  my $event = shift;

  return $EVENTS{$package}->{$event}->{prototype};
}

# get_common_event_description(event)
# returns the raw description for the common event
sub get_common_event_description
{
  my $event = shift;

  return get_package_event_description('*', $event);
}

# get_package_event_description(package, event)
# return the raw description for an event in a package
sub get_package_event_description
{
  my $package = shift;
  my $event = shift;

  return $EVENTS{$package}->{$event}->{description};
}

# fix_alternates()
#  moves the alternate methods into the correct location, and adds text for them
# - if alternate is in same package, add it with same prototype
#   and description 'See thismethod()'
# - if package is different, add it with same prototype and description 
sub fix_alternates
{
  for my $package (keys %PACKAGES) {
    for my $method (keys %{$PACKAGES{$package}->{methods}}) {
      my $alternates = $PACKAGES{$package}->{methods}->{$method}->{alternates};

      my ($altpack, $altproto, $altdesc);
      for my $altmethod (@$alternates) {
        if ($altmethod !~ /^Win32::GUI::/) {
          $altpack = $package;
          $altproto = $PACKAGES{$package}->{methods}->{$method}->{prototype};
          $altdesc = "See $method()";
        }
        else {
          ($altpack = $altmethod) =~ s/(.*::)/$1/;
          $altproto = $PACKAGES{$package}->{methods}->{$method}->{prototype};
          $altdesc = $PACKAGES{$package}->{methods}->{$method}->{description} .
              "\n\n See also ${package}::${method}().";
        }

        die "alternate method ${altpack}::${altmethod} already defined."
            if exists $PACKAGES{$altpack}->{methods}->{$altmethod};

        # store away the details:
        $PACKAGES{$altpack}->{methods}->{$altmethod} = {
                                                        prototype   => $altproto,
                                                        description => $altdesc,
                                                      };
      }
    }
  }

  return 1;
}

1; # end of SrcParser
