#!/usr/bin/perl
#
# mmdscvt.pl -- convert text to text (or something else)
#
my $RCS_Id = '$Id: mmdscvt.pl,v 2.124 2003-06-13 17:53:56+02 jv Exp $ ';
#
# Author          : Johan Vromans
# Created On      : Wed Aug 29 15:08:35 1990
# Last Modified By: Johan Vromans
# Last Modified On: Fri Jun 13 17:51:06 2003
# Update Count    : 1304
# Status          : OK

################ Common stuff ################

use strict;

our ($my_name, $my_version) = $RCS_Id =~ /: (.+).pl,v ([\d.]+)/;
$my_version .= '*' if length('$Locker:  $ ') > 12;
our $TMPDIR = $ENV{"TMPDIR"} || "/usr/tmp";

our ($my_package);
our $MMDSLIB;

use FindBin;
BEGIN {
    $MMDSLIB = $ENV{"MMDSLIB"} || $FindBin::Bin || "/usr/local/lib/mmds"
}

use lib $MMDSLIB;

# Hopefully, we have enough information now to find this module.
use MMDS::Common;

# Common may have changed $MMDSLIB...
use lib $MMDSLIB;
use lib ".";

$ENV{"PATH"} = ".:" . $MMDSLIB . ':' . $ENV{"PATH"};
$ENV{MMDSLIB} = $MMDSLIB;

################ Program parameters ################

use Getopt::Long;

sub optsolete {
    print STDERR ("textcvt: obsolete option: $_[0] (ignored)\n");
}

my $cvttype = "text";

our $document_type;
our $chapnum = 0;		# initial chapter number
our $landscape = -1;		# landscape (for slides)
our $border = 1;		# border (for slides)
our $handouts = 0;
our $draft = 0;
our $justify = 0;
our $raw;
my  $language;
our $toc = 1;
my  $output;
our $keycaps = 0;
my  $nochain = 0;
my  $feedback;
my  @config;

our $verbose;
our $quiet;
our $debug;
our $test;
our $trace;
my  $help;

if ( ! GetOptions
    (
     # Generators.
     "text"	  => sub { $cvttype = shift },
     "latex"	  => sub { $cvttype = shift },
     "latex209"	  => sub { $cvttype = shift },
     "html"	  => sub { $cvttype = shift },
     "generate=s" =>      \$cvttype,

     # Document types.
     "memo"	 => sub { $document_type = shift },
     "mrep"	 => sub { $document_type = shift },
     "report"	 => sub { $document_type = shift },
     "note"	 => sub { $document_type = shift },
     "generic"	 => sub { $document_type = shift },
     "doctype=s" =>      \$document_type,

     "title=s", 			# document attributes
     "footer=s", 			# document attributes
     "output=s" => \$output,		# output name
     "chapter=i" => \$chapnum,		# initial chapter number
     "config=s" => \@config,		# config file(s)
     "toc!" => $toc,			# (suppress) table-of-contents
     "index",				# generate index
     "makeindex",			# generate index, but do not print
     "nochain" => \$nochain,		# do not follow document chain
     "keycaps" => \$keycaps,		# substitute keycap codes
     "border!" => \$border,		# include border (for slides)
     "portrait"  => sub { $landscape = 0 }, # portrait mode (for slides)
     "landscape" => sub { $landscape = 1 }, # landscape mode (for slides)
     "handouts" => \$handouts,
     "draft" => \$draft,		# overlay wth 'DRAFT'
     "language=s" => \$language,	# language code
     "feedback=s" => \$feedback,	# feedback file name
     "raw" => \$raw,			# output control
     "ident",				# identification
     "verbose" => \$verbose,		# verbose info
     "quiet" => \$quiet,
     "help|?" => \$help,

     # Development.
     "test"   => $test,
     "debug"  => \$debug,
     "trace"  => \$trace,

     # Obsolete.
     "margin=i" => \&optsolete,
     "width=i"  => \&optsolete,
 ) || $help ) {
    print STDERR <<EndOfUsage;
This is $my_package [$my_name $my_version]
Usage: $0 [options] file...
  options are:
    -generate text|html|latex|latex209 select output type (def: text)
    -chapter NN		initial chapter number
    -title XXX          specify title of the document (generic only)
    -footer XXX         specify footer of the document (generic only)
    -output XXX		name of output file
    -[no]toc		[suppress] table-of-contents
    -index		generate index
    -makeindex		generate index, but do not include in the output
    -nochain		do not follow document chain
    -keycaps		substitute keycap codes
    -noborder		do not include border (sheets only)
    -portrait		portrait mode (sheets only)
    -landscape		landscape mode (sheets only)
    -handouts		handouts format (overhead sheets only)
    -draft		draft document printing
    -generic		override document type
    -language XX	language code (NL, EN, ...)
    -raw		retain control (text output only)
    -ident		print program name and version
    -verbose		verbose info
    -quiet		no info
    -help		this message
EndOfUsage
    exit 1;
}

our $noindex = 0;
our $notitlepage = 0;

$language = lc($language) if $language;
my $force_generic = 0;
if ( $document_type ) {
    $force_generic = lc($document_type) eq "generic";
}
else {
    $document_type = "generic";
}
my $doctype_fixed = 0;

my $args = "@ARGV";

our $cfg = MMDS::Common::->get_config(join(",",@config));

$language ||= $cfg->gps("general.language");
set_language($language);

our $inputencoding = $cfg->gps("general.input.encoding", "iso-8859-1");
our $use_ts1       = $cfg->gps("tools.latex.use_ts1", 0);

################ Output selection ################

# Redirect output if desired. On the other hand, connect
# STDOUT to STDERR if debug is selected. Output redirection using
# -output does not work in this case.

if ( defined $output && $output ne "-" ) {
    die ("Error: Cannot create $output [$!]\n") 
	unless open (STDOUT, ">$output");
}

*STDOUT = *STDERR if $debug;

################ Selecting the backend ################

my $outdrv;

