#!/usr/bin/perl

use 5.006;

my $RCS_Id = '$Id: mmds.pl,v 1.93 2003-01-09 13:45:45+01 jv Exp $ ';
# Author          : Johan Vromans
# Created On      : Wed Feb 13 13:24:39 1991
# Last Modified By: Johan Vromans
# Last Modified On: Thu Jan  9 13:26:28 2003
# Update Count    : 886
# Status          : OK

################ Common stuff ################

use strict;
use warnings;

our ($my_name, $my_version) = $RCS_Id =~ /: (.+)\.p[lm],v ([\d.]+)/;
$my_version .= '*' if length('$Locker:  $ ') > 12;

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

my %opt;
$opt{ident} = 1;
$opt{latex209} = 0;
$opt{landscape} = -1;
$opt{title} = "";
$opt{footer} = "";
$opt{chapter} = 1;
$opt{copies} = 1;
$opt{pages} = "";
$opt{preview} = "";
my @config;

my $printer = $ENV{"PSPRINTER"} || $ENV{"PRINTER"};

my %file = ( text => "-" );

{ my $texnam = "TeX$$.";
  my $textmp = ($ENV{TMPDIR} || "/usr/tmp") . "/" . $texnam;

  sub workfile { $texnam.shift }
  sub tempfile { $textmp.shift }

  # Work files, put them in temp space.
  foreach my $f ( qw(txt html ltx tex dvi ps pdf fbk) ) {
      $file{$f} = tempfile($f);
  }
  # Most TeX files end up in the current dir.
  foreach my $f ( qw(toc ind idx aux cfg log) ) {
      $file{$f} = workfile($f);
  }
}

my $keep = "";

options();

our $debug = $opt{debug};
our $trace = $opt{test} || $opt{trace} || $debug;
our $verbose = $opt{verbose} || $trace;
$MMDSLIB = "." if $debug;

################ Presets ################

our $cfg = MMDS::Common::->get_config(join(",",@config));

# Load options from properties.
$opt{language} ||= $cfg->gps("general.language", undef);

my $pager = $opt{emacs} ? '' : ($ENV{"PAGER"} || "less");
my $latex = $opt{latex209} ? "nllatex" : "latex";

if ( $opt{output}  ) {
    if ( $opt{pdf} ) {
	$file{pdf} = $opt{output};
    }
    elsif ( $opt{postscript} ) {
	$file{ps} = $opt{output};
    }
    elsif ( $opt{dvi} ) {
	$file{dvi} = $opt{output};
    }
    elsif ( $opt{latex} ) {
	$file{ltx} = $opt{output};
    }
    else {
	$file{txt} = $opt{output};
    }
}

################ The Process ################
#
# There are two basic ways to go: converting to something simple, or 
# typesetting. Allways start with mmdscvt.

my @cmd = ("mmdscvt");
push(@cmd, "--config",   $_            ) for @config;
push(@cmd, "--ident"		       ) if $opt{ident} && $verbose;
push(@cmd, "--verbose"		       ) if $verbose;
push(@cmd, "--trace"		       ) if $trace;
push(@cmd, "--quiet"		       ) if $opt{quiet};
push(@cmd, "--title",    $opt{title}   ) if $opt{title} ne "";
push(@cmd, "--footer",   $opt{footer}  ) if $opt{footer} ne "";
push(@cmd, "--chapter",  $opt{chapter} ) if $opt{chapter} > 1;
push(@cmd, "--nochain"		       ) if $opt{nochain};
push(@cmd, "--generic"		       ) if $opt{generic};
push(@cmd, "--language", $opt{language}) if $opt{language};
push(@cmd, "--feedback", $file{fbk}     );

xx_unlink($file{fbk});

if ( $opt{text} || $opt{html} ) {

    $file{text} = $file{txt};
    $file{text} = "--" if $opt{preview} && $pager eq "";
    xx_unlink($file{text});

    push(@cmd, "--output", $file{text});
    push(@cmd, "--generate=html"      ) if $opt{html};
    push(@cmd, "--generate=text"      ) if $opt{text};
    push(@cmd, "--", @ARGV);
    xx_system(@cmd);
    get_feedback();

    if ( $opt{preview} ) {
	xx_system($pager, $file{text}) if $pager;
	xx_unlink($file{text});
    }
    else {
	terminate("Problem generating text file \"$file{text}\"\n")
	    if -f $file{text} && ! -s $file{text};
    }

    phase_msg(0) unless $opt{quiet};
    exit(0);
}

