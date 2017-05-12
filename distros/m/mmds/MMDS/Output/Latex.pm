package MMDS::Output::Latex;

# RCS Info        : $Id: Latex.pm,v 1.12 2003-01-09 22:20:00+01 jv Exp jv $
# Author          : Johan Vromans
# Created On      : Mon Nov 25 21:08:30 2002
# Last Modified By: Johan Vromans
# Last Modified On: Sun Mar 16 16:04:25 2003
# Update Count    : 96
# Status          : Unknown, Use with caution!
# Based On        : gen_tex.pl 2.109

use strict;

my $RCS_Id = '$Id: Latex.pm,v 1.12 2003-01-09 22:20:00+01 jv Exp jv $ ';
my $my_name = __PACKAGE__;
my ($my_version) = $RCS_Id =~ /: .+,v ([\d.]+)/;
$my_version .= '*' if length('$Locker: jv $ ') > 12;

my $texencoding            = "T1";

my %enctabs = ( "iso-8859-1"  => "Latin1",
		"iso-8859-15" => "Latin9",
	      );

# Semantics of index options:
#  index: scan for index entries, and produce index
#  makeindex: scan for index entries, and produce (but not print) index
#  noindex do not scan for index entries.
*index      = \$::opt_index;
*noindex    = \$::noindex;
*makeindex  = \$::opt_makeindex;

my $appendix = 0;
my $latex209 = 0;			# LaTeX 2.09 instead of 2e

sub new {
    return bless {};
}

sub id_type {
    "latex";
}

sub id_tag {
    "LaTeX";
}

sub id_name {
    __PACKAGE__;
}

sub id_version {
    $my_version;
}

sub emul_209 {
    my ($self, $arg) = (@_, 1);
    $latex209 = $arg;
}

no strict;

sub emit_header {
    shift;
    local ($depth, $text, $tag) = @_;
    local ($pat, $unnumbered);

    # Start a header. 
    # If depth < 0 we're starting appendices.
    # The very first header may be config status 

    if ( $depth == 1 && !$config
	&& ($pat = &::nls ($::PAT_CONFIGMGT))
	&& $text =~ /$pat/io ) {
	&tex_style ($::STANDARD);
	&tex_emitn ('\configurationmanagement{',
		    &::tex_string (&::nls ($::TXT_CONFMGT)), '}{',
		    &::tex_string (&::nls ($::TXT_CONFSTAT)), '}');
	$config = 1;
	return;
    }
    $config = 1;		# no more

    if ( $depth == 1 
	&& $::document_type == $::DTP_MREP
	&& ($pat = &::nls ($::PAT_ANNOUNCE))
	&& $text =~ /$pat/io ) {
	&tex_style ($::STANDARD);
	&tex_emitn ('\newpage');
    }

    $unnumbered = $tag =~ /^[0.]+$/;

    unless ( $unnumbered ) {
	&tex_emitn ('\setcounter{section}{', 
		    $::chapnum - ( $depth <= 1 && $::document_type != $::DTP_IMP ),
		    "}")
	    if $chapnum > 1;
	&tex_emitn ('\setcounter{subsection}{', $subchapnum-($depth<=2), "}")
	    if $subchapnum > 1;
	&tex_emitn ('\setcounter{subsubsection}{', $subsubchapnum-($depth<=3),
		    "}")
	    if $subsubchapnum > 1;
	$chapnum = $subchapnum = $subsubchapnum = 1;	# disable
    }

    if ( $depth < 0 ) {
	$depth = 0;
	if ( ! $appendix ) {
	    $appendix = 1;
	    &tex_style ($::STANDARD);
	    &tex_emitn ('\appendix');
	}
    }
    else {
	$depth--;			# make zero relative
	$depth = 2 if $depth > 4;		# maximize
    }
    &tex_style ($::HEADER1 + $depth);	# change style (and opening { )
    if ( $depth == 0 ) {
	&tex_emitn (&::tex_string ($text), '}{', 
		    &::tex_string ($::headers[$::HDR_VERSION]), '}');
    }
    else {
	&tex_emitn (&::tex_string ($text), '}');
    }
    &tex_style ($::STANDARD);
}

sub emit_enum {
    shift;
    local ($depth, $tag, $text, $para) = @_;

    # Start an enumeration

    #### Disable un-released feature ####
    $para = 1;

    $depth--;			# make zero relative
    $depth = 1 if $depth > 1;

    # If the imminent style change is going to emit a \begin{enum} it
    # *MUST* be followed by a leader, or TeX will complain.
    $tag = $::LEADER_EMPTY 
	if $tag == $::LEADER_NONE
	    && (($current_style < $::ENUM1) ||
		($current_style == $::ENUM1 && $depth == 1));

    &tex_style ($::ENUM1+$depth);	# change style

    return unless $text ne "";

    #### Disable un-released feature ####
    # &tex_emitn ('\vskip\smallskipamount') if $para || !$tag;
    &tex_emit ($enum_leaders[$tag]) if $tag;
    &tex_textn ($text);		# emit text
    &tex_par;
}

sub emit_para {
    shift;
    local ($style, $text) = @_;

    $style = $::STANDARD;

    &tex_style ($style);	# change style

    return unless $text ne "";

    &tex_textn ($text);		# emit text
    &tex_par;			# emit par
}

