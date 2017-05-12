#!perl

package Ponfish::Utilities;

use strict;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use File::Path;
use IO::File;
use File::Copy;
use File::Find;

@ISA = qw(Exporter);
@EXPORT = qw(
ensure_dir_exists
ensure_file_path_exists
create_valid_filepath
create_append_fh
create_read_fh
read_file
overwrite_file
append_file
max min
trim
expand_range_args
serialize_for_command
portable_mv
md_date
find_files
rpad
reverse_hash
);
$VERSION = '0.01';

@Global::date_list	= qw/jan feb mar apr may jun jul aug sep oct nov dec/;
my $i			= 1;
%Global::date_hash	= map { $_ => $i++ } @Global::date_list;


=item reverse_hash HASH_REF

Input: { a => b,	Output: { b => [a, c],
         c => b,		  e => [d],
         d => e }		}

Takes a hash and reverses it.  All the values of the returned hash are array refs.

=cut

sub reverse_hash {
  my $in		= shift;


  my $out		= {};
  while( my($k,$v) = each %$in ) {
    $out->{$v} ||= [];
    push @{$out->{$v}}, $k;
  }

  return $out;
}


=item rpad STRING PAD_CHAR FINAL_LEN

Pad STRING with PAD_CHAR up to FINAL_LEN.  If strlen( STRING ) >= FINAL_LEN,
STRING is returned.

=cut

sub rpad {
  my $string	= shift;
  my $char	= shift || " ";
  my $total_len	= shift || return $string;

  if( length( $string ) >= $total_len ) {
    return $string;
  }
  $string	.= " " x $total_len;
  return substr( $string, 0, $total_len );
}


sub find_files {
  my @files		= ();
  find(
       sub {
	 if( -f $_ ) {
	   push @files, $File::Find::name;
	 }
       },
       @_
      );
  return @files;
}

sub md_date {
  my $time	= shift || time;
  my $temp	= localtime $time;

  if( $temp =~ /^....(\w+)\s+(\d+)/ ) {
    my $md_date		= sprintf( "|%s %02d", $1, $2 );	# MMM DD
    return $md_date;
  }
  # In case of strange error...
  warn "Error figuring date for time string: '$time'! ($temp)";
  return "Xxx 00";
}

use File::Path;

sub portable_mv {
  my @args	= @_;
  my $dest	= pop @args;

  my $error	= 0;
  for( @args ) {
#    if( WINDOWS ) {	# This may not be necessary!!!
#      s/\//\\/g;
#    }
    $error	+= move( $_, $dest ) - 1;
  }
  if( $error ) {
    return "";
  }
  return 1;
}



sub serialize_for_command {
  my $data	= shift;
  $data		=~ s/\t/ /g;
  return $data;
}

sub expand_range_args {
  my @args	= @_;

  # Clean up arguments...
  my $args	= join(",", @args );
  $args		=~ s/\.\./-/g;
  $args		=~ s/[\s\,]*-[\s\,]*/-/g;	# Take care of spaces within a range
  $args		=~ s/\,/\ /g;			# Remove all commas
  $args		=~ s/\s+/\ /g;			# Only one space between arguments

  @args		= split / /, $args;		# Split again
  my @ranges	= grep { /^\d+-\d+$/ } @args;
  my @singles	= grep { /^\d+$/ } @args;
  foreach my $range ( @ranges ) {
    my($f,$l)	= split /-/, $range;
    if( $f > $l ) {
      ($f,$l)	= ($l,$f);
    }
    push @singles, ($f .. $l);
  }
  return @singles;
}


sub trim {
  $_	= shift;
  if( ! defined $_ ) {
    print "Caller: ", join(",", caller );
  }
  s/^\s+//;
  s/\s+$//;
  return $_;
}

sub ensure_dir_exists {
  while( my $dir = shift ) {
    if( ! -d $dir ) {
      mkpath $dir,0,0755	|| return undef;
    }
  }
  return 1;
}

sub ensure_file_path_exists {
  while( my $file = shift ) {
#    print "PATH: '$file'\n";
    if( $file =~ /^(.*)\// ) {
      return ensure_dir_exists( $1 );
#      mkpath $1,0,0755		|| return undef;
    }
    else {
      # !!!
      return "undef";
    }
  }
  return 1;
}

sub create_append_fh {
  my $filepath		= create_valid_filepath( @_ );
  ensure_file_path_exists( $filepath );
  return IO::File->new( ">>$filepath" ) || die "Could not create path or append FH for: '$filepath'";
}

sub create_valid_filepath {
  my $filepath		= shift;
  while( my $fn = shift ) {
    $filepath		.= "/" . $fn;
  }
  $filepath			=~ s/\/\//\//g;
  return $filepath;
}

sub create_read_fh {
  my $filepath		= create_valid_filepath( @_ );
  ensure_file_path_exists( $filepath );
  use Carp;
  if( ! $filepath ) {
    confess "No filepath!";
  }
  return IO::File->new( "$filepath" ) || return undef; #die "Could not create path or read FH for: '$filepath'";
}

=item create_overwrite_fh DIR DATA

Overwrite file in DIR with DATA.

=cut

sub create_overwrite_fh {
  my $filepath		= create_valid_filepath( @_ );
  ensure_file_path_exists( $filepath );
  return IO::File->new( ">$filepath" ) || die "Could not create path or append FH for: '$filepath'";
}

sub overwrite_file {
  my $data		= shift;
  my $OF		= create_overwrite_fh( @_ );
  print $OF $data;
  $OF->close;
}

sub append_file {
  my $data		= shift;
  my $AF		= create_append_fh( @_ );
  print $AF $data;
  $AF->close;
}


sub read_file {
  my $IF		= create_read_fh( @_ ) || return undef;
  return join("", <$IF> );
}

sub max {
  return [ sort { $b <=> $a } @_ ]->[0];
}

sub min {
  return [ sort { $a <=> $b } @_ ]->[0];
}

1;
