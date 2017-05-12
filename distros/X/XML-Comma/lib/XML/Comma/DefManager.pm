##
#
#    Copyright 2001-2005, AllAfrica Global Media
#
#    This file is part of XML::Comma
#
#    XML::Comma is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    For more information about XML::Comma, point a web browser at
#    http://xml-comma.org, or read the tutorial included
#    with the XML::Comma distribution at docs/guide.html
#
##

package XML::Comma::DefManager;
use strict;

if ( XML::Comma->defs_from_PARs() ) {
  eval {
    require PAR;
  }; if ( $@ ) {
    die "Comma is configured to use PAR.pm, but it's not loadable.\n";
  }
}
use File::Spec;
use XML::Comma::Util qw( dbg );

## hash for def references. $def->name_up_path() => $def
my %defs;
my %pnotes;

sub for_path {
  my ( $class, $path ) = @_;
  return $defs{$path} if  $defs{$path} && ! _modified_since ( $defs{$path} );
  my @path = split ':', $path;
  _make_def ( $path[0] );
  return $defs{$path} || die "no Def found for '$path'\n";
}

sub macro_string {
  my ( $class, $name ) = @_;
  my $macro_source = _find_source ( $name, XML::Comma->macro_extension() );
  die "cannot find macro file for '$name'\n"  unless  $macro_source;

  if ( ref $macro_source ) {
    return $macro_source->{source};
  }

  open ( my $macro, $macro_source ) || die "can't open macro file: $!\n";
  my @lines = <$macro>;
  close $macro;
  return join ( '', @lines );
}

sub include_string {
  my ( $class, $name, $args_string ) = @_;
  my $eval = 0;
  if ( $name =~ m|\{\s*(.*)\s*\}| ) {
    $name = $1;
    $eval++;
  }

  my $incl_source = _find_source ( $name, XML::Comma->include_extension() );
  die "cannot find include file for '$name'\n"  unless  $incl_source;

  my $content;
  my $filename = $name;

  if ( ref $incl_source ) {
    $content = $incl_source->{source};
  } else {
    $filename = $incl_source;
    open ( my $incl, $incl_source ) || die "can't open include file: $!\n";
    my @lines = <$incl>;
    close $incl;
    $content = join ( '', @lines );
  }

  if ( $eval ) {
    $args_string ||= "()";
    my $code_ref = eval $content;
    if ( $@ ) {
      die "error while evaling '$filename' code-include: $@\n";
    }
    my @args_list = eval $args_string;
    if ( $@ ) {
      die "error while evaling args list for '$filename' code-include: $@\n";
    }
    eval {
      $content = $code_ref->( @args_list );
    }; if ( $@ ) {
      die "error while executing '$filename' code-include: $@\n";
    }
  }
  # dbg 'include', $filename, $content;
  return ( $content, $filename );
}

sub add_def {
  my ( $class, $def ) = @_;
  $defs{$def->name_up_path()} = $def;
}


sub to_string {
  my $str = "--- DefManager ---\n";
  foreach my $key ( sort keys %defs ) {
    $str .= $key . "    - $defs{$key} \n";
  }
  return $str;
}


sub _modified_since {
  my $def = shift();
  # if we don't have a from_file for this def, we can't know when it
  # was modified, so return false
  return if  ! $def->{_from_file};
  # otherwise, check modified time
  if ( (stat($def->{_from_file}))[9] > $def->{_last_mod_time} ) {
    return 1;
  }
  return;
}


sub _make_def {
  my $doc_type = shift();
  my $def_source = _find_source ( $doc_type,
                                  XML::Comma->defs_extension() );
  die "cannot find definition file for '$doc_type'\n"  unless
  $def_source;

  my $def;
  if ( ref $def_source ) {
    $def = XML::Comma::Def->new ( block => $def_source->{source} );
  } else {
    $def = XML::Comma::Def->new ( file => $def_source );
  }
  # make a "symbolic link" to this def from the requested def name, if
  # the requested name is different from the loaded top-level tag
  if ( $def  and  $doc_type ne $def->element('name')->get() ) {
    $defs{$doc_type} = $defs{$def->element('name')->get()};
  }
}


# we return either a simple filename, or a hashref with a "source"
# value that holds the block to be turned into a
# def/macro/include. this is an evolutionary kludge, and we should
# centralize all *read* logic here (ie, no more file opens in the
# parsers) at some not-too-distant remove.
sub _find_source {
  my ( $name, $extension ) = @_;
  # try each defs_directory in turn
  foreach my $dir ( @{XML::Comma->defs_directories()} ) {
    my $filename = File::Spec->canonpath
      ( File::Spec->catfile($dir, $name . $extension) );
    return $filename  if  -r $filename;
  }
  # if we're allowed to, try a generic PAR load
  if ( XML::Comma->defs_from_PARs() ) {
    my $source = PAR::read_file 
    ( File::Spec->canonpath(File::Spec->catfile('comma', $name . $extension)) );
    return { source => $source }  if  $source;
  }
  # well, no luck
  return;
}


sub _find_macro_file {
  my $name = shift();
  # try each defs_directory in turn
  foreach my $dir ( @{XML::Comma->defs_directories()} ) {
    my $filename = $dir . '/' . $name . XML::Comma->macro_extension();
    return $filename  if  -r $filename;
  }
  die "cannot find macro file for macro '$name'\n";
}

sub _find_include_file {
  my $name = shift();
  # try each defs_directory in turn
  foreach my $dir ( @{XML::Comma->defs_directories()} ) {
    my $filename = $dir . '/' . $name . XML::Comma->include_extension();
    return $filename  if  -r $filename;
  }
  die "cannot find include file for include '$name'\n";
}


sub get_pnotes {
  my ( $class, $def ) = @_;
  if ( ref($def) && ref($def) eq 'XML::Comma::Def' ) {
    return $pnotes{$def->name_up_path()} ||= {};
  } else {
    return $pnotes{ $class->for_path($def)->name_up_path() } ||= {};
  }
}

#
####
####
my $bootstrap_def = XML::Comma::Bootstrap->new
  ( block => XML::Comma::Bootstrap->bootstrap_block() );
####
####
#

# be paranoid about global destruction: undef the references that
# we're holding to all Defs and pnotes objects...
END {
#  print "DefManager undefing...\n";
  map { undef $defs{$_} } keys %defs;
  map { undef $defs{$_} } keys %pnotes;
#  print "done with DM end\n";
}

1;


