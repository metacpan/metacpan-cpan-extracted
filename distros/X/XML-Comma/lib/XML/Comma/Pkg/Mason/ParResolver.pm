##
#
#    Copyright 2003, AllAfrica Global Media
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
#    http://xml-comma.org/, or read the tutorial included
#    with the XML::Comma distribution at docs/guide.html
#
##

package XML::Comma::Pkg::Mason::ParResolver;

use strict;
use vars qw( @ISA );

use PAR;
use Archive::Zip;
use File::Spec;
use Apache::Constants qw(OK NOT_FOUND DECLINED DIR_MAGIC_TYPE);
use Apache::Util qw( ht_time );

use Apache::File;  # for byte-range request handling

use HTML::Mason::Resolver;
use HTML::Mason::ComponentSource;
use XML::Comma::Pkg::Mason::ParComponent;

my $PAR_MASON_DIR = 'mason';
my %PAR_aliases;
my %PAR_attr;
my $verbose;


sub simple_handle_request {
  my ( $self, $r, $apache_handler ) = @_;

  return DECLINED  if  $r->content_type  and
                       $r->content_type =~ m|^httpd|;

  if ( $r->content_type                 and
       $r->content_type  !~  m|^text| ) {
    if ( $r->pnotes('PAR') ) {
      return $self->send_raw_file ( $r );
    } else {
      return DECLINED;
    }
  }

  return $apache_handler->handle_request ( $r );
}


my $in_trans_handler_subr;
sub trans_handler {
  my $r = shift;
  return DECLINED  if  $in_trans_handler_subr;

  $r->warn ( '(ParResolver) in trans handler for: ' . $r->uri );
  my ( $par_archive_file, $par_alias_root, $stripped_path ) =
    __PACKAGE__->_is_par_location ( $r->uri );

  unless ( $par_archive_file ) {
    $r->warn ( '(ParResolver) no par found' )  if  $verbose;
    return DECLINED;
  }

  $in_trans_handler_subr = 1;
  my $subr = $r->lookup_uri ( $r->uri );
  $in_trans_handler_subr = 0;

  my ( $par_filename, $par_path_info,
       $par_is_directory, $par_freadable ) = __PACKAGE__->
         _par_translation ( $r, $par_archive_file, $stripped_path );
  my $root = File::Spec->canonpath
    ( File::Spec->catfile ($r->document_root, $par_alias_root) );

  my $apache_filename = $subr->filename;
  $apache_filename =~ s|^$root||;

  my $pl = length ( $par_filename );
  my $al = length ( $apache_filename );

  if ( $verbose ) {
    $r->warn ( "par archive: $par_archive_file" );
    $r->warn ( "par alias root: $par_alias_root" );
    $r->warn ( "par stripped path: $stripped_path" );
    $r->warn ( "par    filename: $par_filename" );
    $r->warn ( "apache filename: $apache_filename" );
  }

  # if par translation has produced a longer par filename apache
  # translation, we should be using the par component. if there is a
  # tie, we use the apache component, unless it doesn't seem to be
  # readable. explanation: a non-readable apache component (in the
  # context of a translation tie) suggests that mason will need to use
  # a dhandler, and if we're doing this resolution as part of a
  # mod_dir-invoked subrequest, things get all mucked up unless we
  # continue to take responsibility for things.)
  if (($pl > $al)  or
      (($pl == $al) and (! -r $apache_filename))) {
    $par_filename = File::Spec->
      canonpath ( File::Spec->catfile($par_alias_root, $par_filename) );
    # keep track of several things about this par translation, for use
    # in future phases of the request
    $r->pnotes    ( PAR            => $par_archive_file );
    $r->pnotes    ( PAR_filename   => $par_filename );
    $r->pnotes    ( PAR_freadable  => $par_freadable );
    $r->pnotes    ( PAR_directory  => $par_is_directory );
    $r->pnotes    ( PAR_alias_root => $par_alias_root );

    $r->push_handlers ( PerlTypeHandler  => \&type_handler );
    $r->push_handlers ( PerlFixupHandler => \&fixup_handler );
    $r->filename  ( $par_filename );
    $r->path_info ( $par_path_info );

    $r->warn ( "(ParResolver) using '$stripped_path' from par archive" )
      if  $verbose;
    return OK;
  } else {
    $r->warn ( "(ParResolver) not using par archive" )  if  $verbose;
    return DECLINED;
  }
}


# Our mime-type handler only cares about par directories. Anything
# else, we let the standard handler deal with.
sub type_handler {
  my $r = shift;
  if ( $r->pnotes('PAR_directory') ) {
    $r->content_type ( DIR_MAGIC_TYPE );
    return OK;
  } else {
    return DECLINED;
  }
}


