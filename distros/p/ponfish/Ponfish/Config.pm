#!perl

package Ponfish::Config;

use strict;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Ponfish::Utilities;
use File::Copy;
use DirHandle;

@ISA = qw(Exporter);
@EXPORT = qw(
CONFIG

SERVER_FILE
MAIN_DIR
DATA_DIR
NEWSGROUPS_DIR
HEADERS_DIR
ARTICLES_DIR
DECODE_DIR
CACHE_DIR
TRASH_DIR

WINDOWS
FILENAME_FIELD_SEP

config_store
config_retrieve
get_filenames

move_file_to_trash

is_valid_command_file
get_decode_dir_free_space
group_data_file
get_authinfo
my_glob
log
);
$VERSION = '0.01';

my $LOG_FH;
sub log {
  if( ! $global::logging ) {
    return;
  }
  if( ! defined $global::log_file ) {
    $global::log_file = create_valid_filepath( MAIN_DIR(), "ponfish.log" );
  }
  if( ! defined $LOG_FH ) {
    $LOG_FH	= IO::File->new( ">>" . $global::log_file )
      || die "Could not create log file: '$global::log_file'";
    select( [select( $LOG_FH ), $| = 1]->[0] );
    print $LOG_FH "\n\n", "#"x66, "\n\nLog started: ", scalar(localtime(time)),"\n\n";
    if( $global::log_print ) {
      print "\n\n", "#"x66, "\n\nLog started: ", scalar(localtime(time)),"\n\n";
    }
  }
  print $LOG_FH @_;
  if( $global::log_print ) {
    print @_;
  }
}

sub get_filenames {
  my $dir	= shift || die "No directory provided!";
  my $RE	= shift || qr/./;
  my $DH	= DirHandle->new( $dir ) || die "Can't create DirHandle ($dir)";

  my @returns	= ();
  while( my $fn = $DH->read ) {
    if( $fn =~ $RE ) {
      push @returns, create_valid_filepath( $dir, $fn );
    }
  }
  return @returns;
}

sub WINDOWS {
  return defined $ENV{USERPROFILE};
}

=item my_glob FILESPEC

This glob function will work in Windows in deep paths (unlike the regular glob).
It uses chdir to go to the deepest directory in FILESPEC, so your working
directory will change when you call this function!

=cut

sub my_glob {
  my $filespec	= shift;
  if ( $filespec =~ /^(.*)(\/|\\)(.*)$/ ) {
    if( WINDOWS ) {
      my $base_path	= $1;
      my $filespec	= $3;
      # This is causing some problems in windows
      chdir $base_path || return ();	###!!!die "Can't chdir to dir: '$base_path'";
      my @files	= glob( $filespec );
      @files	= map { create_valid_filepath( $base_path, $_ ) } @files;
      return @files;
    }
    return glob $filespec;
  }
}


my %prefs	=
  (
   servers	=> undef,
   dirs		=> {
		    main	=> ((WINDOWS) ? "c:/pf/pfdata"
				    : $ENV{HOME}."/pf/pfdata"),
		   },
   colors	=> {
		    incomplete		=> "red",
		    highlight		=> "yellow",
		    background		=> "black",
		    reverse		=> "bold",
		   },
   prefs	=> {
		    #num_decodes		=> 3,
		   },
   run_settings	=> { date		=> "on",
		     poster		=> "on",
		     rhs		=> 20,
		     vtype		=> "bold",
		     highlight_line	=> 4,
		     avail_format	=> "2",
		     pagesort		=> "on",
		     nolimit		=> "off",
		     decode_dir		=> "",
		     preview_dir	=> "previews",
		     save_dir		=> "saves",
		   },
  );

##################################################################
# Exported Subs:
##################################################################

sub CONFIG {
  return Ponfish::Config->new;
}
CONFIG();	# Creates the singleton!

sub MAIN_DIR {
  CONFIG->get_dir( "main" );
}

sub SERVER_FILE {
  return create_valid_filepath( MAIN_DIR, "servers" );
}

