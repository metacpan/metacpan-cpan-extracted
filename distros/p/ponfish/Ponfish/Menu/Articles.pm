#!perl

package Ponfish::Menu::Articles;

use strict;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Ponfish::Menu::Main;
use Ponfish::Utilities;
use Ponfish::Config;
use IO::File;
use Ponfish::ANSIColor;
use Ponfish::TermSize;
use Time::Local;


@ISA = qw(Exporter Ponfish::Menu::Main);
@EXPORT = qw(
);
$VERSION = '0.01';
##################################################################
my %command_abbrevs	= ( sa		=> "save",
			    de		=> "decode",
			    pr		=> "preview",
			    "*"		=> "decode",
			    ca	     	=> "cancel",
			    vi		=> "view",
			    sort	=> "sort_by",
			    so		=> "sort_by",
			    dump_list	=> "dump_list",
			    scan	=> "scan",
			    date	=> "scan_date",
			    fresher	=> "fresher",
			    older	=> "older",
			    uni		=> "unique_re",
			    poster	=> "filter_poster",
			    reload	=> "reload",
			  );
map { $command_abbrevs{$_} = $_ } values %command_abbrevs;
sub command_abbrevs {
  return %command_abbrevs;
}
# %command_info contains help and some meta-information on each command.
my %command_info	=
  (
   save		=> { summary	=> "Save articles.",
		     redirect	=> 1,
		     range	=> 1,
		     full	=> <<"EOT"
This will save the requested headers.  Currently it saves each article
in it's own file named ARTICLE_NUM.NEWSGROUP.
EOT
		   },
   decode	=> { summary	=> "Decode binaries.",
		     default	=> 1,
		     redirect	=> 1,
		     range	=> 1,
		     full	=> <<"EOT"
Decode binaries.  You can redirect to a directory by using the redirect
operator (>):

  > decode 1-25 > save_binaries_here

The decode process works by saving each article, like in the "save"
command, then processes these files using a third party decode tool,
namely uudeview.

You must have uudeview installed somewhere in your path before you can
decode.
EOT
		   },
   preview	=> { summary	=> "Preview binaries - high priority decode.",
		     redirect	=> 1,
		     range	=> 1,
		     full	=> <<"EOT"
Preview is exactly the same as "decode", but with highest priority.
Anything previewed will jump to the front of the decode queue and
be serviced first by the decoder.

There may still be some delay before the previewed files are decoded,
however.

The files are downloaded to $Global::DECODE_DIR.
EOT
		   },
   dump_list	=> { summary	=> "Dump the list of article subjects to a file.",
		     redirect	=> 1,
		     full	=> <<"EOT"
Simply dumps a list of the article subjects to the file "subject_dump.txt",
or to a file of your own choosing if you use a redirection.

Example:

  > dump_list > july25.txt

This will dump the list of subjects to the file "july25.txt".

The directory used is the directory in which the reader was invoked.
EOT
		   },
   sort_by	=> { summary	=> "Sort the list.",
		     arg_list	=> [ "sub | date | poster" ],
		     full	=> <<"EOT"
Sorts the list by either Subject, Date, or Poster name.
EOT
		   },
   scan		=> { summary	=> "Scan forward into the list...",
		     arg_list	=> [ "[ REGEXP ] | [ date MMM [DD] ] | [ poster REGEXP ]" ],
		     full	=> <<"EOT"
Scans from the current point in the list until the condition
is satisified, repositioning the first matching line at the top
of the screen.

For example, you can sort the list by Subject, then scan forward
for the first subject containing the string "cigar" using the following
commands:

  > sort sub
  > scan cigar

Or you may want to sort the list by date (the default), then scan forward
to the first day of August:

  > sort date
  > scan date aug 01

This does not affect the list like the "filter" command would.
EOT
		   },
   scan_date	=> { summary	=> "Scans forward through the list to a particular date.",
		     arg_list	=> [ "MMM [DD]" ],
		     full	=> <<"EOT"
Exactly the same as "scan date", but slightly more convenient to use.
To scan forward to September 3rd, use the following command:

  > scan_date sep 03

You MUST use the three-character month, and the day is optional.

Valid months are: jan feb mar apr mar jun jul aug sep oct nov dec.
EOT
		   },
   fresher	=> { summary	=> "Show only articles posted after a certain date.",
		     arg_list	=> [ "MMM [DD]" ],
		     modifier	=> 1,
		     full	=> <<"EOT"
Fresher allows you to keep (or remove) articles posted AFTER a
certain date.

To keep only articles posted after July:

  > fresher jul

To remove articles posted after July:

  > -fresher jul

Note: "fresher" is the opposite of "older".
EOT
		   },
   older	=> { summary	=> "Show only articles posted before a certain date.",
		     arg_list	=> [ "MMM [DD]" ],
		     full	=> <<"EOT"
Older allows you to keep (or remove) articles posted BEFORE a
certain date.

To keep only articles posted before April 2nd:

  > older apr 2

To remove articles posted before May:

  > -older may

Note: "older" is the opposite of "fresher".
EOT
		   },
   unique_re	=> { summary	=> "Filter unique matches out of a regular expression.",
		     arg_list	=> [ "REGEXP" ],
		     full	=> <<"EOT"
The "unique_re" (or "uni") command helps to remove duplicate posts
from a list.  REGEXP must contain a grouping, and it is the data
captured in this grouping that is used to filter out any
duplicate matches.

To illustrate, to filter only unique files that follow the format:

  illust001.jpg
  illust002.jpg
  ...

Use the following:

  > uni /(illust\\d{3}\\.jpg)/

EOT
		   },
   filter_poster=> { summary	=> "Filter on the POSTER field.",
		     arg_list	=> [ "REGEXP" ],
		     modifier	=> 1,
		     full	=> <<"EOT"
Same as the "filter" command, but acting on the poster field.
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
  my $ng		= shift || die "No newsgroup!";
  my $filter		= shift || "";

  my $TS		= Ponfish::TermSize->new;
  my $self		= bless { server	=> $server,
				  ng		=> $ng,
				  filter	=> $filter,
				  settings	=> CONFIG->get_settings,
				  TermSize	=> $TS,
				}, $type;
  $self->register_with_TermSize_object;
  return $self;
}

# The array that each article consists of:
my($DATE_COL,$AVAIL_COL,$TOTAL_COL,$POSTER_COL,$IDS_COL,$SUBJ_COL) = (0, 1, 2, 3, 4, 5);


=item menu_display_list -> menu_display_articles

=item menu_display_articles

Displays the current page of articles.

If the setting "pagesort" is "on", each page will be sorted before
display.

=cut

sub menu_display_list {
  my $self	= shift;
  return $self->menu_display_articles( @_ );
}

=item reload

Reload articles from disk.

=cut

sub reload {
  my $self	= shift;
  delete $self->{filtered};
  delete $self->{main_list};
}

sub menu_display_articles {
  my $self	= shift;

  my $pinfo	= $self->{pageinfo};
  my $currline	= $pinfo->{currline};
  # Need to fix array limits here:::
  my $num_filtered	= scalar @{$self->{filtered}};
  print "PAGESORT: '$self->{settings}{pagesort} ($num_filtered articles)'\n";
#  print "CURRLINE: '$self->{pinfo}{currline}'\n";
  if( $self->{settings}{pagesort} eq "on" ) {
    my $absolute_last	= scalar $#{$self->{filtered}};
    my $pagesort_last	= min $absolute_last, $currline + $self->LINES - 1;
    @{$self->{filtered}}[$currline .. $pagesort_last]
      = sort { $a->[$SUBJ_COL] cmp $b->[$SUBJ_COL] } @{$self->{filtered}}[$currline .. $pagesort_last];
  }

  for( 1 .. $self->LINES ) {	###pinfo->{lpp} ) {
#    printf "%02d: ", $_;
    print $self->format_article_for_display( $self->{filtered}[$currline+$_-1], $_ ), "\n";
  }
}


=item format_article_for_display ARTICLE_DATA INDEX

Formats the article data in ARTICLE_DATA into a nice string and
returns it.

=cut

sub format_article_for_display {
  my $self	= shift;
  my $data	= shift || return;
  my $index	= shift;

  my $subj	= $data->[$SUBJ_COL];
  my $cut_subj	= $subj;

  # Highlight every Xth line:
  my $vtype	= $self->{settings}{vtype} || "";

  my $row_attrib	= "";
  if ( ! ($index % $self->{settings}{highlight_line}) ) {
    $row_attrib		= $vtype;
  }

  ##################################################################
  # Put each part of the line together separately, then put them all
  # together at the end:
  ##################################################################

  # Index: #######################################################
  my $s_index		= sprintf( "%02d> ", $index );
  my $index_len		= length $s_index;		# On longer pages, could be 3 digits...

  # Avail: #######################################################
  my $s_avail		= "";
  my $avail_len		= 0;
  {
    my($avail,$total)	= @{$data}[$AVAIL_COL,$TOTAL_COL];

    # Determine the formatting style...
    if( $self->{settings}{avail_format} == 1 ) {
      # This is the usual 70/70 format...
      $s_avail	= sprintf("%02d/%02d",$avail,$total);
    }
    elsif( $self->{settings}{avail_format} == 2 ) {
      # More radical format of only the available articles...
      $s_avail	= sprintf( "%d", $avail );
      $s_avail	= "    " . $s_avail;
      $s_avail	= substr $s_avail, -4;
    }
    $avail_len	= length $s_avail; # Need to do this before formatting with 'colored'
    if ( $avail != $total ) {
      # Missing parts colored red:
      $s_avail	=~ s/ /-/g;
      $s_avail	= colored ["bold yellow on_red"], $s_avail;
    }
    $s_avail	.= "|";
    $avail_len++;
  }

  # Date: #######################################################
  my $s_date	= "";
  if( $self->is_setting_on( "date" ) and $self->get_setting( "rhs" ) >= 7 ) {
    $s_date		= md_date $data->[$DATE_COL];
  }
  my $date_len	= length $s_date;

  # Poster: #######################################################
  my $s_poster	= "";
  my $lhs_len	= $self->{settings}{rhs};
  if( ! defined $lhs_len ) {
    $lhs_len	= 20;
  }
  if( $self->{settings}{poster} eq "on" ) {
    my $poster_len	= $lhs_len - $date_len - 1;		# LHS size minus date length!
    if( $poster_len > 0 ) {
      $s_poster	= "|" . $data->[$POSTER_COL];
      $s_poster	.= " " x $poster_len;		# Pad
      $s_poster	= substr $s_poster, 0, $poster_len;
    }
  }
  else {
    $lhs_len	= $date_len;
  }

  # Subject: #######################################################
  my $s_subj	= $cut_subj;
  my $subj_len	= $self->COLUMNS - $lhs_len - $avail_len - $index_len;
  if( $subj_len < 0 ) {
    $subj_len	= 10;	# Minimum - will screw up display, but at least will not crash program.
  }
  if( length( $s_subj ) < $subj_len ) {
    $s_subj	.= (" " x ($subj_len - length( $s_subj )));	# Pad subject
  }
  $s_subj	= substr( $s_subj, 0, $subj_len );		# Ensure a perfect fit

  #!!! Display PAR files in a different color:
  if( $cut_subj =~ /\.par2/i ) {
    $s_subj	= colored ["yellow"], $s_subj;
  }
  #!!! Display JPG files in a different color:
  if( $cut_subj =~ /\.jpe?g/i ) {
    $s_subj	= colored ["cyan"], $s_subj;
  }

  # Return the joined line: #######################################################
  if( $row_attrib ) {
    return
      colored( ["$row_attrib "], join( "", $s_index, $s_avail, $s_subj, $s_poster, $s_date ) );
  }
  else {
    return join("", $s_index, $s_avail, $s_subj, $s_poster, $s_date );
  }
}



=item decode ARGS

ARGS must follow the following rules:

  * You can specify a range using a dash: 5-12
  * You can specify multiple articles using a comma or space: 5,6,7,12,13,14
  * You can use any combination of the above: 5-12 20 21 22 (5-12,20,21,22)

=cut

sub save {
  my $self	= shift;
  return $self->decode_or_save( "save", @_ );
}
sub decode {
  my $self	= shift;
  return $self->decode_or_save( "decode", @_ );
}
sub preview {
  my $self	= shift;
  return $self->decode_or_save( "preview", @_ );
}

sub cancel {
  my $self	= shift;
  return $self->decode_or_save( "erase", @_ );
}

sub pagesearch {
  my $self	= shift;
  my $re	= shift;

  eval {
    /$re/i
  };
  if( $@ ) {
    $self->menu_errmsg( "Error: regexp '$re' would not compile!\n" );
    return ();
  }
  my $RE	= qr/$re/i;		# compile regexp

  # Now find the article numbers that match for the current visible page:
  my $currline	= $self->{pageinfo}{currline};
  # Need to fix array limits here:::
  my $absolute_last	= scalar $#{$self->{filtered}};
  my $pagesort_last	= min $absolute_last, $currline + $self->LINES - 1;

  my $i		= 1;
  my @article_map	= map { [$i++, $_->[$SUBJ_COL] ] } @{$self->{filtered}}[$currline .. $pagesort_last];
  return map { $_->[0] } grep { $_->[1] =~ /$RE/ } @article_map;
}

sub decode_or_save {
  my $self	= shift;
  my $cmd_type	= shift || "decode";

  my @articles	= ();

  # Handle a regexp here:
  if( $_[0] =~ /^\// ) {
    my $cmd	= $self->{cmd_info}{cmd_str};
    $cmd	=~ s/^\w+\s//;		# Remove command part
    $cmd	=~ s/\>.*$//;		# Remove possible redirect
    $cmd	=~ s/^\///;		# Remove start and end slashes:
    $cmd	=~ s/\/\s*//;		# ...
    my $re	= $cmd;
    @articles	= $self->pagesearch( $re );
    if( ! scalar @articles ) {
      $self->menu_errmsg( "Search regexp: '$re' did not match any articles or is incorrect.\n" );
      return $const::cmd_error;
    }
  }
  elsif( $_[0] =~ /^\s*all\s*$/i ) {
    # Everything on the page...
    @articles	= 1 .. $self->LINES;
  }
  else {
    @articles	= expand_range_args( @_ );
  }
  @articles	= sort { $a <=> $b } @articles;		# Sort in order - don't know why...

  my $arg	= serialize_for_command( $self->{cmd_info}{redirect}
					 || CONFIG->get_setting( $cmd_type . "_dir" )
					 || "" );
  print "saving articles: ", join(",", @articles),".  Arg: '$arg'\n";
  my $max_idx	= $self->LINES;
  my @OOR_indexes	= ();
  foreach my $idx ( @articles ) {
    if( $idx > $max_idx and $self->get_setting( "nolimit" ) eq "off" ) {
      $self->menu_errmsg( "You have tried to $cmd_type articles above line " . $self->LINES . ".\n"
			  . "Turn setting 'nolimit' to 'on' to allow decode/save/etc to work\n"
			  . "across unseen pages.\n" );
      return $const::cmd_error;
    }
    if( $self->item_with_local_index( $idx ) ) {
      $self->queue_article_command( $cmd_type, $self->item_with_local_index( $idx ), $arg );
    }
    else {
      push @OOR_indexes, $idx;
    }
  }
  if( scalar @OOR_indexes ) {
    $self->menu_errmsg( "Error: The following indexes are out of range: ".join(", ", @OOR_indexes ) );
  }

  return $const::cmd_success;
}

sub queue_article_command {
  my $self		= shift;
  my $cmd_type		= shift || die "No cmd_type!";
  my $article_info	= shift || die "No article_info!";
  my $arg		= shift || "";

  my @articles		= grep { /^\d+$/ } split( /,/, $article_info->[$IDS_COL] );
  my $cmd_filename	= join( FILENAME_FIELD_SEP, $article_info->[$DATE_COL], $articles[0],
				$self->{ng}, $self->{server}{server_name} );
  if( $cmd_type eq "preview" ) {
    # Make it one of the first files...
    $cmd_filename	= join( FILENAME_FIELD_SEP, "00000000", $articles[0],
				$self->{ng}, $self->{server}{server_name} );
  }

  my $data		= join( "\t", $cmd_type, $arg, join(",", @articles), $self->{ng}, $article_info->[$SUBJ_COL] );
  overwrite_file $data, DECODE_DIR, $cmd_filename;
}

##################################################################

sub sort_by {
  my $self	= shift;
  my $what	= shift || "sub";
  my %what_to_col	= ( sub		=> $SUBJ_COL,
			    date	=> $DATE_COL,
			    poster	=> $POSTER_COL,
			  );
  my $sort_col	= $what_to_col{$what};
  if( ! defined $sort_col ) {
    $sort_col	= $SUBJ_COL;
  }

  my @sorted;
  if( $what eq "sub" or $what eq "poster" ) {
    @sorted	= sort { $a->[$sort_col] cmp $b->[$sort_col] } @{$self->{filtered}};
  }
  else {
    @sorted	= sort { $a->[$sort_col] <=> $b->[$sort_col] } @{$self->{filtered}};
  }
  $self->{filtered}	= \@sorted;
}




=item unique_re REGEXP [WITH <FILE>]

Specify a regular expression that matches the filenames you are interested in.
Any duplicates are removed from the resultant list.  As well, any filenames
contained in the FILE that match the REGEXP will also be excluded from the list.
This is useful when you want to complete a picture set and don't want to download
a bunch of duplicates.

=cut

sub unique_re {
  my $self	= shift;
  my $re	= shift;
  if( $re =~ /^\// ) {
    $re		=~ s/^.//;
    if( $re =~ /\/$/ ) {
      $re	=~ s/.$//;
    }
  }

  eval {
    /$re/i
  };
  if( $@ ) {
    $self->menu_errmsg( "Error: regexp '$re' would not compile.  Try again.\n" );
  }
  my $RE;
  eval {
    $RE	= qr/($re)/i;
  };
  if( $@ ) {
    $self->menu_errmsg( "Invalid regular expression: /$re/: $@" );
  }

  my %viewed	= ();

  # Now see if there are files to look into that can contain the filenames
  # we do not wish to download
  my $with	= shift || "";
  if( $with ) {
    while( my $fn = shift ) {
      if( ! -f $fn ) {
	if( -f create_valid_filepath( DATA_DIR, $fn ) ) {
	  $fn	= create_valid_filepath( DATA_DIR, $fn );
	}
	else {
	  next;		  # Give up
	}
      }
      if( -f $fn ) {
	my $FH	= create_read_fh( $fn );
	if( ! $FH ) {
	  warn "Could not open file for read: '$fn'\n";
	  next;
	}
	while( <$FH> ) {
	  if( /($RE)/ ) {
	    $viewed{lc($1)}++;
	  }
	}
      }
    }
  }
  my @results	= ();
  for( @{$self->{filtered}} ) {
    if( $_->[$SUBJ_COL] =~ /$RE/ ) {
      my $match	= lc $1;
      if( ! $viewed{$match} ) {
	$viewed{$match}	= 1;
	push @results, $_;
      }
    }
  }
  $self->{filtered}	= \@results;
  return $const::cmd_success;
}






=item fresher DATE

Shows articles FRESHER than DATE, where DATE is in a MMM [DD] format...

=cut

sub fresher {
  my $self	= shift;

  my $min_time	= $self->calculate_time_mmm_dd( @_ );

  my($source,$dest,$polarity)	= $self->convert_plus_minus_to_source_dest_polarity;
  print join(",", $source, $dest, $polarity ),"\n";
  if( $polarity eq "+" ) {
    $self->{$dest}		= [ grep { $_->[$DATE_COL] >= $min_time } @{$self->{$source}} ];
  }
  elsif( $polarity eq "-" ) {
    $self->{$dest}		= [ grep { $_->[$DATE_COL] < $min_time } @{$self->{$source}} ];
  }
  # Need to copy over results in case $source == $dest
  if( $source eq $dest ) {
    $self->{filtered}	= $self->{$dest};
  }

  return $const::cmd_success;
}

=item older DATE

Same as fresher, but in reverse!

=cut

sub older {
  my $self	= shift;
  $self->{cmd_info}{plus_minus} =~ tr/\+\-/\-\+/;
  return $self->fresher( @_ );
}

=item convert_plus_minus_to_source_dest_polarity

Returns two hash keys (source and destination) and
a polarity (keep or remove (+ or -)).



=cut

sub convert_plus_minus_to_source_dest_polarity {
  my $self	= shift;

  my $source	= "main_list";
  my $dest	= "filtered";
  my $polarity	= "+";

  my $plus_minus	= $self->{cmd_info}{plus_minus} || "";
  if( $plus_minus eq "" ) {
    return( $source, $dest, $polarity );
  }
  elsif( $plus_minus eq "+" ) {
    $source	= "filtered";
  }
  elsif( $plus_minus eq "++" ) {
    $dest	= "main_list";
  }
  elsif( $plus_minus eq "-" ) {
    $source	= "filtered";
    $polarity	= "-";
  }
  elsif( $plus_minus eq "--" ) {
    $dest	= "main_list";
    $polarity	= "-";
  }
  else {
    warn "Invalid plus_minus: '$plus_minus'!\n";
    use Data::Dumper;
    print Dumper( $self->{cmd_info} );
    return( undef, undef, undef );
  }
  return( $source, $dest, $polarity );
}



=item scan

Scans through the articles and puts the current page at the specified point...

=cut

sub scan {
  my $self	= shift;
  my $arg1	= shift;

  if( ! defined $arg1 or $arg1 eq "" ) {
    $self->menu_errmsg( "No argument provided for scan function!" );
    return $const::cmd_error;
  }
  if( lc $arg1 eq "date" ) {
    return $self->scan_date( @_ );
  }
  else {
    my $regexp	= trim $arg1;
    $regexp	=~ s/^\///;
    $regexp	=~ s/\/$//;
    eval {
      /$regexp/i
    };
    if( $@ ) {
      $self->menu_errmsg( "Error: scan regexp '$regexp' would not compile.  Try again.\n" );
      return $const::cmd_error;
    }
    my $RE	= qr/$regexp/i;
    my $num_total	= $#{$self->{filtered}};
    for( my $i = $self->{pageinfo}{currline}; $i < $num_total; $i++ ) {
      if( $self->{filtered}[$i][$SUBJ_COL] =~ /$RE/ ) {
	# We have a match - reposition pointer:
	$i	= $num_total - $self->LINES	if( $i + $self->LINES > $num_total );
	$self->reset_pageinfo;
	$self->{pageinfo}{currline}	= $i;
	return $const::cmd_success;
      }
    }
    $self->menu_errmsg( "Could not find regexp /$regexp/ in any subjects.\n" );
    return $const::cmd_success;
  }
}


sub calculate_time_mmm_dd {
  my $self	= shift;

  my $mon_or_day	= lc trim shift;
  my $day		= trim shift || 1;

  my $curr_article	= $self->current_item;
  if( ! $curr_article ) {
    die "Could not get current article!";
  }
  my $curr_article_month_num	= [localtime( $self->current_item()->[$DATE_COL] )]->[4];
  my $month_num;
  if( $Global::date_hash{$mon_or_day} ) {
    # $mon_or_day is a MMM month - convert to number:
    $month_num		= $Global::date_hash{$mon_or_day} - 1;
  }
  else {
    # $mon_or_day is a DD day - use the current article's month
    $day		= $mon_or_day;
    $month_num		= $curr_article_month_num;
  }
  # Make sure the day value defaults to 1 if not properly set...
  if( $day !~ /^\d+$/ ) {
    $day		= 1;
  }
  # There is a case where we might be searching across a new year - December to
  # January, for example.  We'll try to detect this case and increment the year...
  my $year_num		= [localtime( $self->current_item()->[$DATE_COL] )]->[5] + 1900;
  if( $month_num < $curr_article_month_num ) {
    $year_num++;
  }

  # Calculate the time we're looking for:
  my $min_time		= timelocal( 0, 0, 0, $day, $month_num, $year_num );
  return $min_time;
}


sub scan_date {
  my $self		= shift;
#  my $mon_or_day	= shift;
#  my $day		= shift || "01";

  my $min_time		= $self->calculate_time_mmm_dd( @_ );	# Find the minimum time we're looking for...

  # Now, find it:
  my $num_total		= $#{$self->{filtered}};
  for( my $i = $self->{pageinfo}{currline}; $i < $num_total; $i++ ) {
    if( $self->{filtered}[$i][$DATE_COL] >= $min_time ) {
      $i		= $num_total - $self->LINES	if( $i + $self->LINES > $num_total );
      $self->{pageinfo}{currline}	= $i;
      return $const::cmd_success;
    }
  }
  $self->menu_errmsg( "Could not find articles for: " . localtime( $min_time ) . "\n" );#$mon_or_day-$day, $year_num.\n" );
}


=item dump_list

Dump the subjects into a file.

=cut

sub dump_list {
  my $self	= shift;
  my $fn	= $self->{cmd_info}{redirect} || "subject_dump.txt";

  my $OF	= IO::File->new( ">$fn" );
  for( @{$self->{filtered}} ) {
    print $OF $_->[$SUBJ_COL],"\n";
  }
}



=item load_main_list -> load_articles_data

=item load_articles_data

Load article data from files in the articles directory.

=cut

sub load_main_list {
  my $self	= shift;
  return $self->load_articles_data( @_ );
}

sub load_articles_data {
  my $self	= shift;

  if( ! $self->exists_articles_data ) {
    $self->set_errmsg( "No article data found for group '$self->{ng}' (".$self->{server}{name}.")" );
    return undef;
  }

  my @afiles	= $self->get_article_files;
  my @adata	= ();
  foreach my $afile ( @afiles ) {
    print "FILE: $afile\n";
    next	if( $afile =~ /\.retrieved$/ );	# Skip this one file
    my $IF	= IO::File->new( $afile ) || die "Can't open file: '$afile' for read!";
    while( <$IF> ) {
      chomp; chomp;
      next	if( ! $_ );		# Blank lines...
      my @fields	= split /\t/, $_;

      ### Find a bug
      if( ! defined $fields[$SUBJ_COL] ) {
	s/\t/\|/g;
	print "INVALID LINE: '$_'\n";
      }
      else {
	push @adata, \@fields;
      }
    }
  }
  $self->{main_list}	= \@adata;
  $self->{filtered}	= \@adata;
  return $self->{filtered};
}

=item exists_articles_data

Actually returns the number of article files found.  If none found, then
"0" is returned.

=cut

sub exists_articles_data {
  my $self	= shift;
  my @afiles	= $self->get_article_files;
  return scalar @afiles;
}

sub get_article_files {
  my $self		= shift;
  my $server_name	= $self->{server}{server_name};
  my $adir		= create_valid_filepath( ARTICLES_DIR, $server_name );
  my $ng		= $self->{ng};
  ensure_dir_exists $adir;
  my @files		= get_filenames( $adir, qr/^$ng\.(\d+|inc)$/ );
  return @files;
}


sub default {
  my $self	= shift;

  $self->decode( @_ );
}


=item filter_poster REGEXP

Filter the list of articles using REGEXP on the poster.

=cut

sub filter_poster {
  my $self	= shift;
  my $regexp	= shift;

  return $self->filter( $regexp, $POSTER_COL );
}


=item filter REGEXP

Filter the list of articles using REGEXP on the subject.

=cut

sub filter {
  my $self	= shift;
  my $filter	= shift;
  my $COL	= shift;		# The field to apply REGEXP to...
  if( ! defined $COL or $COL eq "" ) {
    $COL	= $SUBJ_COL;
  }
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

    my($source,$dest,$polarity)	= $self->convert_plus_minus_to_source_dest_polarity;
    # Plus/minus filtering:

    if( $polarity eq "+" ) {
      $self->{$dest}	= [ grep { $_->[$COL] =~ /$RE/ } @{$self->{$source}} ];
    }
    elsif( $polarity eq "-" ) {
      $self->{$dest}	= [ grep { $_->[$COL] !~ /$RE/ } @{$self->{$source}} ];
    }
    if( $source eq $dest ) {
      # Make sure new list reflects the filter:
      $self->{filtered}	= $self->{$dest}
    }

    print "Filtered: ",scalar(@{$self->{filtered}}), " articles!\n";
    $self->reset_pageinfo;
  }
}


1;