# We use the fixup handler to set r->filename to our PAR archive file
# -- some parts of Mason expect there to really by an
# r->filename. It's also a convenient place to put debugging info.
sub fixup_handler {
  my $r = shift;

  if ( $verbose ) {
    $r->warn ( "--   perl fixup handler dump   --" );
    $r->warn ( 'uri:            ' . $r->uri );
    $r->warn ( 'filename:       ' . $r->filename );
    $r->warn ( 'path_info:      ' . $r->path_info );
    $r->warn ( 'content_type:   ' . $r->content_type );
    $r->warn ( 'PAR:            ' . $r->pnotes('PAR') );
    $r->warn ( 'PAR_alias_root: ' . $r->pnotes ('PAR_alias_root') );
    $r->warn ( 'PAR_directory:  ' . $r->pnotes('PAR_directory') );
    $r->warn ( 'PAR_filename:   ' . $r->pnotes('PAR_filename') );
    $r->warn ( 'PAR_freadable:  ' . $r->pnotes('PAR_freadable') );
    $r->warn ( "-- end perl fixup handler dump --" );
  }

  $r->filename ( $r->pnotes('PAR') )  if  $r->pnotes('PAR');
  return OK;
}



sub import {
  my $package = shift;
  my %arg     = @_;
  $verbose = $arg{verbose} || 0;
  $arg{base} ||= 'HTML::Mason::Resolver::File::ApacheHandler';
  eval { require $arg{base}; };
  push @ISA, $arg{base};

  while ( my($key, $value) = each %{$arg{par_paths} || {}} ) {
    register_par_path ( $key, $value );
  }
}


sub register_par_path {
  my ( $key, $value ) = @_;
  # simple value
  unless ( ref $value ) {
    $PAR_aliases{$key} = $value;
    return;
  }
  # more complicated case (hash value). right now we know how to deal
  # with a 'par' field and an 'attr' hash
  $PAR_aliases{$key} = $value->{par} ||
    die "no 'par' field for ParResolver path '$key'\n";
  $PAR_attr{$key} = $value->{attr} || {};
}


# this can handle both par and non-par requests, but it's preferable
# in most cases to engineer a 'return DECLINED' in the handler for
# non-par raw file requests rather than to pass them to this
# function. see the "simple_handle_request" method.
sub send_raw_file {
  my ( $self, $r ) = @_;
  $r->warn ( '(ParResolver) send raw file: ' . $r->pnotes('PAR_filename') )
    if $verbose;

  my $content;
  my $content_length;
  my $last_modified;

  if ( $r->pnotes('PAR') ) {
    my $filename = $r->pnotes ( 'PAR_filename' );
    my $root     = $r->pnotes ( 'PAR_alias_root' );
    $filename =~ s|$root||;
    $content = $self->_get_par_source ( $r->pnotes('PAR'), $filename );
    return NOT_FOUND  unless  $content;
    $content_length = length $content;
    $last_modified  = (stat $r->pnotes('PAR'))[9];
  } else {
    $content_length = (stat $r->filename)[7];
    $last_modified  = Apache::Util::ht_time ( (stat _)[9] );
    my $fh = Apache::File->new ( $r->filename )  or  return NOT_FOUND;
    $content = $fh->read ( $fh, $content_length );
    $fh->close();
  }

  $r->header_out ( 'Accept-Ranges' => 'bytes' );
  $r->header_out ( 'Content-Length' => $content_length );
  $r->header_out ( 'Last-Modified'  => Apache::Util::ht_time($last_modified) );

  my $range_request = $r->set_byterange;

  if ( (my $status = $r->meets_conditions) == OK ) {
    $r->send_http_header;
  } else {
    return $status;
  }

  return OK  if  $r->header_only;

  if ( $range_request ) {
    while ( my ($offset, $length) = $r->each_byterange ) {
      $r->print ( substr($content, $offset, $length) );
    }
  } else {
    $r->print ( $content );
  }
  return OK;
}


sub get_info {
  my ( $self, $path ) = @_;
  Apache->request->warn ( "(ParResolver) get_info: $path" )  if  $verbose;

  # is this a readable component as far as SUPER is concerned? If so,
  # we'll use SUPER's resolution
  my $cs = $self->SUPER::get_info ( $path );
  return  $cs  if  $cs;

  # try to resolve this from a par file
  my ( $par_archive_file, $par_alias_root, $stripped_path ) =
    $self->_is_par_location ( $path );
  return  unless  $par_archive_file;

  return $self->_get_par_component_info ( $path,
                                          $par_archive_file,
                                          $stripped_path,
                                          $par_alias_root );
}