unless ( $opt{latex209} ) {
    if ( $ENV{PATH} =~ /^\.:/ ) {
	$ENV{PATH} =~ s/^./.:$MMDSLIB\/texdir/;
    }
    else {
	$ENV{PATH} =~ s/^/$MMDSLIB\/texdir:/;
    }
}

if ( $opt{latex} ) {

    my $preview = $opt{preview} && !$opt{dvi};
    my $output = $file{ltx};
    my $latex_filter = $cfg->gps("tools.latexfilter.cmd", undef);

#    phase_msg("Converting to LaTeX") unless $opt{quiet};
    $output .= "~" if $latex_filter;
    xx_unlink($file{ltx});

    push(@cmd, "--generate=latex");
    $cmd[-1] .= "209" if $opt{latex209};
    push(@cmd, "--output", $output);
    push(@cmd, "--notoc") if $opt{notoc};
    push(@cmd, "--index") if $opt{index};
    push(@cmd, "--makeindex") if $opt{makeindex};
    push(@cmd, "--keycaps") if $opt{keycaps};
    push(@cmd, "--portrait") unless $opt{landscape};
    push(@cmd, "--noborder") if $opt{noborder};
    push(@cmd, "--handouts") if $opt{handouts};
    push(@cmd, "--draft") if $opt{draft};
    push(@cmd, "--", @ARGV);

    xx_system(@cmd);
    get_feedback();

    if ( $latex_filter ) {
	my $args = $cfg->gps("tools.latexfilter.args", "");
	phase_msg("Executing LaTeX filter") unless $opt{quiet};
	xx_system("$latex_filter $args < $output > $file{ltx}");
	xx_unlink($output);
    }

    if ( $preview ) {
	xx_system($pager, $file{ltx});
	xx_unlink($file{ltx});
    }
    else {
	terminate("Problem generating LaTeX file \"$file{ltx}\"\n")
	    if -f $file{ltx} && ! -s $file{ltx};
    }

    phase_msg(0) unless $opt{dvi} || $opt{quiet};
    exit(0) if $preview;
}

my $texlib;
my $texbin;