my $pkg = "MMDS::Output::" . ucfirst($cvttype);
if ( eval { ::loadpkg($pkg) } ) {
    $outdrv = $pkg->new;
}
else {
    die("No MMDS::Output plugin for \"$cvttype\"\n");
}

################ Main program ################

init();
phase_msg("Converting to " . $outdrv->id_tag) unless $quiet;

our $tabular_saved_context;

no strict;

if ( defined($::dtp_name{lc($document_type)}) ) {
    $document_type = $::dtp_name{lc($document_type)};
}
else {
    die("Unsupported document type: $document_type\n");
}

@ARGV = ('-') unless @ARGV;
while (@ARGV) {

    $file = shift (@ARGV);

    unless ( -s $file ) {
	die ("Empty document?\n");
    }
    else {
	open (FILE, '<'.$file) || die ("Cannot read $file [$!]\n");
	print STDERR ("(", &pathexpand ($file), ")\n") if $verbose;
    }

    $delete_vertical_space = 1;
    $lines_to_skip = 0;
    $try_headers = 1;
    $this_header = $::HDR_NULL;
    $enriched_mode = 0;

    while ( $current_line = <FILE> ) {

	if ( $. == 1 && $current_line =~ m|^Content-Type: text/enriched|i ) {
	    $enriched_mode = 1;
	    do {
		$_ = <FILE>;
	    } while /\S/;
	    next;
	}

	# Double formfeed separates documents
	if ( $current_line =~ /^\f\f[\n\r]+$/ ) {
	    $try_headers = 1;
	    $this_header = $::HDR_NULL;
	    next;
	}

	# Get rid of LF, CR and FF characters (no need to chop anymore)
	$current_line =~ s/[\n\r\f]//g;

	# Some directives cause a number of lines to be skipped.
	next if $lines_to_skip-- > 0;
	$lines_to_skip = 0;

	# Sometimes empty (blank) lines are insignificant. Delete them.
	next if ( ($delete_vertical_space || !$inited || $try_headers)
		 && $current_line =~ /^\s*$/ );
	$delete_vertical_space = 0;

	# Replace tabs with blanks, retain layout
	# Call only if needed (reduce overhead).
	$current_line = &detab ($current_line) if $current_line =~ /\t/;

	# Determine type of line and call appropriate routine.

	# Control lines start with a period.
	if ( $current_line =~ /^\./ ) {
	    # Pass it to the routine with the period stripped off.
	    &control_line ($');
	}

	# Else, a data line ...
	else {

	    $current_line = &decode_enriched ($current_line) if $enriched_mode;

	    # Initially we try to find out if this document contains
	    # headers, e.g. "Title: Blah".
	    if ( $try_headers ) {
		# $try_headers is initialized to 1. 
		# Valid transitions for try_headers:
		#  1 -> 2, 2, ..., 2, 0 : if headers found
		#  1 -> 1 : this is not a (known) header
		$try_headers = &scan_header ($current_line, $try_headers);
		if ( $try_headers == 1 ) {
		    # Not a known header. No use trying anymore.
		    $try_headers = 0;
		}
		else {
		    # Found a header. $try_headers is now 2.
		    # Discard blank lines, and proceed.
		    $delete_vertical_space = 1;
		    $inited = 2 if $inited;
		    next;
		}
	    }

	    if ( $inited == 0 ) {

		# The very first probably ouput-generating line of data.

		# Supply default values for headers, and complain
		# about missing headers for this document type.
		&set_headers;

		# Initialize backend
		$outdrv->init();

		$inited = 1;

		$guess_margin = 1;
	    }
	    elsif ( $inited == 2 ) {
		&set_headers;
		$outdrv->emit_newdocument;
		$inited = 1;
	    }

	    # Re-guess the margin if appropriate.
	    if ( $guess_margin && $current_line =~ /\S/ ) {

		# Don't care about the result. Take its length.
		$ruler_margin = length ($`);
		# Initialize margin stack and associated variables.
		@margin_stack = ($tent_margin = $ruler_margin);
		$guess_margin = 0;
	    }

	    # Handle data line.
	    &data_line ($current_line);
	}

	last if $test && $. > 100;
    }

    &flush_line;
    close (FILE);
}

# Finally...
&wrap_up;
exit ($error_count != 0);

################  Subroutines ################

sub init {

    $error_count = 0;		# none
    $pending_text = "";		# nothing
    $pending_tag = "";		# none
    $pending_style = -1;	# unknown
    $lines_to_skip = 0;		# none
    $delete_vertical_space = 0; # no
    $ruler_margin = 6;		# initial
    @margin_stack = ($tent_margin = $ruler_margin);	# initial
    $guess_margin = 1;		# try to find out
    $inited = 0;		# the generators are not inited yet
    $try_headers = 1;		# try to find headers
    $enriched_mode = 0;		# enriched mode

    $tabbing = $tabular = $literal = 0;	# not yet

    # Set header stuff
    set_language($language);

    phase_msg ("This is $my_package" .
	       " [" . nls($::TXT_LANGUAGE) . "]" ) if $opt_ident;

    # Styles and leaders.
    &::enum
	($::STANDARD=1, $::ENUM1, $::ENUM2, $::HEADER1, $::HEADER2,
	 $::HEADER3, $::CAPTION1, $::CAPTION2);
    &::enum
	($::LEADER_NONE=0, $::LEADER_DEFAULT, $::LEADER_ALPH, $::LEADER_NUM,
	 $::LEADER_BULLET, $::LEADER_DASH, $::LEADER_EMPTY);
    &::enum
	($::TBCTL_INIT=0, $::TBCTL_ROW, $::TBCTL_COL, $::TBCTL_END,
	 $::TBCTL_HEAD);

    # Provide defaults
    local (@pw) = getpwuid ($<);
    ($::headers[$::HDR_MHID] = $ENV{"MMDS_ID"}
     || $cfg->gps("general.id", $pw[0])) =~ tr/[a-z]/[A-Z]/;
    $::headers[$::HDR_AUTHOR] = $::headers[$::HDR_FROM] =
     $ENV{"MMDS_FULLNAME"} || $ENV{"FULLNAME"}
     || $cfg->gps("general.author", $pw[6]);
    $::headers[$::HDR_CITY] = $cfg->gps("general.city", "Doolin");
    $::headers[$::HDR_VERSION] = "X0.0";
    $::headers[$::HDR_COMPANY] = $cfg->gps("general.company",
				       "Free Software Foundation");
    $::headers[$::HDR_DEPT] = $ENV{"MMDS_DEPT"} || $ENV{"MMDS_DEPARTMENT"}
			    || $cfg->gps("general.department",
					 "League of Programming Freedom");
    $::headers[$::HDR_DEPT] = $::headers[$::HDR_COMPANY]
	unless vec ($::hdr_set, $::HDR_DEPT, 1) =
	    defined $::headers[$::HDR_DEPT] && ($::headers[$::HDR_DEPT] ne "");
    $::headers[$::HDR_CMPY] = $cfg->gps("general.cmpy", "FSF");
    $::headers[$::HDR_CLOSING] = &nls ($::TXT_CLOSING)
	unless defined $::headers[$::HDR_CLOSING];
    $::headers[$::HDR_CLOSING] .= "\n" . $::headers[$::HDR_COMPANY];

    # Set document properties, if known.
    &set_document_type ($document_type) if $document_type;

    # Open feedback file.
    if ( $feedback ) {
	$feedback = open (FEEDBACK, ">$feedback");
	err("Cannot create $feedback: [$!]") unless $feedback;
    }
}

sub wrap_up {
    if ( $inited ) {
	flush_line();		# flush pending output
	$outdrv->wrapup($error_count);
	close(FEEDBACK) if $feedback;
    }
    else {
	print STDERR ("Empty document?\n");
    }
    if ( $error_count ) {
	phase_msg("Errors detected = $error_count");
    }
    else {
	phase_msg("Conversion completed") if $verbose;
    }
}

sub warn {
    my (@msg) = @_;
    # Common trick: call error handler and decrement error counter.
    err("Warning: ", @msg);
    $error_count--;
}

sub err {
    my (@text) = @_;
    print STDERR ("\"$file\", line ", $., ": ", @text, "\n",
		  $current_line, "\n");
    $error_count++;
}

sub feedback {
    my ($var,$val) = @_;
    return unless $feedback;
    print FEEDBACK ('$feedback_', $var, " = '", $val, "';\n");
    print STDERR ("Feedback: $var = '$val'\n") if $verbose;
}

sub feedbacka {
    my ($var,$val) = @_;
    return unless $feedback;
    print FEEDBACK ('push (@feedback_', $var, ", '", $val, "');\n");
    print STDERR ("Feedback: push (\@$var, '$val')\n") if $verbose;
}

################ Primary input consuming ################

# All input consuming routines get a chopped (primary,overlay)
# pair as parameters. Currently, the overlay part is ignored.

sub control_line {
    my ($line) = @_;
    debug_msg("control_line", @_) if $debug;

    if ( $line =~ /^[I]/i ) {
	# Ignore!
    }
    else {
	&warn ("Unknown directive");
    }
}

sub check_margin {
    my ($why, $do) = @_;
    if ( $rem ne "" && length($tag) < $do ) {
	err("Garbage in ", $why, " margin: \"" .
	    substr($line, 0, $do) . "\"");
	$line = (" " x $do) . $rem;
    }
}

sub data_line {
    my ($line) = @_;
    $line =~ s/\s+$//;		# trim

    debug_msg("data_line", @_) if $debug;

    my ($tag, $rem) = ( $line =~ /^(\s*)(.*)$/ );

    # Protect quotes for raw output
    $line =~ tr/\320\336/"'/ if $raw;		#"/;

    # If there is no whitespace at the left, it must be a chapter/
    # section header number.
    if ( $line =~ /^([0-9A-Z]+\.[0-9.]*)(\s+.*)?$/ ) {
	# Okay. Ship it out.
	($tag, $rem) = ($1, $2);

	# But...
	if ( $literal || $tabular ) {
	    &err ("Unexpected end of ",
		 $literal ? "literal" : "columns", " environment");
	    &flush_line;
	}
	&flush_line if $tabbing;

	&header_line (&deblank($rem), $tag);
	# Blank lines are insignificant after a header.
	$delete_vertical_space = 1;
	# Must calculate new text margin
	$guess_margin = 1;
	return;
    }

    if ( $line =~ /^[0-9A-Z]+\s+/ ) {
	&warn ("Looks like a chapter number, but isn't");
    }

    # If processing a literal section, anything goes except the
    # "[end literal]" terminator line.
    if ( $literal ) {
	&check_margin ("literal", $literal-1);
	if ( $rem =~ /^\[end ?(literal|screen|ignore|inline)\]$/i && 
	    length($tag)+1 == $literal ) {
	    &flush_line;
	    return;
	}
	# Take substr of $line instead of $rem, since we need to
	# retain (leading) blanks.
	$pending_text .= "\t" . substr ($line, $literal-1);
	return;
    }

    # If processing a table, check for the
    # "[end table]" terminator line.
    if ( $tabular ) {
	&check_margin ("table", $tabular-1);
	if ( $rem =~ /^\[end ?table\]$/i ) {
	    &flush_line;
	    &tabcontrol ($::TBCTL_END);
	    $tabular = 0;
	    $current_style = $::STANDARD;
	    ($pending_style, $tent_margin, @margin_stack) = @tabular_saved_context;
	    print STDERR ("=> context restored = (@tabular_saved_context)\n")
		if $debug;
	    $pending_para = 1;
	    return;
	}
	# The line will be handled later on.
    }

    # An empty (blank) line indicates a new paragraph.
    if ( $line !~ /\S/ ) {
	&flush_line;
	$para_pending = 1;
	return;
    }

    # May not be less than ruler margin.
    if ( $tabbing ) {
	&check_margin ("column", $tabbing-1);
    }
    else {
	&check_margin ("text", $ruler_margin);
    }

    # Check for special controls.
    # Control lines contain info between [ and ].
    # Semantically, they are equivalent to a blank line.
    # Literals have been checked, prevent within tabbing.
    # The actual indentation used is significant!
    if ( !$tabbing && $rem =~ /^\[.*\]$/ ) {
	# Flush anything pending.
	&flush_line;
	if ( $pending_style == $::ENUM2 ) {
	    if ( length ($tag) < $margin_stack[2] ) {
		if ( length ($tag) >= $margin_stack[1] ) {
		    # back to enum1
		    $outdrv->emit_enum (1, "", "", "");
		    $pending_style = $::ENUM1;
		}
		else {
		    # back to normal
		    $outdrv->emit_para ($::STANDARD, "");
		    $pending_style = $::STANDARD;
		}
	    }
	}
	elsif ( $pending_style == $::ENUM1 ) {
	    if ( length ($tag) < $margin_stack[1] ) {
		# back to normal
		$outdrv->emit_para ($::STANDARD, "");
		$pending_style = $::STANDARD;
	    }
	}
    }

    # Sigh.
    if ( $rem =~ /^\[\[?newpage\]?\]$/ ) {
	$outdrv->emit_tabular ($rem);
	return;
    }

    # Scalc interface
    if ( $rem =~ /^\[\[?scalc\s+([^ \t\135]+)(\s+.*)?\]?\]$/i ) {
	require "scalc.pl";
	&scalc_sheet ($1, $2);
	&flush_line;
	return;
    }

    # Guru control is [[...]].
    if ( $rem =~ /^\[\[.+\]\]$/ ) {
	# Treat as tabbing
	$pending_text = $rem;
	$tabbing = length ($tag) + 1;
	return;
    }

    # Literal is introduced by [literal] etc.
    if ( $rem =~ /^\[(literal|screen)(\s+(tiny|small|large|landscape))*\]$/i ) {
	$literal = length ($tag) + 1; # zero is a valid tag length!
	($pending_text = $rem) =~ tr/[A-Z]/[a-z]/;
	return;
    }

    # In-line is introduced by [inline ...].
    if ( $rem =~ /^\[inline\s+.+\]$/i ) {
	$literal = length ($tag) + 1;	# zero is a valid tag length!
	$pending_text = $rem;
	return;
    }

    # Ignore is introduced by [ignore ...].
    if ( $rem =~ /^\[ignore\b.*\]$/i ) {
	$literal = length ($tag) + 1;	# zero is a valid tag length!
	($pending_text = $rem) =~ tr/[A-Z]/[a-z]/;
	return;
    }

    # Tabular is introduced by [table ...]
    if ( $rem =~ /^\[table\s+(.+)\]/i ) {
	@tabular_saved_context = ($pending_style, $tent_margin, @margin_stack);
	print STDERR ("=> context saved = (@tabular_saved_context)\n")
	    if $debug;
        &tabcontrol ($::TBCTL_INIT, $1);
	$pending_style = $::STANDARD;
	$tabular = length ($tag) + 1;
	return;
    }

    # Check for special tabular lines
    if ( $tabular && $rem =~ /^\[(row|head)\]$/i ) {
	&tabcontrol ("\L$1" eq "row" ? $::TBCTL_ROW : $::TBCTL_HEAD);
	$pending_style = $::STANDARD;
	return;
    }

    # Columns. Treat like tabbing.
    if ( !$tabbing && $rem =~ /^\[tabular\s+.*\]$/i ) {
	# All following lines must have the same (blank) margin, 
	$tabbing = length($tag)+1; 
	$pending_text = $rem;
	$pending_text =~ tr/[A-Z]/[a-z]/;
	return;
    }

    # Tabbing is introduced by a line containing [....T....] etc.
    # or [...][....]; [^] refers to the last tabbing used.
    if ( !$tabbing && $rem =~ /^\[.*\]$/ ) {
	$rem = $last_tab_used if $rem =~ /^\[\^\]$/ && $last_tab_used;
	local ($ctl) = substr($rem,1,length($rem)-2);

	# Convert old style tabs
	$ctl =~ s/\]\[[l<]/ L /ig;
	$ctl =~ s/\]\[[r>]/ R /ig;
	$ctl =~ s/\]\[[c|]/ C /ig;
	$ctl =~ s/\]\[/ T/g;

	# Verify sanity of tabbing construct.
	&err ("Invalid column control") if $ctl =~ /[\[\]]/;
	&warn ("Column control contains illegal characters")
	    unless ( $ctl =~ /^[lrctfinm ]*/i
		    || ( $document_type == $::DTP_OFFERING
			&& $ctl =~ /^(emphasis|strong)$/i));

	# All following lines must have the same (blank) margin, 
	$tabbing = length($tag)+1; 
	$pending_text = $last_tab_used = '[' . $ctl . ']';
	$pending_text =~ tr/[A-Z]/[a-z]/;
	return;
    }

    # Check for special tabular lines
    if ( $tabular ) {
	if ( $rem =~ m|//| ) {
	    while ( $rem =~ m|\s*//\s*| ) {
		$rem = $';
		if ( $tabbing ) {
		    $pending_text .= "\t" . substr ($tag.$`, $tabbing-1);
		}
		else {
		    $pending_text .= &deblank($`) . " ";
		}
		&flush_line;
		&tabcontrol ($::TBCTL_COL);
		$pending_style = $::STANDARD;
	    }
	    if ( $tabbing ) {
		$pending_text .= "\t" . substr ($tag.$rem, $tabbing-1);
	    }
	    else {
		$pending_text .= &deblank($rem) . " ";
	    }
	    return;
	}
    }

    # Handle tabbing now
    if ( $tabbing ) {
	# Take substr of $line instead of $rem, since we need to
	# retain (leading) blanks.
	$pending_text .= "\t" . substr ($line, $tabbing-1);
	return;
    }

    # Phew. Apparently a normal data line.
    # Check for start of enumeration.
    # Allow only "1." and "a." to start a numbered enumeration,
    # unless we're already enumerating.

    # Try special enumeration first (unreleased)
    if ( $rem =~ /^--\s*/ && 0 ) {
	$tabbing = length($tag)+1; 
	$pending_text = '[mi' . 
	    ( 'n' x (length ($&) - 3 )) .
	    'f]' . "\t$&" . &deblank($');
	return;
    }

    # Normal enumeration
    elsif ( $rem =~ /^(o|\*|-|1\.|a\.)\s+/
	|| ( $pending_style == $::ENUM1 || $pending_style == $::ENUM2 )
	    && ( $rem =~ /^(\d+\.|[a-z]\.)\s+/ )) {
	local ($localmargin) = length ($tag);
	$tag .= $&;
	$rem = $';
	$pending_para = $para_pending;
	&flush_line;
	&set_margin (length($tag));
	$pending_style = (@margin_stack > 2 ) ? $::ENUM2 : $::ENUM1;
#	$pending_style = ($localmargin > $margin_stack[0]) ? $::ENUM2 : $::ENUM1;
	$pending_tag = $::LEADER_DEFAULT;
	$pending_tag = $::LEADER_ALPH if $tag =~ /^\s*[a-z]\.\s*$/;
	$pending_tag = $::LEADER_NUM if $tag =~ /^\s*\d+\.\s*$/;
	$line = $rem;
    }

    # Not an enumeration. Check if the margin has changed.
    # Note that is may only decrease.
    elsif ( length ($tag) < $tent_margin ) {
	&flush_line;
	&set_margin (length ($tag));
	$pending_style = ($#margin_stack == 0) ? $::STANDARD :
	    ($#margin_stack == 1) ? $::ENUM1 : $::ENUM2;
	$pending_tag = $::LEADER_NONE;	# no tag for this paragraph
    }

    # Treat a normal piece of text. Append it to the pending
    # text. Remove hyphenation if input is from LEX document.
    if ( $lex_input && $line =~ /-$/ ) {
	chop ($line);
	$pending_text .= &deblank($line);
    }
    else {
	$pending_text .= &deblank($line) . " ";
    }
}

################ Header Handling Subroutines ################

sub set_document_type {
    my ($type) = @_;

    # This is a no-op is the type is not known yet.

    return if $type == $::DTP_GENERIC;
    $document_type = $type;
    # Reserved for future expansion...
    $landscape = 1 if $type == $::DTP_SLIDES && $landscape < 0;
}

sub set_language {
    my ($lang) = @_;
    $lang = "en" if $lang eq "uk"; # compat
    $lang = '-' . $lang if $lang;
    do "hdrinfo$lang.pl" ||
	die ("No support for language \"", substr($lang, 1), "\"",
	     " -- Aborted.\n");
    ::nls_init(\@::nls_table);
}

sub scan_header {
    my ($line, $try) = @_;
    my $the_value;
    my $hdr;

    # Scan a header.
    # $try = 1 -> trying, 2 -> sure
    # return 1 -> unsuccessful attempt,
    #	     2 -> found a header,
    #	     0 -> end of headers

    if ( $line =~ /^\s*([\w.]+)\s*:\s*/ ) {
	$hdr = $1;
	$the_value = $';
	print STDERR "=Trying header: $hdr \"$the_value\" -> " if $debug;
	$hdr =~ s/^(.)(.*)$/\u$1\L$2\E/;
	print STDERR $hdr, " -> " if $debug;
	if ( defined ( $hdr = $::hdr_tag{$hdr}) && 
	    ($hdr != $::HDR_NULL || $this_header ne "")) {
	    print STDERR $hdr, " -> ", $::hdr_name[$hdr], "\n" if $debug;
	}
	else {
	    print STDERR "fail\n" if $debug;
	    &err ("Unknown header") unless $try == 1;
	    return $try == 1 ? 1 : 2;
	}
    }
    elsif ( $line =~ /^\s*[=_-]+\s*$/ ) {
	# End of headers.
	return 0;
    }
    elsif ( $this_header != $::HDR_NULL && $line =~ /^\s+(.+)\s*$/ ) {
	# Append to previous header
	$::headers[$this_header] .= "\n" . $1;
	return 2;		# found a header
    }
    else {
	# Not a header.
	&err ("Illegal header") unless $try == 1;
	return 1;
    }

    if ( $document_type == $::DTP_GENERIC ) {

	# The document_type is not known yet. Let's see if this
	# is a header that is unique for one specific type of document.
	&set_document_type ($::hdr_dtp[$hdr]) if defined $::hdr_dtp[$hdr];
    }

    unless ( $document_type == $::DTP_GENERIC ||
	    (vec ($::dtp_allow[$document_type], $hdr, 1)) ||
	    ($doctype_fixed && defined $::hdr_dtp[$hdr]) ) {
	&err ("Header \"$::hdr_name[$hdr]\" not allowed for document type ".
		"\"$::dtp_name[$document_type]\"");
	return 1;
    }

    $this_header = $hdr;

    # Skip headers w/o value
    unless ( $the_value ) {
	undef $::headers[$this_header];
	vec ($::hdr_set, $this_header, 1) = 0;
	return 2;
    }

    # Assign value (not fully operational yet)
    if ( 0 && defined $::headers[$this_header] && vec ($::hdr_set, $this_header, 1) ) {
	$::headers[$this_header] .= "\r" . $the_value;
    }
    else {
	$::headers[$this_header] = $the_value;
	vec ($::hdr_set, $this_header, 1) = 1;
    }
    return 2;		# found
}

sub set_version {
    my ($VV,$vv,$rr,$ll);
    unless ( vec ($::hdr_set, $::HDR_VERSION, 1) ) {
	$::headers[$::HDR_VERSION] = "X0.0";
	return;
    }
    my ($version) = $::headers[$::HDR_VERSION];
    if ( ($L,$VV,$vv,$rr,$ll,$R) = 
	($version =~ /^\s*(.*)([XYV])(\d+)\.(\d+)\.(\d+)(.*)$/i) ) {
	if ( $ll <= 1 ) {
	    $version = "";
	}
	else {
	    $version = "A";
	    while ($ll-- > 2) {
		$version++;
	    }
	}
	$::headers[$::HDR_VERSION] = $L . $VV . sprintf("%d.%02d", $vv, $rr) . $version . $R;
    }
    elsif ( ($L,$VV,$vv,$rr,$ll,$R) = 
	   ($version =~ /\s*(.*)([XYV])(\d+)\.(\d+)([a-zA-Z]*)(.*)$/i) ) {
	$ll =~ tr/[a-z]/[A-Z]/;
	$::headers[$::HDR_VERSION] = $L . $VV . sprintf("%d.%02d", $vv, $rr) . $ll . $R;
    }
    elsif ( ($L,$vv,$rr) = 
	   ($version =~ /^\s*(.*)\$Revision: 2.124 $/i) ) {
	$R = $';
	$VV = 'V';
	if ( $R =~ /^\s*\$Locker:  $\s*/ ) {
	    $VV = 'X';
	    $R = $';
	}
	$::headers[$::HDR_VERSION] = $L . $VV . sprintf("%d.%02d", $vv, $rr) . $R;
    }
}

sub set_headers {

    # Validate consistency of headers, supply default values
    # if needed.

    my (@ts) = localtime (time);
    my $year = $ts[5] + ($ts[5] < 72 ? 2000 : 1900);

    # Handle OPTIONS header now.
    if ( defined $::headers[$::HDR_OPTIONS] ) {
	foreach my $opt ( split (/[ \t]*,\s*/, $::headers[$::HDR_OPTIONS]) ) {
	    if ( $opt =~ /keycaps/i ) {
		$keycaps = 1;
	    }
	    elsif ( $opt =~ /no\s*toc/i ) {
		$toc = 0;
	    }
	    elsif ( $opt =~ /landscape/i ) {
		$landscape = 1;
	    }
	    elsif ( $opt =~ /portrait/i ) {
		$landscape = 0;
	    }
	    elsif ( $opt =~ /justify/i ) {
		$justify = 1;
	    }
	    elsif ( $opt =~ /no\s*justify/i ) {
		$justify = 0;
	    }
	    elsif ( $opt =~ /no\s*border/i ) {
		$border = 0;
	    }
	    elsif ( $opt =~ /no\s*index/i ) {
		$noindex = 1;
	    }
	    elsif ( $opt =~ /chapter\s+(\d+)/i ) {
		$chapnum = $1 unless $chapnum;
	    }
	    elsif ( $opt =~ /type\s+(.+)\s*$/i ) {
		$ok = $::DTP_GENERIC; 
		($try = $1) =~ tr/[A-Z]/[a-z]/;
		foreach $hdr ( 0..@::dtp_name ) {
		    if ( $::dtp_name[$hdr] eq $try ) {
			$ok = $hdr;
			last;
		    }
		}
		if ( $ok != $::DTP_GENERIC ) {
		    &err ("Document type conflict")
			unless $document_type == $::DTP_GENERIC
			    || $ok == $document_type;
		    &set_document_type ($ok);
		    $doctype_fixed = 1;
		}
		else {
		    &err ("Unknown document type: \"", $1, "\"");
		}
	    }
	    elsif ( $opt =~ /language\s+(\S+)\s*$/i ) {
		$try = lc($1);
		set_language($try)
		    unless $try eq $language;
	    }
	    elsif ( $opt =~ /no\s*titlepage/i ) {
		$notitlepage = 1;
	    }
	    else {
		&err ("Illegal value \"$opt\" for header \"",
		      $::hdr_name[$::HDR_OPTIONS], "\"");
	    }
	}
    }

    # Last ressorts
    if ( $document_type == $::DTP_GENERIC ) {
	if ( vec ($::hdr_set, $::HDR_VERSION, 1) ||
	     #vec ($::hdr_set, $::HDR_TITLE, 1) ||
	     vec ($::hdr_set, $::HDR_MHID, 1) ||
	     #vec ($::hdr_set, $::HDR_AUTHOR, 1) ||
	     vec ($::hdr_set, $::HDR_DOCID, 1)) {
	    &set_document_type ($::DTP_REPORT);
	}

	# If SUBJECT, but not REF -> MEMO
	elsif ( vec ($::hdr_set, $::HDR_SUBJECT, 1) &&
	     !vec ($::hdr_set, $::HDR_REF, 1)) {
	    &set_document_type ($::DTP_MEMO);
	}
    }

    # Normalize headers
    foreach my $hdr ( 0..$#headers ) {
	next unless defined $::headers[$hdr];
	unless ( $document_type == $::DTP_GENERIC ||
		 !vec ($::hdr_set, $hdr, 1) ||
		 vec ($::dtp_allow[$document_type], $hdr, 1) ||
		 ($doctype_fixed && defined $::hdr_dtp[$hdr]) ) {
	    &err ("Header \"$::hdr_name[$hdr]\" not allowed for document type ".
		  "\"$::dtp_name[$document_type]\"");
	}
	next if $hdr == $::HDR_TITLE &&
	    $document_type =~ /^($::DTP_REPORT|$::DTP_NOTE|$::DTP_OFFERING)$/;
	next if $hdr =~ /^($::HDR_TO|$::HDR_FROM|$::HDR_CC|$::HDR_CLOSING)$/ 
	    && $document_type == $::DTP_LETTER;
	next if $hdr == $::HDR_ENCL;
	$::headers[$hdr] =~ s/[ \t\r\n]+/ /g;
    }

    if ( $::headers[$::HDR_DATE] =~ /^(\d{2,4})(\d\d)(\d\d)$/ ) {
	if ( $2 >= 1 && $2 <= 12 && $3 >= 0 && $3 <= 31 ) {
	    $ts[4] = $2-1;
	    $ts[3] = 0 + $3;
	    $year = $1;
	    $year += 1900 if $year < 100;
	    undef $::headers[$::HDR_DATE];
	}
    }
    elsif ( $::headers[$::HDR_DATE] =~ /^(\d+)-(\d+)-'?(\d+)$/ ) {	#'/){
	if ( $2 >= 1 && $2 <= 12 && $1 >= 0 && $1 <= 31 ) {
	    $year = $3;
	    $year += 1900 if $year < 100;
	    $ts[4] = $2-1;
	    $ts[3] = 0 + $1;
	    undef $::headers[$::HDR_DATE];
	}
    }

    if ( $document_type == $::DTP_MEMO ) {
	$::headers[$::HDR_TITLE] = $opt_title
	    if defined $opt_title;
	$::headers[$::HDR_TITLE] = &nls ($::TXT_MEMO)
		unless defined $::headers[$::HDR_TITLE];
	$::headers[$::HDR_DATE] = &make_date ($ts[3], $ts[4], $year) 
	    unless defined $::headers[$::HDR_DATE];
	$::headers[$::HDR_PHONE] = "(" . &nls ($::TXT_PHEXT) . " " .
	    $::headers[$::HDR_PHONE] . ")"
	    if defined $::headers[$::HDR_PHONE] && $::headers[$::HDR_PHONE] !~ /^\(/;
    }
    elsif ( $document_type == $::DTP_IMP ) {
	$::headers[$::HDR_TITLE] = $opt_title
	    unless defined $::headers[$::HDR_TITLE];
	$::headers[$::HDR_DATE] = $::month_names[$ts[4]] . " " . $year
	    unless defined $::headers[$::HDR_DATE];
    }
    elsif ( $document_type == $::DTP_MREP ) {
	$::headers[$::HDR_FROM] = $::headers[$::HDR_SECR]
	    unless defined $::headers[$::HDR_FROM] ||
		!defined $::headers[$::HDR_SECR];
	$::headers[$::HDR_DATE] = sprintf ("%02d-%02d-%04d",
				       $ts[3], 1+$ts[4], $year)
	    unless defined $::headers[$::HDR_DATE];
	$::headers[$::HDR_ABSENT] = ""
	    unless defined $::headers[$::HDR_ABSENT];
	$::headers[$::HDR_PHONE] = "(" . &nls ($::TXT_PHEXT) . " " .
	    $::headers[$::HDR_PHONE] . ")"
	    if defined $::headers[$::HDR_PHONE] && $::headers[$::HDR_PHONE] !~ /^\(/;
    }
    elsif ( $document_type == $::DTP_REPORT || $document_type == $::DTP_NOTE ) {
	$::headers[$::HDR_TITLE] = $opt_title
	    if defined $opt_title;
	$::headers[$::HDR_TITLE] = "Document: $args"
	    unless defined $::headers[$::HDR_TITLE];
	&set_version;
	unless ( defined $::headers[$::HDR_DATE] ) {
	    local ($month) = $::month_names[$ts[4]];
	    substr($month,0,1) =~ tr/[a-z]/[A-Z]/;
	    $::headers[$::HDR_DATE] = $month . " " . $year;
	}
    }
    elsif ( $document_type == $::DTP_LETTER ) {
	$::headers[$::HDR_DATE] = &make_date ($ts[3], $ts[4], $year)
	    unless defined $::headers[$::HDR_DATE];
    }
    elsif ( $document_type == $::DTP_OFFERING ) {
	&set_version;
	$::headers[$::HDR_DATE] = &make_date ($ts[3], $ts[4], $year)
	    unless defined $::headers[$::HDR_DATE];
    }
    elsif ( $document_type == $::DTP_SLIDES ) {
	&set_version;
	$::headers[$::HDR_TITLE] = $::headers[$::HDR_SLIDES];
	$::headers[$::HDR_DATE] = &make_date ($ts[3], $ts[4], $year)
	    unless defined $::headers[$::HDR_DATE];
    }

    else {
	unless ( $document_type eq "generic" ) {
	    CORE::warn("Document type could not be determined" .
		       " -- using generic type\n");
	    $document_type = "generic";
	    $force_generic = 1;
	}
    }

    if ( $document_type eq "generic" ) {
	$::headers[$::HDR_TITLE] = $opt_title
	    if defined $opt_title;
	$::headers[$::HDR_FROM] = $opt_footer
	    if defined $opt_footer;
    }

    if ( defined $::headers[$::HDR_DOCUMENTSTYLE] ) {
	# Append to default headers if it starts with a '+'.
	$::headers[$::HDR_DOCUMENTSTYLE] =
	  join(" ", "-",
	       $cfg->gps("documents.".$::dtp_name[$document_type].".style",
			 $cfg->gps("documents.default.style")),
	       $cfg->gps("documents.".$::dtp_name[$document_type].".args",
			 $cfg->gps("documents.default.args", undef)),
	       $')
	    if $::headers[$::HDR_DOCUMENTSTYLE] =~ /^\+\s*/;
    }
    else {
	$::headers[$::HDR_DOCUMENTSTYLE] =
	  join(" ", "-",
	       $cfg->gps("documents.".$::dtp_name[$document_type].".style",
			 $cfg->gps("documents.default.style")),
	       $cfg->gps("documents.".$::dtp_name[$document_type].".args",
			 $cfg->gps("documents.default.args", undef)));
    }

    foreach $hdr ( split(/:/, $::dtp_mand[$document_type]) ) {
	&err ("Header \"" . $::hdr_name[$hdr] . "\" not defined")
	    unless defined $::headers[$hdr] && $::headers[$hdr] ne "";
    }

    if ( !$nochain && defined $::headers[$::HDR_NEXT] ) {
	@docs = split (/ +/, $::headers[$::HDR_NEXT]);
	foreach $path ( reverse @docs ) {
	    print STDERR ("Nextdoc: $path\n") if $verbose;
	    unshift (@ARGV, &pathexpand ($path));
	}
	undef $::headers[$::HDR_NEXT];
    }

    # The big undo...
    $document_type = $::DTP_GENERIC if $force_generic;

    # Warn against unexpected results
    unless ( $document_type == $::DTP_LETTER 
	    || $document_type == $::DTP_SLIDES 
	    || $document_type == $::DTP_GENERIC ) {
	&warn ("Header \"" . $::hdr_name[$::HDR_DEPT], 
	      "\" not set, using \"$::headers[$::HDR_DEPT]\"")
	    unless vec ($::hdr_set, $::HDR_DEPT, 1);
    }

    # Feedback properties that may be of interest to the outer world.
    &feedback ('document_type', $::dtp_name[$document_type]);
    &feedback ('document_landscape', $landscape);
    &feedback ('document_titlepage', !$notitlepage);
    &feedback ('document_toc', $toc);
    &feedback ('document_index', !$noindex);
}

################ Other subroutines ################

sub make_date {
    my ($dd, $mm, $yy) = @_;
    if ( $::nls_day_after_month ) {
	$::month_names[$mm] . " " . $dd . ", " . $yy;
    }
    else {
	$dd . " " . $::month_names[$mm] . " " . $yy;
    }
}

sub set_margin {

    # Set tent_margin at the designated value, adjusting the margin stack.
    # Return the previous value.

    my ($at) = @_;
    my ($old_margin) = $margin_stack[$#margin_stack];

    return $old_margin if $at == $old_margin;

    while ( $at <= $margin_stack[$#margin_stack] && $#margin_stack >= 0 ) {
	pop(@margin_stack);
    }

    push(@margin_stack, $at);
    print STDERR ("-> margin stack (", join(",",@margin_stack), ")\n")
	if $debug;

    $tent_margin = $at;
    $old_margin;
}

sub flush_line {

    print STDERR ("=> flush_line",
		  $pending_text ? " (" . $pending_style . ", " .
		  &dpstr($pending_text) . ", " .
		  $pending_tag . ")" : "",
		  $para_pending ? "+" : "", 
		  $tabbing ? "*" : "", "\n") if $debug;

    if ( $pending_text ne "" ) {

	if ( $tabbing || $literal ) {
	    $outdrv->emit_tabular ($pending_text)
		unless ( $pending_text =~ /^\[ignore\b/ );
	}
	elsif ( $pending_style >= $::ENUM1 && $pending_style <= $::ENUM2 ) {
	    $outdrv->emit_enum ($pending_style-$::ENUM1+1, $pending_tag, $pending_text,
			$pending_para);
	}
	else {
	    $outdrv->emit_para ($pending_style, $pending_text);
	}
    }

    # Reset flags.
    $pending_text = $pending_tag = "";
    $tabbing = $literal = $para_pending = 0;
}

sub header_line {
    my ($line, $tag) = @_;
    debug_msg("header_line", @_) if $debug;

    my $depth;

    # Start a header.

    my @depth = split(/\./, $tag);	# get depth
    $depth = @depth;

    flush_line();		# flush pending output

    if ( $depth == 1 && $tag =~ /^[a-z]/i ) { # appendix
	$outdrv->emit_header(-1, $line, $tag);
    }
    else {
	$outdrv->emit_header($depth, $line, $tag);
    }

    $pending_style = $::STANDARD;	# revert to standard style
}

sub tabcontrol {
    my $result = $outdrv->emit_tab_control;
    return 1 unless $result;
    err("Table error: ", $result);
}

sub deblank {
    my ($line) = @_;

    # Discard leading and trailing white-space.
    # Compress multiple white-space to single blanks.

    $line = $' if $line =~ /^\s+/; # leading...
    $line = $` if $line =~ /\s+$/; # ...trailing...
    $line =~ s/\s+/ /g;		   # ...internal...
    $line;			   # return
}

sub detab {
    my ($line) = @_;

    my (@l) = split (/\t/, $line);

    # Replace tabs with blanks, retaining layout

    $line = shift (@l);
    $line .= " " x (8-length($line)%8) . shift(@l) while $#l >= 0;

    $line;
}

sub decode_enriched {
    local ($_) = @_;
    s|<bold><italic>|\252bi\252|g;
    s|</italic></bold>|\252~bi\252|g;
    s|<italic>|\252i\252|g;
    s|</italic>|\252~i\252|g;
    s|<bold>|\252b\252|g;
    s|</bold>|\252~b\252|g;
    s|<underline>|\252u\252|g;
    s|</underline>|\252~u\252|g;
    s|<fixed>|\252t\252|g;
    s|</fixed>|\252~t\252|g;
    s|<<|<|g;
    $_;
}

sub pathexpand {
    my ($path, $mustexist) = @_;
    local($[) = 0;

    if ( $path =~ m|^~/| ) {
	setpwent;
	if ( defined ($home = $ENV{'HOME'} || $ENV{'LOGDIR'}
		      || (getpwuid($>))[7]) ) {
	    $path = $home . '/' . $';
	}
    }
    elsif ( $path =~ m|^~([^/]+)/| ) {
	setpwent;
	if ( defined ($home = (getpwnam($1))[7]) ) {
	    $path = $home . '/' . $';
	}
    }

    if ($path !~ /^\//) {
	chop ($wd = `pwd`);
	$path = "$wd/$path";
    }

    for (;;) {
	my $changes = 0;
	my @components = split (/\//,$path);

      prefix:
	for (my $i = 1; $i <= $#components; $i++) {
	    if ($components[$i] eq ".") {
		splice(@components, $i, 1);
	    }
	    elsif ($components[$i] eq "..") {
		splice(@components, $i-1, 2);
	    }
	    elsif (-l ($prefix = join('/', @components[0 .. $i]))) {
		($components[$i] = readlink $prefix) ||
		    die("Couldn't read $prefix ($!)\n");
		if ($components[$i] =~ /^\//) {
		    splice(@components, 0, $i);
		}
	    }
	    elsif ($mustexist && ! -e $prefix) {
		return "";
	    }
	    else {
		next prefix;
	    }
	    $changes = 1;
	    last prefix;
	}
	$path = join('/', @components);
	if (!$changes) {
	    return $path;
	}
    }
}

