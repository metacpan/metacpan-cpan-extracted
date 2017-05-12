#!/usr/bin/perl

# ********************************************************
# URLToys, Perl-style and command-line driven by Joe Drago
# Now URLToys.pm, the Perl Module!
# 
# Version 1.28 - Updated 6/19/2004
#
# The ChangeLog is at the end of the documentation.
# ********************************************************

# Copyright (c) 2004, Joe Drago <joe@urltoys.com>
# All rights reserved.

# See the POD (Documentation) for all of the specifics. 

=pod

=head1 NAME

WWW::URLToys - gather and download URLs from URLs

=head1 SYNOPSIS

	use WWW::URLToys qw/:DEFAULT ut_command_loop/;
	my @utlist;
	$SIG{'INT'} = 'ut_stop_download';
	if(@ARGV > 0)
	{
	    my $initial_command = join ' ',@ARGV;
	    ut_exec_command($initial_command,\@utlist);
	};
	ut_command_loop(*STDIN,\@utlist);

=head1 DESCRIPTION

WWW::URLToys is a separation of the program URLToys into its core code (this
module), and the programs that use it (urltoys and urltoysw). This module has
been made available via CPAN to allow others to use URLToys commands on their
Perl arrays, and to create interfaces for URLToys that far surpass those of 
the original creator.

=head1 METHODS

=head2 ut_exec_command

	@result = ut_exec_command("make",\@somearray);

Exported by default, this command runs any single URLToys command on a list,
and returns the list that the command would expect it to return.

=head2 ut_command_loop

	ut_command_loop($filepointer,\@list);

This will execute a string of commands from any file pointer. If the file
pointer is the standard input, it will prompt the user to type in commands
with the URLToys command prompt.

=head2 ut_stop_download

	ut_stop_download();

This command will stop a download. Useful for stopping a command while inside
a callback or Tk callback (if you use a GUI).

=head2 loadconfig

	loadconfig("filename");

Loads a URLToys configuration from a file.

=head2 saveconfig

	saveconfig("filename");

Saves the current URLToys configuration to a file.

=head1 CALLBACKS

All callbacks are set via the %ut_callback hash. Setting any of the keywords
for the callbacks to a sub of your own, you override the callback and receive
it instead. All of them are sent 3 variables: which callback, value1, and 
value2.

An example:

	sub print_text { my ($type,$text,$ignored) = @_; print $text; };
	$ut_callback{'print'} = \&print_text;

Here is a list of them:

	Callback                 Description                                  Calls by Default     Value 1                  Value 2
	print                    Called with the 'print' command              cb_tty               text to print            Ignored
	extra                    Things that can safely be ignored            cb_tty               text to print            Ignored
	help                     Syntax Help                                  cb_tty               text to print            Ignored
	error                    Error Messages                               cb_tty               text to print            Ignored
	action                   Explains the current action                  cb_ignore            Current action text      Ignored
	makeupdate               Text explaining what 'make' is doing         cb_tty               text to print            Ignored
	dlbeat                   Sent when download of unknown size gets data cb_dlbeat            Ignored                  Ignored
	dlupdate                 Text explaining what 'get' is doing          cb_tty               text to print            Ignored
	output                   Regular output Text by program               cb_tty               text to print            Ignored
	title                    Sets the title of the window                 cb_title             text for window title    Ignored
	warnuser                 BADFLUX: Returns 1 on allow, 0 on no allow   cb_warnuser          ref to array of bad cmds Ignored
	variable                 Updates a variable to the main script        cb_ignore            variable name            value of variable
	complete                 When a get or resume finishes                cb_ignore            directory that finished  Ignored
	begin                    When a get or resume starts                  cb_ignore            directory its coming to  Ignored

The return value of the callbacks are ignored except the "warnuser" one, which
is to warn a user on a potentially bad flux. It's very important that this
returns a 0 if the user does not wish to run the flux! You must override this
if you create a GUI flux. Please see urltoysw for an example.

=head1 VARIABLES

	$config_file
	$config_useragent
	$config_ext_regex
	$config_ext_ignore
	$config_custom_headers
	$config_href_regex
	$config_img_regex
	$config_prompt
	$config_name_template
	$config_save_url_list
	$config_explain_regex_error
	$config_useundo
	$config_use_xttitle
	$config_pausetime
	$config_downloaddir
	$config_dirslashes
	$config_seq_warning_size
	$config_proxy

These are all given by the EXPORT tag "configvars", except $config_file, which is
exported by default.

=head1 Undocumented

As of yet the actions returned by the action callback, and the variables set by the
'variable' callback are undocumented.

=cut


package WWW::URLToys;

use strict;

# Standard Perl denotation for Version
our $VERSION = "1.28";

# How URLToys refers to its Version
my $URLTOYS_VERSION = "URLToys Version 1.28 (6/19/2004)";

use Exporter;

our @ISA       = qw/Exporter/;

our @EXPORT    = 	qw/
						ut_exec_command
						%ut_callback
						ut_stop_download
						$ut_get_dir
						$urltoys_dir
					/;

our @EXPORT_OK = 	qw/
						$VERSION
						$URLTOYS_VERSION

						ut_command_loop
						ut_getlinks_array

						$ut_term
						ut_getnextline

						loadconfig
						saveconfig

						$config_file
						$config_useragent
						$config_ext_regex
						$config_ext_ignore
						$config_custom_headers
						$config_href_regex
						$config_img_regex
						$config_prompt
						$config_name_template
						$config_save_url_list
						$config_explain_regex_error
						$config_useundo
						$config_use_xttitle
						$config_pausetime
						$config_downloaddir
						$config_dirslashes
						$config_seq_warning_size
						$config_proxy
					/;

our %EXPORT_TAGS = 	(configvars => [
					qw/
						$config_file
						$config_useragent
						$config_ext_regex
						$config_ext_ignore
						$config_custom_headers
						$config_href_regex
						$config_img_regex
						$config_prompt
						$config_name_template
						$config_save_url_list
						$config_explain_regex_error
						$config_useundo
						$config_use_xttitle
						$config_pausetime
						$config_downloaddir
						$config_dirslashes
						$config_seq_warning_size
						$config_proxy
					/]);


# libwww for Perl ... the heart of URLToys
use LWP;

# Used by the 'cookies' command
use HTTP::Cookies;

# Used to help parse out a few things and make the URL pretty
use URI::URL;

# Used in the command line version, unless sufficiently hooked

my $using_tk = (exists $INC{'Tk.pm'});

unless($using_tk)
{
	require Term::ReadLine;
	import Term::ReadLine /new/;

	# Otherwise Windows complains
	$Term::ReadLine::termcap_nowarn = 1;
}

# Used by the 'password' command
use MIME::Base64;

# Used throughout the code, most notably with 'pwd' and 'cwd'
use Cwd;

# Built-in Help Text ... YES THIS IS UGLY! 

my %helplines = (
	add          => "This adds URL to the end of the list. Example:\nadd http://www.example.com/",
	append       => "Loads a list without clearing current list, i.e.\nappend somefile.txt",
	autorun      => "The heart of .flux is 'autorun'. This command executes a flux file.\n\nautorun somefile.flux",
	
	batch        => "Starts a batch session. It'll ask you for URLs until you type 'end', then\nit will perform whatever command you typed after the batch command, i.e.\n\nbatch fusker\n[batch][0] http://www.example.com/[01-10].jpg\n[batch][2] end\n\n... is like typing \"fusker http://www.example.com/[01-10].jpg\". \nSee docs for more details.",
	
	batchcurrent => "Like batch, but instead of asking for a list, it'll use the current list.\n\nSee batch.",
	cd           => "Changes current directory.",

	config       => "Either shows, loads, or saves the configuration to the standard file. Possibilities:\n\nconfig show\nconfig save\nconfig show\n\nSee docs for details.",

	clear        => "Clears the screen.",
	cls          => "Clears the screen.",
	cookies      => "Turns on the usage of cookies when talking to a web server.\nThe cookies will be maintained across\nmultiple conversations for the duration of the program.\n\ncookies\ncookies on\ncookies off\ncookies clear",
	del          => "Deletes list entries that match a regular expression. For example:\n\ndel urltoys\n\n...will delete all URLs with the word 'urltoys' in it.\n\nSee docs for more info.",
	flux         => "The heart of .flux is 'autorun'. This command executes a flux file.\n\nflux somefile.flux",
	
	keep         => "Just like the del command, only it keeps the matching lines other than\nremoving them. See the docs or the 'del' help.",

	delh         => "Deletes the first N lines of a list.\n\ndelh 10",
	keeph        => "Keeps only the first N lines of a list.\n\nkeeph 10",
	delt         => "Deletes the last N lines of a list.\n\ndelt 10",
	keept        => "Keeps only the last N lines of a list.\n\nkeept 10",
	exit         => "Exits URLToys immediately.",
	
	fixparents   => "Fixes parent-ridden URLs. Turns URLs from:\n\nhttp://www.example.com/a/../1.jpg\nto\nhttp://www.example.com/1.jpg\n",

	fusker       => "Create list from fusker string.\n\nSee documentation.",
	fusk         => "Create list from fusker string.\n\nSee documentation.",
	get          => "Downloads list (with optional size requirement)\n\nget\nget +100k\nget -1000k\n\nSee docs.",
	header       => "Adds a custom header to all conversations.\n\nheader Referer: http://www.somesite.url/\nheader Authorization: Basic ...\nheader -d Referer",
	help         => "Shows the command list, or detailed help for a command.\n\nhelp\nhelp [commandname]",
	h            => "Shows the command list, or detailed help for a command.\n\nhelp\nhelp [commandname]",
	
	history      => "Queries the command history. You can view, save, or clear the\ncommand history.\n\nhistory show\nhistory save somefile.txt\nhistory clear",

	keepuni      => "Removes all entries listed more than once, INCLUDING the first one. This\ndiffers from nodupes because nodupes keeps at least one copy.",

	lip          => "Keep only last numbered URL in a series.\n\nSee Docs.",
	load         => "Loads a URL list from a file.\n\nload somefile.txt",
	
	make         => "Generates a list of URLs, based on an optional custom regex.\nBy default, make uses the built-in href regex.\n\nmake\nmake someregex\n\nSee docs.",
	
	href         => "Generates a list of URLs, using the regular link finding regex.",
	hrefimg      => "Generates a list of URLs, using the regular link finding regex\nand the IMG tag regex at the same time.",
	img          => "Generates a list of URLs, using the IMG tags from the HTML pages.",
	makeregex    => "Forces URLToys to only process the URLs matching this regex.\n\nSee the documentation!",
	needparam    => "This is for script creation.\nSee the documentation.",
	nodupes      => "Removes all duplicate entries from the list, leaving only the originals.",
	nsort        => "Sorts list, being careful to count the last number properly.\n\nSee sort as another possibility.",
	password     => "Add username/password combo for a site.\n\npassword [domain] [username] [password]",
	pwd          => "Prints the current working directory.",
	resume       => "Resumes a partially downloaded list. You give it the directory its in:\n\nresume 00005\nresume someothername",
	save         => "Save the list to a file.\n\nsave somefile.txt",
	saveflux     => "Save the list to a flux file by attempting to combine as many lines as possible into fusker lines.\n\nsaveflux somefile.flux",
	spider       => "Takes a parent URL and runs through all sub-URLs of that URL,\nfinding all IMG and A tags. \n\nspider",
	system       => "Executes a system command.\n\nsystem dir\nsystem del somefile.txt",
	systemw      => "Executes a system command, but only if in Windows.\n\nsystemw dir\nsystemw del somefile.txt",
	systemu      => "Executes a system command, but only if in Unix/OSX.\n\nsystemu dir\nsystemu del somefile.txt",
	seq          => "Build from numerical sequence.\n\nSee the documentation on this one.",
	zeq          => "Build from numerical sequence.\n\nSee the documentation on this one.",
	set          => "Sets configuration variables.\nYou can see all variables by typing 'set' alone.\n\nset\nset SomeVariable=SomeValue",
	show         => "Shows the current URL list in its entirety,\nor just those matching a regex.",
	list         => "Shows the current URL list in its entirety,\nor just those matching a regex.",
	ls           => "Shows the current URL list in its entirety,\nor just those matching a regex.",
	
	size         => "Asks the web servers about each URL for their size, then\nonly keeps those in your size range.\n\nsize +100k\nsize -1000k\n\nSee the documentation.",
	
	head         => "Shows the beginning N URLs of the list.\n\nhead 10",
	tail         => "Shows the last N URLs of the list.\n\ntail 10",
	print        => "Writes text to the screen.\nUsually used in scripts.\n\nprint Hello World!",
	replace      => "Replaces text with new text.\nUse rreplace for regex replacement, or\nstrip to replace with nothing.\n\nreplace thisword withthisone",
	rreplace     => "Replaces text with new text.\nUse replace or strip for nonregex replacement.\n\nrreplace /someregex/somevalue/",
	sort         => "Sorts the list, using Perl's built-in sort.\nSee nsort for another possibility.",
	strip        => "Strips unwanted text from all URLs in the list.\n\nstrip thistextout",
	title        => "Sets the title bar of the program. Used in scripts usually.",
	u            => "Undoes the last list-changing command.",
	undo         => "Undoes the last list-changing command.",
	version      => "Shows the version number, which happens to be:\n\n$URLTOYS_VERSION\n\nHA! RUINED THAT FOR YOU!",
);


