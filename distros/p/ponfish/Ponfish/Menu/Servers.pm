#!perl

package Ponfish::Menu::Servers;

use strict;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Ponfish::Utilities;
use Ponfish::Config;
use Ponfish::Menu::Newsgroups;
use Ponfish::TermSize;
use Ponfish::ANSIColor;
use Data::Dumper;

@ISA = qw(Exporter Ponfish::Menu::Main);
@EXPORT = qw(
);
$VERSION = '0.01';

my $SERVER_NAME_LEN	= 12;
my $singleton	= "";

$const::cmd_success	= 2;
$const::cmd_error	= -1;
$const::cmd_unknown	= 1;
$const::cmd_exit	= -2;
my %command_abbrevs	= (
			   default	=> "newsgroups",
			   "*"		=> "newsgroups",
			   sy		=> "sync",
			   resync	=> "resync",
			   add		=> "add_server",
			   remove	=> "remove_server",
			  );
map { $command_abbrevs{$_} = $_ } values %command_abbrevs;
my %command_info	= 
  (
   newsgroups	=> { index	=> 1,
		     default	=> 1,
		     summary	=> "* Start reading newsgroups from a server.",
		     full	=> <<EOT
On the Server Selection screen, use this to select the server to
read news from.  This is the default action - meaning that you need only
type the number.
EOT
		   },
   sync	=> { range	=> 1,
	     summary	=> "Download newsgroup list from a server.",
	     full	=> <<EOT
Use this command to download or update the newsgroups list for
the server or servers.

Example:

  > sync 2-5
EOT
	   },
   add_server	=> { arg_list	=> [ "NAME, SERVER [, USERNAME, PASSWORD, TIMEOUT, CONNECTIONS]" ],
		     summary	=> "Add a new server.",
		     full	=> <<"EOT"
Add a server!

The only required fields are NAME and SERVER.  All arguments
must be separated by a ",".  Spaces will be ignored.  If you want
to leave a field blank, you must still enter a comma.  For example,
if you do not want to specify a USERNAME or PASSWORD, but want to
specify a 60 second TIMEOUT, do the following:

  > add_server Shaw, shaw.gv.shawnews.ca, , , 60

The default for TIMEOUT is 60, the default for CONNECTIONS is 5.

CONNECTIONS is used by the decoder.  It will open up as many download
threads as you specified CONNECTIONS.
EOT
		   },
   remove_server=> { arg_list	=> [ "NAME | SERVER" ],
		     summary	=> "Remove server.",
		     full	=> <<"EOT"
Remove a server from the server list.  You can remove a server
by it's NAME or SERVER_NAME.
EOT
		   },
  );


##################################################################
# HELP
##################################################################
sub command_info {
  return %command_info;
}

sub help_here {
  my $self	= shift;

  $self->print_help( <<"EOT" );
SERVER Menu Help
----------------
I'll assume you have already configured some servers to read news for.
The first thing you want to do, and will want to do periodically to check
for new newsgroups, is to use the "sync" command (see "help sync" for
more details) to update the newsgroup list for your server.

I hope you remembered to run the decoder.  Also, it may take a minute or
more to sync the newsgroups, especially for the first time.  If you have
no idea what I'm talking about, see "help decoder".

Once the newsgroup list is synchronized you will be able to select a server
to start reading news in.  Do so by entering it's correpsonding index number
at the command prompt.

It's unlikely that you'll have so many servers that you'll need to use any
other commands at this menu.
EOT
  ;
  

}


##################################################################
# Commands
##################################################################


sub remove_server {
  my $self		= shift;
  my $server_name	= trim shift;

  my $removed		= CONFIG->remove_server( $server_name );
  if( ! $removed ) {
    $self->menu_errmsg( "Server '$server_name' not found in server list!\n" );
  }
  CONFIG->read_server_data;
  $self->load_main_list;
  return $const::cmd_success;
}

sub add_server {
  my $self	= shift;
  my @args	= map { trim $_ } @_;
  my $list	= join "", @args;
  my @list	= split /,/, $list;

  my $errmsg	= CONFIG->add_server( @list );
  if( $errmsg ) {
    $self->menu_errmsg( "Error adding server:\n`----> $errmsg\n\nSee 'help add_server' for help." );
  }
  else {
    CONFIG->read_server_data;
    $self->load_main_list;
  }
  return $const::cmd_success;
}