sub _get_par_component_info {
  my ( $self, $path, $par_archive, $par_path, $par_alias_root ) = @_;
  my $zip = Archive::Zip->new ( $par_archive );
  return  unless  $zip->memberNamed
    ( File::Spec->canonpath(File::Spec->catfile($PAR_MASON_DIR, $par_path)) );

  #my $comp_class = "HTML::Mason::Component::FileBased";
  my $comp_class = "XML::Comma::Pkg::Mason::ParComponent";

  return HTML::Mason::ComponentSource->new
    (
     friendly_name   => $path,
     comp_id         => "$par_archive||$path",
     last_modified   => (stat $par_archive)[9],
     comp_path       => $path,
     comp_class      => $comp_class,
     source_callback => sub { $self->_get_par_source
                                ( $par_archive, $par_path ) },
     extra => { comp_root      => 'par',
                par_alias_attr => $PAR_attr{$par_alias_root} },
    );
}

sub _get_par_source {
  my ( $self, $par_archive, $par_path ) = @_;
  my $zip = Archive::Zip->new ( $par_archive );
  return $zip->contents
    ( File::Spec->canonpath(File::Spec->catfile($PAR_MASON_DIR, $par_path)) );
}


sub apache_request_to_comp_path {
  my ( $self, $r ) = @_;
  if ( $r->pnotes('PAR') ) {
    if ( $r->pnotes('PAR_freadable') ) {
      return $r->pnotes ( 'PAR_filename' );
    } else {
      return $r->uri;
    }
  } else {
    return $self->SUPER::apache_request_to_comp_path ( $r );
  }
}

sub _is_par_location {
  my ( $self, $path ) = @_;
  foreach my $alias ( keys %PAR_aliases ) {
    return ( $PAR_aliases{$alias}, $alias, $path )  if  $path =~ s|^$alias||;
  }
  return;
}

sub _par_translation {
  my ( $self, $r, $par_file, $path ) = @_;
  $r->warn ( "(ParResolver) doing _par_translation for '$path'" )  if  $verbose;

  $path = File::Spec->canonpath ( $path );
  my @dirs = File::Spec->splitdir ( $path );
  my $zip = Archive::Zip->new ( $par_file );

  my $file_part = $PAR_MASON_DIR;
  my $zip_member;
  do {
    $file_part = File::Spec->catdir ( $file_part, shift @dirs );
    $r->warn ( "(ParResolver) trying to read '$file_part'" )  if  $verbose;
    $zip_member = $zip->memberNamed ( $file_part ) ||
                  $zip->memberNamed ( $file_part . '/' );
  } while ( @dirs        and
            $zip_member  and
            $zip_member->isa('Archive::Zip::DirectoryMember') );

  # if we ended up resolving to a directory, we should make note of that
  my $is_directory;
  if ( $zip_member and
       $zip_member->isa ('Archive::Zip::DirectoryMember') ) {
    $is_directory = 1;
  }

  # finally, we need to figure out our "filename" and "path_info"
  # parts, and return those plus a boolean indicating whether the
  # filename we resolved to is an actual existing thingy.
  $file_part =~ s|$PAR_MASON_DIR||;
  $path =~ m|($file_part)(\/?.*)|;
  my ( $filename, $path_info ) = ( $1 || '/', $2 );
  return ( $filename,
           $path_info,
           $is_directory,
           $zip_member ? 1 : 0 );
}


sub glob_path {
  my ( $self, $pattern ) = @_;
  die "illegal glob_path() -- not allowed to use preloads with ParResolver";
}


1;

__END__

=head1 NAME

XML::Comma::Pkg::Mason::ParResolver - Mason/Comma packages


=head1 DESCRIPTION

C<XML::Comma::Pkg::Mason::ParResolver> knows how to serve Mason
components, Comma defs and perl Modules from zipped archives.

A Comma package is a zip file with the following top-level directories:

  F<comma/> - Def (and macro and include) files
  F<mason/> - Mason components
  F<lib/> - Perl modules

The amazing C<PAR> module handles the loading of modules from the
F<lib/> directory. If you haven't read the PAR documentation, it's
worth doing so. PAR does many interesting things, and we rely only on
a small corner of its functionality.

Comma knows how to load defs from PAR files. The Configuration
variable C<defs_from_PARs> controls whether Comma attempts to load
defs from PARs that have been C<use>'ed into use. That variable is
usually set to 0, so you may need to change it.

This module handles the F<mason/> component serving. Some Apache
configuration is necessary, but with that out of the way you can do
something like the following in a handler.pl file:

  use PAR '/usr/local/apache/htdocs/par-demo.par';
  use XML::Comma::Pkg::Mason::ParResolver
    par_paths => {
      '/par-demo' => { par  => '/usr/local/apache/htdocs/par-demo.par',
                       attr => { color1 => '#0000ff' } }
  };

And the F<mason/> directory in
F</usr/local/apache/htdocs/par-demo.par> will look as if it is part of
the component root, "aliased" to the path F</par-demo>.