if ( $opt{dvi} ) {

    xx_unlink($file{dvi}, $file{aux}, $file{cfg}, $file{toc},
	     $file{ind}, $file{idx}, $file{tex});

    get_properties_from_latex($file{ltx});

    $texlib = "$MMDSLIB/texdir";
    $texlib .= "209" if $opt{latex209};
    $texbin = "$texlib/bin";

    phase_msg("Typesetting") unless $opt{quiet};
    my $cmd;

    # Using an intermediate file keeps the generated file names intact.
    my $tf;
    open ($tf, ">$file{tex}")
      || terminate("Cannot create $file{tex} [$!]\n");
    print $tf ('\input ', $file{ltx}, "\n");
    print $tf ('@bye', "\n");
    close ($tf);

    if ( $opt{latex209} ) {


	$ENV{"TEXFORMATS"} = ".:$texlib/formats";
	# Note: TEXINPUTS needs dot to find ???TeX.{cfg,aux,toc} etc...
	$ENV{"TEXINPUTS"} = ".:$MMDSLIB:$texlib/inputs:.";
	$ENV{"TEXFONTS"} = ".:$texlib/tfm";
	$ENV{"TEXPOOL"} = ".:$texlib";

	$cmd = "$texbin/$latex < /dev/null $file{tex}";

	if ( $opt{trace} ) {
	    for my $env ( "TEXPOOL", "TEXFORMATS", "TEXFONTS", "TEXINPUTS" ) {
		warn("+ ", $env, " = ", $ENV{$env}, "\n");
	    }
	}
    }
    else {
	my $tmp;

	# Note: TEXINPUTS needs dot to find ???TeX.{cfg,aux,toc} etc...
	$ENV{"TEXFONTS"}  = $tmp || "::"
	  if defined($tmp = $cfg->gps("tools.latex.fonts", undef));
	$tmp = $cfg->gps("tools.latex.inputs", undef);
	$ENV{"TEXINPUTS"} = $tmp || ".:$MMDSLIB/texdir::";

	$cmd = "$latex < /dev/null $file{tex}";

	if ( $opt{trace} ) {
	    for my $env ( qw(TEXINPUTS TEXFONTS) ) {
		next unless defined($ENV{$env});
		warn("+ ", $env, " = ", $ENV{$env}, "\n");
	    }
	}
    }

    terminate("Problem generating DVI file \"$file{dvi}\"\n") 
	unless texfilter($cmd) == 0 && -s $file{dvi};

    if ( -s $file{idx} || $opt{indexfiles} ) {
	if ( $opt{index} ) {
	    my $args = $cfg->gps("tools.indexpp.args", "");
	    my @cmd = ($cfg->gps("tools.indexpp.cmd", "indexpp"));
	    push(@cmd, split(' ', $args)) if $args;
	    push(@cmd, "-ident") if $opt{ident} && $opt{verbose};
	    push(@cmd, "-verbose") if $opt{verbose};
	    push(@cmd, "-quiet") if $opt{quiet};
	    push(@cmd, "-output", $file{ind});
	    push(@cmd, split(/,/, $opt{indexfiles}))
		if $opt{indexfiles};
	    push(@cmd, $file{idx});
	    terminate("Problem generating index \"$file{ind}\"\n")
		unless xx_system(@cmd) == 0 && -s $file{ind};
	}
	if ( $opt{makeindex} ) {
	    xx_rename($file{idx}, $opt{makeindex});
	}
    }

    if (    (-s $file{toc} && ! $opt{notoc})
	 || ($opt{index} && -s $file{ind})   ) {
	phase_msg("Typesetting (2nd pass)") unless $opt{quiet};
	terminate("Problem generating 2nd pass DVI output \"$file{dvi}\"\n") 
	    unless &texfilter ($cmd) == 0 && -s $file{dvi};
    }

    xx_unlink($file{aux}, $file{cfg}, $file{toc}, $file{ind}, $file{idx}, $file{tex});
    xx_unlink($file{ltx}) unless $keep eq "ltx";
}
else {
    $texlib = "$MMDSLIB/texdir";
    $texbin = "$texlib/bin";
}

my $dvipages;			# set by texfilter()

my $pagemsg = $dvipages ?
  (" ($dvipages page" . ($dvipages != 1 ? "s" : "") . ")") : "";

if ( $opt{preview} eq "dvi" ) {
    phase_msg("Previewing DVI$pagemsg") unless $opt{quiet};
    dvi_preview();
    phase_msg(0) unless $opt{quiet};
    xx_unlink($file{dvi});
    exit(0);
}

my $printer_driver;		# set by options()
my $feedback_document_style;	# set by get_feedback()
my $feedback_document_type;	# set by get_feedback()
my $feedback_document_prologue = "";	# set by get_feedback()
my $latex_document_style;	# set by get_properties_from_latex()

