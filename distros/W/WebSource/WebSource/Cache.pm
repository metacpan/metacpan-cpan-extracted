package WebSource::Cache;

use strict;
use WebSource::Module;
#use File::Temp qw/tempfile/;
use Carp;
#use DB_File;

our @ISA = ('WebSource::Module');

=head1 NAME

WebSource::Cache : saves a copy of the data into a file and forwards it

=head1 DESCRIPTION

A B<Cache> operator allows to save the data objects which pass thru it
into seperate files. Such an operator is described by a DOM Node having the following
form :

<ws:cache name="opname"
    directory="dir"
    template="temp-XXXXX"
    forward-to="ops" />

The C<forward-to> and C<name> attributes have there usual signification.

The C<directory> attribut allows to determine which directory is to be used
to store the cached files. The C<template> gives the naming template for the
cached files (A substring of fives X's is replaced by a number).

=head1 SYNOPSIS

  $cache = WebSource::Cache->new(wsnode => $node);

  # for the rest it works as a WebSource::Module

=head1 METHODS

=over 2

=item B<< $source = WebSource->new(desc => $node); >>

Create a new Cache module;

=cut

sub _init_ {
  my $self = shift;
  $self->SUPER::_init_;

  my $wsd = $self->{wsdnode};
  if($wsd) {
    $self->{cachetemp} = $wsd->getAttribute("template");
    $self->{cachedir} = $wsd->getAttribute("directory");
  }
  
  $self->{cachedir} or $self->{cachedir} = "/tmp";
  $self->{cachecount} = 0;

  my %index;
#  tie %index, "DB_File", $self->{cachedir} . "/index.db";
  $self->{cacheindex} = \%index;

  $self->log(1,"Saving fetched files to directory ",$self->{cachedir},
                 " with template ", $self->{cachetemp}); 
}

=item B<< $cache->handle($env); >>

Saves the envelopes data into a file

=cut

sub handle {
  my $self = shift;
  my $env = shift;

  my ($fh, $filename);
  if($self->{cachetemp}) {
    $filename = $self->{cachetemp};
    my $strcnt = sprintf("%08d",$self->{cachecount});
    $filename =~ s/XXXXX/$strcnt/;
    $self->{cachecount} += 1;
  } else {
    $filename = $env->{baseuri};
    $filename =~ s{[/\.\:\+\&]+}{_}g;
  }

  if(! $filename =~ m/\./) {
    my $ext = findext($env->{type});
    $filename .= ".$ext";
  }
    
  open($fh,'>',$self->{cachedir}.'/'.$filename);
  if($env->type eq "object/dom-node") {
    print $fh $env->data->toString(1);
  } else {
    print $fh $env->data;
  }
  close($fh);

  $self->{cacheindex}->{$env->{baseuri}} = $filename;

  $self->log(1,"Cached result for ",$env->{baseuri}," in $filename");
  return $env;
}

sub findext {
  my $t = shift;
  $t eq "text/string" and return "txt";
  $t eq "object/dom-node" and return "xml";
  $t eq "text/html" and return "html";
  $t eq "text/xml" and return "xml";
  $t eq "application/pdf" and return "pdf";
  $t eq "application/postscript" and return "ps";
  $t eq "application/ms-word" and return "doc";
  $t eq "application/rtf" and return "rtf";

  # set txt a default for text
  $t =~ "^text/" and return "txt";
  return undef;
}

=back

=head1 SEE ALSO

WebSource::Module

=cut

1;
