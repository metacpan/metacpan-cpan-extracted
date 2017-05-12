#!perl

package Ponfish::Menu::Main;

use strict;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Ponfish::Utilities;
use Ponfish::Config;
use Ponfish::Menu::Newsgroups;
use Ponfish::TermSize;

@ISA = qw(Exporter);
@EXPORT = qw(
);
$VERSION = '0.01';

my $singleton	= "";

$const::cmd_success	= 2;
$const::cmd_error	= -1;
$const::cmd_unknown	= 1;
$const::cmd_exit	= -2;
my %global_command_abbrevs	= ( 's'		=> "show",
#				    ng		=> "newsgroups",
			            n		=> "next_page",
				    next	=> "next_page",
				    p		=> "prev_page",
				    prev	=> "prev_page",
				    f		=> "filter",
				    "/"		=> "filter",
				    exit	=> "quit",
				    "q"		=> "quit",
				    "q!"	=> "quick_quit",
				    resize	=> "resize",
				    c		=> "close",
				    set		=> "setting",
				    push	=> "push_state",
				    pop		=> "pop_state",
				    f2m		=> "filtered_to_main",
				    "?"		=> "help",
				    home	=> "home",
				    end		=> "end",
				    vs		=> "show_settings",
				    cleanup	=> "cleanup",
				    reverse	=> "reverse",
				  );
map { $global_command_abbrevs{$_} = $_ } values %global_command_abbrevs;
my %global_command_info	= ( help	=> { arg_list	=> [ "[ COMMAND | CONCEPT ]" ],
					     summary	=> "Various information for the user.",
					     full	=> "Just type 'help' for more information.",
					   },
			    home	=> { summary	=> "Go to the first page",
					     full	=> "Go to the first page",
					   },
			    end		=> { summary	=> "Go to the last page",
					     full	=> "Go to the last page",
					   },
			    prev_page	=> { summary	=> "Page up",
					     full	=> "Page up",
					   },
			    next_page	=> { summary	=> "Page down",
					     full	=> "Page down",
					   },
			    push_state	=> { summary	=> "Save a copy of the current state for later retrieval.",
					     full	=> <<"EOT"
Use push_state to save a copy of the current visible list and your
location within that list.  You can recall the state of the list
when you executed the push at any later time using the pop_state
command.  The states are saved on a last-in first-out queue.

This allows you to do some fancy things, for example, you might
want to save your location using a push, then do some filtering
and queue up some downloads, then pop your state back and
continue where you left off.

Note that these saved states are lost when you close the current
context or exit the program.
EOT
					   },
			    pop_state	=> { summary	=> "Restore a previously pushed state.",
					     full	=> <<"EOT"
If you have saved a state with the push_state command, pop_state
will restore the previously pushed state.  If there are no pushed
states, pop_state does nothing.

Please see the push_state help for more information.
EOT
					   },
			    filtered_to_main	=> { summary	=> "Replace the main list with the filtered list.",
						     full	=> <<"EOT"
The news reader always maintains two lists, the main list and
the filtered list.  The filtered list is always the list that is
presented to you.  (ie: is visible)

The main list is largely immutable, except with modifiers and/or
with certain commands.  The reason to have this list be immutable
is that there are often times you want to filter again and again
over all the articles.  (for example, multiple searches over all
the articles for certain things you are looking for that can't be
all defined easily in one filter)

The reason to have the main list changeable is for the convenience
of being able to remove things you know you don't want to search
through again, be it old articles, articles from certain posters,
or certain subject lines.

This command lets you replace the main list with the filtered
(visible) list, which you may have changed using filters or
other commands, or which may contain the original list, saved
and restored using the push/pop commands.

Note that the downloaded headers on the disk are not changed
by this command.
EOT
						   },
			    quit	=> { summary	=> "Exits the program.",
					     full	=> "Exits the program.  See quick_quit for a faster way out.",
					   },
			    quick_quit	=> { summary	=> "Exits the program immediately.",
					     full	=> "Exits the program immediately.",
					   },
			    close	=> { summary	=> "Exit the current context.",
					     full	=> <<EOT
Close will exit the current program context to the previous one.
For example, if you are reading a newsgroup, "close" will close
the newsgroup reading and bring you back to the newsgroup selection
screen.
EOT
					   },
			    resize	=> { arg_list	=> [ "[ WIDTH HEIGHT ]" ],
					     summary	=> "Resize the 'window'.",
					     full	=> <<EOT
On a Unix platform, you shouldn't need to call this function, as resizing
the terminal will automatically cause the program to resize itself.

Windows users must specify a size using the WIDTH and HEIGHT options.
EOT
					   },
			    reverse	=> { summary	=> "Reverse the list.",
					     full	=> <<EOT
Reverses the order of the displayed items.  In general you can always
go to the end and work up, but this allows you to work from the bottom
down.
EOT
					   },
			    filter	=> { modifier	=> 1,
					     arg_list	=> [ "REGEXP" ],
					     summary	=> "Filter the list of articles or newsgroups with a regular expression.",
					     full	=> <<EOT
Use this command, preferably using the "/" shortcut, to filter lines
with a regular expression.  Please look at the "regexp" help if you
have not already done so.

You can use the following prefixes to modify how the filtering occurs:

Prefix    Effect
-------------------------------------------------------------------
  None	  Applies the filter on the main list, updates the filtered list.

     +	  Applies the filter on the filtered list and keeps only
          the matching lines.
     -    Applies the filter on the filtered list and removes
          matching lines.

    ++    Applies the filter on the main list and also UPDATES the main
          list by removing any lines NOT matching the REGEXP.
    --    Applies the filter on the main list and also UPDATES the main
          list by removing any lines matching the REGEXP.

See the "modifiers" help for more information on how the modifiers work.
EOT
					   },
			    setting	=> {
					   },
			    show_settings	=> { summary	=> "View current settings",
						     full	=> <<"EOT"
Print a list of all the current settings, and the valid values
for each setting.

Here are the settings:

  date			=> "Display post dates for articles.",
  poster		=> "Display poster for articles.",
  rhs			=> "Space for date/poster.",
  highlight_line	=> "Each X line gets a highlight.",
  vtype			=> "Each Xth line displayed as...",
  avail_format		=> "Display for parts available.",
  pagesort		=> "Sort each page as it is printed.",
  nolimit		=> "Decode any number of articles.",

decode_dir:
  Specify a directory that all your decodes go into.  Reset
  to default when you exit.

preview_dir:
  Specify a directory all previews go into.  Reset to default
  when you exit.

EOT
						   },
			    cleanup	=> { summary	=> "Clean up temporary files.",
					     full	=> <<"EOT"
Removes everything from the "junk" directory.

Every queued download is a command file that is moved to the
junk directory once completed.
EOT
					   },
			  );