# **** GLOBAL INITS ***********************

our $urltoys_dir = $ENV{"HOME"} . "/.urltoys";
our $config_file = $ENV{"HOME"} . "/.urltoys/config";

# These are the globals that can be saved to the config, and set with "set"
our $config_useragent = "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; .NET CLR 1.0.3705)";
our $config_ext_regex = "htm|html|exe|php|cgi|pl|shtml|asp|pl|cgi|stm|jsp";
our $config_ext_ignore = "jpe?g|gif|png|tga|mov|avi|mpe?g|rm|bmp|mp3|ogg|wav|exe";
our $config_custom_headers = 'Referer: %URL';
our $config_href_regex = qr/[Hh][Rr][Ee][Ff]='?"?([^'"<>]+)/;
our $config_img_regex = qr/[Ss][Rr][Cc]='?"?([^'"<>]+)/;
our $config_prompt = 'URLToys (%COUNT)> ';
our $config_name_template = '%COUNT-%NAME';
our $config_save_url_list = 1;
our $config_explain_regex_error = 0;
our $config_useundo = 1;
our $config_use_xttitle = 0;
our $config_pausetime = 0;
our $config_downloaddir = "";
our $config_dirslashes = "/";
our $config_seq_warning_size = 5000;
our $config_proxy = "";

# If this is set, the next 'get' will use this instead of enumerating
our $ut_get_dir = "";

my  $temp_dl_ext = ".utdl";

my $fluxvarupdate = 0;
my $fluxlines = 0;

# NEVER CHANGE THIS! Warnings are good.
my $warn_on_autorun = 1;

# Used for animating the bar on an unknown length
my $animate_pulse = 0;
my $animate_add   = 10;

# Match anything by default
my $makeregex = ".*";

# From 1.15: The password hash. $passwords{domain} = base64 encoded user/pass;
my %passwords;

# "The" command history (as of 1.13)
my @history = ();
my $pulledfromundo = "";
my $fromstdin = 0;

my $loop_readptr = *STDIN;

# Added 1.08
my @undolist = ();

# Used when downloading a file ... callbacks plus recursion = fun!
my $stop_getting_links;
my $current_file;
my $current_k;
my $download_count;
my $download_total;
my $dir;

my $badsize;
my $dlsize;

my $file_complete;
my $resume_spot;

# Version 1.24 ... for 'header' command
my %headers = ();

sub KEEPALIVECOUNT() { 10 };

# Used for custom command parameters .. an array of array refs
my @params;

# Cookie support, very special use
my $use_cookies = 0;
my $cookies = HTTP::Cookies->new;

my @current_action = ('idle'); # Used like a stack

# Makes my stuff "pipin' hot", AKA no buffering... otherwise that whole "command prompt" would suck.
$| = 1;

our ($ut_term,$OUT);
$ut_term = 0;

sub createterm
{
	unless($using_tk)
	{
		# Moved to global in 1.22 to fix Segfaults in Linux
		$ut_term = new Term::ReadLine "URLToys";
		$OUT = $ut_term->OUT || \*STDOUT;
		$ut_term->ornaments(0);
	}
}

# Version 1.10 Win32 Detection
my $win32 = 0;
$win32 = 1 if($^O =~ m/Win/);

our %ut_callback = (
			output       => \&cb_tty,
			print        => \&cb_tty,
			help         => \&cb_tty,
			error        => \&cb_tty,
			extra        => \&cb_tty,
			
			makeupdate   => \&cb_tty,
			dlupdate     => \&cb_tty,
			
			title        => \&cb_title,
			
			dlbeat       => \&cb_dlbeat,
			
			warnuser     => \&cb_warnuser,
			
			action       => \&cb_ignore,
			endaction    => \&cb_ignore,
			variable     => \&cb_ignore,
			begin        => \&cb_ignore,
			complete     => \&cb_ignore,
		);

# **** CALLBACK FUNCTIONS *********************

# This is a cb that is called when the downloader has no idea how large the content is
sub cb_dlbeat
{
	my ($type,$text,$ignored) = @_;
	print "*";
	return 0;
}

# This is the default callback for when the window's Title needs to be set
sub cb_title
{
	my ($type,$text,$ignored) = @_;
	set_title_bar($text) if($config_use_xttitle);
}

# This is for cb's that are ignored by default, but can be overridden
sub cb_ignore
{
	my ($type,$text,$ignored) = @_;
	return 0;
}

# Generic printing callback
sub cb_tty
{
	my ($type,$text,$ignored) = @_;
	print $text;
	return 0;
}

# Generic warning ... please override for a GUI app with a suitable Tk version
sub cb_warnuser
{
	my ($type,$warnlist,$ignored) = @_;

	return 1 unless($warn_on_autorun);

	print "*******************************************************************\n";
	print "* WARNING !!!\n";
	print "* These are potentially dangerous commands in this script:\n* --\n";

	foreach my $cmd (@$warnlist)
	{
		chomp($cmd);
		print "* $cmd\n";
	}

	print "* --\n";
	print "* If you understand what these lines do, and trust the \n";
	print "* source of the .flux file, say yes. Otherwise, say no, and\n";
	print "* contact the creator of this file for an explanation.\n";
	print "* IF YOU SAY YES AND YOUR MACHINE IS COMPROMISED -- BLAME YOURSELF\n";
	print "*******************************************************************\n\n";

	my $prompt = "Would you like to run this script? ['yes' or 'no'] ";

	while(1)
	{
		my $text = ut_getnextline(*STDIN,$prompt);
		return 0 if($text =~ m/^no$/i);
		return 1 if($text =~ m/^yes$/i);
	};

	return 0;
}

# Callback wrapper for the rest of the module
sub cb
{
	my ($which, $v1,$v2) = @_;
	return &{$ut_callback{$which}}($which,$v1,$v2);
}

# **** ACTION STATEMENTS **********************

sub setaction
{
	my $action = shift;
	unshift @current_action, $action;
	cb('action',$action,0);
}

sub endaction
{
	my $oldaction = shift @current_action;
	
	# A failsafe
	@current_action = ('idle') if(@current_action < 1);

	my $action = $current_action[0];
	cb('endaction',$oldaction,0);
	cb('action',$action,0);
}

# **** CONFIG FUNCTIONS ***********************

# Takes a line like "UserAgent=Someone" and sets the proper $config
sub handleconfigline
{
	my $which = shift;
	my $what  = shift;

	chomp($what);
	$what =~ s/\r+$//;

	$config_useragent 			= $what if($which =~ /^useragent$/i);
	$config_ext_regex 			= $what if($which =~ /^extensionregex$/i);
	$config_ext_ignore 			= $what if($which =~ /^extensionignore$/i);
	$config_custom_headers 		= $what if($which =~ /^customheaders$/i);
	$config_href_regex 			= $what if($which =~ /^hrefregex$/i);
	$config_img_regex 			= $what if($which =~ /^imgregex$/i);
	$config_prompt 				= $what if($which =~ /^prompt$/i);
	$config_name_template 		= $what if($which =~ /^nametemplate$/i);
	$config_save_url_list 		= $what if($which =~ /^SaveURLList$/i);
	$config_explain_regex_error = $what if($which =~ /^ExplainRegexError$/i);
	$config_useundo             = $what if($which =~ /^UseUndo$/i);
	$config_use_xttitle         = $what if($which =~ /^UseXTTitle$/i);
	$config_pausetime           = $what if($which =~ /^PauseTime$/i);
	$config_downloaddir         = $what if($which =~ /^DownloadDir$/i);
	$config_dirslashes          = $what if($which =~ /^DirSlashes$/i);
	$config_seq_warning_size    = $what if($which =~ /^SeqWarningSize$/i);
	$config_proxy               = $what if($which =~ /^Proxy$/i);
}

sub loadconfig
{
	my $configfile = shift;

	if (-e $configfile)
	{
		open(CONFIG,$configfile);
		CONFIGLOOP: while(<CONFIG>)
		{
			next CONFIGLOOP if /^#/;
			
			if(m/^([^=]+)=(.*)$/)
			{
				my $which = $1;
				my $what  = $2;

				handleconfigline($which,$what);
			}
		}
		close(CONFIG);
	}
}

sub saveconfig
{
	my $filename = shift;
	my $print_config_file = shift;

	open(CONFIGFILE,"> $filename") or return;

	print CONFIGFILE "UserAgent=$config_useragent\n";
	print CONFIGFILE "ExtensionRegex=$config_ext_regex\n";
	print CONFIGFILE "ExtensionIgnore=$config_ext_ignore\n";
	print CONFIGFILE "CustomHeaders=$config_custom_headers\n";
	print CONFIGFILE "HrefRegex=$config_href_regex\n";
	print CONFIGFILE "ImgRegex=$config_img_regex\n";
	print CONFIGFILE "Prompt=$config_prompt\n";
	print CONFIGFILE "NameTemplate=$config_name_template\n";
	print CONFIGFILE "SaveURLList=$config_save_url_list\n";
	print CONFIGFILE "ExplainRegexError=$config_explain_regex_error\n";
	print CONFIGFILE "UseUndo=$config_useundo\n";
	print CONFIGFILE "UseXTTitle=$config_use_xttitle\n";
	print CONFIGFILE "PauseTime=$config_pausetime\n";
	print CONFIGFILE "DownloadDir=$config_downloaddir\n";
	print CONFIGFILE "DirSlashes=$config_dirslashes\n";
	print CONFIGFILE "SeqWarningSize=$config_seq_warning_size\n";
	print CONFIGFILE "Proxy=$config_proxy\n";
	close(CONFIGFILE);
}

sub showconfig
{
	my $filename = shift;
	my $print_config_file = shift;

	cb('output',"UserAgent=$config_useragent\n",0);
	cb('output',"ExtensionRegex=$config_ext_regex\n",0);
	cb('output',"ExtensionIgnore=$config_ext_ignore\n",0);
	cb('output',"CustomHeaders=$config_custom_headers\n",0);
	cb('output',"HrefRegex=$config_href_regex\n",0);
	cb('output',"ImgRegex=$config_img_regex\n",0);
	cb('output',"Prompt=$config_prompt\n",0);
	cb('output',"NameTemplate=$config_name_template\n",0);
	cb('output',"SaveURLList=$config_save_url_list\n",0);
	cb('output',"ExplainRegexError=$config_explain_regex_error\n",0);
	cb('output',"UseUndo=$config_useundo\n",0);
	cb('output',"UseXTTitle=$config_use_xttitle\n",0);
	cb('output',"PauseTime=$config_pausetime\n",0);
	cb('output',"DownloadDir=$config_downloaddir\n",0);
	cb('output',"DirSlashes=$config_dirslashes\n",0);
	cb('output',"SeqWarningSize=$config_seq_warning_size\n",0);
	cb('output',"Proxy=$config_proxy\n",0);
}

# *** UTILITY FUNCTIONS *********************************

