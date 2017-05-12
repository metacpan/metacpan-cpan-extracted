#!perl

package Ponfish::ArticleJoiner;

use strict;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Ponfish::Utilities;
use Ponfish::Config;
use IO::File;
use Time::Local;	#POSIX qw(mktime);

@ISA = qw(Exporter);
@EXPORT = qw(

);
$VERSION = '0.01';

my $MAX_SUBJ_LEN	= 300;

sub test {
  my $IF		= IO::File->new( "newnews.cache" ) || die "Can't open 'newnews.cache'";
  my $AJ		= Ponfish::ArticleJoiner->new;
  $AJ->reset;
  $AJ->set_storage_path( "where" );
  while( <$IF> ) {
    $AJ->add( $_ );
  }
  use Data::Dumper;
  $AJ->write_out_old_incompletes( 2_000_000_000 );	# Write them all out!
#  print Dumper( $AJ->{data} );
}
##################################################################

sub new {
  my $type	= shift;
  return bless { data		=> {},
		 fw_older_than	=> 100_000,
		 fw_interval	=> 10000,
		 last_id_interval	=> 500,
		 id_queue	=> [],
	       }, $type;
}

sub set_last_id_file {
  my $self	= shift;
  $self->{last_id_file}	= shift;
}

sub set_storage_path {
  my $self	= shift;
  my $spath	= create_valid_filepath( @_ );
  $self->{spath}	= $spath;
}

sub reset {
  my $self	= shift;
  $self->{data}	= {};
}

sub add {
  my $self	= shift;
  my $line	= shift;
#  print "LINE: '$line'\n";
  chomp $line;
  my($numb, $subj, $from, $date, $mesg, $refr, $char, $lines, $xref)	= split /\t/, $line;

  $self->{last_numb}	= $numb;
  my $data	= $self->{data};

  my $prefix;
  my $part;
  my $max_parts;
  my $file_num;
  my $max_files;
###  my $suffix;

  if( $subj =~ /^(.*)\((\d+)\/(\d+)\)(.*)/ ) {
    $prefix	= $1;
###    $suffix	= $4;
    $part	= $2;
    $max_parts	= $3;
    if ( ! $data->{$prefix} ) {
      $data->{$prefix}	= { parts_found	=> 0,
			    max_parts	=> $max_parts,
			    part_nums	=> [],
			    subj	=> $subj,
###			    suffix	=> $suffix,
			    part_zero	=> "",
			    from	=> $from,
			    first_part_num	=> $numb,
			    date	=> xdate_to_perl_time( $date ),
			  };
    }
    if ( $part != 0 ) {
      $data->{$prefix}{parts_found}++;
    }
    $data->{$prefix}{part_nums}[$part]	= $numb;

    # Check to see if complete:
    if ( $data->{$prefix}{parts_found} == $data->{$prefix}{max_parts} ) {
      $self->write_to_file( $prefix );
    }
  } else {
    # Here we have a non-binary / non-multipart
    $data->{$subj}	= { parts_found	=> 0,
			    max_parts	=> 0,
			    part_nums	=> [ $numb ],
			    subj	=> $subj,
###			    suffix	=> "",
			    part_zero	=> "",
			    from	=> $from,
			    first_part_num	=> $numb,
			    date	=> xdate_to_perl_time( $date ),
			  };
    $self->write_to_file( $subj );
  }

  # Is it time to write out the last id file?
  if( ( $numb % $self->{last_id_interval} ) == 0 ) {
    config_store( $numb, $self->{last_id_file} );
  }

  # Is it time to write out some incompletes?  Note: this may skip occasionally, when
  # particular article headers are missing... $numb can skip numbers...
  # This might not be necessary... only trying to keep memory consumption down...
  if( ($numb % $self->{fw_interval}) == 0) {
    $|	= 1;
    select STDERR; $| = 1; select STDOUT;
    warn "Writing out old incompletes... ($numb)\n";
    # Time to write some stuff...
    # Note also that this does some unnecessary work,
    # but that work isn't much and won't kill us...
    if( $numb > $self->{fw_older_than} ) {
      $self->write_out_old_incompletes( $numb - $self->{fw_older_than} );
    }
  }
  return $numb;
}