sub CONF_DIR {
  CONFIG->get_dir( "conf" );
}

# Add more directories to configuration:
for ( qw(cache newsgroups articles data decode trash conf ) ) {
  $prefs{dirs}{$_}	= create_valid_filepath( MAIN_DIR(), $_ );
}

# Specifics:
if( WINDOWS ) {
  $prefs{dirs}{decode}	= "C:/pf";
}
else {
  $prefs{dirs}{decode}	= create_valid_filepath( $ENV{HOME} . "/pf" );
}
# Trash dir:
$prefs{dirs}{trash}	= create_valid_filepath( DECODE_DIR(), "junk" );

# Ensure filepaths exist:
for( qw/cache newsgroups articles data decode trash/ ) {
#  print "EDE: $_ -> ", CONFIG()->get_dir( $_ ), "\n";;
  ensure_dir_exists CONFIG()->get_dir( $_ );
}

sub DATA_DIR {
  return CONFIG->get_dir( "data" );
}
sub NEWSGROUPS_DIR {
  return CONFIG->get_dir( "newsgroups" );
}
sub HEADERS_DIR {
  return CONFIG->get_dir( "headers" );
}
sub ARTICLES_DIR {
  return CONFIG->get_dir( "articles" );
}
sub CACHE_DIR {
  return CONFIG->get_dir( "cache" );
}
sub TRASH_DIR {
  return CONFIG->get_dir( "trash" );
}
sub DECODE_DIR {
  return CONFIG->get_dir( "decode" );
}
$Global::DECODE_DIR	= DECODE_DIR();


sub FILENAME_FIELD_SEP {
  return " ";
}

sub move_file_to_trash {
  for( @_ ) {
    portable_mv( $_, TRASH_DIR );
  }
}

sub is_valid_command_file {
  my $fn		= shift;
  my $field_sep		= FILENAME_FIELD_SEP;
  return 0		if( $fn !~ /^\d+$field_sep\d+$field_sep/ );
  return 0		if( ! -s $fn or -s $fn > 20_000 );
  # NOTE: Can add other checks here...
  return 1;
}

sub get_decode_dir_free_space {
  if( WINDOWS ) {
    my $cmd	= "dir \"" . DECODE_DIR ."\"";
    $cmd	=~ s/\//\\/g;
#    print "CMD: '$cmd'\n";
    my $results	= `$cmd`;
#    print "RES: '$results'\n";
    if( $results =~ /([\d\,]+) bytes free/s ) {
      my $bytes	= $1;
      $bytes	=~ s/\,//g;
      return $bytes;
    }
    else {
      die "Could not get disk free space for dir: '" . DECODE_DIR . "\n";
    }
  }
  else {
    my $cmd	= "df -k " . DECODE_DIR;
    my $df	= `$cmd`;
#    $df =~ s/\n/
    my @lines	= split /\n/, $df;
    my $line2	= join("\t", $lines[1], $lines[2] );

    #my $line2	= [split /\n/, $df]->[1];

    my $col4	= [split /\s+/, $line2]->[3];
    my $bytes	= $col4 * 1024;
#    print "Found '$bytes' in '$df'\n";	
    return $bytes;
  }
}


sub get_authinfo {
  my $server_name	= shift;
  for( @{CONFIG->get_servers} ) {
    if( $_->{server_name} eq $server_name ) {
      return( $_->{username}, $_->{password} );
    }
  }
  return ("","");	# Default to empty authinfo...
}

sub group_data_file {
  my $server_name	= shift;
  return create_valid_filepath( NEWSGROUPS_DIR, $server_name );
}

sub config_store {
  my $data		= shift;
  return overwrite_file( $data, @_ );
}

sub config_retrieve {
  my $filepath		= create_valid_filepath( @_ );
  return read_file( $filepath );
}