sub global_command_info {
  return %global_command_info;
}
##################################################################
# Commands
##################################################################

=item show

Default show method...

=cut

sub show {
  my $self	= shift;

  if( ! $self->main_list_loaded ) {	# Check if data has been loaded
    if( $self->load_main_list ) {	# ... if not, load the data
      $self->reset_pageinfo;		# ... and on success, reset the page info
    }
    else {
      $self->print_errmsg;		# ... on failure, display err msg
      return $const::cmd_error;
    }
  }
  return $self->menu_display_list;	# On success, display the current page.
}

=item menu_display_list

Displays the list of data.

=cut

sub menu_display_list {
  my $self	= shift;

}


=item pop_state

Restores the current line and {filtered} list to the previously pushed version, if it exists.

=cut

sub pop_state {
  my $self	= shift;
  if( defined $self->{state_stack} and scalar @{$self->{state_stack}} ) {
    ($self->{pageinfo}{currline}, $self->{filtered})	= @{ pop @{$self->{state_stack}} };
  }
}

=item push_state

Saves a copy of the current line and {filtered} list to a stack, to be restored later using
the pop_state() sub.

=cut

sub push_state {
  my $self	= shift;
  if( ! defined $self->{state_stack} ) {
    $self->{state_stack}	= [];
  }
  my @list_copy	= @{$self->{filtered}};
  push @{$self->{state_stack}}, [$self->{pageinfo}{currline}, \@list_copy ];
}


=item filtered_to_main

Replaces the MAIN list with the FILTERED list.

=cut

sub filtered_to_main {
  my $self	= shift;

  $self->{main_list}	= [ @{$self->{filtered}} ];
}

=item reverse

Reverse the list...

=cut

sub reverse {
  my $self	= shift;
  $self->{filtered}	= [ reverse @{$self->{filtered}} ];
}



=item main_list_loaded