sub load_main_list {
  my $self	= shift;
  $self->{main_list}	= CONFIG->get_servers;
  $self->{filtered}	= CONFIG->get_servers;
  return 1;
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
    print "PM: $plus_minus\n";
    my $filtered;
    if( $plus_minus eq "+" ) {
      # Positive filter
      $filtered	= [ grep { $_->{name} =~ /$RE/ } @{$self->{filtered}} ];
    }
    elsif( $plus_minus eq "-" ) {
      # Negative (subtractive) filter
      $filtered	= [ grep { $_->{name} !~ /$RE/ } @{$self->{filtered}} ];
    }
    else {
      # Regular filtering...
      $filtered	= [ grep { $_->{name} =~ /$RE/ } @{$self->{main_list}} ];
    }

    if( ! scalar @$filtered ) {
      $self->menu_errmsg( "No groups matched filter: '$filter'" );
      return $const::cmd_error;
    }
    else {
      print "Filtered: ",scalar(@$filtered), " groups!\n";
      $self->{filtered}	= $filtered;
      $self->reset_pageinfo;
#      $self->show;
    }
  }
}





=item menu_display_list -> menu_display_servers

=cut

sub menu_display_list {
  my $self	= shift;
  return $self->menu_display_servers( @_ );
}

sub menu_display_servers {
  my $self	= shift;

  my $vtype	= $self->get_setting("vtype") || "";	# For highlighting
  $vtype	= "" if( $vtype eq "none" );
  my $highlight_line	= $self->get_setting( "highlight_line" );

  my $currline	= $self->{pageinfo}{currline};
  print $self->sepline;
  for( 1 .. $self->LINES ) {
    last	if( ! defined $self->{filtered}[$currline + $_ - 1] );
    my $line	= sprintf("%02d", $_) . ". "
      . $self->format_item_for_display( $currline + $_ - 1 ) . "\n";

    # Highlight every Xth line:
    if( $vtype ) {
      if( ! ($_ % $highlight_line) ) {
	$line	= colored [$vtype], $line;
      }
    }
    print $line;
  }
  print $self->sepline;
  return $const::cmd_success;
}

sub format_item_for_display {
  my $self	= shift;
  my $idx	= shift;
  my $server	= $self->{filtered}[$idx];

  return join("", rpad($server->{name}, " ", $SERVER_NAME_LEN ),
      "\t", $self->formatted_last_update_time( $server->{server_name} ) );
}


=item resync SERVER_IDX

This may replace sync in the future.  It completely downloads a new set of
groups and stores it along side other groups.  Statistics can be grabbed
from the multiple saves to determine which groups are active, and which
groups are excessively active.

=cut

sub resync {
  my $self		= shift;
  my @idxs		= expand_range_args( @_ );

  # Create command file(s):
  foreach my $idx (@idxs) {
    if( ! $self->item_with_local_index( $idx ) ) {
      $self->errmsg( "Error: Local index '$idx' is out of range!\n" );
    }
    my %S		= %{ $self->item_with_local_index( $idx ) };
    my($name,$server_name)	= @S{qw/name server_name/};
    my $cmd_filename	= join( FILENAME_FIELD_SEP, "00000000", "0020", $name, $server_name );
    my $data		= join( "\t", "resync_groups", $server_name, $name,
				create_valid_filepath( NEWSGROUPS_DIR, $server_name.".".time ) );
    overwrite_file $data, DECODE_DIR, $cmd_filename;
  }
}




=item sync SERVER_IDX

Sync up the newsgroup list.  If there is no group data for a group,
all groups will be downloaded.  If there is group data, only new
newsgroups will be downloaded.

This is a queued command handled by the decoder!

=cut

sub sync {
  my $self		= shift;
  my @idxs		= expand_range_args( @_ );

  # Create command file(s):
  foreach my $idx (@idxs) {
    if( ! $self->item_with_local_index( $idx ) ) {
      $self->errmsg( "Error: Local index '$idx' is out of range!\n" );
    }
    my %S		= %{ $self->item_with_local_index( $idx ) };
    my($name,$server_name)	= @S{qw/name server_name/};
    my $cmd_filename	= join( FILENAME_FIELD_SEP, "00000000", "0020", $name, $server_name );
    my $data		= join( "\t", "sync_groups", $server_name, $name, create_valid_filepath( NEWSGROUPS_DIR, $server_name ) );
    overwrite_file $data, DECODE_DIR, $cmd_filename;
  }
}





=item formatted_last_update_time SERVER

Returns the last newsgroups update time for SERVER.

=cut

sub formatted_last_update_time {
  my $self	= shift;
  my $SERVER	= shift || die "No server!";

  my $server_file	= create_valid_filepath( NEWSGROUPS_DIR, $SERVER . ".last_newgroups_time" );
#  print $server_file,"\n";
  if( ! -f $server_file ) {
    return "(No server data.  Use 'sy' to update the data.)";
  }
  my $data	= read_file( $server_file );
  return "(".scalar( localtime( $data ) ).")";
}


sub show_with_prompt {
  my $self	= shift;
  $self->show;
  print "Comamnd: > ";
}