##################################################################
# Config object methods:
##################################################################
# List Value settings:
my %lv_settings	= ( date		=> { map { $_ => 1 } qw/on off/ },
		    poster		=> { map { $_ => 1 } qw/on off/ },
		    rhs			=> { map { $_ => 1 } 0 .. 30 },
		    vtype		=> { map { $_ => 1 } qw/bold underline none/ },
		    highlight_line	=> { map { $_ => 1 } 2 .. 10 },
		    avail_format	=> { map { $_ => 1 } 1 .. 2 },
		    pagesort		=> { map { $_ => 1 } qw/on off/ },
		    nolimit		=> { map { $_ => 1 } qw/on off/ },
		  );
my %freeform_settings	= ( decode_dir	=> 1,
			    preview_dir	=> 1,
			  );
my $singleton	= undef;
sub new {
  my $type	= shift;
  if( defined $singleton ) {
    return $singleton;
  }
  $singleton	= bless {}, $type;
  $singleton->{data}	= \%prefs;
  return $singleton;
}

sub get_dir {
  my $self	= shift;
  my $dir_name	= shift;
  return $self->{data}{dirs}{$dir_name};
}

sub get_color {
  my $self		= shift;
  my $color_name	= shift;
  return $self->{data}{colors}{$color_name};
}

sub get_servers {
  my $self	= shift;
  if( ! defined $self->{data}{servers} ) {
    $self->read_server_data;
  }
  return $self->{data}{servers};
}
sub add_server {
  my $self		= shift;
  my $name		= shift || return "Name must not be blank!";
  my $server_name	= shift || return "Server_name must not be blank!";
  my $username		= shift || "";
  my $password		= shift || "";
  my $timeout		= shift || 60;
  my $max_con		= shift || 5;

  append_file join("|", $name,$server_name,$username,$password,$timeout,$max_con)."\n", SERVER_FILE;
  return "";
}
sub remove_server {
  my $self		= shift;
  my $server_name	= shift;

  my @server_data	= split /\n/, read_file( SERVER_FILE );
  portable_mv SERVER_FILE, SERVER_FILE . "." . time;
  my $removed		= 0;
  for( @server_data ) {
    if( ! /^$server_name\|/ ) {
      append_file $_."\n", SERVER_FILE;
    }
    else {
      $removed		= 1;
    }
  }
  CONFIG->read_server_data;
  return $removed;
}

sub read_server_data {
  my $self	= shift;

  $self->{data}{servers}	= [];	# Clear out server data (clean slate)

  if( ! -f SERVER_FILE ) {
    # No server file configured...
    return;
  }
  my $server_data	= read_file SERVER_FILE;

  my @server_info	= map { [ split /\|/, $_ ] } split( /\n/, $server_data );

  for( @server_info ) {
    my %server_info;
    @server_info{qw/name server_name username password timeout max_con/}	= @$_;
    push @{$self->{data}{servers}}, \%server_info;	# Save!
  }
}




sub get_settings {
  my $self	= shift;
  return $self->{data}{run_settings};
}
sub get_setting {
  my $self	= shift;
  my $setting	= shift;
  return $self->{data}{run_settings}{$setting};
}

=item set_setting SETTING_NAME VALUE

Important: Returns 0 on success, and an error message on falure!

=cut

sub set_setting {
  my $self	= shift;
  my $setting	= trim lc shift;
  my $value	= trim shift;

  if( $freeform_settings{$setting} ) {
    $self->{data}{run_settings}{$setting}	= $value;
    return "";
  }
  if( $lv_settings{$setting} ) {
    # Can only take predefined values
    $value	= lc $value;
    if( ! $lv_settings{$setting}{$value} ) {
      return "Error: Valid options for setting '$setting' are:\n  "
	. join( "  \n", sort(keys(%{$lv_settings{$setting}})) );
    }
    else {
      # Everything is fine!
      $self->{data}{run_settings}{$setting}	= $value;
      return "";
    }
  }
}


##################################################################
# End object methods.
##################################################################


################!!!!!!!!!!!!!!! Hexerodonus !!!!!!!!!!!!!!!!!!!!!!########################

1;


=item ddkdk

=cut

