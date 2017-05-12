#!perl

package Ponfish::News::Decoder;

use strict;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Ponfish::ArticleJoiner;
use Ponfish::News::MyNNTP;
use Ponfish::Utilities;
use Ponfish::Config;
use IO::File;

@ISA = qw(Exporter);
@EXPORT = qw(
);
$VERSION = '0.01';


sub extract_command_info {
  my $fn	= shift;

  my $data	= read_file( $fn );

  my @fields	= split /\t/, $data;
  return( $fields[0], $fields[1], [split /\,/, $fields[2]], $fields[3] );
}
my $MAX_RETRIES	= 3;
my $SLEEP_TIME	= 10;	### !!!
my $ARTICLE_TIMEOUT	= 60;
##################################################################

sub new {
  my $type	= shift;
  my $tid	= shift;
  print "New '$type' instance created.  (TID: $tid)\n";
  return bless { servers		=> {},
		 active_group		=> "",
		 active_server		=> "",
		 tid			=> $tid,
	       }, $type;
}

sub get_tid {
  my $self	= shift;
  return $self->{tid};
}

sub process_file {
  my $self	= shift;
  my $fn	= shift;

#  $self->msg( "Processing file: $fn\n" );

  my $field_sep	= FILENAME_FIELD_SEP;
  my($time,$first_id,$newsgroup,$server)	= split /$field_sep/, $fn;
  my($cmd, $arg1, $arg2, $arg3)		= extract_command_info( $fn );	# Note: $arg2 is a list ref.

  $self->set_active_server( $server );
  $self->set_active_group( $newsgroup );

  if( $cmd eq "save" ) {
#    die "save not implemented!";
    return $self->cache_articles( $arg2 );
#    return $self->save_articles( $arg, $articles );
  }
  if( $cmd eq "decode" or $cmd eq "preview" ) {
    $self->cache_articles( $arg2 );
    return $self->decode_cached_articles( $arg2, $arg1 );
  }
  if( $cmd eq "erase" ) {
    $self->msg( "Erase command found in file: '$fn'.  No download.\n" );
    return 1;
  }
  if( $cmd eq "sync_articles" ) {
    return $self->sync_articles( $arg1 );
  }
  if( $cmd eq "purge_unavailable" ) {
    return $self->purge_unavailable( $arg1 );
  }
  if( $cmd eq "sync_groups" ) {
    return $self->sync_groups( $arg1, $arg3, $arg2 );
  }
}

=item sync_groups SERVER_NAME OUTPUT_FILE [LISTREF]

Downloads new groups (or all groups)

=cut

sub sync_groups {
  my $self		= shift;
  my $server_name	= shift;
  my $groups_fn		= shift;
  my $name		= shift;
  $name			= $name->[0];
  my $last_time_filename	= $groups_fn . ".last_newgroups_time";

  $self->msg( "SG: $server_name, $groups_fn, ($name: $last_time_filename)\n" );

  my $this_update_time	= time;		# Save current time...
  my $new_groups;			# To hold the new newsgroups that we'll (maybe) download...

  my $NNTP		= $self->get_or_create_active_server;
  if( ! $NNTP ) {
    log "Error connecting to server!";
    return 0;
  }

  if( -f $last_time_filename ) {
    # Read the last filetime and get the new groups!
    my $time		= read_file( $last_time_filename );
    $self->msg( "Downloading NEW newsgroups from '$server_name' since '$time' (" . scalar(localtime($time)) . ")\n");
    $new_groups		= $NNTP->newgroups( $time );
  }
  else {
    # Let's read all the groups!
    $self->msg( "Downloading ENTIRE newsgroup list from '$server_name'.\n" );
    $new_groups	= $NNTP->list;	#newgroups( time - (3600 * 24 * 60) );
  }

  # Save the data to file:
  my $OF	= create_append_fh( $groups_fn );
  for( sort keys %$new_groups ) {
    print $OF join(" ", $_, @{$new_groups->{$_}}),"\n";
  }
  $OF->close;
  $OF		= "";
  overwrite_file( $this_update_time, $last_time_filename );	# Update the last time file...
  $self->msg( "Downloaded " . scalar( keys %$new_groups ) . " new groups.\n" );
  return 0;	# Force the command file to not be deleted!
  return scalar( keys %$new_groups ) || -1;
}



sub purge_unavailable {
  my $self	= shift;
  my $ng	= shift;

  my $NNTP	= $self->get_or_create_active_server;
  my($num, $gf,$gl)	= $NNTP->group( $ng );	# GroupFirst, GroupLast

  # Create / setup the ArticleJoiner...
  my $AJ	= Ponfish::ArticleJoiner->new;
  $AJ->set_storage_path( ARTICLES_DIR, $self->{active_server}, $ng );
#  $AJ->set_last_id_file( create_valid_filepath( ARTICLES_DIR, $self->{active_server}, $ng . ".retrieved" ) );
  return $AJ->purge_articles( $gf, $ng );
}