sub set_title_bar
{
	my $text = shift;
	system("xttitle \"$text\"");
}

# Recursive mkdir, a modified code snippet from a newsgroup
sub makedir 
{   
    my $Dir = shift;

	$Dir =~ s/\/$//;

    unless (-d $Dir) 
	{
		my $Parent = $Dir;
		$Parent =~ s/\/[^\/]+$//;
			
		makedir($Parent) unless $Parent eq '';
		mkdir($Dir);
	}
}

# **** HELP FUNCTIONS ******************************************

sub getcustomsyntax
{

	my $which = shift;

	my $filename = $ENV{"HOME"} . "/.urltoys/$which.u";

	my $helpline = '';

	my $commentptr;
	if(open($commentptr,$filename))
	{	
		my $temp = <$commentptr>;
		$helpline = $1 if($temp =~ m/^#\s+(.*)$/);
		close($commentptr);
	}

	return $helpline;
}

sub customcmdslist
{
	my $customloc = $ENV{"HOME"} . "/.urltoys/*.u";
	my @files = glob $customloc;
	my @ret = ();

	for my $filename (sort @files)
	{
		if($filename =~ m/\/([^\/.]+)\.u$/i)
		{
			my $text = $1;
			push @ret, $text;
		}
	}

	return @ret;
}

# Printed when someone types in "help" or "h", or "help command"
sub helpsyntax
{
	my $which = shift;

	if($which)
	{
		if($helplines{$which})
		{
			my $text = $helplines{$which};
			$text =~ s/\n/\n\t/gis;
			$text = "$which:\n\t" . $text . "\n\n";
			cb('help',$text,0);
		}
		else
		{
			my $syntax = getcustomsyntax($which);
			if($syntax)
			{
				my $text = $syntax;
				$text =~ s/\n/\n\t/gis;
				$text = "$which:\n\t" . $text . "\n\n";
				cb('help',$text,0);
			}
			else
			{
				cb('error',"No help available for $which.\n",0);
			}
		}
	}
	else
	{
		my @ar = customcmdslist;
		my @helplist = keys %helplines;
		push @helplist, @ar;

		cb('help',"\nType \"help command\", where command is one of these words: \n\n",0);

		# The following code is in the Perl Cookbook ... thanks!
		# Obviously it's been altered for callback-osity

		my ($item, $cols, $rows, $maxlen);
		my ($mask, @data);

		$maxlen = 1; 
		for(sort @helplist) {
	    	my $mylen;
		    s/\s+$//;
		    $maxlen = $mylen if (($mylen = length) > $maxlen);
		    push(@data, $_);
		}

		$maxlen += 1;    # to make extra space

		# determine boundaries of screen
		$cols = 5;
		$rows = int(($#data+$cols) / $cols);

		# pre-create mask for faster computation
		$mask = sprintf("%%-%ds ", $maxlen-1);

		# now process each item, picking out proper piece for this position
		my $outputline = '';

		for ($item = 0; $item < $rows * $cols; $item++) {
		    my $target =  ($item % $cols) * $rows + int($item/$cols);
		   	my $piece = sprintf($mask, $target < @data ? $data[$target] : "");
		    $piece =~ s/\s+$// if (($item+1) % $cols == 0);  # don't blank-pad to EOL
		    $outputline .= $piece;
		    if (($item+1) % $cols == 0)
			{
				$outputline .= "\n";
				cb('help',$outputline,0);
				$outputline = '';
			}
		}

		# finish up if needed
	    if (($item+1) % $cols == 0)
		{
			$outputline .= "\n";
			cb('help',$outputline,0);
		}
	
		cb('help',"\nRead http://www.urltoys.com/pod.html\n\n",0);
	}
}

# Sets up the next download folder, and increments value in nextdir.txt
sub checkdir
{

	my $nextdirfile = open(NEXTDIR,"<nextdir.txt");
	my $current_folder = 0;
	
	if(defined $nextdirfile)
	{
		$current_folder = <NEXTDIR>;
		close(NEXTDIR);
	}

	my $nextdirfileout = open(NEXTDIR,">nextdir.txt");

	if(defined $nextdirfileout)
	{
		print NEXTDIR $current_folder+1;
		close(NEXTDIR);
	}

	$dir = sprintf("%.5d",$current_folder);
	mkdir($dir);
}


# Turns:
# http://somesite.url/a/b/../1.jpg
# into
# http://somesite.url/a/1.jpg

sub fixparents
{
	my $url_list = shift;

	foreach my $url (@$url_list)
	{
		if($url =~ m!(http://[^/ ]+(?:/[^/]+)*/)(\.\./.+)!i)
		{
			my $urlclass = url $2;
			$url = $urlclass->abs($1);
		}
	}
}

# Added 1.07 -- This checks for a typo in a regex without crashing URLToys
sub test_regex
{
	my $regex = shift;

	if(!$regex)
	{
		return 1;
	}

	my $testtextforregex = "http://www.somesite.url/somefile.something";
	my $testregex= '$testtextforregex =~ m/$regex/gis';

	eval $testregex;
	if($@)
	{
		if($config_explain_regex_error)
		{
			cb('error',"Error parsing regex. Details:\n\t$@",0);
		}
		else
		{
			cb('error',"Error parsing regex. Please review it for errors and try again.\n",0);
		}
		return 0;
	}

	# Its OK.
	return 1;
}

# *** LINK GRABBING / HTTP / DOWNLOADING FUNCTIONS ********

# addcustomheaders will set up any HTTP::Request for usage
sub addcustomheaders
{
	my($req,$url,$host) = @_;

	my %final_headers = ();

	# Add custom headers here
	my @headerlist = split(/\|/,$config_custom_headers);

	foreach my $header (@headerlist)
	{
		if($header =~ /^(.+): (.+)$/)
		{
			my $which = $1;
			my $what = $2;
			
			$final_headers{$which} = $what;
		}
	}

	my $domain = $host;
	my $pwheader;
	
	for my $key (keys %passwords)
	{
		if($domain =~ m/$key/)
		{
			$pwheader = $passwords{$key};
			last;
		}
	}

	if($pwheader)
	{
		$final_headers{"Authorization"} = "Basic $pwheader";
	}

	foreach my $headercmdkey (keys %headers)
	{
		# The header command overrides any default headers
		$final_headers{$headercmdkey} = $headers{$headercmdkey};
	}

	foreach my $key (keys %final_headers)
	{
		my $a = $key;
		my $b = $final_headers{$key};
		
		# Add other custom header variables here (and one other place)
		$b =~ s/%URL/$url/;
		$b =~ s/%DOMAIN/$host/;
		
		$req->header($a => $b);
	}
}

# Sets up proxy, turns on cookies if need be
sub setupagent
{
	my $useragent = shift;
	
	$useragent->proxy('http',$config_proxy)
		if(length $config_proxy > 0);

	$useragent->cookie_jar($cookies) if ($use_cookies);
}

sub ext_and_parent
{
	my $url = shift;
	my $parent;
	my $parent_abs;
	my $extension;

	if($url =~ m/\/$/)
	{
		$parent = $url;
		$extension = "";

		if($url =~ m/(http:\/\/[^\/]+).*$/i)
		{
			$parent_abs = $1;
		}

	}
	else
	{
		if($url =~ m/(http:\/\/.+\/)[^\/?]+\.([^\/?&]+)(\?[^\/]+)?/i)
		{
			$parent = $1;
			$extension = $2;
		}

		if($url =~ m/(http:\/\/[^\/]+).*$/i)
		{
			$parent_abs = $1;
		}
	}

	return ($parent,$parent_abs,$extension);
}

sub SKIPEXT_HTML() { 0 };
sub SKIPEXT_NOTHTML() { 1 };
sub SKIPEXT_IGNORED() { 2 };

sub skipext
{
	my $ext = shift;
	my $ret = SKIPEXT_HTML; # Dont skip by default

	unless($ext =~ m/$config_ext_regex/i)
	{
		$ret = SKIPEXT_NOTHTML;
	}
	else
	{
		if($ext =~ m/$config_ext_ignore/i)
		{
			$ret = SKIPEXT_IGNORED;
		}
	}

	return $ret;
}

# getlinks is the heart of all of of the "make" functions

sub getlinks
{
	my $useragent = shift;
	my $argurl = shift;
	my $regexarray = shift;
	my $count = shift;
	my $total = shift;

	my $parent;
	my $parent_abs;

	my $url_pieces = url $argurl;
	my @lines;

	# This will tack on the trailing slash if need be
	my $url = $url_pieces;

	my $extension;
	my $extension_allowed = 0;

	# Figure out the parent URL here
	
	($parent,$parent_abs,$extension) = ext_and_parent($url);

	if($extension)
	{
		my $se = skipext($extension);

		if($se == SKIPEXT_NOTHTML)
		{
			cb('makeupdate',"Skipping ($count/$total) \"$url\". ($extension not HTML)\n",0);
			push(@lines,$url);
			return @lines;
		}
		elsif($se == SKIPEXT_IGNORED)
		{
			cb('makeupdate',"Skipping ($count/$total) \"$url\". ($extension ignored)\n",0);
			push(@lines,$url);
			return @lines;
		}
	}

	cb('makeupdate',"Searching ($count/$total) \"$url\"...",0);
	
	my $req = HTTP::Request->new(GET => $url);

	addcustomheaders($req,$url,$url_pieces->host);

	my $res = $useragent->request($req);

	if($res->is_success)
	{
		my $html = $res->content;

		for my $regex(@$regexarray)
		{

			while($html =~ m/$regex/gis)
			{
				my $link = $1;

				if($link =~ m/^\//)
				{
					$link = $parent_abs . $link;
				}
				else
				{
					# Tacks on the parent portion of the url for a relative link
					unless($link =~ m/^http:\/\//)
					{
						# These two lines will change things like "/a/b/../1.jpg" to "/a/1.jpg"
						my $tempurl = url $link;
						$link = $tempurl->abs($parent);
					}
				}

				push(@lines,$link);
			} # while
		} # for

	}

	my $foundlines = @lines . " found.\n";
	cb('makeupdate',$foundlines,0);
	return @lines;
}

sub ut_getlinks_array
{
	my $list = shift;
	my $regexarray = shift;

	my @final_list;
	my $link;

	for my $regex(@$regexarray)
	{
		return @$list if(!test_regex($regex));
	}

	$stop_getting_links = 0;

	my $count = 0;
	my $total = @$list;
	
	my $useragent = LWP::UserAgent->new( keep_alive => KEEPALIVECOUNT);
	$useragent->agent($config_useragent);
	setupagent($useragent);

	foreach $link (@$list)
	{
		return @$list if($stop_getting_links);

		$count++;
		cb('title',"($count/$total) URLToys Finding Links...",0);

		if($link =~ m/$makeregex/)
		{
			cb('variable','dlcount',$count);
			cb('variable','dltotal',$total);
			cb('variable','dlk',0);
			cb('variable','dllen',0);

			# Simpler variables
			if($total > 0)
			{
				cb('variable','cp',(100*$count)/$total);
			}
			else
			{
				cb('variable','cp',0);
			}
			cb('variable','ct',"[Search ($count/$total) ] $link");

			my @sitelist = getlinks($useragent,$link,$regexarray,$count,$total);

			if(@sitelist > 0)
			{
				push @final_list, @sitelist;
			}
		}
		else
		{
			# Added Version 1.03 4/22/03 (Fixes makeregex bug)
			push @final_list,$link;
		}
	}

	return @final_list;
};

sub ut_stop_download
{
	$stop_getting_links = 1;
}

# The interior of the downloading code ... draws the little % bar, writes data
sub downloadfile_callback
{
	my($data, $response, $protocol) = @_;

	# Believe it or not, this is the way to do it according to the docs
	die if ($stop_getting_links);

	if($response->is_success)
	{

	if($resume_spot > 0)
	{
		if($response->code != 206) # Partial Content
		{
			# The server didn't support the Range header,
			# so move to the beginning of the file and start over
			
			seek OUTPUT,0,0;
			truncate OUTPUT,0;
			$resume_spot = 0;
		}
	}

	my $length = $response->content_length;

	if($length < 1)
	{
		cb('dlbeat',0,0);
		cb('variable','dlcount',$download_count);
		cb('variable','dltotal',$download_total);
		cb('variable','dlk',0);
		cb('variable','dllen',0);
		cb('variable','dldir',$dir);
			
		# Simpler variables

		$animate_pulse = ($animate_pulse + $animate_add) % 100;
		
		cb('variable','cp',$animate_pulse);
		cb('variable','tp',(100*$download_count)/$download_total);
	}
	else
	{
		if(!goodsize($length,$dlsize))
		{
			# Doesn't match the good size
			$badsize = 1;
			cb('dlupdate',"\r[  Incorrect Size for DL  ]",0);
			die;
		}

		my $dl_line = '';

		$dl_line = "\r[";
		$current_k += length($data);

		my $percentage = (25 * $current_k) / $length;
		my $total_percentage = (10 * $download_count) / $download_total;
		my $count = 0;

		while($count < $percentage)
		{
			$dl_line .= "*";
			$count++;
		}

		while($count < 25)
		{
			$dl_line .= "-";
			$count++;
		}

		$dl_line .= "] [ ${current_k}b of ${length}b | $download_count/$download_total (to $dir) ]";
		
		cb('dlupdate',$dl_line,0);
		
		cb('variable','dlcount',$download_count);
		cb('variable','dltotal',$download_total);
		cb('variable','dlk',$current_k);
		cb('variable','dllen',$length);
		cb('variable','dldir',$dir);
		
		cb('variable','cp',(100*$current_k)/$length);
		cb('variable','tp',(100*$download_count)/$download_total);
	}

	print OUTPUT $data;

	$file_complete = 1 if($current_k == $length);
	
	} #is_success

} #downloadfile_callback


# Called by download_file array ... downloads one file
sub downloadfile
{
	# $count is used as a unique number, created inside of downloadfile_array
	
	my $useragent = shift;
	my $url = shift;
	my $count = shift;

	cb('variable','url',$url);

	# Calculate filename

	my $base_filename = "unknown-name";
	my $domain = "unknown-domain";
	my $urldir = "";
	my $extension = "";
#	if($url =~ m/http:\/\/(?:[^\/]+\/)+(.+)(?:\?.*)?/i)
	if($url =~ m/http:\/\/([^\/]+)\/((?:[^\/]+\/)+)?(.+)(?:\?.*)?/i)
	{
		$domain = $1;
		$urldir = $2;
		$base_filename = $3;
	}

	if(length($base_filename) > 0)
	{
		if($base_filename =~ m/\.([^.]+)$/)
		{
			$extension = $1;
		}
	}
	
	my $countstr = sprintf("%.5d",$count);
	
	my $filename = $config_name_template; 

	my $currentdir = cwd();

	my ($tsec, $tmin, $thour, 
		$tday, $tmonth, $tyear, 
		$tweekday, $tdoy, $tdst) = localtime(time);
	
	$tyear += 1900; # Fix the year
	my $t24hr = $thour;
	$thour -= 12 if($thour > 12);

	# Fix up the urldir, use DirSlashes too
	if($urldir)
	{
		$urldir =~ s/\/+$//;
		$urldir =~ s/^\/+//;
		$urldir =~ s/\//$config_dirslashes/g;
	}

	$filename =~ s/%DOMAIN/$domain/g;
	$filename =~ s/%DIR/$urldir/g;

	my $a = uc $extension;
	$filename =~ s/%CEXT/$a/g;
	$a = lc $extension;
	$filename =~ s/%LEXT/$a/g;
	$filename =~ s/%EXT/$extension/g;

	$filename =~ s/%DAY/$tday/g;
	$filename =~ s/%MONTH/$tmonth/g;
	$filename =~ s/%YEAR/$tyear/g;

	$filename =~ s/%24HR/$t24hr/g;
	$filename =~ s/%HOUR/$thour/g;
	$filename =~ s/%MIN/$tmin/g;
	$filename =~ s/%SEC/$tsec/g;

	# Add other NameTemplate variables here
	$filename =~ s/%COUNT/$countstr/;
	$filename =~ s/%NAME/$base_filename/;

	my $full_filename = "$dir/$filename";

	# Fix $full_filename
	$full_filename =~ s!//!/!g;
	
	# Added condition Version 1.04 for Resuming LISTS not FILES
	if(-e $full_filename)
	{
		cb('dlupdate',"Skipping $url... found $full_filename\n",0);
	}
	else
	{
		# Sets the globally downloading filename
		$current_file = $full_filename;

		$file_complete = 0;
	
		my $req = HTTP::Request->new('GET', $url);

		addcustomheaders($req,$url,$domain);

		$resume_spot = 0;
		my $openmode = ">";

		# New Resuming-file code
		my $dl_filename = $full_filename . $temp_dl_ext;
		$current_file = $dl_filename;

		if(-e $dl_filename)
		{
			my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = 
				stat $dl_filename;

			cb('dlupdate',"\rSizing $url for resume...",0);
			my $completesize = document_length($url);

			if($completesize < 1)
			{
				cb('dlupdate',"Cannot resume.\n",0);
				unlink $dl_filename;
			}
			else
			{
				$openmode = ">>"; # We're gonna be resuming
				$resume_spot = $size;
				$req->header("Range" => "bytes=$size-");
				cb('dlupdate',"\n",0);
			}
		}

		# Create any needed subdirectories
		my $dir_to_create = $full_filename;
		$dir_to_create =~ s/\/[^\/]+$//; # Strip off name
		makedir($dir_to_create);
		
		unless(open(OUTPUT,"$openmode $dl_filename"))
		{
			cb('error',"can't open output file. ($dl_filename)\n",0);
			return; 
		}

		binmode OUTPUT;
		$current_k = 0;

		if($resume_spot > 0)
		{
			cb('dlupdate',"Resuming \"$url\"...\n",0);
		}
		else
		{
			cb('dlupdate',"Downloading \"$url\"...\n",0);
		}

		$badsize = 0;
		my $response = $useragent->request($req, \&downloadfile_callback, 4096);
		close(OUTPUT);

		my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = 
			stat $dl_filename;

		# Added 1.10
		if($size < 1) # Its nothing
		{
			unlink $dl_filename;
		}
		elsif($file_complete)
		{
			unlink $full_filename;
			rename $dl_filename,$full_filename;
		}

		cb('dlupdate',"\n",0);
	}

	# Moved here in 1.10
	$current_file = "";
}					    

# The wrapper for downloadfile, gets entire list
sub downloadfile_array
{

	my $list = shift;

	my @final_list;
	my $link;
	my $count = 0;

	if($ut_get_dir)
	{
		# This is an override for the Perl Module
		$dir = $ut_get_dir;
		$ut_get_dir = '';
		mkdir($dir);
	}
	else
	{
		checkdir;
	}

	cb('variable','dldir',$dir);

	$download_count = 0;
	$download_total = @$list;

	if($config_save_url_list)
	{
		my $url_list_filename = "$dir/url_list";
		open(URLLIST, "> $url_list_filename");
		unless(defined *URLLIST)
		{
			cb('error',"Cannot write to $url_list_filename\n",0);
			return;
		}

		print URLLIST "$_\n" for (@$list);
		close(URLLIST);

		if(keys %passwords > 0)
		{
			my $pw_list_filename = "$dir/pw_list";
			open(PWLIST, "> $pw_list_filename");
			unless(defined *PWLIST)
			{
				cb('error',"Cannot write to $pw_list_filename\n",0);
				return;
			}

			for my $key (sort keys %passwords)
			{
				print PWLIST $passwords{$key} . " " . "$key\n";
			}
			close(PWLIST);
		}
	
		# As of Version 1.24, the headers and config are saved too

		if(keys %headers > 0)
		{
			my $hd_list_filename = "$dir/hd_list";
			open(HDLIST, "> $hd_list_filename");
			unless(defined *HDLIST)
			{
				cb('error',"Cannot write to $hd_list_filename\n",0);
				return;
			}

			for my $key (sort keys %headers)
			{
				print HDLIST $key . ": " . $headers{$key} . "\n";
			}
			close(HDLIST);
		};
		
		saveconfig("$dir/cf_list",1);
	}

	cb('begin',$dir,0);

	my $useragent = LWP::UserAgent->new( keep_alive => KEEPALIVECOUNT);
	$useragent->agent($config_useragent);
	setupagent($useragent);
	
	$stop_getting_links = 0;
	foreach $link (@$list)
	{
		last if($stop_getting_links);
		$download_count++;
		cb('title',"($download_count/$download_total) URLToys Downloading...",0);
		
		cb('variable','cp',0);
		cb('variable','tp',(100*$download_count)/$download_total);
		cb('variable','ct',"$link");
		cb('variable','tt',"Downloading ($download_count/$download_total)...");
		
		downloadfile($useragent,$link,$count);
		if($config_pausetime)
		{
			cb('dlupdate',"Sleeping $config_pausetime seconds...\n",0);
			sleep $config_pausetime;
		}
		$count++;
	}

	cb('complete',$dir,0) unless($stop_getting_links);
};

# Added Version 1.04 4/24/2003
sub resume_list
{
	my $list_to_resume = shift;

	my @resumelist;
	my $link;
	my $count = 0;

	my $url_list_filename = "$list_to_resume/url_list";

	unless(-f $url_list_filename)
	{
		cb('dlupdate',"cannot resume $list_to_resume: $url_list_filename is missing.\n",0);
		return;
	}

	open(RESUMEFILE,"< $url_list_filename");

	unless(defined *resumefile)
	{
		cb('error',"cannot open $url_list_filename\n",0);
		return;
	}

	while(<RESUMEFILE>)
	{
		my $url = $_;
		chomp($url);
		push @resumelist,$url;
	}

	my $pw_list_filename = "$list_to_resume/pw_list";

	if(-f $pw_list_filename)
	{

		open(PWFILE,"< $pw_list_filename");

		if(defined *PWFILE)
		{
			while(<PWFILE>)
			{
				if(/^(\S+)\s+(.*)$/)
				{
					my $b64 = $1;
					my $domain = $2;
					chomp($domain);
					$passwords{$domain} = $b64;
				}
			}
		
		close(PWFILE);
		
		} #if defined

	} # if -f


	my $hd_list_filename = "$list_to_resume/hd_list";

	if(-f $hd_list_filename)
	{
		open(HDFILE,"< $hd_list_filename");

		if(defined *HDFILE)
		{
			while(<HDFILE>)
			{
				if(/^([^: ]+): (.+)$/)
				{
					my $which = $1;
					my $what = $2;
					chomp($what);
					$headers{$which} = $what;
				}
			}
		
		close(HDFILE);
		
		} #if defined

	} # if -f

	my $cf_list_filename = "$list_to_resume/cf_list";

	if(-f $cf_list_filename)
	{
		loadconfig($cf_list_filename);
	} # if -f

	$dir = $list_to_resume;
	
	cb('variable','dldir',$dir);
	cb('begin',$dir,0);

	$download_count = 0;
	$download_total = @resumelist;

	my $useragent = LWP::UserAgent->new( keep_alive => KEEPALIVECOUNT);
	$useragent->agent($config_useragent);
	setupagent($useragent);

	$stop_getting_links = 0;

	foreach $link (@resumelist)
	{
		last if($stop_getting_links);
		$download_count++;
		cb('title',"($download_count/$download_total) URLToys Resuming Download...",0);
		
		cb('variable','cp',0);
		cb('variable','tp',(100*$download_count)/$download_total);
		cb('variable','ct',"$link");
		cb('variable','tt',"Downloading ($download_count/$download_total)...");

		downloadfile($useragent,$link,$count);
		if($config_pausetime)
		{
			cb('dlupdate',"Sleeping $config_pausetime seconds...\n",0);
			cb('variable','ct',"Sleeping $config_pausetime seconds...\n");
			cb('variable','cp',0);
			sleep $config_pausetime;
		}
		$count++;
	}
	
	cb('complete',$dir,0) unless($stop_getting_links);
};

sub spider
{
	my $utlist = shift;
	my $prefix;
	my %seen;
	my @final;

for(@$utlist)
{
	$prefix = $_;

	$prefix =~ s/\/([^\/]+)$//;

	my @l = ();
	push @l, $_;
	$seen{$prefix} = 1;

	while(1)
	{
		$stop_getting_links = 0;
		ut_exec_command("hrefimg",\@l);
		return @$utlist if($stop_getting_links);

		my @newl = ();
	
		for my $u (@l)
		{

			$u =~ s/(#.*)?$//;

			next if($u =~ /^mailto/i);
			next if($u =~ /^nntp:\/\//i);
			if($u =~ /^ftp:\/\//i)
			{
				push @final,$u;
				$seen{$u} = 1;
				next;
			}

			unless($seen{$u})
			{
				$seen{$u} = 1;
				push @final,$u;

				my ($parent,$parent_abs,$extension) = ext_and_parent($u);

				if($extension)
				{
					unless(skipext($extension))
					{
						push @newl,$u if($u =~ m/^$prefix/);
					}
				}
				else
				{
					push @newl,$u if($u =~ m/^$prefix/);
				}
			}
		}

		@l = @newl;
		last if(@l < 1);
	}

} # for

return @final;

}

# *** LIST MANAGEMENT FUNCTIONS *************************

# Added 1.09a
sub replace
{
	my ( $list, $tofind,$replacewith,$useregex) = @_;

	if($useregex)
	{
		return @$list if(!test_regex($tofind));
	}
	else
	{
		$tofind = quotemeta $tofind;
	}

	# Fixed 1.09b
	$_ =~ s/$tofind/$replacewith/g foreach(@$list);

	return @$list;
}

# ... AKA Strip
sub replace_with_nothing
{
	my ($list,$tofind,$useregex) = @_;

	if($useregex)
	{
		return @$list if(!test_regex($tofind));
	}
	else
	{
		$tofind = quotemeta $tofind;
	}

	# Fixed 1.09b
	$_ =~ s/$tofind// foreach(@$list);

	return @$list;
}

# Either deletes entries in a list by regex, or -doesn't- delete them
# Version 1.02 redone from Saint Marck 4/21/03
# Version 1.03a Removed and added back in with the /o removed
sub keep_by_regex
{
	my ( $list, $regex, $delete_instead ) = @_;
	# Added /i in 1.08b
	grep { $delete_instead ? !/$regex/i : /$regex/i } @$list;
}

sub document_length
{
	my $url = shift;
	my $len = -1;
	
	my $req = HTTP::Request->new('HEAD', $url);
	
	my $url_pieces = url $url;

	addcustomheaders($req,$url,$url_pieces->host);
	
	my $useragent = LWP::UserAgent->new;
	$useragent->agent($config_useragent);
	setupagent($useragent);

	my $response = $useragent->request($req);
	my $templen = $response->header("Content-Length");

	$len = $templen if($templen > 0);

	return $len;
}

sub goodsize
{
	my($len,$typedsize) = @_;

	my $comparison = '+';
	my $size = 0;
	my $unit = 'b';
	
	my $k = int($len / 1024);

	my $good = 0;

	if($typedsize =~ /\s*([-+]?)(\d+)([kKbB]?)\s*/)
	{
		my($tcomp,$tsize,$tunit) = ($1,$2,$3);
		$comparison = '-' if($tcomp eq '-');
		$size = $tsize;
		$unit = 'k' if ($tunit =~ m/^k$/i);
	}

	if($comparison eq '-')
	{
		# Less Than
		if($unit eq 'k')
		{
			$good=1 if($k <= $size);
		}
		else
		{
			$good=1 if($len <= $size);
		}
	}
	else
	{
		# Greater Than
		if($unit eq 'k')
		{
			$good=1 if($k >= $size);
		}
		else
		{
			$good=1 if($len >= $size);
		}
	}
	
	return $good;
}

sub keep_by_size
{
	my ($list, $typedsize ) = @_;
	$stop_getting_links = 0;

	# Default is to allow anything larger than 0 bytes

	my @retlist = ();

	for my $entry (@$list)
	{
		if($stop_getting_links)
		{
			return @$list;		
		}
		
		cb('dlupdate',"Sizing ${entry}...",0);
		
		my $len = document_length($entry);
		if($len == -1)
		{
			cb('dlupdate',"[? Keep ?]\n",0);
			push @retlist,$entry;
		}
		else
		{
			my $k = int($len / 1024);
			my $keep = 0;
			
			cb('dlupdate',"${k}k",0);

			if(goodsize($len,$typedsize))
			{
				push @retlist,$entry;
				cb('dlupdate'," [ Keep ]\n",0);
			}
			else
			{
				cb('dlupdate'," [ Del  ]\n",0);
			}
		}
	}

	return @retlist;
}

sub removedupes
{
	my $in = shift;
	
	my %saw;
	@saw{@$in} = ();

	# Nodupes sorts now. - 1.26
    my @out = sort keys %saw;

	return @out;	
}

sub keep_uniques
{
	my $in = shift;
	my %saw;
	my @final;
	
	for(@$in)
	{
		$saw{$_}++;
	}

	for(keys %saw)
	{
		push(@final,$_) if($saw{$_} < 2);
	}

	return @final;
}

sub delhead
{
	my $list = shift;
	my $count = shift;

	my $listcount = @$list;

	return @$list if($listcount == 0);
	return @$list if($count == 0);

	if($count >= $listcount)
	{
		$list = ();
		return $list;
	}

	my @final;

	my $i = 0;
	for(@$list)
	{
		push(@final, $_) if($i >= $count);
		$i++;
	}

	return @final;
}

sub keephead
{
	my $list = shift;
	my $count = shift;

	my $listcount = @$list;

	return @$list if($count >= $listcount);
	return @$list if($listcount == 0);
	
	if($count == 0)
	{
		return ();
	}

	my @final;

	for(my $i=0;$i<$count;$i++)
	{
		push(@final, $$list[$i]);
	}

	return @final;
}

sub deltail
{
	my $list = shift;
	my $count = shift;

	my $listcount = @$list;

	return @$list if($listcount == 0);
	return @$list if($count == 0);

	if($count >= $listcount)
	{
		$list = ();
		return $list;
	}

	for(my $i=0;$i<$count;$i++)
	{
		pop(@$list);
	}

	return @$list;
}

sub keeptail
{
	my $list = shift;
	my $count = shift;

	my $listcount = @$list;

	return @$list if($count >= $listcount);
	return @$list if($listcount == 0);
	
	if($count == 0)
	{
		return ();
	}

	my @final;

	for(my $i=$count;$i>0;$i--)
	{
		push(@final, $$list[$listcount-$i]);
	}

	return @final;
}

# shows list to standard output
sub showlist
{
	my $list = shift;
	my $regex = shift;

	unless(defined $regex)
	{
		$regex = ".*"; # Show any goddamn thing
	}

	if($#$list < 0)
	{
		cb('output',"No records to view.\n",0);
		return;
	}

	$stop_getting_links = 0;
	foreach my $entry (@$list)
	{
		if($entry =~ m/$regex/)
		{
			cb('output',"$entry\n",0);
		}
		last if ($stop_getting_links);
	}
}

sub showhead
{
	my $list = shift;
	my $amount_to_show = shift;

	$amount_to_show = 10 if(!$amount_to_show);

	if($#$list < 0)
	{
		cb('output',"No records to view.\n",0);
		return;
	}

	my $count = 0;
	foreach my $entry (@$list)
	{
		cb('output',"$entry\n",0);

		$count++;
		last if($count >= $amount_to_show);
	}
}

sub showtail
{
	my $list = shift;
	my $amount_to_show = shift;

	$amount_to_show = 10 if(!$amount_to_show);

	my $listcount = @$list;

	$amount_to_show = $listcount if($amount_to_show > $listcount);

	if($#$list < 0)
	{
		cb('output',"No records to view.\n",0);
		return;
	}

	my $count = -1 * $amount_to_show;
	while($count < 0)
	{
		my $entry = @$list[$count];
		cb('output',"$entry\n",0);

		$count++;
	}
}

# Used internally by nsort
sub sort_by_num
{
	my $i = reverse shift;
	my $j = reverse shift;

	unless($i =~ m/^(\D+?)(\d+)(.+)$/)
	{
		return $i cmp $j;
	}

	my $iprefix = reverse $3;
	my $id		= reverse $2;
	my $isuffix = reverse $1;
		
	unless($j =~ m/^(\D+?)(\d+)(.+)$/)
	{
		return $i cmp $j;
	}
	
	my $jprefix = reverse $3;
	my $jd		= reverse $2;
	my $jsuffix = reverse $1;

	return $i cmp $j unless($iprefix eq $jprefix);
#	return $i cmp $j unless($isuffix eq $jsuffix);

	return $id <=> $jd;	
}

# Added 1.05
# This takes in a list like:
# http://site/10.jpg
# http://site/100.jpg
# http://site/1.jpg
# and sorts it:
# http://site/1.jpg
# http://site/10.jpg
# http://site/100.jpg
# (based on number)

sub nsort
{
	my $list = shift;
	my %cool; # The neato hash of arrays used for this
	my @outputlist;

	for(@$list)
	{
		my $current = reverse $_;
	
		if($current =~ m/^(\D+?)(\d+)(.+)$/)
		{
			my $prefix 	= reverse $3;
			my $d		= reverse $2;
			my $suffix 	= reverse $1;

			$current = reverse $current;
			push (@{ $cool{$prefix} }, $current);
		}
		else
		{
			push @{$cool{'unmatched'}}, $_;
		}	
	}

	foreach my $family ( sort keys %cool ) 
	{
		my @sorted = sort { sort_by_num($a,$b) } @{ $cool{$family} };
		push @outputlist,@sorted;
	}

	return @outputlist;
}

# *** SAVING / LOADING LIST FUNCTIONS **************************

sub savetofile
{
	my $utlist = shift;
	my $filename = shift;

	unless(open(LISTFILE,"> $filename"))
	{
		cb('error',"Couldn't Open file: $filename\n",0);
		return;
	}

	foreach my $link (@$utlist)
	{
		print LISTFILE "$link\n";
	}
	
	cb('output',"Saved list to \"$filename\".\n",0);
	
	close(LISTFILE);
}

sub loadfromfile
{
	my $filename = shift;
	my @list;
	
	unless(-r $filename)
	{
		cb('error',"You cannot read this file: $filename\n",0);
		return;
	}

	unless(open(LISTFILE,"< $filename"))
	{
		cb('error',"Couldn't Open file: $filename\n",0);
		return;
	}
	
	while(<LISTFILE>)
	{
		my $link = $_;
		chomp($link);
		push @list,$link;
	}
	
	close(LISTFILE);
		
	cb('output',"Loaded list from \"$filename\".\n",0);
	
	return @list;
}

# *** THE "SEQUENTIALS" *********************************

sub lastinprefix
{
	my $list = shift;
	my @lastlist;	

	my $lastprefix;
	my $lasturl;


	@$list = nsort($list);

foreach my $url (@$list)
{

	$url = reverse $url;

	if($url =~ m/^(\D+?)(\d+)(.+)$/)
	{
		my $prefix = reverse $3;
		my $d = reverse $2;
		my $suffix = reverse $1;

		if($lastprefix && !($lastprefix eq $prefix))			
		{
			if($lasturl)
			{
				push @lastlist, $lasturl;
			}
		}

		$lastprefix = $prefix;

	}
	else
	{
		push @lastlist, $url;
	}

	$lasturl = reverse $url;

} # foreach

return @lastlist;

}

sub seqlinesize
{
	my $line = shift;

	if($line =~ /^[sz]eq\s+(.+)$/)
	{
		my $url = reverse $1;
		if($url =~ m/^(\D+?)(\d+)(.+)$/)
		{
			my $d = reverse $2;
			return $d;
		}
	}
	
	return 0;
}

# 99.9% of this code comes courtesy of Saint_Marck of SE fame
sub seq
{
	my $url = reverse shift;
	my $leading_zeros = shift;

	my @seqlist;
	
	if($url =~ m/^(\D+?)(\d+)(.+)$/)
	{
		my $prefix = reverse $3;
		my $d = reverse $2;
		my $suffix = reverse $1;
		
		my $len = length $d;

		if($d > $config_seq_warning_size)
		{
			cb('error',"** That command will create $d URLs! Raise SeqWarningSize if you wish to do this.\n");
			return ();
		}

		if($leading_zeros)
		{
			@seqlist = map { sprintf( "%s%0${len}d%s", $prefix, $_, $suffix ) } 1..$d;
		}
		else
		{
			@seqlist = map { "$prefix$_$suffix" } 1..$d;
		}
	}
	else
	{
		@seqlist = (reverse $url);
	}

	return @seqlist;
}

sub lengthsort
{
	my $list = shift;
	my %n;

	for my $v (@$list)
	{
		push(@{$n{length $v}},$v);
	}

	my @final;

	for my $k (sort keys %n)
	{
		push @final, sort @{$n{$k}};
	}

	return @final;
}

sub autofusk
{
	my $list = shift;
	my @unoptimized;
	my @final;
	my %f;

	if(@$list < 1)
	{
		# An empty list is sorted.
		return @$list;
	}

	# %f is a hash table of arrays. The key is the URL template,
	# and the values of the array are numbers that go in the 
	# template.

	# Using http://www.example.com/pic35.jpg as an example ...

	for my $u (@$list)
	{
		if($u =~ m/^([^\[]+[^\[0-9])(\d+)(.*)$/)
		{
			my $prefix = $1; # http://www.example.com/
			my $digit  = $2; # 35
			my $suffix = $3; # .jpg

			# http://www.example.com/pic<>.jpg
			my $hashvalue = "$prefix<>$suffix";

			# push 35 onto the array @${http://www.example.com/pic<>.jpg}
			push @{$f{$hashvalue}}, $digit;
		}
		else
		{
			# This will be where all of the prefusked or unfuskables go
			push @unoptimized, $u;
		}
	}

	# For all templated URLs (the hash values) ...
	for my $hv (sort keys %f)
	{
		my $front = undef;
		my $back = undef;
	
		# Sort a special way, by digit count. 9 goes before 03
		my @valuelist = lengthsort(\@{$f{$hv}});
		
		for my $v (@valuelist)
		{
			if(!defined($front))
			{
				# First time in the loop ... set some basic values
				$front = $v;
				$back  = $v;
			}
			else
			{
				# Figure out what the next value would be
				my $next = $back+1;

				# Create a copy of the current value, without leading zeros
				my $tempv = $v;
				$tempv =~ s/^0+//;

				# If keepgoing is false, break off a fresh fuskline
				my $keepgoing = 0;
				
				$keepgoing = (int($next) == int($tempv));

				if($keepgoing)
				{
					if(length($back) < length($v))
					{
						# if the bracketed values are different length
						# due to a zero, break that

						$keepgoing = 0 if($v =~ m/^0/);
					}
				}

				if($keepgoing)
				{
					# Keep going, stretch out that list
					$back = $v;
				}
				else
				{
					# Break off a new fusker line and reset f&b
					my $fuskline = $hv;
					$fuskline =~ s/<>/\[$front-$back\]/;
					push @final,$fuskline;
					$front = $v;
					$back  = $v;
				}
			}
		} # for my $v

		my $fuskline = $hv;
		$fuskline =~ s/<>/\[$front-$back\]/;
		push @final,$fuskline;
	}

	my @blao = ();

	if(@final > 0)
	{	
		# Recursion. This works because the intial regex
		# ignores bracketed numbers, so something that 
		# is all brackets will be ignored.
		@blao = autofusk(\@final);
	}

	push @unoptimized,@blao;

	# remove all brackets that don't do anything meaningful
	return strip_dumb_brackets(\@unoptimized);
}

# strip all brackets where the two values are the same
sub strip_dumb_brackets
{
	my $list = shift;

	for(@$list)
	{
		while(m/\[(\d+)-(\d+)\]/g)
		{
			if(int($1) == int($2))
			{
				my $torep = "\\[$1-$2\\]";
				my $with = $1;
				s/$torep/$with/g;
			}
		}
	}

	return @$list;
}


sub saveflux
{
	my $list = shift;
	my $filename = shift;

	if(!open(FLUXFILE,"> $filename"))
	{
		cb('error',"Could not open $filename, sorry.\n",0);
		return;
	}
	
	my @answer = autofusk($list);

	for(@answer)
	{
		if(m/\[\d+-\d+\]/)
		{
			print FLUXFILE "fusk $_\n";
		}
		else
		{
			print FLUXFILE "$_\n";
		}
	}

	close(FLUXFILE);

	return if(@answer < 1);	
	my $stats = "Saved \"$filename\" - " . @$list . " URLs in " . @answer . " command(s). Efficiency Index: " . 
		sprintf("%2.2f",scalar(@$list)/scalar(@answer)). "\n";
	cb('output',$stats,0);
}

# Saint Marck gets all of the credit on this one

sub fusk {
	my $url = shift;
	unless ($url) {
#		warn 'function fusk requires a URL argument';
		return ();
	}
	my @list = ();
	$url =~ s/^([^\[{]+)//;
	my $pre .= $1;
	if ($url =~ s/^[\[]//) {
	
		# Version 1.04 Change
		$url =~ s/^([0-9a-z]+-[0-9a-z]+)]// || return ();
#		$url =~ s/^(\d+-\d+)]// || return ();

		my ( $r1, $r2 ) = split '-', $1;
		my $len = length $r1;

		# Version 1.04 Change
		push @list, map { fusk( sprintf( "$pre%0${len}s$url", $_ ) ) } $r1..$r2;
#		push @list, map { fusk( sprintf( "$pre%0${len}d$url", $_ ) ) } $r1..$r2;

	} elsif ($url =~ s/^{//) {
		$url =~ s/^([^}]+)}// || return ();
		my @strings = split ',', $1;
		push @list, map { fusk( "$pre$_$url" ) } @strings;
	} else {
		push @list, $pre;
	}
	return @list;
}

# *** HISTORY COMMANDS ****************************

# Made this a command just in case I wanted to add stuff to it
sub addhistory
{
	my $cmd = shift;
	return if(!$fromstdin);

	$pulledfromundo = "";

	push(@history,$cmd);
}

sub addhistory_undo
{
	my $cmd = shift;
	return if(!$fromstdin);

	if($pulledfromundo)
	{
		push(@history,$pulledfromundo);
		$pulledfromundo = "";
	}
	else
	{
		$pulledfromundo = pop(@history);
	}
}

sub clearhistory
{
	@history = ();
	cb('output',"History Cleared.\n",0);
}

sub showhistory
{
	my $count = shift;

	if(@history < 1)
	{
		cb('output',"The history is empty.\n",0);
		return;
	}

	my $n = 0;

	for my $h (@history)
	{
		cb('output',"$h\n",0);
		$n++;
		if($count)
		{
			return if($n >= $count);
		}
	}
}

sub savehistory
{
	my $filename = shift;
	my $count = shift;

	my $n = 0;

	if(!open(HISTORYFILE,"> $filename"))
	{
		cb('error',"Cannot open \"$filename\".\n",0);
		return;
	}

	for my $h (@history)
	{
		print HISTORYFILE "$h\n";
		
		$n++;

		if($count)
		{
			last if($n >= $count);
		}
	}

	close(HISTORYFILE);

	cb('output',"Saved $n commands to \"$filename\".\n",0);
}


# *** COMMAND LINE FUNCTIONS ***********************************

sub createprompt
{
	my $list = shift;

	my $temp = $config_prompt;
	my $count = @$list;

	# Add other variables for the prompt here
	my $currentdir = cwd();

	my ($tsec, $tmin, $thour, 
		$tday, $tmonth, $tyear, 
		$tweekday, $tdoy, $tdst) = localtime(time);

	$tyear += 1900; # Fix the year

	$temp =~ s/%DAY/$tday/;
	$temp =~ s/%MONTH/$tmonth/;
	$temp =~ s/%YEAR/$tyear/;

	my $t24hr = $thour;
	$thour -= 12 if($thour > 12);

	$temp =~ s/%24HR/$t24hr/;
	$temp =~ s/%HOUR/$thour/;
	$temp =~ s/%MIN/$tmin/;
	$temp =~ s/%SEC/$tsec/;

	$temp =~ s/%COUNT/$count/;
	$temp =~ s/%CWD/$currentdir/;

	return $temp;
}

sub makeundo
{
	my $list = shift;
	
	if($config_useundo)
	{
		@undolist = (@$list);
	}
}

sub doundo
{
	my $list = shift;
	my @templist = (@undolist);
	@undolist = (@$list);

	return @templist;
}

sub ut_exec_command
{
	$_ = shift;
	my $utlist = shift;

	chomp;

	# New Parameter code for 1.09
	if(@params > 0)
	{
		my $cmd = $_;
		my $p = $params[0];
		for(my $i = 0;$i<@$p;$i++)
		{
			my $replacestr = "~$i";
			$cmd =~ s/$replacestr/$$p[$i]/;
		}

		$_ = $cmd;
	}

	CMDPARSE: 
	{
		if (/^$/) { last CMDPARSE; }
		if (/^#/) { last CMDPARSE; }
		if (/^\s+$/) { last CMDPARSE; }

		if (/^exit$/i) { exit; };
		
		if (/^clear$/i) { if($win32) { system("cls"); } else { system("clear"); } last CMDPARSE; };
		if (/^cls$/i)   { if($win32) { system("cls"); } else { system("clear"); } last CMDPARSE; };

		if (/^show(?: (.+))?$/i) { my $r = $1; showlist($utlist,$r) if(test_regex($r)); last CMDPARSE;};
		if (/^list(?: (.+))?$/i) { my $r = $1; showlist($utlist,$r) if(test_regex($r)); last CMDPARSE;};
		if (/^ls(?: (.+))?$/i)   { my $r = $1; showlist($utlist,$r) if(test_regex($r)); last CMDPARSE;};
		
		if (/^head(?: (.+))?$/i)   { my $r = $1; showhead($utlist,$r); last CMDPARSE;};
		if (/^tail(?: (.+))?$/i)   { my $r = $1; showtail($utlist,$r); last CMDPARSE;};

		if (/^history\s+show(?:\s+)?$/i)
		{ 
			showhistory(0);
			last CMDPARSE;
		};

		if (/^history\s+show\s+(\d+)$/i)
		{ 
			my $count = $1;
			showhistory($count);
			last CMDPARSE;
		};

		if (/^history\s+save(?:\s+)?$/i)
		{ 
			helpsyntax('history');
			last CMDPARSE;
		};

		if (/^history\s+save\s+(\S.*)\s+(\d+)$/i)
		{ 
			my $filename = $1;
			my $count = $2;
			savehistory($filename,$count);
			last CMDPARSE;
		};

		if (/^history\s+save\s+(\S.*)$/i)
		{ 
			my $filename = $1;
			savehistory($filename,0);
			last CMDPARSE;
		};

		if (/^history\s+clear/i)
		{ 
			clearhistory;
			last CMDPARSE;
		};

		if (/^history(?:\s+)?$/i)
		{ 
			helpsyntax('history');
			last CMDPARSE;
		};

		if (/^keep(?:\s+)?$/i) { helpsyntax('keep'); last CMDPARSE;};
		if (/^keep (.+)$/i)
		{ 
			my $regex = $1;
			makeundo($utlist);
			if(test_regex($regex))
			{
				setaction('filter');
				@$utlist = keep_by_regex($utlist,$regex,0);
				endaction;
				addhistory($_);
			}
			last CMDPARSE;
		};

		if (/^size(?:\s+)?$/i) { helpsyntax('size'); last CMDPARSE;};
		if (/^size (.+)$/i)
		{ 
			my $size = $1;
			makeundo($utlist);
			setaction('size');
			@$utlist = keep_by_size($utlist,$size);
			endaction;
			addhistory($_);
			
			last CMDPARSE;
		};

		if(/^needparam$/i) { helpsyntax('needparam'); last CMDPARSE;};
		if(/^needparam\s+(\d+)(?:\s+(.*))?$/i)
		{
			my $which = $1;
			my $why = $2;

			if(@params < 1)
			{
				cb('error', "You can't type this in manually. This is for .u scripts.\n",0);
			}
			else
			{
				my $p = $params[0];
				if(!$$p[$which])
				{
					cb('help', "$why\n",0);
					return 0; # End this script
				}
			}

			last CMDPARSE;
		}

		if (/^batch(?:\s+)?$/i) { helpsyntax('batch'); last CMDPARSE;};
		if (/^batch (.+)$/i)
		{ 
			my $batchline = $1;
			
			makeundo($utlist);
			addhistory($_);
		
			# This disables messing with the undo during this
			my $cuu = $config_useundo;
			$config_useundo = 0;
			batchloop($loop_readptr,$utlist,$batchline);
			$config_useundo = $cuu;
			last CMDPARSE;
		};

		if (/^batchcurrent(?:\s+)?$/i) { helpsyntax('batchcurrent'); last CMDPARSE;};
		if (/^batchcurrent (.+)$/i)
		{ 
			my $batchline = $1;
			
			makeundo($utlist);
			addhistory($_);
		
			# This disables messing with the undo during this
			my $cuu = $config_useundo;
			$config_useundo = 0;
			@$utlist = batchcurrent($utlist,$batchline);
			$config_useundo = $cuu;
			last CMDPARSE;
		};

		if(/^keeph/)
		{
			if(/^keeph\s+(\d+)\s*$/)
			{
				addhistory($_);
				makeundo($utlist);
				setaction('filter');
				@$utlist = keephead($utlist,$1);
				endaction;
			}
			else
			{
				helpsyntax('keeph');
			}

			last CMDPARSE;
		}

		if(/^delh/)
		{
			if(/^delh\s+(\d+)\s*$/)
			{
				addhistory($_);
				makeundo($utlist);
				setaction('filter');
				@$utlist = delhead($utlist,$1);
				endaction;
			}
			else
			{
				helpsyntax('delh');
			}

			last CMDPARSE;
		}

		if(/^keept/)
		{
			if(/^keept\s+(\d+)\s*$/)
			{
				addhistory($_);
				makeundo($utlist);
				setaction('filter');
				@$utlist = keeptail($utlist,$1);
				endaction;
			}
			else
			{
				helpsyntax('keept');
			}

			last CMDPARSE;
		}

		if(/^delt/)
		{
			if(/^delt\s+(\d+)\s*$/)
			{
				addhistory($_);
				makeundo($utlist);
				setaction('filter');
				@$utlist = deltail($utlist,$1);
				endaction;
			}
			else
			{
				helpsyntax('delt');
			}

			last CMDPARSE;
		}

		if (/^del(?:\s+)?$/i) { helpsyntax('del'); last CMDPARSE;};
		if (/^del (.+)$/i)
		{ 
			my $regex = $1;
			makeundo($utlist);
			if(test_regex($regex))
			{
				addhistory($_);
				setaction('filter');
				@$utlist = keep_by_regex($utlist,$regex,1);
				endaction;
			}
			last CMDPARSE;
		};

		if (/^replace(?:\s+)?$/i) { helpsyntax('replace'); last CMDPARSE;};
		if (/^replace\s+(\S+)\s+(\S+)$/i)
		{ 
			addhistory($_);
			setaction('replace');
			@$utlist = replace($utlist,$1,$2,0);
			endaction;
			last CMDPARSE;
		};

		if (/^rreplace(?:\s+)?$/i) { helpsyntax('rreplace'); last CMDPARSE;};
		if (/^rreplace\s+(.*)$/i)
		{ 
			addhistory($_);
			setaction('replace');
			$_ = $1;
			if (/^s?\/(.*)(?<!\\)\/(.*)(?<!\\)\/.*$/i)
			{
				@$utlist = replace($utlist,$1,$2,1);
			}
			else
			{
				cb('error',"rreplace: Cannot understand that. Please check for errors.\n",0);
			}
			endaction;
			last CMDPARSE;
		};

		if (/^password(?:\s+)?$/i) { helpsyntax('password'); last CMDPARSE;};
		if (/^password\s+clear\s*$/i)
		{
			%passwords = ();
			last CMDPARSE;
		}
		if (/^password\s+show\s*$/i)
		{
			my @keys = sort keys %passwords;

			if(!@keys)
			{
				cb('output',"URLToys isn't aware of any passwords.\n",0);
			}
			else
			{
				for my $key(@keys)
				{
					cb('output',"$key - " . decode_base64($passwords{$key}) . "\n",0);
				}
			}

			last CMDPARSE;
		}
		elsif (/^password\s+(\S+)\s+(\S+)\s+(\S+)\s*$/i)
		{ 
			addhistory($_);
			my $domain = $1;
			my $username = $2;
			my $password = $3;
			
			chomp($username);
			chomp($password);
			
			$passwords{$domain} = encode_base64("$username:$password");
			chomp($passwords{$domain});

			cb('output',"URLToys will use $username for $domain now.\n",0);
			
			last CMDPARSE;
		};

		if (/^strip(?:\s+)?$/i) { helpsyntax('strip'); last CMDPARSE;};
		if (/^strip\s+(.*)$/i)
		{ 
			addhistory($_);
			setaction('replace');
			@$utlist = replace_with_nothing($utlist,$1,0);
			endaction;
			last CMDPARSE;
		};

		if ((/^u$/i) or (/^undo\s*$/))
		{ 
			addhistory_undo($_);
			@$utlist = doundo($utlist);
			last CMDPARSE;
		};

		if (/^nodupes$/i)
		{ 
			addhistory($_);
			makeundo($utlist);
			setaction('filter');
			@$utlist = removedupes($utlist); 
			endaction;
			last CMDPARSE;
		};

		if (/^spider$/i)
		{ 
			addhistory($_);
			makeundo($utlist);
			setaction('make');
			$fromstdin = 0;
			@$utlist = spider($utlist); 
			endaction;
			last CMDPARSE;
		};


		if (/^keepuni$/i)
		{ 
			addhistory($_);
			makeundo($utlist);
			setaction('filter');
			@$utlist = keep_uniques($utlist); 
			endaction;
			last CMDPARSE;
		};

		# Added 1.01 4/19/03
		if (/^fusk(?:\s+)?$/i) { helpsyntax('fusk'); last CMDPARSE;};
		if (/^fusker(?:\s+)?$/i) { helpsyntax('fusker'); last CMDPARSE;};
		if (/^fusk(?:er)? (.+)$/i)
		{ 
			my $fuskurl = $1;
			chomp($fuskurl);
			
			addhistory($_);

			setaction('add');
			my @fusklist = fusk($fuskurl);
			
			makeundo($utlist);
			push(@$utlist, @fusklist) if @fusklist;
			
			endaction;

			last CMDPARSE;
		};

		# Last In Prefix ... Added 1.06 05/19/03
		if (/^lip$/i)
		{ 
			addhistory($_);
			makeundo($utlist);
			setaction('filter');
			@$utlist = lastinprefix($utlist);
			endaction;
			
			last CMDPARSE;
		};

		# Version ... Added 1.06 05/19/03
		if (/^ver/i)
		{ 
			cb('output',"$URLTOYS_VERSION\n",0);
			
			last CMDPARSE;
		};

		if (/^seq(?:\s+)?$/i) { helpsyntax('seq'); last CMDPARSE;};
		if (/^seq (.+)$/i)
		{ 
			my $sequrl = $1;
			chomp($sequrl);
			addhistory($_);

			setaction('add');
			# The 0 means "no leading zeros"
			my @seqlist = seq($sequrl,0);
			
			makeundo($utlist);
			push @$utlist, @seqlist;
			endaction;

			last CMDPARSE;
		};

		if (/^cd(?:\s+)?$/i) { helpsyntax('cd'); last CMDPARSE;};
		if (/^cd\s+(.+)$/i)
		{ 
			my $newdir = $1;
			chomp($newdir);
			addhistory($_);

			chdir $newdir;

			last CMDPARSE;
		};

		if (/^header(?:\s+)?$/i) 
		{
			cb('output',"\nCurrently assigned headers:\n",0);
			if(%headers > 0)
			{
				foreach my $key (keys %headers)
				{
					cb('output',$key . ": " . $headers{$key} . "\n",0);
				}
			}
			else
			{
				cb('output',"-- None --\n",0);
			}

			cb('output',"\n",0);
			
			last CMDPARSE;
		};
		if (/^header\s+(.+)$/i)
		{ 
			my $newheader = $1;
			chomp($newheader);
			addhistory($_);

			if($newheader =~ m/^\s*([^ \t:]+):?\s+(.*)$/)
			{
				my ($which,$what) = ($1,$2);
				if($which =~ /^-d$/)
				{
					delete($headers{$what});
				}
				else
				{
					$headers{$which} = $what;
				}
			}

			last CMDPARSE;
		};

		if (/^pwd(?:\s+)?$/i)
		{ 
			my $tehdir = cwd();
			cb('output',"$tehdir\n",0);

			last CMDPARSE;
		};

		if (/^zeq(?:\s+)?$/i) { helpsyntax('zeq'); last CMDPARSE;};
		if (/^zeq (.+)$/i)
		{ 
			my $sequrl = $1;
			chomp($sequrl);
			addhistory($_);

			setaction('add');
			# The 1 means "use the leading zeros"
			my @seqlist = seq($sequrl,1);
			
			makeundo($utlist);
			push @$utlist, @seqlist;

			endaction;

			last CMDPARSE;
		};


		if (/^(http:\/\/[^ <>]+)$/i)
		{
			my $toadd = $1;
			chomp($toadd);
			addhistory($_);
			makeundo($utlist);
			setaction('add');
			push @$utlist, $toadd;
			endaction;
			last CMDPARSE;
		};

		# Added 1.03
		if (/^sort$/i) 
		{ 
			makeundo($utlist);
			addhistory($_);
			setaction('sort');
			@$utlist = sort @$utlist;
			endaction;
			last CMDPARSE;
		};
		# Added 1.05
		if (/^nsort$/i) 
		{ 
			makeundo($utlist);
			addhistory($_);
			setaction('sort');
			@$utlist = nsort($utlist);
			endaction;
			last CMDPARSE;
		};
		
		# Added 1.04a
		if (/^system(?:\s+)?$/i) { helpsyntax('system'); last CMDPARSE;};
		if (/^system (.+)$/i)
		{
			my $cmd = $1;
			chomp($cmd);
			addhistory($_);
			setaction('system');
			system($cmd);
			endaction;
			last CMDPARSE;
		};

		if (/^systemw(?:\s+)?$/i) { helpsyntax('systemw'); last CMDPARSE;};
		if (/^systemw (.+)$/i)
		{
			my $cmd = $1;
			chomp($cmd);
			addhistory($_);
			setaction('system');
			system($cmd) if($win32);
			endaction;
			last CMDPARSE;
		};

		if (/^systemu(?:\s+)?$/i) { helpsyntax('systemu'); last CMDPARSE;};
		if (/^systemu (.+)$/i)
		{
			my $cmd = $1;
			chomp($cmd);
			addhistory($_);
			setaction('system');
			system($cmd) if(!$win32);
			endaction;
			last CMDPARSE;
		};

		if (/^add(?:\s+)?$/i) { helpsyntax('add'); last CMDPARSE;};
		if (/^add (.+)$/i)
		{
			my $toadd = $1;
			chomp($toadd);
			addhistory($_);
			makeundo($utlist);
			setaction('add');
			push @$utlist, $toadd;
			endaction;
			last CMDPARSE;
		};

		if (/^save(?:\s+)?$/i) { helpsyntax('save'); last CMDPARSE;};
		if (/^save (.+)$/i)
		{
			my $filename = $1;
			chomp($filename);
			addhistory($_);
			setaction('save');
			savetofile($utlist,$filename);
			endaction;
			last CMDPARSE;
		};

		if (/^saveflux(?:\s+)?$/i) { helpsyntax('saveflux'); last CMDPARSE;};
		if (/^saveflux (.+)$/i)
		{
			my $filename = $1;
			chomp($filename);
			addhistory($_);
			setaction('save');
			saveflux($utlist,$filename);
			endaction;
			last CMDPARSE;
		};

		if (/^load(?:\s+)?$/i) { helpsyntax('load'); last CMDPARSE;};
		if (/^load (.+)$/i)
		{
			my $filename = $1;
			chomp($filename);
			addhistory($_);
			makeundo($utlist);
			setaction('load');
			@$utlist = loadfromfile($filename);
			endaction;
			last CMDPARSE;
		};

		if (/^append(?:\s+)?$/i) { helpsyntax('append'); last CMDPARSE;};
		if (/^append (.+)$/i)
		{
			my $filename = $1;
			chomp($filename);
			addhistory($_);
			makeundo($utlist);
			setaction('load');
			my @templist = loadfromfile($filename);
			push @$utlist, @templist;
			endaction;
			last CMDPARSE;
		};

		if (/^title\s*$/) { helpsyntax('title'); last CMDPARSE;};
		if (/^title (.+)$/i)
		{
			my $text = $1;
			addhistory($_);
			cb('title',$text,0);
			last CMDPARSE;
		};

		if (/^print$/i)	{ cb('print',"\n",0); last CMDPARSE; };
		if (/^print (.*)$/i)
		{
			my $text = $1;
			addhistory($_);
			cb('print',"$text\n",0);
			last CMDPARSE;
		};

		if(/^href$/i)
		{
			addhistory($_);
			makeundo($utlist);
			setaction('make');
			@$utlist = ut_getlinks_array($utlist,[$config_href_regex]);
			endaction;
			last CMDPARSE;
		}

		if(/^img$/i)
		{
			addhistory($_);
			makeundo($utlist);
			setaction('make');
			@$utlist = ut_getlinks_array($utlist,[$config_img_regex]);
			endaction;
			last CMDPARSE;
		}

		if(/^hrefimg$/i)
		{
			addhistory($_);
			makeundo($utlist);
			setaction('make');
			@$utlist = ut_getlinks_array($utlist,[$config_href_regex,$config_img_regex]);
			endaction;
			last CMDPARSE;
		}

		if(/^fixparents$/i)
		{
			addhistory($_);
			makeundo($utlist);
			setaction('replace');
			fixparents($utlist);
			endaction;
			last CMDPARSE;
		}

		if(/^config(?: +)?$/i)
		{
			showconfig("-",0);
			last CMDPARSE;
		}

		if(/^config\s+save\s*$/i)
		{
			addhistory($_);
			cb('output',"Saving Configuration...\n",0);
			mkdir($urltoys_dir);
			setaction('save');
			saveconfig($config_file);
			endaction;
			last CMDPARSE;
		}

		if(/^set$/i)
		{
			showconfig("-",0);
			last CMDPARSE;
		}

		if(/^config\s+load\s*$/i)
		{
			addhistory($_);
			cb('output',"Loading Configuration...\n",0);
			setaction('load');
			loadconfig($config_file);
			endaction;
			last CMDPARSE;
		}

		if (/^makeregex(?: (.+))?$/i) 
		{
			if(defined $1)
			{
				if(test_regex($1))
				{
					$makeregex = $1;
					addhistory($_);
				}
			}
			else
			{
				cb('output',"Current Make Regex is: \"$makeregex\"\n",0);
			}
			last CMDPARSE;
		};

		if (/^make(?: (.+))?$/i) 
		{
			makeundo($utlist);

			if(defined $1)
			{
				my $new_regex = $1;
				if(test_regex($new_regex))
				{
					addhistory($_);
					setaction('make');
					@$utlist = ut_getlinks_array($utlist,[$new_regex]); 
					endaction;
				};
			}
			else
			{
				if(test_regex($config_href_regex))
				{
					addhistory($_);
					setaction('make');
					@$utlist = ut_getlinks_array($utlist,[$config_href_regex]); 
					endaction;
				};
			}
			last CMDPARSE;
		};

		# Added Version 1.04 4/24/2003 -- resume list
		if (/^resume(?:\s+)?$/i) { helpsyntax('resume'); last CMDPARSE;};
		if (/^resume (.+)$/i)
		{
			my $resumedir = $1;
			chomp($resumedir);
			addhistory($_);
			$dlsize = "+0b";
			setaction('download');
			resume_list($resumedir);
			endaction;
			last CMDPARSE;
		}

		if(/^get$/i)
		{
			addhistory($_);
			$dlsize = "+0b";
			setaction('download');
			downloadfile_array($utlist);
			endaction;
			last CMDPARSE;
		}

		if(/^get\s+(.+)$/i)
		{
			my $dl = $1;
			addhistory($_);
			$dlsize = $dl;
			setaction('download');
			downloadfile_array($utlist);
			endaction;
			last CMDPARSE;
		}

		if(/^help\s+(\S+)(?:\s+(?:.*))?$/i){	helpsyntax($1); last CMDPARSE;	}
		if(/^h\s+(\S+)(?:\s+(?:.*))?$/i){	helpsyntax($1); last CMDPARSE;	}

		if(/^help(?:\s+)?$/i){	helpsyntax; last CMDPARSE;	}
		if(/^h(?:\s+)?$/i)   {	helpsyntax; last CMDPARSE;	}
		
		# Attempt to set a command
		if(/^set ([^=]+)=(.*)$/)
		{
			my $which = $1;
			my $what  = $2;
				
			addhistory($_);
			handleconfigline($which,$what);
			last CMDPARSE;
		}

		if (/^cookies(?:\s+)?$/i) 
		{ 
			if($use_cookies)
			{
				cb('output',"Cookies enabled.",0);
			}
			else
			{
				cb('output',"Cookies disabled.",0);
			}

			cb('output',"\nCurrent Cookie Jar: \n",0);
			my $cookiestring = $cookies->as_string;

			if(length $cookiestring > 0)
			{
				cb('output',$cookiestring,0);
			}
			else
			{
				cb('output'," None.\n",0);
			}
			
			last CMDPARSE;
		};
		if (/^cookies (.+)$/i)
		{
			my $cmd = $1;
			chomp($cmd);
			addhistory($_);

			$use_cookies = 1 if($cmd =~/^on/);
			$use_cookies = 0 if($cmd =~/^off/);
			$cookies->clear  if($cmd =~/^clear/);

			last CMDPARSE;
		}

		if (/^autorun(?:\s+)?$/i) { helpsyntax('autorun'); last CMDPARSE;};
		if (/^autorun (.+)$/i)
		{
			my $fluxfile = $1;
			chomp($fluxfile);
			$fluxfile =~ s/^"+//;
			$fluxfile =~ s/"+$//;
			addhistory($_);

			setaction('flux');

			my $cmdfileptr;
			if(open($cmdfileptr,$fluxfile))
			{
				my $warn = 0;
				my @warnlist = ();

				my $seqcount = 0;

				$fluxlines = 0;

				while(<$cmdfileptr>)
				{
					$fluxlines++;

					my $w=0;
					$w=1 if(m/^\s*system/i);
					$w=1 if(m/^\s*cd/i);
					$w=1 if(m/^\s*config/i);
					$w=1 if(m/^\s*set/i);
					$w=1 if(m/^\s*spider/i);

					if($w)
					{
						$warn = 1;
						push @warnlist,$_;
					}

					$seqcount += seqlinesize($_);
				}
				close($cmdfileptr);

				my $docmd = 1;

				if($seqcount > 30000)
				{
					push @warnlist, "NOTE: The seq/zeq commands in this flux will generate $seqcount URLs.";
					$warn = 1;
				}
				
				if($warn) 
				{
					$docmd = 0 unless(cb('warnuser',\@warnlist,0));
				}
		
				# This protects against malicious .flux files, somewhat.
				if($docmd)
				{
					open($cmdfileptr,$fluxfile);
					$stop_getting_links = 0;
					$fluxvarupdate = 1;
					ut_command_loop($cmdfileptr,$utlist);
					$fluxvarupdate = 0;
					close($cmdfileptr);
				}
			}

			endaction;

			last CMDPARSE;
		}
	
		# Look for custom command in the .urltoys folder
		my $cmd = $_;
		chomp($cmd);
		my $theactualcommand = '';
		if(/^(\S+)/)
		{
			$theactualcommand = $1;
		}

		my $cmdfile = $ENV{"HOME"} . "/.urltoys/" . $theactualcommand . ".u";

		if (-e $cmdfile)
		{
			addhistory($_);
			my $cmdfileptr;
			open($cmdfileptr,$cmdfile);
			my @tempparams = split(' ',$cmd);
			shift @tempparams; # remove first one to replace it
			my $allparams = join(' ',@tempparams);
			unshift @tempparams,$allparams;

			unshift @params, \@tempparams;
			$stop_getting_links = 0;
			setaction('custom');
			ut_command_loop($cmdfileptr,$utlist);
			endaction;
			shift @params;
			close($cmdfileptr);

			last CMDPARSE;
		}

		# Otherwise ... we don't know this command!
		cb('error',"Unknown Command: $_\n",0);
    }

	return 1;
}

sub ut_getnextline
{
	my $htr = shift;
	my $prompt = shift;
	
#	if($htr == *STDIN)
	if(-t $htr)
	{
		$fromstdin = 1;
		createterm() unless($ut_term);
		my $text = $ut_term->readline($prompt);
		return "" unless(defined($text));
		$text = " " if(!$text);
		return $text;
	}
	else
	{
		$fromstdin = 0;
	}

	return <$htr>;
}

sub batchcurrent
{
	my $utlist = shift;
	my $commandtobatch = shift;

	my @newlist;

	for my $entry (@$utlist)
	{
		my $cmd = $commandtobatch;
		if($cmd =~ m/~/)
		{
			# It's got a specific location to place the line
			$cmd =~ s/~/$entry/g;
		}
		else
		{
			# just tack it on the end otherwise
			$cmd .= " $entry";
		}

		ut_exec_command($cmd,\@newlist);
	}
	
	return @newlist;
}

sub batchloop
{
	my $handletoread = shift;
	my $utlist = shift;
	my $commandtobatch = shift;

  my $batchcount = 0;
  my @batchlist;
  my $batchprompt = "[batch][$batchcount] ";
#  my $endbatch = 0;

READCMD: while ($_ = ut_getnextline($handletoread,$batchprompt))
{
#	last if ($endbatch);

	if(m/^end$/i)
	{
		last;
	}
	elsif(m/^exit$/i)
	{
		last;
	}
	elsif(m/^quit$/i)
	{
		last;
	}
	else
	{
		unless(m/^\s*$/) # It's just whitespace
		{
			push @batchlist, $_;
		}
	};

	if($handletoread == *STDIN)
	{
		if (-t *STDIN) 
		{
			$batchcount = @batchlist;
  			$batchprompt = "[batch][$batchcount] ";
		}
	}
} # while loop

for my $entry (@batchlist)
{
	my $cmd = $commandtobatch;
	if($cmd =~ m/~/)
	{
		# It's got a specific location to place the line
		$cmd =~ s/~/$entry/g;
	}
	else
	{
		# just tack it on the end otherwise
		$cmd .= " $entry";
	}

	ut_exec_command($cmd,$utlist);
}

# return @$utlist;

} #batchloop

sub ut_command_loop
{
	my $handletoread = shift;
	my $utlist = shift;

	my $count = @$utlist;

	$loop_readptr = $handletoread;

	cb('title',"URLToys ($count)",0);

	$stop_getting_links = 0;

	my $currentline = 0;

READCMD: while ($_ = ut_getnextline($handletoread,createprompt($utlist)))
{

	s/\r+$//; # Fix issue with /r/n people making unix files

#	last if ($stop_getting_links);

	if($fluxvarupdate)
	{
		$currentline++;
		cb('variable','tt',"Fluxing ($currentline/$fluxlines Lines)...");
		if($fluxlines > 0)
		{
			cb('variable','tp',(100*$currentline)/$fluxlines);
		}
		else
		{
			cb('variable','tp',0);
		}
	}

	if(!ut_exec_command($_,$utlist))
	{
		return;
	}

	$count = @$utlist;
	cb('title',"URLToys ($count)",0);

	$stop_getting_links = 0;
}

cb('output',"\n",0);

}

1;

# ** END OF MODULE **