if ( $opt{postscript} && $printer_driver =~ /^(ps\d?|pk)$/ ) {

    phase_msg("Generating PostScript" .
	      ($printer_driver eq "pk" ? "/Pk" : "") .
	      ($opt{print} ? " for $printer" : "") .
	      $pagemsg)
      unless $opt{quiet};

    if ( $opt{print} && $opt{preview} ) {
	$opt{printer} = "PostScript";
    }

    my $tmp;
    $ENV{"TEXCONFIG"} = $tmp || "::"
      if defined($tmp = cfg_gps("tools.dvips", "config",
				$printer_driver, undef));
    $ENV{"TEXFONTS"} = $tmp || "::"
      if defined($tmp = cfg_gps("tools.dvips", "fonts",
				$printer_driver, undef));
    $ENV{"VFFONTS"} = $tmp || "::"
      if defined($tmp = cfg_gps("tools.dvips", "vfs",
				$printer_driver, undef));
    $ENV{"TEXPKS"} = $tmp || "::"
      if defined($tmp = cfg_gps("tools.dvips", "pks",
				$printer_driver, undef));
    $tmp = cfg_gps("tools.dvips", "headers",
		   $printer_driver, undef);
    $ENV{"PSHEADERS"} = $tmp || ".:$MMDSLIB/texdir::";

    if ( $opt{trace} ) {
	for my $env ( qw(TEXFONTS TEXCONFIG VFFONTS TEXPKS PSHEADERS) ) {
	    next unless defined($ENV{$env});
	    warn("+ ", $env, " = ", $ENV{$env}, "\n");
	}
    }

    my $ps_prologue = $opt{psprologue} || $feedback_document_prologue ||
      $cfg->gps("documents.$feedback_document_type.prologue",
		$cfg->gps("documents.default.prologue",
			  $feedback_document_style ||
			  $latex_document_style));

    my $conf = cfg_gps("tools.dvips", "cfg", $printer_driver, undef);
    xx_unlink($file{ps});
    my @cmd = cfg_gps("tools.dvips", "cmd", $printer_driver);
    push(@cmd, "-M")
      if cfg_gps("tools.dvips", "makepk", $printer_driver, "false") eq "false";
    push(@cmd, "-U");		# disable a certain optimization
    push(@cmd, "-d96") if $opt{debug};
    push(@cmd, "-q") unless $opt{verbose};
    push(@cmd, "-h" . $ps_prologue . ".pro");
    push(@cmd, "-r" . ($opt{reverse} ? "1" : "0"));
    push(@cmd, "-c$opt{copies}") if $opt{copies} > 1;
    push(@cmd, "-P$conf") if $conf;
    push(@cmd, "-o", $file{ps});
    push(@cmd, "-m") if $opt{manual};
    push(@cmd, $file{dvi});
    dvipsfilter(@cmd);

    terminate("Problem generating PostScript output \"$file{ps}\"\n") 
	unless -s $file{ps};

    xx_unlink($file{dvi}) unless $keep eq "dvi";

    if ( $opt{pages} ne "" || $opt{twoup} ) {
	@cmd = ("parr");
	push(@cmd, "-ident") if $opt{ident} && $opt{verbose};
	push(@cmd, "-verbose") if $opt{verbose};
	push(@cmd, "-quiet") if $opt{quiet};
	push(@cmd, ($opt{twosame} ? " -twosame" : " -twoup")) if $opt{twoup};
	push(@cmd, "-pages", $opt{pages}) if $opt{pages} ne "";
	push(@cmd, "-output", $file{ps}, $file{ps});
	xx_system(@cmd);
    }
}

if ( $opt{preview} eq "ps" && $printer_driver =~ /^(ps\d?|pk)$/ ) {
    phase_msg("Previewing PostScript$pagemsg") unless $opt{quiet};
    ps_preview();
    xx_unlink($file{ps}) unless $keep eq "ps";
    phase_msg(0) unless $opt{quiet};
    exit(0);
}

if ( $opt{pdf} ) {
    phase_msg("Producing PDF") unless $opt{quiet};
    xx_system($cfg->gps("tools.pspdf.cmd"), $file{ps}, $file{pdf});
    xx_unlink($file{ps});
}

if ( $opt{preview} eq "pdf" ) {
    phase_msg("Previewing PDF$pagemsg") unless $opt{quiet};
    pdf_preview();
    xx_unlink($file{pdf}) unless $keep eq "pdf";
}

if ( $opt{print} && !$opt{printfile} ) {
    phase_msg("Sending to printer $printer") unless $opt{quiet};

    xx_system(cfg_gps("printers", "cmd", $printer), $file{ps});

    xx_unlink($file{ps}) unless $keep eq "ps";
    phase_msg(0) unless $opt{quiet};

    exit(0);
}

phase_msg(0) unless $opt{quiet};
exit(0);

################ Subroutines ################

