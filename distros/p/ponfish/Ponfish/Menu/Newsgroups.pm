#!perl

package Ponfish::Menu::Newsgroups;

use strict;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Ponfish::Menu::Main;
use Ponfish::Menu::Articles;
use Ponfish::Menu::MultiGroup;
use Ponfish::Utilities;
use Ponfish::Config;
use Ponfish::ANSIColor;
use Ponfish::TermSize;
use Data::Dumper;

@ISA = qw(Exporter Ponfish::Menu::Main);
@EXPORT = qw(
);
$VERSION = '0.01';
##################################################################

my %command_abbrevs	=
  (
   sy			=> "sync_articles",
   sync			=> "sync_articles",
   sub			=> "subscribed",
   all			=> "all_newsgroups",
   pu			=> "purge_unavailable",
   remove		=> "remove",
   sort			=> "sort_newsgroups",
   so			=> "sort_newsgroups",
   "*"			=> "multi_read",
   read			=> "articles",
   read			=> "read_newsgroup",
   mr			=> "multi_read",
  );
map { $command_abbrevs{$_} = $_ } values %command_abbrevs;

sub command_abbrevs {
  return %command_abbrevs;
}

my %command_info	=
  (
   all_newsgroups	=> { summary	=> "Displays all newsgroups.",
			     full	=> <<"EOT"
Shows a list of ALL the newsgroups downloaded for the server.  Use this
to search for new newsgroups you might want to read.
EOT
			   },
   articles		=> { index	=> 1,
			     summary	=> "Read news for a newsgroup.",
			     full	=> <<"EOT"
This is the default function.  Just type the index of the newsgroup you
want to read at the prompt and hit enter.

Remember, article data must exist for this newsgroup to be able to read
the group.  When in doubt, use the "sub" command to see which newsgroups
have data.
EOT
			   },
   multigroup		=> { default	=> 1,
			     summary	=> "Read multiple newsgroups at once.",
			     full	=> <<"EOT"
Similar to the articles command, the differences are:

  * You can read multiple newsgroups at the same time.
  * Optimized for memory (consumes around 40% less memory than 'articles'.
  * Sorting by date is slower.
  * Sorting by poster is slower and only groups them together.

If you find that sorting by poster or date takes longer than you care for,
use the 'articles' command instead.
EOT
			   },
   sort_newsgroups	=> { summary	=> "Sorts list of newsgroups.",
			     full	=> <<"EOT"
By default, sorts the newsgroup list alphabetically.

- Use "sort art" to sort by number of articles.
- Use "sort date" to sort by date (last update time).*  Note that this will
  only work on "subscribed" newsgroups.
EOT
			   },
   subscribed		=> { summary	=> "Show only subscribed newsgroups.",
			     full	=> <<"EOT"
Displays newsgroups you are 'subscribed' to.  Being subscribed to a newsgroup
means you have header data for this newsgroup.

The program checks the disk for article data files and will show a list of
the newsgroups the data files are for, plus number of available article
headers for each newsgroup.

To 'unsubscribe' to a newsgroup you need to use the "remove" command, which
will remove the article data from the disk.
EOT
			   },
   remove		=> { range	=> 1,
			     summary	=> "Remove header information for one or more newsgroups.",
			     full	=> <<"EOT"
This removes all saved header data for a newsgroup.  Use with caution!
Once removed, the data can only be brought back by downloading it again.

This command effectively unsubscribes you from a newsgroup.
EOT
			   },

   sync_articles	=> { range	=> 1,
			     summary	=> "Update header list for newsgroups",
			     full	=> <<EOT
This command downloads all new headers for the specified newsgroups.
All "sync" commands are scheduled as high priority, and
may take precedence to any queued downloads.  Currently it is
somewhat important to not interrupt the download daemon while these
commands are executing or you may experience some (slight) data
loss.

!!! Currently it is important that you do not purge and sync the same
    newsgroup at the same time.  There is a chance (though slim) that you
    will lose some data.

Examples:

  > sync 1-12

EOT
			   },
    purge_unavailable	=> { range	=> 1,
			     summary	=> "Remove expired articles from header files",
			     full	=> <<EOT
Checks a newsgroup or newsgroups for any articles no longer on the server
and removes them from the stored headers files.

Currently the implementation works by simply removing any articles older
than the oldest available on the news server.  Some articles might not be
removed from the header files that no longer exist on the server.

Also, this operation is quite fast and very I/O intensive, as it will
read and re-write files quickly.

!!! Currently it is important that you do not purge and sync the same
    newsgroup at the same time.  There is a chance (though slim) that you
    will lose some data.

Examples:

  > pu 1-12

EOT
			   },
   read_newsgroup	=> { summary	=> "Read a newsgroup by regexp",
			     arg_list	=> [ "REGEXP" ],
			     full	=> <<EOT
Search for and read the first newsgroup matching PATTERN
EOT
			   },
  );
sub command_info {
  my $self	= shift;
  return %command_info;
}

##################################################################

sub new {
  my $type		= shift;
  my $parent		= shift;
  my $server		= shift || die "No server data!";
  my $filter		= shift || "";

  my $TS		= Ponfish::TermSize->new;

  my $self		= bless { server	=> $server,
				  server_name	=> $server->{server_name},
				  filter	=> $filter,
				  sequence	=> 10000,
				  settings	=> CONFIG->get_settings,
				  TermSize	=> $TS,
				}, $type;
  $self->register_with_TermSize_object;
  return $self;
}

sub get_latest_group_data_file {
  my $self	= shift;
  my $server_name	= $self->{server}{server_name};

  get_filenames( NEWSGROUPS_DIR, qr/./ );
  print NEWSGROUPS_DIR, "\n\n";
  my @files		= get_filenames( NEWSGROUPS_DIR, qr/$server_name/ );
  @files		= reverse sort @files;
  if( ! scalar @files ) {
    return "";
  }
  else {
    return $files[0];
  }
}


=item exists_newsgroup_data

Returns true of the newsgroup file for the active server is present.

=cut

sub exists_newsgroup_data {
  my $self	= shift;
  return $self->get_latest_group_data_file;
}

=item load_main_list -> load_newsgroup_data

Loads newsgroup data.  Assumes the newsgroups data file exists.

If there are subscribed groups, then only display those (defer loading
of the possibly HUGE newsgroups list for when the user really wants it)

=cut

sub load_main_list {
  my $self = shift;
  $self->load_newsgroup_data( @_ );
}

sub load_newsgroup_data {
  my $self		= shift;
  my $what		= shift || "sub";

  if( ! $self->exists_newsgroup_data ) {
    $self->set_errmsg( "No newsgroups data found for server '".$self->{server}{name}."'\n" );
    return undef;
  }
  if( $what eq "sub" ) {
    if( $self->subscribed ) {	# Attempt to load subscribed groups... if we cannot, fall through to load 'all'
      return 1;
    }
  }
  # Here load the groups from the newsgroups data file.

  my $IF		= create_read_fh( group_data_file( $self->{server}{server_name} ) );
  $self->{groups_list}	= "";
  my @glist		= ();
  my($g,$l,$f,$yn);
  my $columns		= int($self->COLUMNS / 8) * 8;
  while( <$IF> ) {
    ($g,$l,$f,$yn)	= split /\s+/, $_;
    push @glist, [$g, $l - $f];
  }
  @glist		= sort { $a->[0] cmp $b->[0] } @glist;
  $self->{groups_list}	= \@glist;
  $self->{filtered}	= \@glist;
  $self->menu_msg( "Loaded " . scalar( @glist ) . " newsgroups.\n" );
}


=item remove IDX <IDX>

Removes article data for a newsgroup.  This article data is fully
removed - no trace will exist afterwards.

=cut

sub remove {
  my $self	= shift;
  my @idxs	= expand_range_args( @_ );

  my @ngs	= map { $self->item_with_local_index( $_ )->[0] } @idxs;

  print "PERMANENTLY remove article data for the following newsgroups?:\n\n";
  print Dumper( \@ngs );
  print join("\n", @ngs), "\n\n";
  print "Please type YES to remove data: > ";
  my $response	= trim scalar <STDIN>;
  if( $response =~ /^yes$/i ) {
    my $articles_dir	= create_valid_filepath( ARTICLES_DIR, $self->{server}{server_name} );
###    print "AD: $articles_dir\n";
    foreach my $ng (@ngs) {
      my @ng_files	= get_filenames( $articles_dir, qr/^$ng/ );	#####my_glob "$articles_dir/$ng.*";
###      print join(",", @ng_files ),"\n";
      foreach my $ng_file (@ng_files) {
	if( $ng_file =~ /.*[\/\\]$ng\.(\d+|inc)$/i ) {
###	  print "unlink $ng_file\n";
	  unlink $ng_file;
	}
      }
      $self->remove_from_menu_lists( $ng );
    }
  }
  return $const::cmd_success;
}

=item remove_from_menu_lists NEWGROUP_NAME

Removes a newsgroup from the groups_list and filtered lists.

=cut

sub remove_from_menu_lists {
  my $self	= shift;
  my $ng	= shift;
  # Remove from main list:
  $self->{groups_list}	= [ grep { $_->[0] ne $ng } @{$self->{groups_list}} ];
  # Remove from filter list:
  print "NG: $ng\n";
  print "LIST: ", Dumper( $self->{filtered} );
  $self->{filtered}	= [ grep { $_->[0] ne $ng } @{$self->{filtered}} ];
}



sub sync_articles {
  my $self	= shift;
  my @ng_idxs	= expand_range_args( @_ );

  foreach my $ng_idx (@ng_idxs) {
    next	if( ! $self->item_with_local_index( $ng_idx ) );
    my $ng	= $self->item_with_local_index( $ng_idx )->[0];
#    my $cmd_filename	= join( ":", "00".$self->{sequence}++, "0000", $ng, $self->{server_name} );
    my $cmd_filename	= join( FILENAME_FIELD_SEP, "00000000", "0030", $ng, $self->{server_name} );
    my $data		= join( "\t", "sync_articles", $ng, "NONE", "NONE" );
    overwrite_file $data, DECODE_DIR, $cmd_filename;
  }
}

=item menu_display_list -> menu_display_newsgroups

=cut

sub menu_display_list {
  my $self	= shift;
  return $self->menu_display_newsgroups( @_ );
}

sub menu_display_newsgroups {
  my $self	= shift;

  my $vtype	= $self->get_setting("vtype") || "";	# For highlighting
  $vtype	= "" if( $vtype eq "none" );
  my $highlight_line	= $self->get_setting( "highlight_line" );

  my $currline	= $self->{pageinfo}{currline};
  for( 1 .. $self->LINES ) {
    last	if( ! defined $self->{filtered}[$currline + $_ - 1] );
    my $line	= sprintf("%02d", $_) . ". "
      . $self->format_ginfo_for_display( $currline + $_ - 1 ) . "\n";

    # Highlight every Xth line:
    if( $vtype ) {
      if( ! ($_ % $highlight_line) ) {
	$line	= colored [$vtype], $line;
      }
    }

    print $line;#sprintf("%02d", $_), ". ", $self->format_ginfo_for_display( $currline + $_ - 1 ), "\n";
  }
  return $const::cmd_success;
}

sub format_ginfo_for_display {
  my $self	= shift;
  my $i		= shift;

  my($group,$avail)	= @{$self->{filtered}[$i]};

  my $retval	= "";
#  if( $self->COLUMNS < 78 ) {
  if( scalar( @{$self->{filtered}[$i]} ) == 3 ) {
    my $mtime		= localtime $self->{filtered}[$i][2];
    $mtime		=~ s/^....(......).+/$1/;
    $retval	= sprintf( "%8d", $avail ) . " - " . "($mtime) " . $group; #. "\t($mtime)"; #"\t"x int( ($self->COLUMNS - int((length( $group )+8)/8)*8) /  8 - 1);
  }
  else {
    $retval	= sprintf( "%8d", $avail ) . " - " . $group . "\t"x int( ($self->COLUMNS - int((length( $group )+8)/8)*8) /  8 - 1);
  }
#  $retval	.= sprintf( "%8d", $avail );
#  }
#   else {
#     $retval	= $group . (" "x100);
#     $retval	= substr $retval, 0, 70;
#     $retval	.= sprintf( "%8d", $avail );
#   }
  return $retval;
}

sub default {
  my $self	= shift;
  return $self->multi_read( @_ );
#   my $num	= shift;

#   my $pinfo	= $self->{pageinfo};
#   my $index	= $pinfo->{currline} + $num - 1;
#   if( ! defined $self->{filtered}[$index] ) {
#     return $const::cmd_error;
#   }
#   else {
#     my $ng	= $self->{filtered}[$index][0];
#     $ng		=~ s/\s+.*//;	# Strip off junk from end...
#     return $self->articles( $ng );
#   }
}

sub articles {
  my $self	= shift;
  my $ng	= shift;

  my $ART	= Ponfish::Menu::Articles->new( $self, $self->{server}, $ng );
  my $status	= $ART->take_control;
  $self->register_with_TermSize_object;		# Sets the TermSize callback...
  return $status;
}


sub multi_read {
  my $self	= shift;

  my @ng_idxs	= expand_range_args( @_ );

  my @ngs	= ();
  foreach my $ng_idx (@ng_idxs) {
    next	if( ! $self->item_with_local_index( $ng_idx ) );
    push @ngs, $self->item_with_local_index( $ng_idx )->[0];
  }

  my $MG	= Ponfish::Menu::MultiGroup->new( $self, $self->{server}, \@ngs );
  my $status	= $MG->take_control;
  $self->register_with_TermSize_object;
  return $status;
}

=item all_newsgroups

Display the entire list of newsgroups.

=cut

sub all_newsgroups {
  my $self	= shift;

  return( [$self->load_newsgroup_data( "all" ), $self->reset_pageinfo]->[0] );
}


sub sort_newsgroups {
  my $self	= shift;
  my $arg	= shift || "";

  # Note: probably will never happen, but if you somehow have an empty list (ie:
  # by removing newsgroups) sort might crash the program.  Not something to worry
  # about though.

  if( $arg =~ /^art/i ) {
    $self->{filtered}	= [ sort { $a->[1] <=> $b->[1] } @{$self->{filtered}} ];
  }
  elsif( $arg =~ /^date/i ) {
    if( scalar @{$self->{filtered}[0]} < 3 ) {
      $self->menu_errmsg( "Cannot sort this list by date - only groups with article data can be\n"
		     . "sorted by date!\n" );
      return;
    }
    $self->{filtered}	= [ sort { $a->[2] <=> $b->[2] } @{$self->{filtered}} ];
  }
  else {
    $self->{filtered}	= [ sort { $a->[0] cmp $b->[0] } @{$self->{filtered}} ];
  }

}



=item purge_unavailable IDX

Cleaning a group clears out any articles that have been purged from the
news server.

!!! Do not purge and sync a newsgroup at the same time, you'll probably lose
some information !!!

=cut

sub purge_unavailable {
  my $self	= shift;

  my @ng_idxs	= expand_range_args( @_ );

  foreach my $ng_idx (@ng_idxs) {
    if( ! $self->item_with_local_index( $ng_idx ) ) {
      $self->menu_errmsg( "Error: Local index '$ng_idx' out of range!" );
      next;
    }
    my $ng	= $self->item_with_local_index( $ng_idx )->[0];
#    my $cmd_filename	= join( ":", "00".$self->{sequence}++, "0000", $ng, $self->{server_name} );
    my $cmd_filename	= join( FILENAME_FIELD_SEP, "00000000", "0010", $ng, $self->{server_name} );
    my $data		= join( "\t", "purge_unavailable", $ng, "NONE", "NONE" );
    overwrite_file $data, DECODE_DIR, $cmd_filename;
  }
  return $const::cmd_success;
}


=item subscribed

Shows all subscribed newsgroups.

=cut

sub subscribed {
  my $self	= shift;
  my %newsgroup_map	= map { $_ => 1 } $self->get_newsgroups_with_article_data;
###!!! This taken out because we don't want a complete list of newsgroups every
###!!! we run the program...
###  my $subscribed	= [ grep { $newsgroup_map{$_->[0]} } @{$self->{groups_list}} ];

  # Subscribed newsgroups... must calculate the number of articles available...
  my $subscribed	= [ sort { $a->[0] cmp $b->[0] } 
			    map { [ $_, $self->articles_available( $_ ), $self->last_update_date( $_ ) ]  }
			    grep { /[\w\d]+\.[\w\d]+/ } keys %newsgroup_map
			  ];
  if( ! scalar @$subscribed ) {
    $self->menu_errmsg( "No groups 'subscribed'\n" );
    return $self->all_newsgroups;
#    return $const::cmd_error;
  }
  else {
    print "Filtered: ", scalar(@$subscribed), " groups subscribed!\n";
    $self->{groups_list}	= $subscribed;
    $self->{filtered}	= $subscribed;
    $self->reset_pageinfo;
    return $const::cmd_success;
  }
}

=item last_update_date NEWSGROUP

Returns the date of last update for NEWSGROUP:

=cut

sub last_update_date {
  my $self	= shift;
  my $ng	= shift;
  my $articles_dir	= create_valid_filepath( ARTICLES_DIR, $self->{server}{server_name} );
  my $retrieved_file	= create_valid_filepath( $articles_dir, $ng . ".retrieved" );
  if( ! -f $retrieved_file ) {
    return 0;
  }
  else {
    return (stat $retrieved_file)[9];
  }
}



=item articles_available NEWSGROUP

Returns the approximate articles available for NEWSGROUP.

This subroutine is pretty ugly - it takes a lot of steps
to determine this number.

=cut

sub articles_available {
  my $self	= shift;
  my $ng	= shift;
  my $articles_dir	= create_valid_filepath( ARTICLES_DIR, $self->{server}{server_name} );
  my $retrieved_file	= create_valid_filepath( $articles_dir, $ng . ".retrieved" );
  my $retrieved		= read_file( $retrieved_file );
  if( ! $retrieved ) {
    warn "Error getting retrieved number for newsgroup '$ng'!";
    return 0;
  }
  my $IGNORE_FILESIZE	= 2048;
  ensure_dir_exists $articles_dir;
  my @ng_files		= grep { -s $_ > $IGNORE_FILESIZE } get_filenames( $articles_dir, qr/^$ng\.\d+$/ );
    #####grep { /\/$ng\.\d+$/ && -f $_ && -s $_ } my_glob("$articles_dir/$ng.*");
  if( ! scalar @ng_files ) {
    warn "Error getting file list for newsgroup '$ng'!";
    return 0;
  }
  my @temp_fmap		= ();
  for( @ng_files ) {
    /$ng\.(\d+)$/;
    push @temp_fmap, [ $_, $1 ];
  }
  my $first_file	= [ sort { $a->[1] <=> $a->[1] } @temp_fmap ]->[0][0];
  if( ! -f $first_file or ! -s $first_file ) {
    warn "File does not exist or is zero length: '$first_file'!";
    return 0;
  }
  my $FH		= create_read_fh( $first_file )
    || warn "Error creating read FH for file: '$first_file'";
  my $first_line	= <$FH>;
#  my $ffs		= FILENAME_FIELD_SEP;
  my @first_line	= split /\t/, $first_line;
#  use Data::Dumper;
#  print Dumper( \@first_line );
  my @articles		= split /,/, $first_line[4];
  my $article		= 0;
  for( @articles ) {
#   print "'$_'\n";
    if( $_ ) {
      $article		= $_;
      if( $article !~ /^\d+$/ ) {
	warn "Reading file: '$first_file'\n";
      }

      return $retrieved - $article;
    }
  }

  warn "Error retrieving first article number stored for ng '$ng' (file: '$first_file')";
  return 0;
}


=item get_newsgroups_with_article_data

Returns a list of newsgroups that have header/article information.
Basically looks in the right directory and returns a list of the
files there... basically.

=cut

sub get_newsgroups_with_article_data {
  my $self	= shift;
  my $articles_dir	= create_valid_filepath( ARTICLES_DIR, $self->{server}{server_name} );

  print "AD: '$articles_dir'\n";
  ensure_dir_exists $articles_dir;
  my @retrieved_files	= get_filenames( $articles_dir );	#####my_glob("$articles_dir/*.*");
  print Dumper( \@retrieved_files );
  my @newsgroups	= map { s/.*\///; $_ } map { s/\.retrieved//; $_ } @retrieved_files;
  my %newsgroups	= ();
  for( @newsgroups ) {
    if( /^(.*)\.\d+$/ ) {
      $newsgroups{$1}	= 1;
    }
  }

  return sort keys %newsgroups;
}

=item read_newsgroup

=cut

sub read_newsgroup {
  my $self	= shift;
  my $regexp	= shift || $self->menu_errmsg( "Error: REGEXP required" );

  eval { /$regexp/i };	if( $@ ) {
    $self->menu_errmsg( "Error: regexp '$regexp' would not compile.  ($@).  Try again.\n" );
  }
  else {
    my $RE	= qr/$regexp/i;
    for( @{$self->{filtered}} ) {
      if( $_->[0] =~ /$RE/ ) {
	return $self->articles( $_->[0] );
      }
    }
    # Could find no match...
    $self->menu_errmsg( "Error: regexp '$regexp' did not match any newsgroups in the filtered list.\n" );
  }
}


=item filter

Filter all newsgroups using a regular expression.

=cut

sub filter {
  my $self	= shift;
  my $filter	= shift;
  print "FILTER: '$filter'\n";
  eval {
    /$filter/i
  };
  if( $@ ) {
    $self->menu_errmsg( "Error: filter '$filter' would not compile.  Try again.\n" );
  }
  else {
    # Perform the filtering here:
    my $RE	= qr/$filter/i;

    # plus/minus filtering - works on what's already filtered:
    my $plus_minus		= $self->{cmd_info}{plus_minus};
    my $target_list		= "filtered";
    my $filtered;
    if( $plus_minus eq "+" ) {
      # Positive filter
      $filtered	= [ grep { $_->[0] =~ /$RE/ } @{$self->{filtered}} ];
    }
    elsif( $plus_minus eq "++" ) {
      # Positive filter plus replace main list:
      $filtered	= [ grep { $_->[0] =~ /$RE/ } @{$self->{groups_list}} ];
      $target_list		= "groups_list";
    }
    elsif( $plus_minus eq "-" ) {
      # Negative (subtractive) filter
      $filtered	= [ grep { $_->[0] !~ /$RE/ } @{$self->{filtered}} ];
    }
    elsif( $plus_minus eq "--" ) {
      # Negative filter plus replace main list:
      $filtered	= [ grep { $_->[0] !~ /$RE/ } @{$self->{groups_list}} ];
      $target_list		= "groups_list";
    }
    else {
      # Regular filtering...
      $filtered	= [ grep { $_->[0] =~ /$RE/ } @{$self->{groups_list}} ];
    }

    if( ! scalar @$filtered ) {
      $self->menu_errmsg( "No groups matched filter: '$filter'" );
      return $const::cmd_error;
    }
    else {
      print "Filtered: ",scalar(@$filtered), " groups!\n";
      $self->{filtered}		= $filtered;
      $self->{$target_list}	= $filtered;	# $target_list will be either "filtered" or "groups_list"
      $self->reset_pageinfo;
#      $self->show;
    }

  }
}

1;