sub get_abbrevs_for_command {
  my $self	= shift;
  my $cmd	= shift;

  my $full_cmd	= $self->translate_command( $cmd );
  if( ! $full_cmd ) {
    return undef;
  }

  my %all_ca	= $self->all_command_abbrevs;

  my @abbrevs	= ();
  while( my($k,$v) = each %all_ca ) {
#    print $v->[0]."/".$full_cmd,"\n";
    if( $v eq $full_cmd ) {
      push @abbrevs, $k;
    }
  }
  my @sorted_abbrevs	= map { $_->[0] } sort { $a->[1] <=> $b->[1] } map { [ $_ => length $_ ] } @abbrevs;
  return @sorted_abbrevs;
}




sub server {
  my $self	= shift;
  my $arg	= shift || $self->{cmd_info}{args}[0];

  my @server_list	= @{CONFIG->get_servers};

  if( $arg !~ /^\d+$/ ) {
    foreach my $server ( @server_list ) {
      if( $server->{name} =~ /$arg/i ) {
	$self->make_active_server( $server );
	return $const::cmd_success;
      }
    }
    $self->menu_errmsg( "Error: server match for string '$arg' not found!\n" );
  }
  else {
    if( defined $server_list[$arg-1] ) {
      $self->make_active_server( $server_list[$arg-1] );
    }
    else {
      $self->menu_errmsg( "Error: server #".$arg." does not exist!\n" );
    }
  }
  return 1;
}

sub newsgroups {
  my $self	= shift;
  my $server	= shift || "";
  my $filter	= shift || "";
  if( $server ) {
    $self->server( $server );
  }
  if( ! $self->{active_server} ) {
    $self->menu_errmsg( "No active server selected!\n" );
    return $const::cmd_error;
  }
  else {
    # Ok, open a newsgroups display:
    my $NG	= Ponfish::Menu::Newsgroups->new( $self, $self->{active_server}, $filter );
    $NG->take_control;
    $self->register_with_TermSize_object;		# So resized reference the correct object.
#    $self->show;
    return $const::cmd_success;
  }
}

sub make_active_server {
  my $self	= shift;
  $self->{active_server}	= shift;
  $self->menu_msg( "Server: ".$self->{active_server}{name}." is now active.\n" );
}

sub menu_msg {
  my $self	= shift;

  print @_;
}



sub default {
  my $self	= shift;
  my $arg	= shift;
  return $self->newsgroups( $arg );
}



=item command_abbrevs

Pure virtual function that gets the command abbrevs for the particular Menu
class.

=cut

sub command_abbrevs {
  my $self	= shift;
  return %command_abbrevs;
}

sub quick_quit {
  my $self	= shift;
  exit 0;
}

sub quit {
  my $self	= shift;
  print "Really exit? (y/N) > ";
  my $response	= trim lc <>;
  chomp $response; chomp $response;
  if( $response eq "y" ) {
    exit 0;
  }
  else {
    $self->menu_msg( "Quit aborted!\n" );
  }
}

=item stuff

1. s(how) s(ervers): Displays a list of servers
2. act(ivate) server X (x = server number or server name/substring
3. s(how) n(ewsgroups): displays a list of newsgroups on the server, one page at a time
4. set filter (sf) REGEXP: Add a filter whenever a list is displayed
5. remove filters (rf): Remove any active filters
6. n(ext): Next page
7. p(rev): Prev page
8. sort [date|sub|alpha|poster]
9. 

=cut

=item close

Quit the program.

=cut

sub close {
  my $self	= shift;
  $self->quit;
}

sub reset_pageinfo {
  my $self	= shift;
  $self->{pageinfo}	= { currline	=> 0,
			    lpp		=> $self->LINES,	# Lines Per Page
			    filter	=> "",
			  };
}


sub new {
  my $type	= shift;
  if( ! $singleton ) {
    $singleton	= bless { TermSize	=> Ponfish::TermSize->new,
			}, $type;
  }
  $singleton->register_with_TermSize_object;
  $singleton->{last_command}	= $singleton->get_default_empty_command;
  return $singleton;
}

sub register_with_TermSize_object {
  my $self	= shift;
  $self->{TermSize}->register_callback( $self, "show_with_prompt" );
}



=item take_control

This method starts a loop.  Control is returned to the caller
when the user decides to end the current task.

=cut

sub take_control {
  my $self	= shift;

  while( $self->page_one != $const::cmd_exit ) {
    # Loop until page_one() returns $const::cmd_exit.
  }
}


=item resize / COLUMNS / LINES

These three subs all are redirected to the TermSize singleton.

=cut

sub resize {
  my $self	= shift;
  return $self->{TermSize}->resize;
}
sub COLUMNS {
  my $self	= shift;
  return $self->{TermSize}->COLUMNS;
}
sub LINES {
  my $self	= shift;
  return $self->{TermSize}->LINES;
}








=item page_one

Displays the list of selections (and maybe other things)
and prompts the user for input.

=cut

sub page_one {
  my $self	= shift;

  $self->show_with_prompt;
  my $cmd	= <STDIN>;
  chomp $cmd; chomp $cmd;

  return $self->interpret_command( $cmd );
}

sub get_default_empty_command {
  my $self	= shift;
  return "next";
}



1;