sub options {
    use Getopt::Long;
    no warnings;

    # Prescan.
    # For convenience we allow -indexfiles to have multiple arguments,
    # so users can say "-indexfiles *.idx".
    {   my (@a) = (@ARGV);
	my (@g) = ();
	@ARGV = ();
        foreach my $a ( @a ) {
	    if ( $a =~ /^-/ ) {
		if ( @g > 1 ) {
		    shift (@g);
		    push (@ARGV, join(',', @g));
		}
		push (@ARGV, $a);
		@g = ();
		if ( $a =~ /^-indexfiles$/i ) {
		    @g = ('x');
		}
		next;
	    }
	    if ( @g > 0 ) {
		push (@g, $a);
	    }
	    else {
		push (@ARGV, $a);
	    }
        }
	push (@ARGV, join(',', @g)) if @g > 0;
    }

    # NOTE: some undocumented options remain
    if ( ! GetOptions
	(\%opt,
	 "chapter=i",
	 "config=s" => \@config,
	 "copies=i",
	 "debug",
	 "draft",
	 "dvi",
	 "emacs",
	 "footer=s",
	 "generic",
	 "handouts",
	 "help",
	 "html",
	 "ident",
	 "index",
	 "indexfiles=s",
	 "keycaps",
	 "landscape",
	 "language=s",
	 "latex",
	 "latex209",
	 "latex_filter=s",
	 "makeindex=s",
	 "manual",
	 "noborders",
	 "nochain",
	 "notoc",
	 "output=s",
	 "pages=s",
	 "pdf",
	 "portrait",
	 "postscript|ps",
	 "preview|view",
	 "printer=s",
	 "printfile",
	 "psprologue=s",
	 "quiet",
	 "reversed",
	 "test",
	 "text",
	 "title=s",
	 "trace",
	 "twosame|a5d",
	 "twoup|a5",
	 "verbose",
	 ) || $opt{help} ) {
	usage();
    }

    phase_msg("This is $my_package") if $opt{ident};

    $opt{twoup} |= $opt{twosame};

    # Infer generation type from output extension, if possible.
    unless ( $opt{postscript} || $opt{latex} || $opt{text} || $opt{pdf}
	     || $opt{html} || $opt{dvi} ) {
	if ( lc($opt{output}) =~ /\.(ps|pdf|html|ltx|dvi|txt)$/ ) {
	    $opt{postscript}  = 1 if $1 eq "ps";
	    $opt{pdf}	      = 1 if $1 eq "pdf";
	    $opt{html}	      = 1 if $1 eq "html";
	    $opt{latex}	      = 1 if $1 eq "ltx";
	    $opt{dvi}	      = 1 if $1 eq "dvi";
	    $opt{text}	      = 1 if $1 eq "txt";
	}
    }

    unless ( $opt{postscript} || $opt{latex} || $opt{text} || $opt{pdf}
	     || $opt{html} || $opt{dvi} ) {
	if ( $opt{latex209} ) {
	    $opt{latex} = 1;
	}
    }

    unless ($opt{postscript} || $opt{latex} || $opt{pdf}
	    || $opt{text} || $opt{html} || $opt{dvi} || $opt{preview}) {
	$opt{print} = 1;
    }

    $opt{sheets} = 1
	if ( $opt{portrait} || $opt{landscape} > 0 || $opt{handouts});

    terminate("Error: only one of \"text\", \"-postscript\", \"-latex\",",
	  "\"pdf\", \"dvi\", and \"makeindex\" allowed\n")
	if $opt{postscript} + $opt{latex} + $opt{text} + $opt{dvi} +
	  $opt{pdf} + $opt{html} + $opt{makeindex} > 1;

    $opt{index} = 1 if $opt{indexfiles};

    if ( $opt{pdf} ) {
	$opt{postscript} = 1;
    }
    if ( $opt{print} ) {
	$opt{postscript} = $opt{dvi} = $opt{latex} = 1;
    }
    elsif ( $opt{postscript} || $opt{makeindex} ) {
	$opt{dvi} = $opt{latex} = 1;
    }
    elsif ( $opt{dvi} ) {
	$opt{latex} = 1;
    }
    elsif ( $opt{preview} ) {
	$opt{text} = !($opt{latex} || $opt{html});
    }

    terminate("Error: only one of \"portrait\" and \"-landscape\" allowed\n")
	if $opt{portrait} && $opt{landscape} > 0;
    $opt{landscape} = 0 if $opt{portrait};

    terminate("Error: cannot use \"-preview\" with \"-output\"\n")
	if $opt{output} && $opt{preview} && !($opt{dvi} || $opt{postscript});

    warn("Warning: do you really want to see it $opt{copies} times?\n")
	if $opt{preview} && $opt{copies} > 1;

    # Some options need PostScript
    unless ( $opt{postscript} ) {
	my $tag;
	$tag = "-twoup" if $opt{twoup};
	$tag = "-manual" if $opt{manual};
	$tag = "-pages" if $opt{pages} ne "";
	# $tag = "-keycaps" if $opt{keycaps};
	$tag = "-handouts" if $opt{handouts};
	$tag = "-draft" if $opt{draft};
	$tag = "-psprologue" if $opt{psprologue};
	terminate("Error: \"", $tag, "\" is only relevant when printing ",
	      "(or with \"-postscript\")\n") 
	    if defined $tag;
    }

    unless ( $opt{latex} ) {
	my $tag;
	$tag = "-latex_filter" if $opt{latex_filter};
	terminate("Error: \"", $tag, "\" is only relevant when printing ",
	      "(or with \"-latex\" or \"-postscript\")\n") 
	    if defined $tag;
    }

    if ( $opt{preview} && !defined $ENV{"DISPLAY"} ) {
	my $tag;
	$tag = "DVI" if $opt{dvi};
	$tag = "PostScript" if $opt{postscript};
	terminate("Error: the ", $tag, " previewer needs display capabilities.\n",
	 "(The \"DISPLAY\" environment variable is not set.)\n")
	    if defined $tag;
    }

    terminate("Error: \"-twoup\" cannot be used with overhead sheets\n")
	if $opt{twoup} && $opt{sheets};

    $printer = $opt{printer} ||
	$ENV{"MMDS_PSPRINTER"} ||
	    $ENV{"MMDS_PRINTER"} ||
		$ENV{"PSPRINTER"} ||
		    $ENV{"PRINTER"} ||
			"lp";

    # Default is PS in PS mode.
    $printer_driver = "ps";
    if ( $printer =~ /:/ ) {
	$printer_driver = $';
	($printer = $`) =~ tr/A-Z/a-z/;
    }
    else {
#	while (my ($try, $type) = each (%printer_drivers) ) {
#	    next unless $printer =~ /^$try$/i;
#	    $printer_driver = $type;
#	}
    }

    # Process printer options.
    foreach my $opt ( split (/:/, $printer_driver) ) {
	$opt =~ tr/A-Z/a-z/;
	if ( $opt =~ /^rev(ersed?)$/ ) {
	    $opt{reverse} = !$opt{reverse};
	}
	elsif ( $opt =~ /^manual$/ ) {
	    $opt{manual} = 1;
	}
	elsif ( $opt =~ /^(ps\d?|pk|pspk|lj|ln)$/ ) {
	    $printer_driver = $opt;
	}
	else {
	    terminate("Unknown printer option: \"$opt\"");
	}
    }

    terminate("Error: \"reverse\" cannot be used with \"manual\"\n")
	if $opt{reverse} && $opt{manual};

    # Choose PK or PS depending on other options.
    if ( $printer_driver eq "pspk" ) {
	$printer_driver = ( $opt{twoup} || $opt{handouts} ) ? "ps" : "pk";
    }

    terminate("Cannot preview \"$printer_driver\"-type printer output.\n")
	if $opt{preview} && $opt{postscript} && $printer_driver !~ /^(ps\d?|pk)$/;

    warn("Using printer driver $printer_driver for printer $printer.\n")
	if $opt{verbose};

    # Some options need PostScript fonts
    unless ( $opt{postscript} && $printer_driver =~ /^ps/ ) {
	my $tag;
	$tag = "-twoup\" or \"-twosame" if $opt{twoup};
	$tag = "-handouts" if $opt{handouts};
	terminate("Error: Cannot handle \"", $tag, "\" with PK-fonts\n") 
	    if defined $tag;
    }

    if ( $opt{preview} ) {
	$opt{preview} = "dvi" if $opt{dvi};
	$opt{preview} = "ps" if $opt{postscript};
	$opt{preview} = "pdf" if $opt{pdf};
    }

    # Check for prepared input.
    if ( @ARGV == 1 ) {
	if ( $ARGV[0] =~ /\.ltx$/ ) {
	    $opt{latex} = 0;
	    $file{ltx} = shift(@ARGV);
	    $keep = "ltx";
	}
	elsif ( $ARGV[0] =~ /\.dvi$/ ) {
	    $opt{latex} = $opt{dvi} = 0;
	    $file{dvi} = shift(@ARGV);
	    $keep = "dvi";
	}
	elsif ( $ARGV[0] =~ /\.ps$/ ) {
	    $opt{latex} = $opt{dvi} = $opt{postscript} = 0;
	    $file{ps} = shift(@ARGV);
	    $opt{preview} = "ps" if $opt{preview};
	    $keep = "ps";
	}
	elsif ( $ARGV[0] =~ /\.pdf$/ ) {
	    $opt{latex} = $opt{dvi} = $opt{postscript} = $opt{pdf} = 0;
	    $file{pdf} = shift(@ARGV);
	    $opt{preview} = "pdf" if $opt{preview};
	    $keep = "pdf";
	}
    }
}

sub usage {
    print STDERR <<EndOfUsage;
This is $my_package [$my_name $my_version]
Usage: $0 [options] file...
  General options:
    -help		this message
    -ident		show identification
    -language XX	language code (NL,EN, ...)
    -config XX,YY	configuration file(s), default mmds.prp
    -quiet		show only error messages
    -verbose		verbose information
  Processing options:
    -chapter NN		initial chapter number
    -generic		override document type
    -keycaps		enable keycap substitution
    -nochain		do not follow document chain
    -notoc		suppress table of contents
    -index		generate and print index
    -makeindex XXX	build index file XXX, does not include unless -index
    -indexfiles ...	uses index files
    -output XXX		name of output file
    -preview		preview document
    -text|latex|latex209|postscript|pdf|dvi|html
			select output, no printing
  If printing or PostScript output:
    -copies nn		number of copies to print
    -manual		print with manualfeed
    -pages		specify page range, e.g. ii,4-1..4-7,5-2
    -reverse		reverse output pages
    -twosame		print 2 identical A5 pages per page
    -twoup		print 2 different A5 pages per page
    -draft		draft document printing
    -psprologue XXX	PostScript prologue
  For overhead sheets:
    -handouts		handouts
    -landscape		landscape mode
    -noborder		do not include border
    -portrait		portrait mode
  For generic documents
    -title XXX		specify title
    -footer XXX		specify footer
EndOfUsage
    exit 1;
}

sub xx_unlink{
    for my $file ( @_ ) {
	warn("+ unlink(", $file, ")\n") if $opt{trace};
	next unless -f $file;
	unlink($file) ||
	    warn("Warning: could not unlink\"$file\": $!\n");
    }
}

sub xx_rename {
    my ($old, $new) = @_;
    warn("+ rename($old,$new)\n") if $opt{trace};
    return 0 unless -f $old;
    return 0 if CORE::rename($old, $new) == 1;
    my @cmd = ( "mv", $old, $new);
    warn("+ @cmd\n") if $opt{trace};
    return 0 unless xx_system(@cmd);
    warn("Warning: could not rename \"$old\" to \"$new\"\n");
    return 1;
}

sub xx_system{
    my (@cmd) = @_;

    warn("+ @cmd\n") if $trace;

    my $result = system(@cmd);

    if ( $result ) {
	terminate("Problem executing \"@cmd\"\n",
		  "Return status = ", sprintf ("0x%x", $result), "\n");
    }
    $result;
}

sub pdf_preview {
    warn("Starting PDF previewer... be patient\n");
    my @cmd = ($cfg->gps("tools.pdfviewer.cmd", "acroread"),
	       "-tempFile",
	       $file{pdf});
    warn("+ @cmd\n") if $opt{trace};
    return system(@cmd);
}

sub ps_preview {
    warn("Starting PostScript previewer... be patient\n");
    my @cmd = ($cfg->gps("tools.psviewer.cmd", "gv"));
    push(@cmd, "-landscape") if $opt{landscape} > 0;
    push(@cmd, $file{ps});
    warn("+ @cmd\n") if $opt{trace};
    return system(@cmd);
}

sub dvi_preview {
    warn("Starting DVI previewer... be patient\n");
    my @cmd = ($cfg->gps("tools.dviviewer.cmd", "xdvi"),
	       "-S", 25,
	       "-hush");
    push(@cmd, "-debug", 32) if $opt{debug};
    push(@cmd, $file{dvi});

    my $tmp;
    $ENV{"TEXFONTS"} = $tmp || "::"
      if defined($tmp = $cfg->gps("tools.dviviewer.fonts", undef));
    $ENV{"XDVIMAKEPK"} = $tmp
      if defined($tmp = $cfg->gps("tools.dviviewer.makepk", undef));

    if ( $opt{trace} ) {
	for my $env ( "TEXFONTS" ) {
	    next unless defined($ENV{$env});
	    warn("+ ", $env, " = ", $ENV{$env}, "\n");
	}
    }
    warn("+ @cmd\n") if $opt{trace};
    return system(@cmd);
}

sub terminate {
    warn(@_);
    phase_msg(1);
}

sub texfilter {
    my ($cmd) = @_;
    my $oops = 0;

    warn("+ $cmd\n") if $trace;

    # Open TeX pipe and filter output.
    open my $tex => $cmd . '|';
    while ( <$tex> ) {
	chop;
	unless ( $verbose || $oops ) {
	    if ( /^[!?]/ ) {
		$oops = 1;
	    }
	    else {
		$dvipages = $1 if /Output written on .+ \((\d+) pages?,/;
		next;
	    }
	}
	warn($_, "\n");
    }
    close($tex);
    my $result = $?;

    # Move files.
    xx_system("mv", workfile("log"), tempfile("log"))
	if -s workfile("log") && !samefile(workfile("log"), tempfile("log"));

    if ( -s workfile("dvi") && !samefile(workfile("dvi"), $file{dvi}) ) {
	xx_system("mv", workfile("dvi"), $file{dvi});
    }
    elsif ( -s tempfile("dvi") && !samefile(tempfile("dvi"), $file{dvi}) ) {
	xx_system("mv", tempfile("dvi"), $file{dvi});
    }

    # Feedback.
    if ( $result ) {
	warn("Problem executing \"$cmd\"\n",
	     "Wait return status = ", sprintf ("0x%x", $result), "\n");
    }

    # Return result.
    $result;
}

sub dvipsfilter {
    my (@cmd) = @_;
    my $cmd = "@cmd";
    my $strip = "$texbin/dvips: ";

    # Filter unwanted messages from dvips.

    if ( $opt{verbose} || $printer_driver !~ /^(ps\d?|pk)$/ ) {
	# No need to filter.
	xx_system($cmd);
	return;
    }

    warn("+ $cmd\n") if $trace;

    $strip =~ s/(\W)/\\$1/g;
    $strip .= '[^!]';

    # Open pipe and filter output.
    open my $dvips => $cmd . ' 2>&1 |';
    while ( <$dvips> ) {
	next if /Design size mismatch/;
	next if /$strip/o;
	warn($_);
    }
    close($dvips);
    my $result = $?;

    # Feedback.
    if ( $result ) {
	warn("Problem executing \"$cmd\"\n",
	     "Return status = ", sprintf ("0x%x", $result), "\n");
    }

    # Return result.
    $result;
}

sub samefile {
    my ($f1, $f2) = @_;
    join(':',stat($f1)) eq join(':',stat($f2));
}

sub get_feedback {
    # Process feedback from mmdscvt.
    return unless $file{fbk};
    return unless -s $file{fbk};
    open(my $fb, $file{fbk});
    { no strict; eval join('',<$fb>) or warn("$@"); }
    close($fb);
    xx_unlink($file{fbk});
}

sub get_properties_from_latex {
    my ($file) = @_;

    return unless open my $ltx => $file;
    while ( <$ltx> ) {
	if ( /\\document(class|style)(\[.*\])?{(.+)}/ ) {
	    $latex_document_style = $3;
	    last;
	}
    }
    close($ltx);
}