In addition, we've specified that any calls to
C<$m->current_comp->attr('color1')> (or any of its friends) will
return the value '#0000ff', even if components inside the PAR file set
that attribute differently.

Finally, we can selectively shadow any component in the PAR file by
creating an actual F</par-demo> directory and components therein. Each
time we attempt to resolve a component down any PAR alias path, we
first check to see if there is an "ordinary" component that we can
use.


=head1 DEMO/EXAMPLE

There is a demo file, called F<par-demo.par>, distributed with the
XML::Comma distribution in the same directory as this source file.


=head1 CONFIGURATION

C<XML::Comma::Pkg::Mason::ParResolver> needs to handle several phases
of the Apache request. Mostly, it can set up to do this itself, but it
is necessary to manually specify a PerlTransHandler in your httpd.conf
(or equivalent). I use these two lines, in the top level of my conf
files:

  # in httpd.conf
  PerlModule       XML::Comma::Pkg::Mason::ParResolver;
  PerlTransHandler XML::Comma::Pkg::Mason::ParResolver::trans_handler

Then, in your F<handler.pl>, you'll need to C<use
XML::Comma::Pkg::Mason::ParResolver>, supplying as arguments your PAR
path information. (You can also supply a C<verbose =&gt; 1> argument,
to have this module print out voluminous debugging info to the Apache
error log.)

Here is a simple handler.pl file that I often use on development servers:

  #!/usr/bin/perl
  #
  # This is a basic handler.pl using XML::Comma::Pkg::Mason::ParResolver.

  package HTML::Mason;

  #
  # Sample Mason handler.

  use HTML::Mason;
  use HTML::Mason::ApacheHandler;
  use Apache::Constants qw(:common);
  use Apache:

  use strict;

  {
     package HTML::Mason::Commands;
     use vars qw( $auth );

     use Apache::Util;
     use XML::Comma;
  }

  use PAR '/usr/local/apache/htdocs/par-demo.par';
  use XML::Comma::Pkg::Mason::ParResolver
    verbose   => 1,
    par_paths => {
      '/foo'      => '/usr/local/apache/htdocs/foo.par',
      '/par-demo' => { par  => '/usr/local/apache/htdocs/par-demo.par',
                       attr => { color1 => '#0000ff' } }
  };

  my $ah_show_error = HTML::Mason::ApacheHandler->new
    (
     comp_root      => '/usr/local/apache/htdocs',
     resolver_class => 'XML::Comma::Pkg::Mason::ParResolver',
     data_dir       => '/usr/local/apache/mason_data',
     error_mode     => 'output',
    );


  sub handler {
    my ($r) = @_;
    my $status = $ah_show_error->interp->resolver
      ->simple_handle_request ( $r, $ah_show_error );
    return $status;
  }

This should work for you too, once your comp_root and par_paths are
adjusted.

=head1 COMPLEXITIES

You may have noticed the C<simple_handle_request> method, used in our
handler sub above. Here is the code for that method, in its entirety:

  sub simple_handle_request {
    my ( $self, $r, $apache_handler ) = @_;

    return DECLINED  if  $r->content_type  and
                         $r->content_type =~ m|^httpd|;

    if ( $r->content_type                 and
         $r->content_type  !~  m|^text| ) {
      if ( $r->pnotes('PAR') ) {
        return $self->send_raw_file ( $r );
      } else {
        return DECLINED;
      }
    }

    return $apache_handler->handle_request ( $r );
  }

Many handler.pl setups have complex setups to determine whether (and
how) Mason should serve top-level requests. If you need to integrate a
ParResolver into such a setup, you'll need to code your own version of
the logic above.

It's important to avoid asking the ParResolver to handle "httpd/*"
content types. Apache uses some heavy wizardry under the covers to
make requests for directories to eventually turn into requests for
index.html files. (And along the way pick up missing trailing
slashes.) We're not going to be able to do this as well as Apache, so
we needs to get out of its way as much as possible.

It's also worth noting that PAR packages will often include binary
files that need to be served without the benefit of Mason
componentization. The C<simple_handle_request> routine assumes that
all "text/*" content types are fair game for Mason, but that all other
content types will be sent byte-for-byte to the client. Your rules for
this may differ.

Components that are served from PAR archives belong to the class
C<XML::Comma::Pkg::Mason::ParComponent>, which is a subclass of
C<HTML::Mason::Component::FileBased>.


=head1 COPYRIGHT and LICENSE

This code is copyright 2003 AllAfrica Global Media.

Like all of the XML::Comma distribution, it is free software; you can
redistribute it and/or modify it under the terms of the GNU General
Public License as published by the Free Software Foundation; either
version 2 of the License, or any later version.  

=cut