=item sync_articles NEWSGROUP

Downloads headers and store them.

=cut

sub sync_articles {
  my $self	= shift;
  my $ng	= shift;

  # First some set up:

  # Get the article number to start with:
  my $first	= config_retrieve( ARTICLES_DIR, $self->{active_server}, $ng.".retrieved" )
    || 0;
  $first	=~ s/\n*//g;	$first++;	# Now it's the first article to get

  my $NNTP	= $self->get_or_create_active_server;
  my($num, $gf,$gl)	= $NNTP->group( $ng );	# GroupFirst, GroupLast
  $first	= max($gf,$first);		# GroupFirst may be larger than our last retrived article
  $self->msg( "Sync Articles: '$ng': From '$first' to '$gl'...\n" );

  return 0	if( $gl == $first );	# No articles to retrive
  if( $gl < $first ) {
    warn "For group: '$ng': last < first ($gl < $first)";
    return 0;
  }
  $first++;	# The actual first article to grab...
  my $AJ	= Ponfish::ArticleJoiner->new;
  $AJ->set_storage_path( ARTICLES_DIR, $self->{active_server}, $ng );
  $AJ->set_last_id_file( create_valid_filepath( ARTICLES_DIR, $self->{active_server}, $ng . ".retrieved" ) );
#  $NNTP->set_AJ( $AJ );
  $AJ->load_prior_incompletes;				# Load any prior incompletes
  $AJ->delete_incompletes_file;				# Remove the incompletes files
  $NNTP->sync_headers_file( $ng, $first, $gl, $AJ );	# This does all of the work!

  $AJ->flush_all_incompletes;
###  $AJ->write_out_old_incompletes( 2_000_000_000 );
  $AJ->store_final_retrieved_numb;
  return 1;
}

sub set_active_server {
  my $self	= shift;
  $self->{active_server}	= shift || die "No server!";
}

sub set_active_group {
  my $self	= shift;
  $self->{active_group}		= shift || die "No newsgroup!";
}

sub decode_binary {
  my $self	= shift;
  my $articles	= shift;

  $self->cache_articles( $articles );
  $self->decode_cached_articles( $articles );
}


sub get_or_create_active_server {
  my $self	= shift;

  my $NNTP	= "";
  my $active_server	= $self->{active_server};
  if( ! $self->{servers}{$active_server} ) {
    $self->msg("Opening new news connection to: '$active_server'\n" );
    $self->open_news_connection( $active_server )
      || die "Can't open connection to server: '$active_server'";
  }
  $NNTP		= $self->{servers}{$active_server};
  return $NNTP;
}


sub cache_articles {
  my $self	= shift;
  my $articles	= shift || die "No articles provided!";

  my $NNTP	= $self->get_or_create_active_server;
  $NNTP->group( $self->{active_group} );
#  if( ( $self->{active_server} ne $server ) or ( $self->{active_group} ne $newsgroup ) ) {
#    $NNTP->safe_group( $newsgroup );
#    $NNTP->group( $newsgroup );
#  }
  for( @$articles ) {
    $self->msg( "Caching article: $_.\n" );
    $self->cache_article( $_ );
  }
}

sub msg {
  my $self	= shift;
  $|		= 1;
  my $msg	= join "", @_;
  print "(",$self->get_tid,"):     ", $msg;
}


sub destroy {
  my $self	= shift;
  $self->disconnect;
  $self->{servers}	= undef;
}


sub open_news_connection {
  my $self	= shift;
  my $server	= shift;

  my $sleep_time	= 30;
  my $NNTP;
  for( 0 .. 10 ) {
    $NNTP	= Ponfish::News::MyNNTP->new( $server,
					      Timeout => 60,
					    )
      || sleep $sleep_time;
    $sleep_time		+= 60;
    last	if( $NNTP );
  }
  my @authinfo	= get_authinfo( $server );
  if( $authinfo[0] ) {
    $NNTP->authinfo( @authinfo );
  }
  $self->{servers}{$server}	= $NNTP;
  return $NNTP;
}

sub disconnect {
  my $self	= shift;
  # Close connections:
  foreach my $server ( values %{$self->{servers}} ) {
    $server->quit;
    delete $self->{servers}{$server}
  }
  $self->{servers}	= {};
  # Invalidate group:
#  delete $self->{active_group};
}

sub wait_for_connection {
  my $self	= shift;

#  my $NNTP	= $self->{servers}{$self->{active_server}} || die "No NNTP object!";
  # Reconnect!
  my $this_group	= $self->{active_group};

  while( 1 ) {
    $self->msg( "Disconnecting...\n" );
    $self->disconnect;
    $self->msg( "Waiting for connection: testing with group( $self->{active_group} ) command...\n" );
    my $NNTP	= $self->get_or_create_active_server;
    my $group	= $NNTP->group( $self->{active_group} );
    if( $group ) {
      $self->msg( "Group returned: '$group'\n" );
      return 1;
    }
    $self->msg( "group( $self->{active_group} ) command failed... sleeping...\n" );
    sleep $SLEEP_TIME;
  }
}