sub store_final_retrieved_numb {
  my $self	= shift;

  config_store( $self->{last_numb}, $self->{last_id_file} );
}



sub write_out_old_incompletes {
  my $self		= shift;
  my $older_than	= shift;

  my $data		= $self->{data};
  while( my($k,$v) = each %$data ) {
    if( $v->{first_part_num} < $older_than ) {
      warn "Write out: $v->{first_part_num}\n";
      $self->write_to_file( $k );
    }
  }
}



sub flush_all_incompletes {
  my $self	= shift;

  # First, what's the filename?
  my $filename	= $self->{spath} . "." . "inc";
  my $OF	= create_append_fh( $filename )
    || die "Can't open append mode on file: '$filename'";

  my $data		= $self->{data};

  while( my($prefix,$ad) = each %$data ) {	# prefix and article data
    print $OF $self->serialize_post( $ad, $prefix );
    $self->remove_article_data( $prefix );
  }
}


=item load_prior_incompletes

WHen downloading headers, the ones towards the end may not be
complete - as some posts are always in progress.

This method will load the incompletes data from the previous
time headers were downloaded.  This data replaces any current
data being worked on, if any - and there really shouldn't be.
This routine should be called before the download of any additional
headers.

44726887' to '57453656'...
45370000

=cut

sub load_prior_incompletes {
  my $self	= shift;

  my $filename	= $self->{spath} . "." . "inc";
  if( -f $filename ) {
    my $IF	= create_read_fh( $filename )
      || die "Can't open read mode on file: '$filename'";
    my %article_data	= ();
    my $num_loaded	= 0;
    while( <$IF> ) {
      my $ad	= $self->deserialize_data( $_ );
      if( ! defined $ad or ! defined $ad->{prefix} ) { # or ! defined $article_data{$ad->{prefix}} ) {
	log "Could not deserialize data: '$_'";
	next;
      }
      $article_data{$ad->{prefix}}	= $ad;
      $num_loaded++;
    }
    $self->{data}	= \%article_data;
    return $num_loaded;
  }
  else {
    $self->{data}	= {};
    return 0;
  }
}


sub delete_incompletes_file {
  my $self	= shift;
  my $filename	= $self->{spath}. "." . "inc";
  unlink $filename;
}


sub write_to_file {
  my $self	= shift;

  my $prefix	= shift;

#  use Data::Dumper;
#  print Dumper( $self->{data} );
  my $ad	= $self->{data}{$prefix} || die "No data found for prefix: '$prefix'";

  # Select the correct filename:
  my $numb	= $ad->{first_part_num};
  my $file_ext	= int( $numb / 1_000_000 );
  my $filename	= $self->{spath} . "." . $file_ext;
  if( ! defined $self->{cached_fhs}{$filename} ) {
    $self->{cached_fhs}{$filename}	= create_append_fh( $filename )
      || die "Can't open append mode on file: '$filename'";
  }
  my $OF	= $self->{cached_fhs}{$filename};
  print $OF $self->serialize_post( $ad );

  $self->remove_article_data( $prefix );
}

sub remove_article_data {
  my $self	= shift;
  my $prefix	= shift;
  delete $self->{data}{$prefix};
}