Returns true if the "main_list" data exists.  Undef otherwise.
* This routine checks the 'filtered' data member for existence *

=cut

sub main_list_loaded {
  my $self	= shift;
  return defined $self->{filtered};
}


=item print_errmsg

Prints out the error message set with set_errmsg().

=cut

sub print_errmsg {
  my $self	= shift;
  print "XXXXXXXXXXXXXXXXXXXXX\n";
  print $self->{errmsg};
  print "XXXXXXXXXXXXXXXXXXXXX\n";
  $self->pause;
}

=item set_errmsg ERRMSG

Saves ERRMSG for later printing (see print_errmsg)

=cut

sub set_errmsg {
  my $self	= shift;
  $self->{errmsg}	= shift;
}

=item item_with_local_index IDX

Returns the item in the 'filtered' list corresponding to LOCAL index IDX.

=cut

sub item_with_local_index {
  my $self	= shift;
  my $idx	= shift;

  my $index	= $self->{pageinfo}{currline} + $idx - 1;
  ( defined $self->{filtered}[$index] ? $self->{filtered}[$index] : undef );
#  return $self->{filtered}[$index];
}

=item current_item

Returns the current line (top of the page line).

=cut

sub current_item {
  my $self	= shift;
  return $self->{filtered}[$self->{pageinfo}{currline}];
}




=item load_main_list

Pure virtual class to load the data (display data).
Expected Output:
  On error, a FALSE value should be returned, and an appropriate
  message should be passed through a call to set_errmsg().

  On success, a TRUE value should be returned, and the member
  variables "filtered" and "main_list" should be set properly.

=cut

sub load_main_list {
  die "load_main_list() is pure virtual.";
}


=item sepline

Returns a string that can be used to separate sections / etc, with a newline.

=cut

