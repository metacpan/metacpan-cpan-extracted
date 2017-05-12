##
#
#    Copyright 2001-2006, AllAfrica Global Media
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

package XML::Comma::BlobElement;

@ISA = ( 'XML::Comma::AbstractElement' );

use strict;
use File::Temp;
use File::Copy;
use XML::Comma::Util qw( dbg trim );

##
# object fields
#
# _Blob_tmpfname            : if the blob is in tmp space, we have these
# _Blob_tmpfhand            :    two things
# _Blob_tmperase            : and possible this one, if we've been "unset"
# _Blob_location            : if the blob is in a permanent store, we have this,
#                           :    perhaps in addition to the two above
# _Blob_content_while_parsing
#
# _set_was_called           : indicates whether to clobber or append when we
#                           : copy the tmpfile back (currently not used, but
#                           : eventually could be used to avoid expensive
#                           : copy() before append
#
# Doc_storage               :



########
#
# Blob Manipulation
#
########


sub set {
  my ( $self, $content, %args ) = @_;
  $self->{_set_was_called} = 1;
  $self->set_or_append($content, "set", %args);
}

sub append {
  my ( $self, $content, %args ) = @_;
  $self->set_or_append($content, "append", %args);
}

sub set_or_append {
  my ( $self, $content, $action, %args ) = @_;
  $self->assert_not_read_only();

  eval {
    # run set hooks
    unless ( $args{no_set_hooks} ) {
      foreach my $hook ( @{$self->def()->get_hooks_arrayref('set_hook')} ) {
        $hook->( $self, \$content, \%args );
      }
    }

    # write or "unwrite"
    if ( defined $content ) {
      $self->_maybe_create_temp();
      copy($self->{_Blob_location}, $self->{_Blob_tmpfname}) if($action eq "append");
      $self->{_Blob_tmperase} = 0;
      my $fh = $self->{_Blob_tmpfhand};
      #seek to EOF (2) to append, else seek to start of file (0)
      seek ( $fh, 0, (($action eq "set") ? 0 : 2) );
      #XML::Comma::Log->warn ( "$action-ing ".length($content)." chars to: ".$self->{_Blob_tmpfname}."\n" );
      print { $fh }  $content;
      truncate( $fh, length($content) ) if($action eq "set");
      seek ( $fh, 0, 0 );
    } else {
      # set an 'erased' flag
      $self->{_Blob_tmperase} = 1;
    }

  }; if ( $@ ) { XML::Comma::Log->err ( 'BLOB_SET_ERROR', $@ ); }

  return $content;
}

sub get {
  my $self = shift();
  return  if  $self->{_Blob_tmperase};
  return  unless  $self->{_Blob_tmpfname} or $self->{_Blob_location};

  my $content = eval {
    if ( $self->{_Blob_tmpfname} ) {
      local $/ = undef;
      #FIXME: this seems either wrong or extraneous code...
      #if we expect $fh to always be at offset zero, why the initial seek?
      #if we expect it to be at an arbitrary offset, we are clobbering
      #that offset instead of using tell() and seeking back to that.
      my $fh = $self->{_Blob_tmpfhand};
      seek ( $fh, 0, 0 );
      my $content = <$fh>;
      seek ( $fh, 0, 0 );
      return $content;
    } else {
      my $content = $self->{Doc_storage}->{store}->read_blob ( $self );
      return $content;
    }
  }; if ( $@ ) { XML::Comma::Log->err ( 'BLOB_GET_ERROR', $@ ); }
  return $content;
}

sub set_from_file {
  my ( $self, $filename, %args ) = @_;
  $self->assert_not_read_only();
  XML::Comma::Log->err ( 'BLOB_ERROR', 'set_from_file() needs a filename arg' )
      unless $filename;
  eval {
    # run set hooks
    foreach my $hook 
      ( @{$self->def()->get_hooks_arrayref('set_from_file_hook')} ) {
        $hook->( $self, $filename, \%args );
      }

    $self->_maybe_create_temp();
    $self->{_Blob_tmperase} = 0;
    copy ( $filename, $self->{_Blob_tmpfname} ) ||
      die "could not copy to blob tmp file '$filename': $!\n";
  }; if ( $@ ) { XML::Comma::Log->err ( 'BLOB_SET_ERROR', $@ ); }
  return '';
}

my $comma_temp_directory = XML::Comma->tmp_directory();
sub _maybe_create_temp {
  my $self = shift;
  unless ( $self->{_Blob_tmpfname} ) {
    ( $self->{_Blob_tmpfhand}, $self->{_Blob_tmpfname} ) =
      File::Temp::tempfile ( 'comma_XXXXXX',
                             DIR    => $comma_temp_directory,
                             SUFFIX => $self->get_extension() || '',
                             UNLINK => 1 );
  }
}


sub validate {
  my $self = shift();
  eval {
    $self->def()->validate ( $self );
  }; if ( $@ ) {
    XML::Comma::Log->err
        ( 'BLOB_VALIDATE_ERROR', "for " . $self->tag_up_path() . ": $@" );
  }
  return '';
}

sub get_location {
  my $self = shift();
  return ''  if  $self->{_Blob_tmperase};
  return $self->{_Blob_tmpfname} || $self->{_Blob_location} || '';
}

# you really don't want to call this unless you know what you're
# doing. this clears out the location pointer from this blob without
# marking the file for erase or changing tmp status
sub clear_location {
  $_[0]->{_Blob_location} = '';
}