sub emit_tabular {
    shift;
    local (@lines) = split ("\t", @_[0], -1);
    local ($ctl, @ctl);

    ($ctl) = (shift (@lines) =~ /^\[(.*)\]/);

    # If we have one element, containing "lit", we're going to use 
    # citation mode. 

    if ( $ctl =~ /^(literal|screen)(\s+(tiny|small|large|landscape))*$/i ) {

	local ($vbox) = 0;
	local ($_landscape) = 0;

	&tex_par;
	$ctl =~ tr/[A-Z]/[a-z]/;
	@ctl = split (' ', $ctl);
	if ( shift(@ctl) eq "screen" ) {
	    $ctl = 'screen';
	    $vbox = 1;
	    foreach ( @ctl ) {
		$_landscape = 1, next if $_ eq "landscape";
		$ctl = 'literal', next if $_ eq 'large';
		$ctl = 'report', next if $_ eq 'tiny';
	    }
	    if ( $_landscape ) {
		&tex_emit ('\newbox\scrbox') unless $scrbox++;
		&tex_emit ('\setbox\scrbox=');
	    }
	    &tex_emit ('\vbox{\begin{', $ctl, '}');
	    &tex_emitn ('\parindent\enumindent') if $current_style == $::STANDARD;
	    &tex_emitn ('\parindent2\enumindent') if $current_style == $::ENUM1;
	    &tex_emitn ('\parindent3\enumindent') if $current_style == $::ENUM2;
	}
	else {
	    $ctl = 'literal';
	    foreach ( @ctl ) {
		&::warn ("landscape ignored for [literal]"), next
		    if $_ eq "landscape";
		$ctl = 'screen', next if $_ eq 'small';
		$ctl = 'report', next if $_ eq 'tiny';
	    }
	    &tex_emit ('\begin{', $ctl, '}');
	    &tex_emitn ('\parindent\enumindent');
	}

	for $line ( @lines ) {

	    # Watch out! Since pseudo-verbatim mode uses hard blanks
	    # to retain spaces, TeX has no opportunity to do page
	    # breaks. Therefore insert \mbox{} before the leading ~.
	    # (Cannot use \strut since that is too high.)

	    if ( $line eq '' ) {
		&tex_emitn ('\mbox{}');
	    }
	    else {
		&tex_emit ('\mbox{}') if ord($line) eq ord(' ');
		&tex_emitn (&tex_verbatim ($line));
	    }
	}

	&tex_emitn ('\end{', $ctl, $vbox ? '}}' : '}');
	if ( $_landscape ) {
	    &tex_emitn ('\begin{figure}[p]',
			'\xxrotl\scrbox',
			'\end{figure}');
	}
	return;
    }

    if ( $ctl =~ /^(emphasis|strong)$/i ) {

	&tex_par;
	$ctl =~ tr/[A-Z]/[a-z]/;
	&tex_emitn ('\begin{', $ctl, '}');

	for $line ( @lines ) {
	    &tex_textn ($line);
	}

	&tex_emitn ('\end{', $ctl, '}');
	return;
    }

    # EPSF pictures

    if ($ctl =~ /^\[epsf\s+(\S+)(.*)\]$/i ) {
	local ($home);
	local ($comment) = $2;

	$file = &::pathexpand ($1);

	$comment =~ s/^\s+//;
	$comment =~ s/\s+$//;
	&tex_emitn ('');
	if ( $comment ) {
	    &tex_emitn ('\epspic[', &::tex_string ($comment), ']{', $file, '}');
	}
	else {
	    &tex_emitn ('\epspic{', $file, '}');
	}
	&tex_emitn('');
	&::err ("Cannot find picture \"$file\"")
	    unless -r $file;
	return;
    }

    # Inline data

    if ( $ctl =~ /^\[?inline\s+(\S+)\s*(\S.+)?\s*\]?$/i ) {
	&inline_data ($1, $2);
	return;
    }

    # For TeX gurus only...

    if ($ctl =~ /^\[TeX(\s+.+|)\]$/ ) {
	$command = $1;
	&tex_emitn ('');
	if ( $command =~ /\S/ ) {
	    $command =~ s/^\s+//;
	    $command =~ s/\s+$//;
	    &tex_emitn ($command);
	}
	for $line ( @lines ) {
	    &tex_emitn ($line);
	}
	&tex_emitn('');
	return;
    }

    # Sigh.

    if ( $ctl =~ /^\[?newpage\]?$/i ) {
	if ( $tabular ) {
	    &::err ("[newpage] illegal in [table]");
	}
	else {
	    &tex_emitn ('\newpage');
	}
	return;
    }

    if ( $ctl =~ /^tabular\s+(.*)/i ) {

	my @tblr_just;
	my @tblr_post;
	my @tblr_width;
	my $tblr_sep = '&';
	my $len = 0;
	my $length = 0;
	my $tblr_unk = 0;

	foreach my $w ( split (/,/, $1) ) {

	    if ( $w =~ /^l/i ) {
		$w = $';
		push (@tblr_just, '');
		push (@tblr_post, '');
	    }
	    elsif ( $w =~ /^r/i ) {
		$w = $';
		push (@tblr_just, '\hfill ');
		push (@tblr_post, '');
	    }
	    elsif ( $w =~ /^c/i ) {
		$w = $';
		push (@tblr_just, '\hfill ');
		push (@tblr_post, '\hfill');
	    }
	    else {
		push (@tblr_just, '');
		push (@tblr_post, '');
	    }

	    if ( $w =~ /^(\d+)\.(\d)(cm|mm)$/ ) {
		push (@tblr_width, $len = ($1 + $2/10) * ($3 eq 'cm' ? 10 : 1));
		$length += $len;
	    }
	    elsif ( $w =~ /^(\d+)(cm|mm)$/ ) {
		push (@tblr_width, $len = $1 * ($2 eq 'cm' ? 10 : 1));
		$length += $len;
	    }
	    elsif ( $w eq '*' ) {
		push (@tblr_width, 0);
		$tblr_unk++;
	    }
	    else {
		die 'illegal width specification: '. $w;
	    }
	}

	while ( $par =~ /\bsep=(["'])([^\1]+)\1/i ) {
	    $tblr_sep = $2;
	}

	foreach $w ( split (' ', $par) ) {
	    if ( 0 ) {
	    }
	    else {
		die "illegal tabular option \"$w\"";
	    }
	}

	tex_emitn ('\begingroup\renewcommand{\arraystretch}{1}');

	# Fill in the unknown.
	if ( $tblr_unk > 0 ) {
	    tex_emitn ('\setlength{\mctcw}{\linewidth}%');
	    tex_emitn ('\addtolength{\mctcw}{-0.3pt}');
	    # Subtract known length
	    tex_emitn ('\addtolength{\mctcw}{-', int($length+0.5), 'mm}')
		if $length > 0.5;
	    # Subtract inter-column space
	    tex_emitn ('\addtolength{\mctcw}{-', 2*@tblr_width-2,
			'\tabcolsep}');
	    tex_emitn ('\divide \mctcw by ', $tblr_unk) if $tblr_unk > 1;
	}

	tex_emit ("\\begin{tabular}[t]{\@{}");

	my @w = @tblr_just;
	foreach my $w ( @tblr_width ) {
	    tex_emit ($w ? "p{${w}mm}" : 'p{\mctcw}');
	}

	tex_emitn ("\@{}}");
	tex_emitn("\\parskip0pt");

	my $sep = quotemeta ($tblr_sep);
	my @a;
	foreach my $line ( @lines ) {
	    if ( @a ) {
		if ( $line =~ /^\s*$sep/ ) {
		    $line = $';
		}
		else {
		    die "illegal column continuation";
		}
	    }
	    push (@a, split (/\s*$sep\s*/, $line, -1));
	    if ( @a == @tblr_width ) {
		my $i = 0;
		foreach ( @a ) {
		    tex_emit ($tblr_just[$i]);
		    tex_text ($_);
		    tex_emit ($tblr_post[$i]);
		    tex_emit ("&") unless $i == @a-1;
		    $i++;
		}
		tex_emitn ("\\\\");
		@a = ();
	    }
	}
	die "incorrect number of columns" if @a;
	tex_emitn ("\\end{tabular}\\endgroup");

	return;
    }

    # Something column like. Split
    print STDERR "=> \"$ctl\" -> " if $::debug;
    @ctl = ('');
    $ctl = ' ' . $ctl . ' ';
    while ( $ctl =~ /[TLRCF]/i ) {
	$ctl[$#ctl] .= $`;
	push (@ctl, $&);
	$ctl = $';
    }
    $ctl[$#ctl] .= $ctl;
    print STDERR ':', join (':', @ctl), ":\n" if $::debug;

    local ($pat) = '';		# to break lines
    local ($col, @cols);	# column info
    local (@just);		# justify info (per column)
    local (@width);		# width info (per column)
    local ($c, $w, $cc);	# working storage
    local ($tw) = 0;		# total width
    local ($fill);		# filling mode
    local ($doing) = 0;		# emitted text
    local ($did) = 0;		# switched \parskip to zero

    while ( $#ctl >= 0 ) {
	$c = shift (@ctl);

	# Get pattern
	if ( $#ctl >= 0 ) {
	    $pat .= '(.{0,' . length($c) . '})';
	}
	else {
	    # last one - be liberate
	    $pat .= '(.*)';
	}

	# Get justification. Only the last one can fill.
	if ( $fill = ($#ctl < 0 && $c =~ /^f/i) ) 
	     { $just[$col] = 'f'; }
	elsif ( $c =~ /^r/i) { $just[$col] = 'r'; }
	elsif ( $c =~ /^c/i ) { $just[$col] = 'c'; }
	else { $just[$col] = 'l'; }

	# Get width.
	$c =~ s/[^imn]/n/g;	# nominal width for unsupported chars
	$tw += $width[$col] = &tex_width ($c);

	# Advance.
	$col++;
    }

    # Reveal some of the basics.
    &tex_emit ('% columns ');
    for ( $c = 0; $c <= $#width; $c++ ) {
	&tex_emit ($just[$c], $width[$c], 'em ');
    }
    &tex_emitn ('');


    # Gonna treat the last column slightly different...
    $col--;
    $tw -= $width[$#width];
    # Amount to raise a rule (pt)
    $raiserule = $fill ? 10 : 3;

    local ($line);

    while ( $#lines >= 0 ) {

	local ($line) = shift (@lines);

	# Intercept lines that are only index entries.
	if ( !$noindex && $line =~ /\s*\043\[(.+)\]\043\s*$/ ) {
	    foreach $tag ( split (/\]\043\s*\043\[/, $1) ) {
	        next unless $index || $makeindex;
		# Let tex_string do the dirty work.
		&tex_emitn (&::tex_string ("#[$tag:]#"));
	    }
	    next;
	}

	# Break into columns, split off the rightmost one.
	@cols = $line =~ /^$pat$/;

	# Check for all rules / blanks
	# Normal \textwidth is about 71 dashes (35.5en)

	$allrule = @cols;
	foreach $cc ( @cols ) {
	    if ( $cc !~ /^(-+|\s+)$/ ) {
		$allrule = 0;
		last;
	    }
	}

	$w = pop (@cols);
	$c = 0;

	# Pre-/Interamble. 
	if ( $fill ) {
	    if ( grep (/\S/, @cols) ) {
		&tex_par if $doing;
		&tex_emitn ('\hangindent=', $tw, 'em\hangafter=1');
	    }
	    else {
		# Effectivily skip columns.
		$c = $col if $doing;
	    }
	} else {
	    &tex_newline if $doing;
	}

	&tex_emit ('\rlap{') if $allrule;

	# Columns 1 ... last-1
	while ( $c < $col ) {
	    $cc = $cols[$c];
	    if ( $cc =~ /^-+$/ ) {
		&tex_emitn ('\rule[', $raiserule, 'pt]{', $width[$c], 
			    'em}{\arrayrulewidth}%');
	    }
	    else {
		&tex_emit ('\makebox[', $width[$c], 'em][', $just[$c], ']{');
		$cc =~ s/\s+$//;
		$cc =~ s/^\s+//;
		&tex_text ($cc);
		&tex_emit (' ') if $just[$c] eq 'r';
		&tex_emitn ('}%');
	    }
	    $c++;
	}

	# Last column.
	$w =~ s/\s+$//;		# strip
	$w =~ s/^\s+//;		# strip
	if ( $fill ) {
	    # If filling, we issued a \hang that needs a \par to
	    # take effect. Therefore we cannot use \\ to skip a line.
	    # Temporary set \parskip to zero.
	    &tex_emitn ('{\parskip 0pt plus 1pt') unless $did++;
	    if ( $w =~ /^-+$/ ) {
		&tex_emitn ('\rule[', $raiserule, 'pt]{', $width[$c], 
			    'em}{\arrayrulewidth}%');
	    }
	    else {
		&tex_textn ($w);
	    }
	}
	elsif ( $just[$c] eq 'l' ) {
	    if ( $w =~ /^-+$/ ) {
		&tex_emitn ('\rule[', $raiserule, 'pt]{', $width[$c], 
			    'em}{\arrayrulewidth}%');
	    }
	    else {
		&tex_text ($w);
	    }
	}
	else {
	    # Right or center. Make box.
	    if ( $w =~ /^-+$/ ) {
		&tex_emitn ('\rule[', $raiserule, 'pt]{', $width[$c], 
			    'em}{\arrayrulewidth}%');
	    }
	    else {
		&tex_emit ('\makebox[', $width[$#width], 
			   'em][', $just[$c], ']',
			   '{', &::tex_string ($w), '}');
	    }
	}
	if ( $allrule ) {
	    &tex_emitn ('}\vskip-8pt%');
	    $doing = 0;
	}
	else {
	    $doing = 1;		# aren't we?
	}
    }

    # Final \par. Close context if needed.
    &tex_emitn ('\par', ($did ? '}' : ''));

}

sub emit_tab_control {
    shift;
    local ($ctl) = shift (@_);

    if ( $ctl == $::TBCTL_INIT ) {
	local ($par) = shift(@_);
	return 'cannot nest tables' if $tbl_control > 0;

	$tbl_control = 1;
	$tbl_row = $tbl_col = 1;
	$tbl_columns = $tbl_offset = 0;
	$tbl_float = 0;
	$tbl_landscape = 0;
	$tbl_title = '';
	$tbl_long = 0;

	if ( $par =~ /\s+/ ) {
	    $ctl = $`;
	    $par = $';
	}
	else {
	    $ctl = $par;
	    $par = '';
	}
	@tbl_width = ();
	@tbl_just = ("c");
	$tbl_unk = 0;
	$length = 0;
	foreach $w ( split (/,/, $ctl) ) {

	    if ( $w =~ /^l/i ) {
		$w = $';
		push (@tbl_just, '{\raggedright');
	    }
	    elsif ( $w =~ /^r/i ) {
		$w = $';
		push (@tbl_just, '{\raggedleft');
	    }
	    elsif ( $w =~ /^c/i ) {
		$w = $';
		push (@tbl_just, '{\centering');
	    }
	    elsif ( $w =~ /^f/i ) {
		$w = $';
		push (@tbl_just, '{\sloppy');
	    }
	    else {
		push (@tbl_just, 
		      $::document_type == $::DTP_IMP ? '{\sloppy' : '{\raggedright');
	    }

	    if ( $w =~ /^(\d+)\.(\d)(cm|mm)$/ ) {
		push (@tbl_width, $len = ($1 + $2/10) * ($3 eq 'cm' ? 10 : 1));
		$length += $len;
	    }
	    elsif ( $w =~ /^(\d+)(cm|mm)$/ ) {
		push (@tbl_width, $len = $1 * ($2 eq 'cm' ? 10 : 1));
		$length += $len;
	    }
	    elsif ( $w eq '*' ) {
		push (@tbl_width, 0);
		$tbl_unk++;
	    }
	    else {
		return 'illegal width specification';
	    }
	}

	while ( $par =~ /\btitle=(["'])([^\1]+)\1/i ) {
	    $tbl_float = 1;
	    $tbl_title = $2;
	    $par = "$` $'";
	}

	foreach $w ( split (' ', $par) ) {
	    if ( $w =~ /^type=(\d)$/i ) {
		$tbl_control = 1+$1;
	    }
	    elsif ( $w =~ /^offset=(\d+)\.(\d)(cm|mm)$/i ) {
		$tbl_offset = ($1 + $2/10) * ($3 eq 'cm' ? 10 : 1);
	    }
	    elsif ( $w =~ /^offset=(\d+)(cm|mm)$/i ) {
		$tbl_offset = $1 * ($2 eq 'cm' ? 10 : 1);
	    }
	    elsif ( $w =~ /^float$/i ) {
		$tbl_float = 1;
	    }
	    elsif ( $w =~ /^long$/i ) {
		$tbl_long = 1;
	    }
	    elsif ( $w =~ /^landscape$/i ) {
		$tbl_landscape = 1;
	    }
	    else {
		return "illegal table option \"$w\"";
	    }
	}
	$tbl_columns = @tbl_width;
	$length += $tbl_offset + $tbl_offset;
	$tbl_float = $tbl_offset = 0 if $tbl_landscape;

	&tex_style ($::STANDARD);

	&tex_emitn ('\begin{figure}[htp]') if $tbl_float;

	&tex_emit ('\makebox[\enumindent]{}')
	    if $::tabular_saved_context[0] >= $::ENUM1;
	&tex_emit ('\makebox[\enumindent]{}')
	    if $::tabular_saved_context[0] >= $::ENUM2;
	&tex_emit ('\makebox[', $tbl_offset, 'mm]{}') if $tbl_offset;
	if ( $tbl_landscape ) {
	    &tex_emit ('\newbox\tblbox') unless $tblbox++;
	    &tex_emitn ('\setbox\tblbox=\vbox{%');
	    &tex_emitn ('\setlength{\mctcw}{\textheight}%');
	}
	else {
	    &tex_emitn ('\setlength{\mctcw}{\linewidth}%');
	    &tex_emitn ('\addtolength{\mctcw}{-\enumindent}%')
		if $::tabular_saved_context[0] >= $::ENUM1;
	    &tex_emitn ('\addtolength{\mctcw}{-\enumindent}%')
		if $::tabular_saved_context[0] >= $::ENUM2;
	}
	&tex_emitn ('\addtolength{\mctcw}{-', $tbl_offset, 'mm}%')
	    if $tbl_offset;

	&tex_emitn ('\begin{minipage}{\mctcw}')
	    unless $tbl_long;

	# Fill in the unknown.
	if ( $tbl_unk > 0 ) {
	    # This fine-tuning prevents an overfull hbox for tables
	    &tex_emitn ('\addtolength{\mctcw}{-0.3pt}');
	    # Subtract known length
	    &tex_emitn ('\addtolength{\mctcw}{-', int($length+0.5), 'mm}')
		if $length > 0.5;
	    # Subtract inter-column space
	    &tex_emitn ('\addtolength{\mctcw}{-', 2*$tbl_columns, 
			'\tabcolsep}');
	    # And distribute
	    &tex_emitn ('\divide \mctcw by ', $tbl_unk) if $tbl_unk > 1;
	}
	else {
	    &tex_emitn ('\begin{center}');
	}
	&tex_emit ('\begin{', $tbl_long ? 'longtable' : 'tabular',
		   '}[t]{@{}');
	&tex_emit ('|') if $tbl_control > 2;
	for $w ( @tbl_width ) {
	    &tex_emit ('p{', $w ? "${w}mm}" : '\mctcw}');
	    &tex_emit ('|') if $tbl_control > 2;
	}
	&tex_emitn ('@{}}%');
	if ( $tbl_long ) {
	    local ($tbl_first) = 1;
	    for $w ( @tbl_width ) {
		&tex_emit (' &') unless $tbl_first;
		&tex_emit ('\hbox to ', $w ? "${w}mm" : '\mctcw', '{}');
		$tbl_first = 0;
	    }
	    &tex_emitn('\kill');
	    &tex_emitn('\multicolumn{', $tbl_columns, '}{@{}|r|@{}}%');
	    &tex_emitn ('{Zie volgende pagina}\\\\\hline');
	    &tex_emitn ('\endfoot');
	    &tex_emitn ('\endlastfoot');
	}
	if ( $tbl_control > 2 ) {
	    &tex_emitn ('\hline');
	}
	&tex_emitn ('% row ', $tbl_row, ', column ', $tbl_col,
		    ' (of ', $tbl_columns, ')');
	&tex_emit ($tbl_just[$tbl_col], $tbl_long ? ' ' : "\n");
        return '';
    }
    elsif ( $tbl_control == 0 ) {
	die ('Illegal call to tex_tabcontrol = ', $ctl, "\n");
    }

    if ( $ctl == $::TBCTL_COL ) {
	return 'too many columns in this row'
	    if $tbl_col == $tbl_columns;
	&tex_style ($::STANDARD);
	&tex_emitn ('\vspace{-\baselineskip}}&');
	$tbl_col++;
	&tex_emitn ('% row ', $tbl_row, ', column ', $tbl_col,
		    ' (of ', $tbl_columns, ')');
	&tex_emit ($tbl_just[$tbl_col], $tbl_long ? ' ' : "\n");
    }

    elsif ( $ctl == $::TBCTL_HEAD ) {
	return 'not enough columns in this row'
	    unless $tbl_col == $tbl_columns;
	&tex_style ($::STANDARD);
	&tex_emit ('\vspace{-\baselineskip}\vspace{4pt}}\\\\\endhead');
	if ( $tbl_control > 3 || $tbl_control > 1 && $tbl_row == 1 ) {
	    &tex_emitn ('\hline');
	}
	$tbl_row++;
	$tbl_col = 1;
	&tex_emitn ('% row ', $tbl_row, ', column ', $tbl_col,
		    ' (of ', $tbl_columns, ')');
	&tex_emit ($tbl_just[$tbl_col], $tbl_long ? ' ' : "\n");
	return "[head] requires 'long' option"
	    unless $tbl_long;
    }

    elsif ( $ctl == $::TBCTL_ROW ) {
	return 'not enough columns in this row'
	    unless $tbl_col == $tbl_columns;
	&tex_style ($::STANDARD);
	&tex_emit ('\vspace{-\baselineskip}');
	&tex_emit ('\vspace{4pt}');
	if ( $tbl_control > 3 || $tbl_control > 1 && $tbl_row == 1 ) {
	    &tex_emitn ('}\\\\\hline');
	}
	else {
	    &tex_emitn ('}\\\\');
	}
	$tbl_row++;
	$tbl_col = 1;
	&tex_emitn ('% row ', $tbl_row, ', column ', $tbl_col,
		    ' (of ', $tbl_columns, ')');
	&tex_emit ($tbl_just[$tbl_col], $tbl_long ? ' ' : "\n");
    }

    elsif ( $ctl == $::TBCTL_END ) {
	return 'unexpected [end table]' unless $tbl_control > 0;
	return 'not enough columns in this row'
	    unless $tbl_col == $tbl_columns;
	$tbl_columns = 0;
	&tex_style ($::STANDARD);
	&tex_emit ('\vspace{-\baselineskip}');
	&tex_emit ('\vspace{4pt}');
	&tex_emitn ('}', $tbl_control > 2 ? '\\\\\hline' : '\\\\');
	&tex_emitn ('\end{', $tbl_long ? 'longtable' : 'tabular', '}');
	&tex_emitn ('\end{center}') unless $tbl_unk > 0;
	if ( $tbl_title ne '' ) {
	    &tex_emitn ('\centerline{\footnotesize \strut}');
	    &tex_emitn ('\centerline{\footnotesize {',
			&::tex_string ($tbl_title), '}}');
	}
	&tex_emitn ('\end{minipage}') unless $tbl_long;
	&tex_emitn ('\end{figure}') if $tbl_float;
	if ( $tbl_landscape ) {
	    &tex_emitn ('}');
	    &tex_emitn ('\begin{figure}[p]',
			'\makeatletter\xxrotl\tblbox',
			'\end{figure}');
	}

	&tex_par;
	$tbl_control = 0;
    }

    else {
	die ('Illegal param to tex_tabcontrol = ', $ctl, "\n");
    }
    '';
}

sub tex_width {
    local ($arg, $w, $c) = @_;
    foreach $c (split (//, $arg)) {
	$w += 0.5;
	$w += 0.5 if $c eq 'm';
	$w -= 0.25 if $c eq 'i';
    }
    $w;
}

sub inline_data {
    local ($ctl, $par) = @_;
    require "shellwords.pl";
    $ctl = "\L$ctl";

    if ( $ctl eq "tbl" ) {

	local ($tbl_box, $tbl_center, $tbl_float, $tbl_expand) = (0, 0, 0, 0);
	local ($tbl_tab, $tbl_title) = ('&', '');
	local (@words, $line);

	# inline tbl [float][title "..."]
	@words = &shellwords ($par);
	while ( @words ) {
	    $_ = shift (@words);
	    if ( "\L$_" eq "title" && @words > 0 ) {
		$tbl_title = shift (@words);
		$tbl_center++;
		$tbl_float++;
	    }
	    elsif ( "\L$_" eq "float" ) {
		$tbl_float++;
	    }
	    else {
		&::err ("Unknown inline tbl option: \"\L$_\E\"");
	    }
	}

	# First line should be [box][center][expand][tab(#)];
	$line = shift (@lines);
	if ( $line =~ /;$/ ) {
	    @words = split (' ', $`);
	    while ( @words ) {
		$_ = shift (@words);
		if ( "\L$_" eq "box" ) {
		    $tbl_box++;
		}
		elsif ( "\L$_" eq "center" ) {
		    $tbl_center++;
		}
		elsif ( "\L$_" eq "expand" ) {
		    $tbl_expand++;
		}
		elsif ( /^tab\((\W)\)$/i ) {
		    $tbl_tab = $1;
		}
		else {
		    &::err ("Inline tbl error: 1st line: $line");
		}
	    }
	    $line = shift (@lines);
	}

	# Next line should designate columns and alignment.

	&::err ("Inline tbl error: 2nd line: $line")
	    unless ($line) =~ /^[lrcn ]+\.$/;
	chop ($line);
	$line =~ s/n/r/g;	# treat n as right col
	$line =~ s/ //g;	# allow 'lll' as well as 'l l l'
	local (@just) = split ('', $line);
	local ($ncols) = $#just;

	# Cannot handle expand yet...
	$tbl_expand = 0;

	&tex_emitn ('\begin{figure}[', $tbl_float ? 'htp' : 'h', ']');
	&tex_emitn ('\centerline{%') if $tbl_center;
	&tex_emitn ('\renewcommand{\arraystretch}{1}');
	if ( $tbl_expand ) {
	    &tex_emit ('\begin{tabular*}{\textwidth}');
	    &tex_emit ($tbl_box ? '{|' :'{@{}' );
	    foreach ( @just ) {
		if ( $_ eq 'l' ) {
		    &tex_emit ('l@{\fill}');
		}
		elsif ( $_ eq 'r' ) {
		    &tex_emit ('@{\fill}r');
		}
		else {
		    &tex_emit ('@{\fill}c@{\fill}');
		}
	    }
	    &tex_emitn ($tbl_box ? '|}' :'@{}}' );
	}
	else {
	    if ( $tbl_box ) {
		&tex_emitn ('\begin{tabular}{|', join('|', @just), '|}');
	    }
	    else {
		# Need @{} to get rid of extra space before/after.
		&tex_emitn ('\begin{tabular}{@{}', join('', @just), '@{}}');
	    }
	}
	&tex_emitn ('\hline') if $tbl_box;

	$tbl_tab =~ s/(\W)/\\\1/g; # make pattern
	while ( @lines > 0 ) {
	    $line = shift (@lines);
	    if ( $line =~ /^_$/ ) {
		&tex_emitn ('\hline');
	    }
	    else {
		@cols = split (/$tbl_tab/, $line);
		$cols[$ncols] .= '';
		$last = pop (@cols);
		foreach ( @cols ) {
		    s/^\s+//;
		    s/\s+$//;
		    &tex_emit (&::tex_string ($_), '&');
		}
		&tex_emitn (&::tex_string ($last), '\\\\');
	    }
	}
	&tex_emitn ('\hline') if $tbl_box;
	&tex_emitn ('\end{tabular', $tbl_expand ? '*}' : '}');
	&tex_emitn ('}') if $tbl_center;
	if ( $tbl_title ne '' ) {
	    &tex_emitn ('\centerline{\footnotesize\strut}');
	    &tex_emitn ('\centerline{\footnotesize{'.
			&::tex_string ($tbl_title), '}}');
	}
	&tex_emitn ('\end{figure}');
    }
    elsif ( $ctl eq "screen" ) {

	local ($scr_border, $scr_grid, $scr_float, $scr_expert) = (1, 0, 0, 0);
	local ($scr_title) = ('');
	local (@words, $line);

	# inline screen [expert][noborder][grid][float][title "..."]
	@words = &shellwords ($par);
	while ( @words ) {
	    $_ = shift (@words);
	    if ( "\L$_" eq "title" && @words > 0 ) {
		$scr_title = shift (@words);
		$scr_float++;
	    }
	    elsif ( "\L$_" eq "expert" ) {
		$scr_expert = 1;
	    }
	    elsif ( "\L$_" eq "noborder" ) {
		$scr_border = 0;
	    }
	    elsif ( "\L$_" eq "grid" ) {
		$scr_grid++;
	    }
	    elsif ( "\L$_" eq "float" ) {
		$scr_float++;
	    }
	    else {
		&::err ("Unknown inline screen option: \"\L$_\E\"");
	    }
	}

	local (*SCR);
	local ($scrfile) = sprintf ("$::TMPDIR/sc$$%03d.scr", ++$scr_index);

	if ( open (SCR, ">$scrfile") ) { 
	    print SCR (0+@lines, "x80\n") unless $scr_expert;;
	    foreach ( @lines ) {
		print SCR ($_, "\n");
	    }
	    close (SCR);
	    local ($cmd) = "scr2eps -quiet";
	    $cmd .= " -noborder" unless $scr_border;
	    $cmd .= " -grid" if $scr_grid;
	    $cmd .= " " . $scrfile;
	    system ($cmd);
	    unlink ($scrfile);
	    $scrfile =~ s/\.scr$/.eps/;
	    &::feedbacka ('tempfiles', $scrfile);
	    &emit_tex_tabular ("[[epsf $scrfile".
			       ($scr_title ne '' ? " $scr_title" : "") . "]]");
	}
	else {
	    &::warn ("$scrfile: $!\n");
	}
    }
    else {
	&::err ("Unknown inline code: \"$ctl\"");
    }
}

sub emit_newdocument {
    my $self = shift;
    &tex_preamble ($self, 1);
}

sub init {
    my $self = shift;
    &tex_init;
    &tex_preamble ($self, 0);
}

sub wrapup {
    shift;
    local ($fail) = @_;
    &tex_style ($::STANDARD);
    &tex_trailer;
    $fail;
}

################ private routines ################

sub tex_init {

    @enum_leaders =		# KEEP IN SYNC WITH $::LEADER_...!
	('',			# no leader
	 '\xitem ',		# default
	 '\aitem ',		# alpha-numeric
	 '\nitem ',		# numeric
	 $latex209 ? '\litem{$\bullet$}' : '\litem{\textbullet}',	# bullet
	 '\litem{--}',		# en-dash
	 '\litem{}',		# empty
	 );

    my $dtbl = $enctabs{lc($::inputencoding)};
    ::loadpkg($dtbl.$texencoding); # e.g, Latin1T1

    ::loadpkg("String");
    ::loadpkg("KeyCaps") if $::keycaps;

    $current_style = -1;
    $config = $::toc && ( $::document_type != $::DTP_REPORT );
    $secno = 0;
}

# Primary output routines

sub tex_emit	{ print STDOUT (@_); }
sub tex_emitn	{ print STDOUT (@_, "\n"); }
sub tex_text	{ print STDOUT (&::tex_string ($_[0])); }
sub tex_textn	{ print STDOUT (&::tex_string ($_[0]), "\n"); }
sub tex_par	{ print STDOUT ("\n", '\par', "\n"); }
sub tex_newline	{ print STDOUT ('\\\\\relax', "\n"); }

sub tex_verbatim {

    # Convert string to verbatim LaTeX format.
    # Everything is kept intact as much as possible.
    local ($line, $allow_break) = @_;
    local ($chr, $prev, $tmp);
    local ($res) = "";

    # Translate pseudo-ISO characters back
    $line =~ tr/\320\336\240/"' /;

    # Hmm. \verb skips leading blanks??
    if ( $line =~ /^ +/ ) {
	$line = $';
	$res = '~' x length($&); # make them hard
    }

    $res .= '\verb@';		# start verbing

    # Everything will be put out as a \verb@ ... @ sequence, except 
    # @ itself.
    while ( $line =~ /[\200-\377@]/ ) {

	$chr = $&;		# the special character
	$line = $';		# what comes after it
	$tmp = $`;		# what came before it
	$prev = (length ($`) > 0) ? substr($`,length($`)-1) : '';
				# the character that came before

	if ( length($tmp) > 0 ) {
	    $res .= $tmp;
	}

	if ( ord($chr) >= 128 ) {

	    # specials, e.g. "\353" -> e-acute "\\'{e}"
	    if ( defined ($tmp = $::iso2tex{$chr}) ) {
		# temporary get out of verb mode
		$res .= "@".$tmp."\\verb@";
		next;
	    }
	    else {
		# ignore it
		&::warn (sprintf ('unknown ISO character \%o (ignored)', ord($chr)));
		next;
	    }
	}
	elsif ( $chr eq '@' ) {
	    $chr = '@@\verb@';
	}

	$res .= $chr;
    }

    $res .= $line . '@';
    $res =~ s/([^\@])([ ---\/\.])([^\@])/\1\2@\\discretionary{}{}{}\\verb@\3/g if $allow_break;
    $res;
}

# Change style, if needed.

sub tex_style {
    local ($style) = @_;
    print STDERR "=> style $current_style -> $style\n" if $::debug;

    &tex_emitn ('');

    return if $style == $current_style && $style < $::HEADER1;

    if ( $style == $::ENUM1 ) {
	if ( $current_style == $::ENUM2 ) {
	    &tex_emitn ('\end{enum}');
	    #### Disable un-released feature ####
	    # &tex_emitn ('\vskip\smallskipamount');
	}
	else {
	    &tex_emitn ('\begin{enum}');
	}
    }
    elsif ( $style == $::ENUM2 ) {
	if ( $current_style == $::ENUM1 ) {
	    #### Disable un-released feature ####
	    # &tex_emitn ('\vskip\smallskipamount');
	    &tex_emitn ('\begin{enum}');
	}
	else {
	    &tex_emitn ('\begin{enum}');
	    &tex_emitn ('\begin{enum}');
	}
    }
    else {
	if ( $current_style == $::ENUM1 ) {
	    &tex_emitn ('\end{enum}');
	}
	elsif ( $current_style == $::ENUM2 ) {
	    &tex_emitn ('\end{enum}');
	    &tex_emitn ('\end{enum}');
	}
	if ( $style == $::HEADER1 ) {
	    &tex_emit ($unnumbered ? "\\nn" : "\\", 'section{');
	}
	elsif ( $style == $::HEADER2 ) {
	    &tex_emit ($unnumbered ? "\\nn" : "\\", 'subsection{');
	}
	elsif ( $style == $::HEADER3 ) {
	    &tex_emit ($unnumbered ? "\\nn" : "\\", 'subsubsection{');
	}
	elsif ( $style == $::CAPTION1 ) {
	    &tex_emit ('\bfcaption{');
	}
	elsif ( $style >= $::CAPTION2 ) {
	    &tex_emit ('\emcaption{');
	}
    }
    $current_style = $style;
}

# Include TEX preamble.

sub tex_preamble {
    my $self = shift;
    local ($changedoc) = @_;
    local (@ts) = localtime (time);
    local ($doc_style);
    local (@doc_opts);

    unless ( defined ($doc_style = $::headers[$::HDR_DOCUMENTSTYLE]) ) {
	&::err ("No document style defined.\n");
	$doc_style = "mh_doc";
    }

    # User (or config) defined style and options.
    @doc_opts = split (/\s+/, $doc_style);
    $doc_style = shift(@doc_opts);
    if ( $doc_style eq "-" ) {	# default
	$doc_style = shift(@doc_opts);
    }
    else {
	# Explicitly specified style implies explicit prologue.
	&::feedback ('document_prologue', $doc_style);
    }
    &::feedback ('document_style', $doc_style);

    # Add program options.
    push (@doc_opts, 'makeidx') if $index || $makeindex;
    push (@doc_opts, 'justify') if $::justify;
    if ( $::document_type == $::DTP_SLIDES ) {
	push (@doc_opts, 'handouts') if $handouts;
	push (@doc_opts, $::landscape ? 'landscape' : 'portrait');
	push (@doc_opts, 'border') if $border;
    }

    # For some ::headers, allow breaks on ",\s+" only...
    foreach $hdr ( $::HDR_TO, $::HDR_CC, $::HDR_PRESENT, $::HDR_ABSENT ) {
	next unless defined $::headers[$hdr];
	next if ($hdr == $::HDR_TO || $hdr == $::HDR_CC) &&
	    $::document_type == $::DTP_LETTER;
	$::headers[$hdr] =~ s/\s+/\240/g;
	$::headers[$hdr] =~ s/,\240/, /g;
    }

    unless ($changedoc) {
	print STDOUT 
	    ("% LaTeX generated by ", $self->id_name, " ",
	     $self->id_version, ", ",
	     sprintf ('%02d/%02d/%02d %02d:%02d',
		      $ts[5], $ts[4]+1, $ts[3], $ts[2], $ts[1]),
	     "\n%\n");
	print STDOUT ('\document', $latex209 ? 'style' : 'class');
	print STDOUT ('[', join(',',@doc_opts), ']') if @doc_opts;
	print STDOUT ("{$doc_style}\n");
	if ( $::document_type == $::DTP_IMP ) {
	    print STDOUT ('\def\Map{', &::nls ($::TXT_MAP), '}', "\n",
			  '\def\Section{', &::nls ($::TXT_SECTION), '}', "\n",
			  '\def\Page{', &::nls ($::TXT_PAGE), '}', "\n");
	}
	if ( $latex209 ) {
	    print STDOUT ('\language\\', &::nls ($::TXT_LANG), "\n");
	}
	else {
	    print STDOUT ('\usepackage[', lc(::nls($::TXT_LANG)), "]{babel}\n");
	    print STDOUT ('\selectlanguage\\', lc(::nls($::TXT_LANG)), "\n");
	}
	if ( $::use_ts1 ) {
	    print STDOUT ('\usepackage{textcomp}',"\n");
	}
	print STDOUT ('\draft{', &::tex_string (&::nls ($::TXT_DRAFT)), '}', "\n")
	    if $::draft;
	if ( $index || $makeindex ) {
	    print STDOUT ('\makeindex', "\n");
	    print STDOUT ('\def\indexcaption{', 
			  &::tex_string(&::nls ($::TXT_INDEX)), "}\n");
	}
	print STDOUT ("\n", '\begin{document}', "\n\n");
    }
    else {
	&tex_style ($::STANDARD);
	if ($::document_type == $::DTP_LETTER ) {
	    &tex_closing;
	}
	else {
	    &tex_emitn ('\reset');
	}
    }

    print STDOUT ('\def\indexname{', 
		  &::tex_string($::headers[$::HDR_INDEX]), "}\n")
	if $::headers[$::HDR_INDEX] ne '';

    if ( $::document_type == $::DTP_MREP ) {

	print STDOUT 
	    ("%\n% Page ::headers and footers\n%\n",
	     '\header{', &::tex_string ($::headers[$::HDR_DEPT]), "}\n",
	     '       {', int($::headers[$::HDR_NUMBER])
	                   ? &::tex_string (sprintf (&::nls ($::FMT_MEETING), 
						 int($::headers[$::HDR_NUMBER])))
	                   : &::tex_string ($::headers[$::HDR_NUMBER]), "}\n",
	     '       {', &::tex_string ($::headers[$::HDR_MEETING]), "}\n",
	     '       {', &::tex_string ($::hdr_name[$::HDR_DATE]. ': ' . $::headers[$::HDR_DATE]), "}\n",
	     '\footer{', &::tex_string ($::headers[$::HDR_CMPY] . " \255 " . $::headers[$::HDR_FROM]));

	if ( $::headers[$::HDR_PHONE] ) {
	    print STDOUT (' ', &::tex_string ($::headers[$::HDR_PHONE]));
	}

	print STDOUT
	    ('}{\thepage}', "\n");

	print STDOUT 
	    ("%\n% Generate heading\n%\n",
	     '\begin{headers}', "\n");

	foreach $hdr ($::HDR_TO, $::HDR_PRESENT, $::HDR_ABSENT, $::HDR_SECR, $::HDR_CC) {
	    next unless defined $::headers[$hdr];
	    print STDOUT ('\item[', $::hdr_name[$hdr], ':] ',
			  &::tex_string ($::headers[$hdr]), "\n");
	}

	print STDOUT ('\end{headers}', "\n");
    }

    elsif ( $::document_type == $::DTP_MEMO ) {

	print STDOUT 
	    ("%\n% Page ::headers and footers\n%\n",
	     '\header{\strut}{\strut}', "\n",
	     '       {', &::tex_string ($::headers[$::HDR_DEPT]), "}\n",
	     '       {', &::tex_string ($::headers[$::HDR_TITLE]), "}\n",
	     '\footer{', &::tex_string ($::headers[$::HDR_CMPY] . " \255 " . $::headers[$::HDR_FROM]));

	if ( $::headers[$::HDR_PHONE] ) {
	    print STDOUT (' ', &::tex_string ($::headers[$::HDR_PHONE]));
	}

	print STDOUT
	    ('}', '{\thepage}', "\n");

	print STDOUT 
	    ("%\n% Generate heading\n%\n",
	     '\begin{headers}', "\n");

	foreach $hdr ($::HDR_TO, $::HDR_FROM, $::HDR_DATE, $::HDR_CC, $::HDR_SUBJECT ) {
	    print STDOUT ('\item[', $::hdr_name[$hdr], ':] ',
			  &::tex_string ($::headers[$hdr]), "\n");
	}

	print STDOUT ('\end{headers}', "\n");
    }

    elsif ( $::document_type == $::DTP_IMP ) {

	$::headers[$::HDR_TITLE] =~ s/[ \t\n\r]+/ /g;
	print STDOUT 
	    ("%\n% Page ::headers and footers\n%\n",
	     '\header{\leftmark}{', &::tex_string ($::hdr_name[$::HDR_SECTION]),
	     ' \thesection.0}', "\n",
	     '       {\rightmark}{}', "\n",
	     '\footer{', &::tex_string ($::headers[$::HDR_TITLE]), '}', "\n");
	$section = $::headers[$::HDR_SECTION];
	if ( $section =~ /^\s*([\d*]+[\d.]*)\s*(.*)\s*$/ ) {
	    $chaptitle = $2;
	    ($chapnum,$subchapnum,$subsubchapnum) = split (/\./, $1);
	    $::chapnum = $secnum + 1 if $::chapnum eq "*";
	    $secnum = $::chapnum;
	}
	print STDOUT ('\setcounter{section}{', $::chapnum, '}', "\n")
	    if $::chapnum > 0;
	print STDOUT ('\maptitle{', &::tex_string($chaptitle), '}', "\n")
	    if $chaptitle;
	if ( $::toc ) {
	    if ( !$changedoc ) {
		print STDOUT ('\supertableofcontents{',
			      &::nls ($::TXT_TOC), '}', "\n",
			      '\newpage', "\n");
	    }
	    print STDOUT ('\tableofcontents{',
			  &::nls ($::TXT_COS), ' ', $::chapnum, '}', "\n",
			  '\newpage', "\n");
	}
    }

    elsif ( $::document_type == $::DTP_REPORT ) {

	$year = ($ts[5] < 72) ? 2000+$ts[5] : 1900+$ts[5];
	unless ( defined $::headers[$::HDR_DOCID] ) {
	    $::headers[$::HDR_DOCID] = 
		$::headers[$::HDR_CMPY] . " \255 " .
		$::headers[$::HDR_MHID] .
		' / ' . $::hdr_name[$::HDR_VERSION] . ' ' .
		$::headers[$::HDR_VERSION] . 
		sprintf (' [%02d/%02d/%4d %02d:%02d]',
			 $ts[3], $ts[4]+1, $year, $ts[2], $ts[1]);
	}

	($title = $::headers[$::HDR_TITLE]) =~ tr/\n/ /;
	unless ( $::notitlepage ) {
	    print STDOUT
		('\begin{titlepage}', "\n",
		 '\addtolength{\oddsidemargin}{1.5cm}', "\n",
		 '\vspace*{2.8cm}', "\n");

	    print STDOUT ('\vbox to 6.2cm {{\large', "\n");

	    foreach $line ( split (/\n/, $::headers[$::HDR_TITLE]) ) {
		print STDOUT
		    ('\uppercase{{', &::tex_string ($line), '}}\par', "\n");
	    }

	    print STDOUT
		('}\vfill}', "\n",
		 '\vbox to 14cm{', "\n",
		 '\begin{trivlist}\addtolength{\leftmargin}{2cm}', "\n",
		 '\addtolength{\rightmargin}{2cm}\item[]', "\n");

	    for $hdr ( $::HDR_VERSION, $::HDR_DATE ) {
		print STDOUT 
		    ('\hangindent=2cm\hangafter=1\makebox[2cm][l]{', 
		     $::hdr_name[$hdr], ':}%', "\n",
		     &::tex_string ($::headers[$hdr]), 
		     '\par', "\n");
	    }

	    print STDOUT
		('\makebox[2cm][l]{}\par', "\n",
		 '\makebox[2cm][l]{}\par', "\n");

	    for $hdr ( $::HDR_AUTHOR, $::HDR_DEPT, $::HDR_PROJECT, $::HDR_DOCID ) { 
		$tag = $::hdr_name[$hdr];
		print STDOUT 
		    ('\hangindent=2cm\hangafter=1\makebox[2cm][l]{', $tag, 
		     ':}%', "\n",
		     &::tex_string ($::headers[$hdr]),
		     '\par', "\n");
	    }

	    print STDOUT
		('\makebox[2cm][l]{}\par', "\n");

	    for $hdr ( $::HDR_OK ) {
		next unless $::headers[$hdr];
		$tag = $::hdr_name[$hdr];
		print STDOUT 
		    ('\hangindent=2cm\hangafter=1\makebox[2cm][l]{', $tag, 
		     ':}%', "\n",
		     &::tex_string ($::headers[$hdr]),
		     '\par', "\n");
	    }
	    print STDOUT
		('\end{trivlist}', "\n", '\vfill', "\n", '}', "\n");

	    print STDOUT
		('\par', "\n",
		 '{\footnotesize Copyright \copyright ', $year,
		 ' ', &::tex_string ($::headers[$::HDR_COMPANY]), '}', "\n",
		 '\end{titlepage}', "\n");
	}

	print STDOUT 
	    ("%\n% Page ::headers and footers\n%\n",
	     '\header{', &::tex_string ($title), '}{\strut}', "\n",
	     '       {\rightmark}{\strut}', "\n",
	     '\footer{', &::tex_string ($::headers[$::HDR_DOCID]), '}',
	     '{\leftmark\thepage}', "\n");

	if ( $::toc && !$changedoc ) {
	    print STDOUT ('\tableofcontents{',
			  &::nls ($::TXT_TOC) , '}',
			  "\n", '\newpage', "\n");
	}
    }

    elsif ( $::document_type == $::DTP_NOTE ) {

	$year = ($ts[5] < 72) ? 2000+$ts[5] : 1900+$ts[5];
	unless ( defined $::headers[$::HDR_DOCID] ) {
	    $::headers[$::HDR_DOCID] = 
		$::headers[$::HDR_CMPY] . " \255 " .
		$::headers[$::HDR_MHID] .
		' / ' . $::hdr_name[$::HDR_VERSION] . ' ' .
		$::headers[$::HDR_VERSION] . 
		sprintf (' [%02d/%02d/%4d %02d:%02d]',
			 $ts[3], $ts[4]+1, $year, $ts[2], $ts[1]);
	}

	($title = $::headers[$::HDR_TITLE]) =~ tr/\n/ /;
	unless ( $::notitlepage ) {
	    print STDOUT
		("%\n% Generate titlepage\n%\n",
		 '\begin{titlepage}', "\n",
		 '\addtolength{\oddsidemargin}{1.5cm}', "\n",
		 '\vspace*{2.8cm}', "\n");

	    print STDOUT ('\vbox to 6.2cm {{\large', "\n");

	    foreach $line ( split (/\n/, $::headers[$::HDR_TITLE]) ) {
		print STDOUT
		    ('\uppercase{{', &::tex_string ($line), '}}\par', "\n");
	    }

	    print STDOUT ('}\vfill}', "\n");

	    for $hdr ( $::HDR_NOTE, $::HDR_VERSION, $::HDR_DATE ) {
		$tag = $::hdr_name[$hdr];
		print STDOUT 
		    ('\makebox[2cm][l]{', $tag, ':}',
		     &::tex_string ($::headers[$hdr]), 
		     '\par', "\n");
	    }

	    print STDOUT
		('\makebox[2cm][l]{}\par', "\n",
		 '\makebox[2cm][l]{}\par', "\n");

	    for $hdr ( $::HDR_AUTHOR, $::HDR_DEPT, $::HDR_DOCID ) { 
		$tag = $::hdr_name[$hdr];
		print STDOUT 
		    ('\makebox[2cm][l]{', $tag, ':}',
		     &::tex_string ($::headers[$hdr]),
		     '\par', "\n");
	    }

	    print STDOUT
		('\vspace*{8cm}', "\n",
		 '{\footnotesize Copyright \copyright ', $year,
		 ' ', &::tex_string ($::headers[$::HDR_COMPANY]), '}', "\n",
		 '\end{titlepage}', "\n");
	}

	print STDOUT 
	    ("%\n% Page ::headers and footers\n%\n",
	     '\header{', &::tex_string ($::headers[$::HDR_DEPT]), '}',
	     '{\strut}', "\n",
	     '       {', &::tex_string ($title), '}',
	     '{\strut}', "\n",
	     '\footer{', &::tex_string ($::headers[$::HDR_DOCID]), '}',
	     '{\thepage}', "\n");

	if ( $::toc && !$changedoc ) {
	    print STDOUT ('\tableofcontents{', &::nls($::TXT_TOC), '}',
			  "\n", '\newpage', "\n");
	}
    }

    elsif ( $::document_type == $::DTP_LETTER ) {

	print STDOUT ('\begin{letter}', "\n", '{');
	@lines = split (/\s*\n\s*/, $::headers[$::HDR_TO]);
	while ( $#lines >= 0 ) {
	    local ($l) = &::tex_string(shift(@lines));
	    if ( $l =~ /^(\d\d\d\d)\s+([A-Z][A-Z])\s+/ ) {
		$l = $1 . '~' . $2 . '~~~' . $';
	    }
	    print STDOUT ($l, $#lines >= 0 ? '\\\\' : '}', "\n");
	}
	print STDOUT
	    ('\ref[', &::nls($::TXT_REF), ':]{', &::tex_string($::headers[$::HDR_REF]), '}', "\n",
	     '\date{', &::tex_string($::headers[$::HDR_CITY]),
	     ', ', $::headers[$::HDR_DATE], '}', "\n",
	     '\subject[', &::tex_string ($::hdr_name[$::HDR_SUBJECT]), ':]{',
	     &::tex_string ($::headers[$::HDR_SUBJECT]), '}', "\n",
	     '\signature{');
	@lines = split (/\s*\n\s*/, $::headers[$::HDR_FROM]);
	while ( $#lines >= 0 ) {
	    print STDOUT (&::tex_string(shift(@lines)), 
			  $#lines >= 0 ? '\\\\' : '}', "\n");
	}
	print STDOUT ('\opening{', &::tex_string($::headers[$::HDR_OPENING]),
		      '}', "\n");
	@saved_::headers = @::headers;
    }

    elsif ( $::document_type == $::DTP_SLIDES ) {

	$year = ($ts[5] < 72) ? 2000+$ts[5] : 1900+$ts[5];
	unless ( defined $::headers[$::HDR_DOCID] ) {
	    $::headers[$::HDR_DOCID] = 
		$::headers[$::HDR_CMPY] . " \255 " .
		$::headers[$::HDR_MHID] .
		' / ' . 
		$::headers[$::HDR_VERSION] . 
		sprintf (' [%02d/%02d/%4d %02d:%02d]',
			 $ts[3], $ts[4]+1, $year, $ts[2], $ts[1]);
	}
	$::headers[$::HDR_TITLE] =~ s/[ \t\n\r]+/ /g;

	print STDOUT 
	    ("%\n% Page ::headers and footers\n%\n",
	     '\header{', &::tex_string ($::headers[$::HDR_TITLE]), '}', "\n",
	     '\footer{', &::tex_string ($::headers[$::HDR_DOCID]), '}', "\n");
#	if ( $::toc ) {
#	    print STDOUT ('\tableofcontents{', &::nls($::TXT_TOC), '}',
#			  "\n", '\newpage', "\n");
#	}
    }

    elsif ( $::document_type == $::DTP_OFFERING ) {

	$year = ($ts[5] < 72) ? 2000+$ts[5] : 1900+$ts[5];

#	unless ( defined $::headers[$::HDR_DOCID] ) {
	    $::headers[$::HDR_DOCID] = 
		$::headers[$::HDR_COMPANY] . " \255 " .
		$::headers[$::HDR_OFFERING];
#	}

	($title = $::headers[$::HDR_TITLE]) =~ tr/\n/ /;
	unless ( $::notitlepage ) {
	    print STDOUT
		("%\n% Generate titlepage\n%\n",
		 '\begin{titlepage}', "\n",
		 '\addtolength{\oddsidemargin}{1.5cm}', "\n",
		 '\vspace*{2.8cm}', "\n");

	    print STDOUT ('\vbox to 6.2cm {{\xivpt', "\n");

	    foreach $line ( split (/\n/, $::headers[$::HDR_TITLE]) ) {
		print STDOUT
		    ('\uppercase{{', &::tex_string ($line), '}}\par', "\n");
	    }

	    print STDOUT ('}\vfill}', "\n", '{\xiipt', "\t\t", '% \xiipt',
			  "\n");

	    for $hdr ( $::HDR_DATE ) {
		print STDOUT 
		    ('\makebox[2cm][l]{', $::hdr_name[$hdr], ':}',
		     &::tex_string ($::headers[$hdr]), 
		     '\par', "\n");
	    }

	    print STDOUT
		('\makebox[2cm][l]{}\par', "\n",
		 '\makebox[2cm][l]{}\par', "\n");

	    for $hdr ( $::HDR_OFFERING ) {
		$tag = $::hdr_name[$hdr];
		print STDOUT 
		    ('\makebox[2cm][l]{', $tag, ':}',
		     &::tex_string ($::headers[$hdr]),
		     '\par', "\n");
	    }

	    for $hdr ( $::HDR_ENCL ) {
		next unless $::headers[$hdr];
		print STDOUT 
		    ('\leavevmode\hangindent=2cm\hangafter=1', "\n");
		$tag = $::hdr_name[$hdr];
		$indent = '\makebox[2cm][l]{' . $tag . ':}';
		foreach $line ( split (/\n/, $::headers[$hdr])) {
		    print STDOUT
			($indent, &::tex_string ($line), '\par', "\n");
		    $indent = '\makebox[2cm][l]{}';
		}
		print STDOUT ('\par', "\n");
	    }
	    print STDOUT ('}', "\t\t", '% end of \xiipt', "\n");

	    print STDOUT
		('\vspace*{8cm}', "\n",
		 '{\footnotesize Copyright \copyright ', $year,
		 ' ', &::tex_string ($::headers[$::HDR_COMPANY]), '}', "\n",
		 '\end{titlepage}', "\n");
	}

	print STDOUT 
	    ("%\n% Page ::headers and footers\n%\n",
	     '\header{\strut}{\strut}', "\n",
	     '       {', &::tex_string ($title), '}',
	     '{\strut}', "\n",
	     '\footer{', &::tex_string ($::headers[$::HDR_DOCID]), '}',
	     '{\thepage}', "\n");

	if ( $::toc ) {
	    print STDOUT ('\tableofcontents{', &::nls($::TXT_TOC), '}',
			  "\n", '\newpage', "\n");
	}
    }

    else {
	print STDOUT 
	    ("%\n% Page ::headers and footers\n%\n",
	     '\header{\strut}{\strut}', "\n",
	     '       {', &::tex_string ($::headers[$::HDR_TITLE]), '}{\strut}', "\n",
	     '\footer{', &::tex_string ($::headers[$::HDR_FROM]),
	     '}{\thepage}', "\n");

	if ( $::toc ) {
	    print STDOUT ('\tableofcontents{', &::nls($::TXT_TOC), '}',
			  "\n", '\newpage', "\n");
	}
    }

    print STDOUT ("\n");
}

# TEX trailer.

sub tex_trailer {

    &tex_closing if $::document_type == $::DTP_LETTER;
    &tex_emitn ("\n", '\printindex') if $index;
    &tex_emitn ("\n", '\end{document}');
}

sub tex_closing {
    local (*::headers) = *saved_::headers;
    print STDOUT ('\closing{');
    @lines = split (/\s*\n\s*/, $::headers[$::HDR_CLOSING]);
    while ( $#lines >= 0 ) {
	print STDOUT (&::tex_string(shift(@lines)), 
		      $#lines >= 0 ? '\\\\' : '}', "\n");
    }
    foreach $hdr ( $::HDR_ENCL, $::HDR_CC ) {
	next unless $::headers[$hdr];
	$tag = $::hdr_name[$hdr];
	@lines = split (/\s*\n\s*/, $::headers[$hdr]);
	if ( $hdr == $::HDR_ENCL && $#lines > 0 ) {
	    $tag =~ s/(Bijlage)$/${1}n/;
	    $tag =~ s/(Enclosure)$/${1}s/;
	}
	print STDOUT ('\cc[', $tag, ':]{', "\n");
	while ( $#lines >= 0 ) {
	    print STDOUT (&::tex_string(shift(@lines)),
			  $#lines >= 0 ? '\\\\': '}', "\n");
	}
    }
    &tex_emitn ('\end{letter}');
}

print STDERR ("Loading plugin: $my_name $my_version\n") if $::verbose;

1;