sub sepline {
  return "-" x 66, "\n";
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


sub all_command_info {
  my $self	= shift;
  my %gci	= $self->global_command_info;
  my %lci	= $self->command_info;
  return (%gci,%lci);
}

sub command_info {
  die "command_info is pure virtual!";
}

sub all_command_abbrevs {
  my $self	= shift;
  my %gca	= $self->global_command_abbrevs;
  my %lca	= $self->command_abbrevs;

  return( %gca, %lca );
}

=item help_on_help

Help on help.  It will probably be the same across all the Menu classes.

=cut

sub help_on_help {
  my $self	= shift;

  print <<"EOT"
-----------------------------------------------------------------------------
* For general help on this program, type "help general".
* For context related help (on the menu you are in now), type: "help here".
* For help on one of the following important topics, type "help TOPIC":

  ranges        modifiers      decoder
  regexp        searching      misc

* For help on any of the following commands, type "help CMDNAME":

LOCAL:
EOT
    ;
  print $self->command_list( $self->command_abbrevs );
  print <<"EOT"

GENERAL:
EOT
    ;
  print $self->command_list( $self->global_command_abbrevs );
  print "-"x77,"\n\n";

  $self->pause;
}

=item command_list

Returns a formatted list of commands.

=cut

sub command_list {
  my $self		= shift;
  my %command_abbrevs	= @_;

#  my %command_abbrevs	= $self->command_abbrevs;

#  my @commands		= sort values %command_abbrevs;
  my $reversed_abbrevs	= reverse_hash \%command_abbrevs;

  my @formatted		= ();
  foreach my $cmd ( sort keys %$reversed_abbrevs ) {
    my $abbrevs		= $reversed_abbrevs->{$cmd};
    my $formatted	.= "  " . $cmd;
    if( scalar @$abbrevs > 1 ) {
      # Pad with spaces before offering abbreviations list:
      $formatted	= rpad $formatted, " ", int( (max(length( $formatted ),10) + 8 ) / 8 ) * 8;
      $formatted	.= "(";
      for( sort { $a cmp $b } @$abbrevs ) {
	if( $_ eq "default" ) {
	  $formatted	=~ s/\(([^\)]*)$/(*, $1/s;
	  next;
	}
	if( $_ ne $cmd ) {
	  $formatted	.= $_ . ", ";
	}
      }
      $formatted	= substr( $formatted, 0, -2 );	# Remove comma
      $formatted	.= ")";
    }
    $formatted		=~ s/\(\)//s;
    push @formatted, $formatted;
  }

  # Format the list of commands into two columns:
  my $padlen		= max( map { length $_ } @formatted ) + 2;
  $padlen		= max( $padlen, 34 );	# Assuming at least 80 character wide terminal.
  my $formatted		= "";
  my $i			= 1;
  my $mod		= 2;
  for( @formatted ) {
    if( $i % $mod ) {
      $formatted		.= rpad( $_, " ", $padlen );
    }
    else {
      $formatted	.= $_ . "\n";
    }
    $i++;
  }
  if( $formatted !~ /\n$/s ) {
    $formatted		.= "\n";
  }


  return $formatted;
}


=item print_help TEXT

Displays a block of help in small chunks.  If TEXT contains
the string "<PAGEBREAK>", the page will be broken IF not breaking
the page will cause a section to be broken.

=cut

sub print_help {
  my $self	= shift;
  my $text	= shift;

  my @split_chunks	= ();
  for( split /\<--PAGEBREAK--\>\n/s, $text ) {
    my @lines	= split /\n/, $_;
    push @split_chunks, \@lines;
  }

  for( @split_chunks ) {
    print "-"x77,"\n";
    print join("\n", @$_), "\n";
    print "-"x77,"\n";
    $self->pause;
  }
}



=item help_general

The help text here explains the general behavior of the program.

=cut

sub help_general {
  my $self	= shift;

  $self->print_help( <<"EOT" );
Thanks for trying out this program.  It should be quite easy to learn how
to use, however it may not be as intuitive as most GUI-based programs you
may be used to.

I should warn you right now that this program really needs to be run on
a terminal that's 40+ lines high, and 130+ lines wide for it to be of
any convenient use.  This is because of the length of most headers.
Therefore I have taken some liberties with the formatting of the
help files - they may be too long or too wide for a standard 25x80
terminal.

The program functions somewhat like a command shell, where you type a command
followed by some (or no) arguments, then hit <Enter> to run the command.

Usually a numbered list of options is
visible, which I call the option list.  Typing a valid option number and
hitting <Enter> will execute the default action for that option.  For
example, in the SERVER menu, the default action is to enter
the NEWSGROUP menu, which brings up the subscribed newsgroups for the
selected server.  In the NEWSGROUP menu the default action is to enter the
ARTICLE menu, where you can see what articles / binaries are in the selected
newsgroup.  (In the ARTICLE menu the default action is to decode the selected
articles/binaries)
<--PAGEBREAK-->
As stated above, there are three menu levels:

  SERVER
   |
   `---> NEWSGROUP
          |
          `---> ARTICLE

You can go down (into) the menu levels by making an option selection
(typing a valid option number and hitting <Enter>).  To go up (out of) the
menu levels, use the "close" command.

Use the "help" command to get a list of available commands, then for more
detail on a particular command, use that command (or abbreviation) as an
argument to "help".  For example:

Command: > help decode

Will bring up detailed information on the decode command.
<--PAGEBREAK-->
Please note that almost all commands have one or more shortcuts - these are
listed in brackets after the command name in the help.

To get started quickly, make sure you read the context help for each menu,
and the following help options:

  ranges, filters, and decoder


Finally, the last command executed can be repeated by hitting the <Enter>
key.  For example, to page down we use the "next" command (or the "n"
abbreviation).  To continue paging down, simply hit the <Enter> key.

Have fun playing around.  Remember, you can't break anything!
EOT
  ;
}


=item help_decoder

Help on the decoder program.

=cut

sub help_decoder {
  my $self	= shift;
  $self->print_help( <<"EOT" );
Decoder Program (ponfishd) Help
-------------------------------
***The decoder program, ponfishd, must be running to read news***

The DECODER program (ponfishd) is responsible for all communications to and
from the configured news servers.  In other words, any time you want to decode
a file, download newsgroup lists, or download headers, the decoder is doing
the work.

What this means is the READER (ponfishr) does no network work.  Instead it
passess commands to the decoder.  The decoder services these commands in the
manner it sees fit, and when resources are available, meaning that often
some requests take longer to complete than others.  Usually the result of
a command results in data being downloaded and saved to a file, which, when
complete, the reader can then use.  Let me use an example to illustrate:

Using the reader and in the Server menu, I issue a sync command to download
the newsgroup list for a server.  The request is saved as a file in a
special place.  Assuming the decoder is running, the file will be noticed
by the decoder and placed in a priority queue.  When the command reaches
the head of the queue, it will be serviced, and the newsgroup list will be
updated/downloaded and saved to a particular location.  Once the data has
been saved, you can access the data from the reader.
<--PAGEBREAK-->
Decode Directory
----------------
All binaries are decoded to $Global::DECODE_DIR.  You can come here to
see the results of your downloads.

This also happens to be the directory that all the command files are
placed into.  They all begin with a dot ".".

Because the commands are files, they will persist until deleted or moved.
This means this data will persist until they are serviced by the decoder
or are manually removed.
<--PAGEBREAK-->
Decode Queues
-------------
The decoder can be set up to have multiple download threads to maximize
bandwidth, but I feel the magic number is 3 - any more and latency might
start to become an issue.

The decoder maintains one queue that these threads use to get commands
from.  The items are arranged in the queue by priority, as follows:

Highest
  - Server sync (download newsgroup list).
  - Newsgroup sync (download article headers).
  - Previews (decode a binary with priority).
  - Decodes and saves, prioritized according to date - oldest first.
Lowest

You might encounter latency issues when your threads are all busy
with large binaries, as a thread will only go back to the queue once
it has fully completed it's previous command.  In other words, higher
priority commands will not preempt an already executing command.
<--PAGEBREAK-->
Decode Process
--------------
This is what happens when a decoded thread executes a decode command:

  1. The command is read - it gets information about what it should do
     from the command file.
  2. Each article in the command will be downloaded and saved.
  3. When all the articles are saved, they are decoded and joined to
     form the file you want.
  4. If there is a 'redirect' directory, the file will be moved to this
     directory.
  5. When complete, the command file is moved to the 'junk' directory.
EOT
;
}


=item help_misc

=cut

sub help_misc {
  my $self	= shift;
  $self->print_help( <<"EOT" );
EOT
;
}


=item help_searching

=cut

sub help_searching {
  my $self	= shift;
  $self->print_help( <<"EOT" );
Help on Searching
-----------------

FILTERING:

When you're looking for something, there's nothinge easier than filtering
your list using the filter, or "/" command.  For example, if you're looking
for butterfly pictures, you might want to use the command: "/butterfl", which
will match "butterfly" or "butterflies", or even "butterflub".

Get to know your regular expressions by using "help regexp".

SCANNING:

Scan forward through your list of articles or newsgroups using the scan
command.  For example, "scan popcorn" will position the list on the first
occurrence of the string "popcorn" from the current screen.

DATE SCANNING:

To scan forward to the first articles from August, use the command
"scan date aug".  For August 10th, try "scan date aug 10".  See the help
on "scan" for more info.
EOT
;
}

=item help_modifiers

=cut

sub help_modifiers {
  my $self	= shift;
  $self->print_help( <<"EOT" );
Help on Modifiers
-----------------

Modifiers allow you to add or remove things from your displayed list of
articles in ways typically only programmers use.  To begin, it is useful
to know what is going on behind the scenes:

Internally, two lists are stored in memory at any one time: the main list
and the filtered list.  The filtered list is always what is displayed
on the screen.

Any time you use the filter command, it filters from the main list, and
populates the filtered list.  This allows you to perform multiple filters
for different strings without having to re-load the data.  (main list)
This is good, but often we want to pare down the main list to rid ourselves
of articles we know we aren't interested in.  This is where the modifiers
come in.
<--PAGEBREAK-->
The modifiers are "++", "--", "+", and "-".  They prefix the following
commands:

  filter, fresher and older

The modifiers are as follows:

++ ADDS matching articles to the main list.
-- REMOVES matching articles from the main list.
+  REMOVES NON-matching articles from the filtered list.
-  REMOVES matching articles from the filtered list.

For example, to get rid of anything older than July 7th from any future
consideration:

  > ++ fresher jul 7
OR
  > -- older jul 7

The main list will be modified, removing any articles older than July 7.
To re-load these articles, you'll have to close and re-enter the
newsgroup, or use the "reload" command.
<--PAGEBREAK-->
Now let's say we want to find all subjects containing "Kennedy", but none
that contain "Jackie".  We can do so with two commands:

  > /kennedy
  > -/jackie

Now let's say we're only interested in the ones that were posted in July:

  > +fresher jul  (Keeps anything posted in and since July)
  > -fresher aug  (Removes anything posted in and since August)

Because we used the "+" and "-", and not the "++" and "--" modifiers,
the main list remains untouched, and we can get the entire list back
by using a filter command that matches everything:

  > /.

*** It is important to note that the "scan" command works on the
    filtered list!
EOT
;
}

=item help_regexp

=cut

sub help_regexp {
  my $self	= shift;
  $self->print_help( <<"EOT" );
Help on Regular Expressions  (A very brief introduction)
--------------------------------------------------------

Regular expressions are easy to use at their simplest.  You will use
regexps primarily with the filter command.  Since this program is written
in Perl, it uses the built-in Perl regular expression syntax.  For more
details, I suggest you consult the Perl Regexp manpage by executing
"man perlre" at the command prompt.

The filter command is best used with the "/" shortcut.  To search for a
string, you need only type the following:

  > /STRING


Example 1:
----------
For example, to search a list for anything matching "falafel", use:

  > /falafel

<--PAGEBREAK-->
Example 2:
----------
Now, let's say we're searching for the free game MechCommander, but we're
not sure if the game title is "MechCommander" or "Mech Commander".  We can
use the "?" operator, which means "zero or one of the previous character" to
match either with one filter:

  > /mech ?commander

Example 3:
----------
Now let's say we want to see only the image files in a newsgroup.  To do
this we'll use the "|" operator, which is the or-operator.  Image files
that end with .png .jpg .jpeg or .gif can be found like so:

  > /png|jpg|jpeg|gif

To combine what we've learned in Example 2 above with Example 3:

  > /png|jpe?g|gif

<--PAGEBREAK-->
Example 4:
----------
Now let's say we're interested in pictures of Johnny Depp (one of my favorite
actors).  We can use "Depp" as a search string, as there aren't many Depps
around, but there are likely many Johnnys that may result in a false match.
We want to match files like "Johnny Depp - Fear and Loathing 032.jpg":

  > /depp.*\.(jpg|jpeg|png|gif)

The above example contains four new concepts:

  .: matches any character.

  *: matches none or 1 or more of the previous character.

  \: escapes the following character, forcing it to be taken as
     a literal character.  In this example, we want to match the
     period before the file extension.

  (): grouping.

<--PAGEBREAK-->
Translated into English, the above regexp says:

  Match a string that contains "depp" followed by zero or more of any
  character, then a period, and either of "jpg", "jpeg", "png", or "gif".

Some examples of what will match:

  * johnny_depp.png
  * jdepp01.jpg
  * depp the hunky guy from sleepy hollow!  alabam.jpg

Some examples of what will NOT match:

  * depp is a hunk!
  * sleepy_hollow_02.jpg - Johnny Depp!
  * deppjpg

EOT
;
}

=item help_ranges

=cut

sub help_ranges {
  my $self	= shift;
  $self->print_help( <<"EOT" );
Help on Ranges
--------------

Many commands take ranges, like the decode, save, or sync commands.

A range can be a list of numbers separated by a space or comma:

  1,2,3,5,10

Or a contiguous range defined by two numbers separated by a dash or
two dots:  (note spaces are ignored)

  5..10  ==  5-10  ==  10-5  ==  5 6 7 8 9 10

Or a combination of the two:

  2-43, 48, 50-55

<--PAGEBREAK-->
By default ranges are limited to the number of visible options on
the screen.  This avoids accidentally attempting to download hundreds
or thousands of articles by mistake:

  > de 1-54 58-655

When you really wanted this:

  > de 1-54 58-65

To remove this limitation, you can use the "set" command to turn
the "nolimit" property to "on":

  > set nolimit on

Then you can download as much as you want using one command:

  > de 1-6000

See the help on "set" for more information.
EOT
;
}





=item help [COMMAND_NAME]

Help displays a list of available commands (and their summaries) or
detailed help if a valid COMMAND_NAME is specified.

=cut

sub help {
  my $self	= shift;
  my $abbrev	= lc shift || "";

  if( ! $abbrev ) {
    return $self->help_on_help;
  }
  if( $abbrev =~ /^general|here|decoder|ranges|regexp|modifiers|searching|misc$/ ) {
    # These are the built-in helps:
    my $sub_string	= "help_" . $abbrev;
    return $self->$sub_string();
  }

  else {
    # Here the argument may be a command:
    my $cmd_name	= $self->translate_command( $abbrev );
    if( ! $cmd_name ) {
      $self->pause( "Help: Invalid command: '$abbrev'\n\n" );
      return $const::cmd_error;
    }

    my %aci		= $self->all_command_info;
    use Data::Dumper;
#    print "($cmd_name)", Dumper( \%aci );
    my $cmd_info	= $aci{$cmd_name} || undef;
    if( ! $cmd_info ) {
      $self->pause( "Help > Command '$abbrev' not found!\n\n" );
      return $const::cmd_error;
    }
    else {
      my @abbrevs	= $self->get_abbrevs_for_command( $cmd_name );
      my $arg_text	= "";
      if( $cmd_info->{default} ) {
	$cmd_name	.= " (Default)"
      }
      if( $cmd_info->{index} ) {
	$arg_text	= "INDEX";
      }
      elsif( $cmd_info->{range} ) {
	$arg_text	= "RANGE";
      }
      if( $cmd_info->{redirect} ) {
	$arg_text	.= " [ > DIRECTORY_NAME ]"
      }
      if( $cmd_info->{arg_list} ) {
	$arg_text	.= " " . join(" ", @{$cmd_info->{arg_list}} );
      }
      if( $cmd_info->{modifier} ) {
	$cmd_name	= "[++|--|+|-] " . $cmd_name;
      }
      $arg_text		=~ s/^\s+//;
      $self->pause( "Help > '$abbrev' ($cmd_name):\n"
		    . "-" x 66 . "\n"
		    . "Usage:\n\n"
		    . "\t$cmd_name". " $arg_text". "\n\n"
		    . "Abbreviations: " . "\n\n\t" . join(", ", @abbrevs) . "\n\n"
		    . "Description:\n\n"
		    . $cmd_info->{full} . "\n"
		    . "-" x 66 . "\n"
		  );
      return $const::cmd_success;
    }
  }
}


sub pause {
  my $self	= shift;
  print shift || "";
  print "Press <Enter> to continue...";
  my $scalar	= <STDIN>;
  return $const::cmd_success;
}

sub show_settings {
  my $self	= shift;

  print Dumper( CONFIG->get_settings );
}



=item setting SNAME VALUE

 Examples:

setting date [ON|off]
setting poster [ON|off]
setting rhs 20
#setting visible_lines [ON|off]
setting vtype [bold|underline|none]

=cut

sub setting {
  my $self	= shift;
  my $setting	= shift;
  my $first_arg	= shift;	# Ignored for time being.

  my $cmd_str	= $self->{cmd_info}{cmd_str};
  my $full_arg	= $cmd_str;
  $full_arg	=~ s/^set\s+[\w\d]+\s+//i;

  my $errmsg	= CONFIG->set_setting( $setting, $full_arg );
  if( $errmsg ) {
    $self->errmsg( $errmsg );
    return $const::cmd_error;
  }
  else {
    return $const::cmd_success;
  }
}

sub is_setting_on {
  my $self	= shift;
  my $sname	= shift;
  if( CONFIG->get_setting( $sname ) eq "on" ) {
    return 1;
  }
  return 0;
}

sub get_setting {
  my $self	= shift;
  my $sname	= shift;
#  print "Setting: '$sname' => $self->{settings}{$sname}.\n";
  if( $self->{settings} ) {
    return $self->{settings}{$sname} || undef;
  }
  return undef;
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

sub menu_errmsg {
  my $self	= shift;
  print "-"x66,"\n";
  print @_;
  print "-"x66,"\n";
  $self->pause;
}

sub menu_msg {
  my $self	= shift;

  print @_;
}


=item global_command_abbrevs

Returns a set of command abbreviations that work across all Menu subclasses.

=cut

sub global_command_abbrevs {
  return %global_command_abbrevs;
}

=item command_abbrevs

Pure virtual function that gets the command abbrevs for the particular Menu
class.

=cut

sub command_abbrevs {
  die "command_abbrevs is pure virtual!";
}



=item translate_command CMD_OR_CMD_ABBREV

Translates an abbreviation to its full command name.
Returns UNDEF if no command could be found.

=cut

sub translate_command {
  my $self	= shift;
  my $cmd	= shift;

  my %aci	= $self->all_command_abbrevs;
#  print Dumper( \%aci );
  return $aci{$cmd} || undef;
}

sub quick_quit {
  my $self	= shift;
  exit 0;
}

sub quit {
  my $self	= shift;
#  system( "clear" );
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

Menu items are stack-like.  The first (root) Menu's close function could
well perform an exit - to exit the program, however most of the time you
want to close your current context, by way of returning the $const::cmd_exit.

=cut

sub close {
  return $const::cmd_exit;
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
  return $self->{TermSize}->resize( @_ );
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

=item interpret_command CMD_STR

Will parse CMD_STR and call the appropriate routine with the
appropriate arguments.

Certain special cases are handles, such as regexp filtering, +/- filtering,
default commands, etc.

=cut

sub interpret_command {
  my $self	= shift;
  my $cmd_str	= shift;

  # This hash holds all the command information:
  my %cmd_info	= (
		   cmd_str	=> $cmd_str,
		   command	=> "",
		   translated	=> "",
		   args		=> [],
		   redirect	=> "",
		   plus_minus	=> "",			# For +/- filtering!
		  );
  my @args     	= ();

  # Remove leading whitespace and leading +/-:
  $cmd_str	=~ s/^\s+//;			# Remove leading whitespace
  if( $cmd_str =~ /^([+-]+)/ ) {
    $cmd_info{plus_minus}	= $1;		# Store +/- filter
    $cmd_str	=~ s/^([+-]+)\s*//;		# remove from command string
  }

  # Check emtpy command string, re-play last command on empty string
  if( $cmd_str =~ /^\s*$/ ) {
    if( $self->{last_command} ) {
      #$cmd_str	= $self->{last_command} || return $const::cmd_unknown;
      @args	= $self->{last_command};
    }
    else {
      # Don't do anything:
      return $const::cmd_success;
    }
  }
  # Check for search string (/... == filter ...)
  elsif( $cmd_str =~ /^\s*(\/)(.*)/ ) {
    print "Filter: $1, $2\n";
    @args	= ("filter", $2);
  }
  else {
    # Command with arguments, and a possible redirection operator...
    # Split argument into 2 parts to handle output operator ">":
    my($c,$r)	= split /\>/, $cmd_str;
    @args	= map { trim $_ } split /\s+/, $c;
    $cmd_info{redirect}	= trim( $r||"" );
  }
  my $command		= trim shift @args;
  $cmd_info{command}	= $command;
  $cmd_info{args}	= \@args;
  $self->{cmd_info}	= \%cmd_info;

  use Data::Dumper;
  print Dumper( \%cmd_info );
  # A number triggers the default() routine:
  if( $command =~ /^\d+$/ or $command =~ /^[\d\s\-\.\,]+$/ ) {
    push @{$self->{cmd_info}{args}}, $command;
    return $self->default( @{$self->{cmd_info}{args}} );
  }

  my $translated	= $self->translate_command( $command );
  $cmd_info{translated}	= $translated;
  if( ! $translated ) {
    $self->menu_errmsg( "Invalid command:\n  |\n  `--> '$command' ($cmd_str)!\n\n" );
    return $const::cmd_unknown;
  }
  else {
    print ">>>$translated<<< (", join(",", @args), ")\n";
    $self->{last_command}	= $translated;
    return $self->$translated( @args );
  }
}




=item COMMON METHODS

=cut

sub next_page {
  my $self	= shift;
  my $pinfo	= $self->{pageinfo};
  my $lpp	= $pinfo->{lpp};

  if( $self->num_filtered > $lpp ) {	# Only if we have more items than can be displayed on one page...
    $pinfo->{currline}+= $lpp;
    $pinfo->{currline}	= min( $pinfo->{currline}, $self->num_filtered - $lpp - 0 );
  }
  return $const::cmd_success;
}

sub end {
  my $self	= shift;
  my $pinfo	= $self->{pageinfo};
  my $lpp	= $pinfo->{lpp};
  $pinfo->{currline}	= max( 0, $self->num_filtered - $lpp - 1 );
}



=item home

Go to the first page.

=cut

sub home {
  my $self	= shift;
  $self->{pageinfo}{currline}	= 0;
}



=item num_filtered

The number of filtered (displayable) items.

=cut

sub num_filtered {
  my $self	= shift;
  return scalar @{$self->{filtered}};
}


sub prev_page {
  my $self	= shift;
  my $pinfo	= $self->{pageinfo};
  $pinfo->{currline}-= $pinfo->{lpp};
  if( $pinfo->{currline} < 0 ) {
    $pinfo->{currline}	= 0;
  }
  return $const::cmd_success;
}



1;