sub purge_articles {
  my $self		= shift;
  my $purge_up_to	= shift;
  my $newsgroup		= shift;

  print "\n\nPURGING UP TO: $purge_up_to\n";

  my $storage_path	= shift || $self->{spath};

  my @files		= my_glob($storage_path."*");
  @files		= map { $_->[1] } sort { $a->[0] <=> $b->[0] } map { /.*\.(\d+)$/; [$1, $_] } grep { /.*$newsgroup\.\d+$/ } @files;
  use Data::Dumper;
  print Dumper( \@files );
  my $total_articles_purged	= 0;

 PERFILE: foreach my $article_file ( @files ) {
    next		if( $article_file !~ /\.(\d+|inc)$/ );	# Examine only valid files...

    # Check zero-length file:
    if( ! -s $article_file ) {
      print "In purge_articles: Deleting 0-size article file: '$article_file'\n";
      unlink $article_file;
      next;
    }
    my $purge_count	= 0;
    my $total_count	= 0;
    my $kept_count	= 0;
    my $purged_file	= $article_file . ".purged";
    my $OF		= IO::File->new( ">$purged_file" ) || die "Can't open file: '$purged_file' for write!";
    my $IF		= IO::File->new( $article_file ) || die "Can't open file: '$article_file' for read!";
  OUTER: while( my $line = <$IF> ) {
      $total_count++;
      my($time,$avail,$parts,$poster,$articles,$sub)	= split /\t/, $line;
      my @articles	= split /,/, $articles;
      for( @articles ) {
	next	if( ! $_ );
	if( $_ < $purge_up_to ) {
	  $purge_count++;
	  $total_articles_purged++;
	  next OUTER;
	}
      }
      $kept_count++;
      print $OF $line;
    } # OUTER
    $OF->close;
    # Do some file moving...
    move_file_to_trash $article_file;

    if( ! -s $purged_file ) {
      print "Deleting 0-size article file: '$article_file'\n";
    }
    else {
      portable_mv $purged_file, $article_file;
    }

    my $temp_a	= $article_file;
    $temp_a =~ s/.*\///;
    print "\tPURGE: $temp_a: (purged+kept=total): $purge_count + $kept_count = $total_count\n";
    if( ! $purge_count ) {
      # If no articles purged, then we can probably safely stop as
      # no articles will match in subsequent files...
      last;
    }
    sleep 5;
  }	# PERFILE
  print "PURGED $total_articles_purged POSTS\n\n";
  return 1;	# Success!
}

=item serialize_post ARTICLE_DATA

Returns a highly-concise description of a post suitable for saving
to a file.  The serialization results in one line.

No message IDs are stored - they're huge.
Only the article numbers for the parts are preserved.

=cut

sub serialize_post {
  my $self	= shift;
  my $ad	= shift;
  my $prefix	= shift || "";

  {
    no warnings;
    # Handle super-long subjects...
    if( length( $ad->{subj} ) > $MAX_SUBJ_LEN ) {
      $ad->{subj}	= substr( $ad->{subj}, 0, $MAX_SUBJ_LEN );
    }
    return join("\t", (@$ad{qw(date parts_found max_parts from)}, 
		       join(",", @{$ad->{part_nums}}),
		       $ad->{subj}, $prefix) ) . "\n";
  }
}

=item deserialize_data SERIALIZED_DATA

Convert data saved by serialize_post() back to the
original hash format.  Some information may not be
preserved between the two operations!

=cut

sub deserialize_data {
  my $self	= shift;
  my $data	= shift;
  chomp $data; chomp $data;

  my @fields	= split /\t/, $data;
  my @part_nums	= split /,/, $fields[4];
  my $deserialized	= { date	=> $fields[0],
			    parts_found	=> $fields[1],
			    max_parts	=> $fields[2],
			    from	=> $fields[3],
			    part_nums	=> \@part_nums,
			    subj	=> $fields[5],
			    prefix	=> $fields[6],
###			    suffix	=> "",
			    part_zero	=> "",
			    # Note: first_part_num may not be accurate, but it will contain an article num.
			    first_part_num	=> [ grep { defined $_ and $_ ne "" } @part_nums ]->[0],
			  };
  return $deserialized;
}


my %mon_to_num		= (JAN => 0,
			   FEB	=> 1,
			   MAR	=> 2,
			   APR	=> 3,
			   MAY	=> 4,
			   JUN	=> 5,
			   JUL	=> 6,
			   AUG	=> 7,
			   SEP	=> 8,
			   OCT	=> 9,
			   NOV	=> 10,
			   DEC	=> 11,
			  );

sub xdate_to_perl_time {
  my $date_string	= shift;
  if( $date_string =~ /(\d+) (\w+) (\d{2,4}) (\d+)\:(\d+)\:(\d+)/ ) {
    my $year		= $3;
    if( length( $year ) == 2 ) {
      $year		= "20" . $year;
    }
    return timelocal( $6, $5, $4, $1	, $mon_to_num{uc($2)}, $year - 1900 );
  }
  else {
    die "Invalid date string: '$date_string'";
  }
}




1;