# call erase on temp file and/or _Blob_location.
sub scrub {
  my $self = shift();

  if ( $self->{_Blob_location} ) {
    # print "actually erasing\n";
    $self->{Doc_storage}->{store}->erase_blob( $self, $self->{_Blob_location} );
    $self->{_Blob_location} = undef;
  }

  $self->{_Blob_tmperase} = 0;
  if ( $self->{_Blob_tmpfname} ) {
    close ( $self->{_Blob_tmpfhand} );
    unlink $self->{_Blob_tmpfname};
    $self->{_Blob_tmpfname} = $self->{_Blob_tmpfhand} = undef;
  }
}

# called from Storage/Store to handle store() or copy() of parent
# doc. writes tmp files to real storage or erase backing store files,
# returning 1 if there was a copy done, 0 if not. (note that a restore
# of the parent is still necessary to make sure that blob pointers are
# written out, if this routine returs a 1. takes a "copy" arument,
# indicating that this is a copy operation, which means that the store
# should be performed whether or not there's been any modification,
# but that no "scrub" should be done.
sub store {
  my ( $self, %arg ) = @_;

  $self->{_set_was_called} = undef;

  if ( $arg{copy} ) {
    if ( $self->{_Blob_tmperase} ) {
      # don't copy erased blobs
    } elsif ( $self->{_Blob_tmpfname} ) {
      # print "TMP BLOB STORE for " . $self->{_Blob_location} . "\n";
      $self->_store_from_tmp ( copy => $arg{copy} );
    } else {
      # print "IN BLOB STORE for " . $self->{_Blob_location} . "\n";
      $self->{_Blob_location} =
        $self->{Doc_storage}->{store}->copy_to_blob
          ( $self->{Doc_storage}->{location},
            $self->{Doc_storage}->{id},
            $self,
            $self->{_Blob_location} );
      # print "NEW LOCATION " . $self->{_Blob_location} . "\n";
    }
    return 1;
  }

  # rest of code in this method handles normal (non-copy) case
  if ( $self->{_Blob_tmperase} ) {
    print "store - calling scrub\n";
    $self->scrub();
    return 1;
  } elsif ( $self->{_Blob_tmpfname} ) {
    $self->_store_from_tmp();
    return 1;
  }
  return 0;
}

sub _store_from_tmp {
  my ( $self, %arg ) = @_;
  my $to_location;
  if ( $arg{copy} ) {
    $to_location = undef;
  } else {
    $to_location = $self->{_Blob_location} || undef;
  }
  seek ( $self->{_Blob_tmpfhand}, 0, 0 );
  $self->{_Blob_location} =
    $self->{Doc_storage}->{store}->copy_to_blob
      ( $self->{Doc_storage}->{location},
        $self->{Doc_storage}->{id},
        $self,
        $self->{_Blob_tmpfname},
        $to_location );
  close ( $self->{_Blob_tmpfhand} );
  unlink $self->{_Blob_tmpfname};
  $self->{_Blob_tmpfname} = $self->{_Blob_tmpfhand} = undef;
  return 1;
}


# call this on a blob to generate an extension (if any) for the blob's
# location
sub get_extension {
  my $self = shift();
  my ( $_extension_el ) = $self->def()->elements('extension');
  return ''  if  ! $_extension_el;
  my $extension = eval $_extension_el->get();
  # dbg 'ext', $_extension_el->get(), $extension;
  if ( $@ ) { XML::Comma::Log->err ( 'BLOB_EXTENSION_ERROR', $@ ); }
  return $extension;
}

sub _get_hash_add { return $_[0]->get(); }

sub to_string {
  my $self = shift();
  if ( $self->{_Blob_location} ) {
    my $str;
    $str = '<' . $self->tag() . $self->attr_string() . '><_comma_blob>' .
      ( $self->{_Blob_location} ) .
        '</_comma_blob></' . $self->tag() . ">\n";
    return $str;
  } else {
    return '';
  }
}


##
# auto_dispatch -- called by AUTOLOAD, and anyone else who wants to
# mimic the shortcut syntax
#
sub auto_dispatch {
  my ( $self, $m, @args ) = @_;
  if ( my $method = $self->can($m) || $self->method_code($m) ) {
    $method->( $self, @args );
  } else {
    XML::Comma::Log->err ( 'UNKNOWN_ACTION',
                           "no method '$m' found in '" .
                           $self->tag_up_path . "'" );
  }
}


##
# called by parser
#
# keep track of all internal content during the parsing phase, so that
# finish_initial_read can do whatever initialization it needs to do.
sub raw_append {
  $_[0]->{_Blob_content_while_parsing} .= $_[1];
}
sub finish_initial_read {
  my $str = $_[0]->{_Blob_content_while_parsing};
  $str =~ m:(.*)<_comma_blob>(.*)</_comma_blob>(.*):;
  my $preceding = trim $1;
  my $following = trim $3;
  if ( $preceding || $following ) {
    die "illegal content for blob element: $preceding/$following\n";
  }
  $_[0]->{_Blob_location} = $2;
  $_[0]->SUPER::finish_initial_read();
}


#
# on deletion, set to empty
#
sub call_on_delete {
  print "call on delete\n";
  $_[0]->{_Blob_tmperase} = 1;
}

sub DESTROY {
  my $self = shift;
  if ( $self->{_Blob_tmpfname} ) {
    close ( $self->{_Blob_tmpfhand} );
    unlink $self->{_Blob_tmpfname};
    $self->{_Blob_tmpfname} = $self->{_Blob_tmpfhand} = undef;
  }
}

1;