sub cache_article {
  my $self	= shift;
  my $id	= shift;

  my $article_filename	= $id . FILENAME_FIELD_SEP . $self->{active_group};

  # If article already cached, don't download again...
  if( -f $article_filename and -s $article_filename ) {
    return -s $article_filename;
  }

  my $try;
  for ( 1 .. 3 ) {
    $try	= $_;
    if( -f $article_filename.".try".$try ) {
      if( $try == 3 ) {
	# Tried 3 times already to cache this article...
	overwrite_file( "download error", $article_filename );
	unlink $article_filename.".try".$try;
	return -666;
      }
      else {
	my $new_try	= $try+1;
	overwrite_file( "try $try...", $article_filename.".try".$new_try );
	unlink $article_filename.".try".$try;
	last;
      }
    }
  }
  if( $try != 3 ) {
    $self->msg( "TRY: $try\n" );
  }
  if( $try == 3 ) {
    # Did not find any previous attempts at download...
    $try	= 1;	# First try
    overwrite_file( "try $try...", $article_filename.".try".$try );
  }

  # Article is not cached, cache it!
  my $NNTP	= $self->{servers}{$self->{active_server}} || die "No NNTP object!";
#  $self->safe_group( $self->{current
#  if( ! $NNTP->group( $self->{active_group} ) ) {
#    $NNTP->
#  }
  my $adata	= undef;
  for( 1 .. $MAX_RETRIES ) {
#     eval {
#       local $SIG{ALRM} = sub { die "alarm" };
#       alarm $ARTICLE_TIMEOUT;
    $adata	= $NNTP->article( $id );
    if( ! $adata ) {
      $self->wait_for_connection;
    }
    else {
      last;
    }
  }
#       alarm 0;
#     };
#     if( ! $@ ) {
#       last;
#     }
#   }
  if( defined $adata ) {
    overwrite_file( join("", @$adata), $article_filename );
    # Remove try file...
    unlink $article_filename.".try".$try;
    return 1;
  }
  else {
    return undef;
  }
}

sub decode_cached_articles {
  my $self	= shift;
  my $articles	= shift;
  my $arg	= shift;

  # Create the filenames and decode the file...
  my $ng	= $self->{active_group};
  my @files	= map { $_ . FILENAME_FIELD_SEP . $ng } @$articles;
  my $result	= system( "uudeview", "-i", "-a", "-d", @files );

  my $decoded_filename	= $self->get_decoded_filename( $files[0] );
  if( ! $decoded_filename ) {
    $decoded_filename	= $self->get_decoded_filename( $files[1] );	# Hack - second arg could be the first one...
  }
  print ">>>>$decoded_filename<<<<\n";
  # Fix for uudeview's problem with certain characters (&)
  if( $decoded_filename ) {
    if( $decoded_filename =~ /[\&\}\{]/ ) {
      # Need to fix:
      my $on_disk_filename	= $decoded_filename;
      $on_disk_filename		=~ s/[\&\}\{]/_/g;
      if( -f $on_disk_filename ) {
	portable_mv( $on_disk_filename, $decoded_filename );
      }
    }
  }
  ##################################################################
  {
    # If we are saving to a directory, make sure it exists:
    if ( $arg ) {
      if ( -f $arg ) {
	# Can't decode to this directory!
	warn "Cannot decode to directory '$arg' - file called '$arg' already exists";
	$arg	= "";
      }
      if ( ! -d $arg ) {
	ensure_dir_exists( $arg );
	if ( ! -d $arg ) {
	  warn "Could not create directory '$arg'!";
	  $arg	= "";
	}
      }
    }
    # Then
    if( $arg ) {
      if( $decoded_filename ) {
	# Attempt to move...
	portable_mv( $decoded_filename, $arg );
      }
    }
  }
  ##################################################################

  # Now it's safe to delete the files... we don't need them anymore...
  if( ! $result ) {
    # Everything went ok, delete files...
    $self->delete_cached_files( @files );
  }
  return 1;	#!!!
}

sub get_decoded_filename {
  my $self	= shift;
  my $enc_file	= shift;

  my $IF	= IO::File->new( $enc_file );
  if( ! $IF ) {
    warn "Could not open file: '$enc_file'!";
    return undef;
  }
  while( <$IF> ) {
    if( /begin \d\d\d (.*)/ ) {
      return $1;
    }
    if( /name=\"?(.*?)\"?$/ ) {
      return $1;
    }
  }
}


sub delete_cached_files {
  my $self	= shift;

  unlink @_;
}


1;
