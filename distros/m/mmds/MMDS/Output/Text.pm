package MMDS::Output::Text;

# RCS Info        : $Id: Text.pm,v 1.4 2003-01-09 22:19:00+01 jv Exp $
# Author          : Johan Vromans
# Created On      : Mon Nov 25 20:47:47 2002
# Last Modified By: Johan Vromans
# Last Modified On: Thu Jan  9 22:06:06 2003
# Update Count    : 18
# Status          : Unknown, Use with caution!
# Based On        : gen_lex.pl 2.18

use strict;

my $RCS_Id = '$Id: Text.pm,v 1.4 2003-01-09 22:19:00+01 jv Exp $ ';
my $my_name = __PACKAGE__;
my ($my_version) = $RCS_Id =~ /: .+.pm,v ([\d.]+)/;
$my_version .= '*' if length('$Locker:  $ ') > 12;

my $appendix	   = 0;

sub new {
    return bless {};
}

sub id_type {
    return "text";
}

sub id_tag {
    return "Text";
}

sub wrapup {
    my ($self, $fail) = @_;
    $fail;
}

sub init {
    shift;
    &text_init;
}

no strict;

sub emit_header {
    shift;
    local ($depth, $text, $tag) = @_;
    local ($unnumbered);
    $unnumbered = $tag =~ /^[0.]+$/;

    # Start a header. 
    # Note that @header_numbers and its element spring into
    # existence upon request.

    if ( $depth < 0 ) {
	$depth = 0;
	if ( !$appendix ) {
	    local ($current) = $header_numbers[0];
	    @header_numbers = ("A"); 		# appendix
	    if ( $current == $::chapnum-1 ) {	# not used yet
		while ( $::chapnum > 1 ) {	# apply
		    $header_numbers[0]++;
		    $::chapnum--;
		}
	    }
	    $appendix = 1;
	}
	else {
	    pop (@header_numbers) while $#header_numbers > 0;
	    $header_numbers[0]++;
	}
    }
    else {
	$depth--;			# make zero relative
	$depth = 4 if $depth > 4;

	if ( !$unnumbered ) {
	    # clear all levels above this one
	    pop (@header_numbers) while $#header_numbers > $depth;
	    $header_numbers[$depth]++;	# increment current level
	}
    }

    if ( $unnumbered ) {
	$tag = '' unless $::raw;
    }
    else {
	$tag = join(".",@header_numbers); # build tag
	$tag .= "." unless $depth > 0; # easteticly pleasing
    }

    $indent = $def_indent;

    $par_pending++;
    &flush;
    $text =~ tr/[a-z]/[A-Z]/ if $depth == 0 && !$::raw;
    &text_text ($tag, $indent, $text);
    if ( $depth < 2 ) {
	$par_pending = 1;
	$previous = $::HEADER1 + $depth;
    } else {
	$previous = $::STANDARD;
    }
}

sub emit_enum {
    shift;
    local ($depth, $tag, $text, $para) = @_;

    # Start an enumeration

    # Uncomment the next lines if this feature should be disabled.
    #   $para = 1;
    #   $tag = $::LEADER_DEFAULT;

    $depth = 2 if $depth > 2;

    $tag = $::LEADER_BULLET - 1 + $depth if $tag == $::LEADER_DEFAULT;
    $tag = $::ENUM_TAGS[$tag] unless $tag == $::LEADER_ALPH || $tag == $::LEADER_NUM;
    if ( $previous == $::ENUM1 + $depth - 1 ) {
	$par_pending++ if $para;
	$tag = ++$ctr[$depth] . "." 
	    if $tag == $::LEADER_ALPH || $tag == $::LEADER_NUM;
    }
    elsif ( $previous == $::ENUM2 && $depth == 1 ) {
	$par_pending++;
	$tag = ++$ctr[$depth] . "." 
	    if $tag == $::LEADER_ALPH || $tag == $::LEADER_NUM;
    }
    else {
	$par_pending++;
	$tag = ($ctr[$depth] = "a") . "." if $tag == $::LEADER_ALPH;
	$tag = ($ctr[$depth] = 1) . "." if $tag == $::LEADER_NUM;
    }

    &flush;
    $indent = $def_indent + 3 * $depth;
    $depth = 0 unless $tag;
    &text_text ((" " x ($indent-3)) . $tag,
	       $indent, $text);
    $previous = $::ENUM1 + $depth - 1;
    $par_pending++ if $para;
}

sub emit_para {
    shift;
    local ($style, $text) = @_;

    $style = $::STANDARD;

    $par_pending++;# if $previous == $style;	# emit par if needed
    &flush;

    $indent = $def_indent;
    &text_text ("", $indent, $text);
    $previous = $style;
}

sub emit_tabular {
    shift;
    local (@lines) = split (/\t/, @_[0]);

    if ( $gen_text || $::raw ) {
	if ( $gen_text ) {
	    # We should to do something more intelligent than this...
	    shift (@lines);
	}
	else {
	    push (@lines, "[end literal]") 
		if $lines[0] =~ /^\s*\[literal\b.*\]\s*$/i;
	    push (@lines, "[end screen]") 
		if $lines[0] =~ /^\s*\[screen\b.*\]\s*$/i;
	    push (@lines, "[end inline]") 
		if $lines[0] =~ /^\s*\[inline\b.*\]\s*$/i;
	}
	&text_emit ("\n");
	local ($indent) = $def_indent;
	$indent += 6 unless $::raw;
	foreach $line ( @lines ) {
	    &text_emit ((" " x $indent) . $line . "\n");
	}
	return;
    }

    if ( $lines[0] =~ /^\s*\[(literal|screen)\b.*\]\s*$/i ) {
	shift (@lines);
	&text_emit ("\n");
	foreach $line ( @lines ) {
	    $line =~ tr/\320\336\325/"''/;	#"/;
	    &text_emit ((" " x ($def_indent+6)) . $line . "\n");
	}	
	return;
    }

    if ( $lines[0] =~ /^\s*\[(emphasis|strong)\]\s*$/i ) {
	shift (@lines);
	&text_emit ("\n");
	&text_text ("", $indent, join(" ",@lines));
	return;
    }

    if ( $lines[0] =~ /^\s*\[\[(epsf|tex).*\]\]\s*$/i ) {
	foreach $line ( @lines ) {
            &text_emit ((" " x ($indent+6)) . $line . "\n");
        }
        return;
    }

    # Inline data

    if ( $lines[0] =~ /^\[inline\s+(\S+)\s*(\S.+)?\s*\]$/i ) {
	&text_emit ("\n");
	shift (@lines);
	&inline_data ($1, $2);
	return;
    }

    local ($ctl, $pat, $col, @width, @just);
    local (@ctl);

    # Something column like. Split
    $ctl = shift (@lines);
    print STDERR "=> \"$ctl\" -> " if $::debug;
    @ctl = ("");
    while ( $ctl =~ /[TLRCF]/i ) {
	$ctl[$#ctl] .= $`;
	push (@ctl, $+);
	$ctl = $';
    }
    $ctl[$#ctl] .= $ctl;
    print STDERR ":", join (":", @ctl), ":\n" if $::debug;

    $col = 0;
    while ( $#ctl >= 0 ) {
	$c = shift (@ctl);
	if ( $c =~ /^r/i) { $just[$col] = "r"; }
	elsif ( $c =~ /^c/i ) { $just[$col] = "c"; }
	else { $just[$col] = "l"; }
	if ( $#ctl >= 0 ) {
	    $pat .= "(.{0," . length($c) . "})";
	}
	else {
	    # last one - be liberate
	    $pat .= "(.*)";
	}
	$width[$col] = length ($c) + ($c =~ /^[rc]/);
	$col++;
    }
    $width[$#width] = 0 unless $just[$#just] =~ /[rc]/;

    if ( $::debug ) {
	for ( $c = 0; $c <= $#width; $c++ ) {
	    print STDERR "=> col $c, width = $width[$c], just = $just[$c]\n"
		if $::debug;
	}
    }
    &text_emit ("\n");

    while ( $#lines >= 0 ) {
	&text_emit (" " x $indent);
	@cols = shift(@lines) =~ /^$pat$/;
	for ( $c = 0; $c <= $#cols; $c++ ) {
	    $col = $cols[$c];
	    $col =~ s/^\s+//;
	    $col =~ s/\s+$//;
	    if ( $just[$c] eq "l" ) {
		&text_emit ($col);
		&text_emit (" " x ($width[$c]-length($col)));
	    }
	    elsif ( $just[$c] eq "r" ) {
		&text_emit (" " x ($width[$c]-length($col)-1));
		&text_emit ($col . " ");
	    }
	    else {
		$fill = ($width[$c] - length($col)) / 2;
		&text_emit ((" " x $fill) . $col);
		&text_emit (" " x ($width[$c]-length($col)-$fill));
	    }
	}
	&text_emit ("\n");
    }
}

sub emit_newdocument {
    shift;
    print STDOUT "\f";
    &text_init;
}

sub emit_tab_control {
    shift;
    local ($ctl) = shift (@_);

    if ( $ctl == $::TBCTL_INIT ) {
	local ($cmd) = "@_";
	local (@par) = split (/\s+/, shift(@_));
	&flush;
	return "cannot nest columns" if $tbl_control > 0;

	$tbl_control = 1;
	$tbl_row = $tbl_col = 1;
	$tbl_columns = $tbl_offset = 0;
	$ctl = shift (@par);
	$unk = 0;
	$length = 0;
	$col = 0;
	@tbl_width = ();
	@tbl_just = ();
	foreach $w ( split (/,/, $ctl) ) {
	    $j = '<';
	    if ( $w =~ /^l/i ) {
		$w = $';
	    }
	    elsif ( $w =~ /^r/i ) {
		$w = $';
		$j = '>';
	    }
	    elsif ( $w =~ /^f/i ) {
		$w = $';
	    }
	    push (@tbl_just, $j);
	    if ( $w =~ /^(\d+)\.(\d)(cm|mm)$/ ) {
		push (@tbl_width, $len = ($1 + $2/10) * ($3 eq "cm" ? 10 : 1));
		$length += $len;
	    }
	    elsif ( $w =~ /^(\d+)(cm|mm)$/ ) {
		push (@tbl_width, $len = $1 * ($2 eq "cm" ? 10 : 1));
		$length += $len;
	    }
	    elsif ( $w eq "*" ) {
		push (@tbl_width, 0);
		$unk++;
	    }
	    else {
		return "illegal width specification";
	    }
	    $tbl_width[$#tbl_width] /= 1.6;	# assume 6 chars / cm
	}

	foreach $w ( @par ) {
	    if ( $w =~ /^type=(\d)$/ ) {
		$tbl_control = 1+$1;
	    }
	    elsif ( $w =~ /^offset=(\d+)\.(\d)(cm|mm)$/ ) {
		$tbl_offset = ($1 + $2/10) * ($3 eq "cm" ? 10 : 1);
	    }
	    elsif ( $w =~ /^offset=(\d+)(cm|mm)$/ ) {
		$tbl_offset = $1 * ($2 eq "cm" ? 10 : 1);
	    }
	    else {
		return "illegal column option \"$w\"";
	    }
	}
	$tbl_columns = @tbl_width;
	$tbl_offset /= 2.5;

	print STDERR "width = @tbl_width, length = $length, unk = $unk\n"
	    if $::debug;

	$remw = ($defmargin - $def_indent - $length/2.5 - $tbl_offset) / $unk
	    if $unk > 0;
	print STDERR "remw = $remw, offset = $tbl_offset\n" if $::debug;
	$tbl_offset /= 2 if $tbl_offset;

	$tbl_format = "format tbl_format =\n~~" . (" " x ($indent + $tbl_offset-2));
	for $w ( @tbl_width ) {
	    $j = shift (@tbl_just);
	    $tbl_format .= "\^" . ($j x (($w ? $w : $remw)-1));
	    $tbl_format .= " " if $j eq '>';
	}
	$tbl_format .= "\n";
	for $w ( 1..@tbl_width ) {
	    $tbl_format .= "\$tbl_col" . $w . ",";
	}
	chop ($tbl_format);
	$tbl_format .= "\n.\n";
	eval ($tbl_format);
	select (STDOUT);
	$~ = "tbl_format";
	$tbl_col1 = $tbl_text = "";
	$tbl_col = 1;
	if ( $::raw ) {
	    &text_emit ((" " x $indent) . "[table $cmd]");
	}
        return "";
    }
    elsif ( $tbl_control == 0 ) {
	die ("Illegal call to tex_tabcontrol = ", $ctl, "\n");
    }

    if ( $ctl == $::TBCTL_COL ) {
	return "too many columns in this row"
	    if $tbl_col == $tbl_columns;
	if ( $::raw ) {
	    &flush;
	    &text_emit ((" " x $indent) . "//");
	    $tbl_col++;
	    return;
	}
	eval ('$tbl_col' . $tbl_col . ' .= $tbl_text');
	$tbl_col++;
	eval ('$tbl_col' . $tbl_col . ' .= ""');
	$tbl_text = "";
    }

    elsif ( $ctl == $::TBCTL_ROW ) {
	return "not enough columns in this row"
	    unless $tbl_col == $tbl_columns;
	if ( $::raw ) {
	    &flush;
	    &text_emit ((" " x $indent) . "[row]");
	    $tbl_row++;
	    $tbl_col = 1;
	    return;
	}
	eval ('$tbl_col' . $tbl_col . ' .= $tbl_text');
	write (STDOUT);
	$tbl_row++;
	$tbl_col = 1;
	$tbl_col1 = $tbl_text = "";
    }

    elsif ( $ctl == $::TBCTL_END ) {
	return "unexpected [end columns]" unless $tbl_control > 0;
	return "not enough columns in this row"
	    unless $tbl_col == $tbl_columns;
	if ( $::raw ) {
	    &flush;
	    &text_par;
	    &text_emit ((" " x $def_indent) . "[end table]");
	    &text_par;
	    $tbl_control = 0;
	    return;
	}
	eval ('$tbl_col' . $tbl_col . ' .= $tbl_text');
	write;
	$tbl_columns = 0;
	$tbl_control = 0;
    }

    else {
	die ("Illegal param to tex_tabcontrol = ", $ctl, "\n");
    }
    "";
}

################ private routines ################

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

	# Cannot handle expand yet....
	$tbl_expand = 0;

	# Next line should designate columns and alignment.

	&::err ("Inline tbl error: 2nd line: $line")
	    unless ($line) =~ /^[lrcn ]+\.$/;
	chop ($line);
	$line =~ s/n/r/g;
	local (@just) = split (' ', $line);
	local ($ncols) = $#just;

	local (@width);
	local ($t0, $t1, $w0, $w1);
	$tbl_tab =~ s/(\W)/\\\1/g;

	# Pre-scan for widths.
	foreach ( @lines ) {
	    @cols = split (/$tbl_tab/, $_);
	    for ($i = 0; $i < @cols; $i++) {
		$t0 = &text_string_noatt ($cols[$i]);
		$t0 =~ s/^\s+//;
		$t0 =~ s/\s+$//;
		$w0 = length ($t0);
		if ( $width[$i] < $w0 ) {
		    $width[$i] = $w0;
		}
	    }
	}

	local ($twidth) = 0;
	foreach ( @width ) {
	    $twidth += $_;
	}
	$twidth += @width * ($tbl_box ? 3 : 2) - 1;

	&text_emitn (' ' x ($indent+2), '+', '-' x $twidth, '+') if $tbl_box;
	foreach $line ( @lines ) {
	    if ( $line eq "_" ) {
		&text_emit (' ' x ($indent+2));
		&text_emit ($tbl_box ? '+-' : ' ');
		for ( $i=0; $i <= $ncols; $i++ ) {
		    &text_emit ('-' x ($width[$i]));
		    &text_emit ($tbl_box ? '-+-' : '--') if $i < $ncols;
		}
		&text_emit ('-+') if $tbl_box;
		&text_emitn ('');
		next;
	    }
	    @cols = split (/$tbl_tab/, $line);
	    $cols[$ncols] .= '';
	    &text_emit (' ' x ($indent+2));
	    for ( $i=0; $i <= $ncols; $i++ ) {
		&text_emit ($tbl_box ? '| ' : ' ');
		$t0 = &text_string_noatt ($cols[$i]);
		$t0 =~ s/^\s+//;
		$t0 =~ s/\s+$//;
		$w0 = length ($t0);
		if ( $just[$i] eq 'l' ) {
		    &text_emit ($t0, ' ' x ($width[$i] - $w0));
		}
		elsif ( $just[$i] eq 'r' ) {
		    &text_emit (' ' x ($width[$i] - $w0), $t0);
		}
		else {
		    $w1 = int ($w0/2);
		    &text_emit (' ' x $w1, $t0, ' ' x ($width[$i] - $w1 - $w0));
		}
		&text_emit (' ');
	    }
	    &text_emit ('|') if $tbl_box;
	    &text_emitn ('');
	}
	&text_emitn (' ' x ($indent+2), '+', '-' x $twidth, '+') if $tbl_box;
	if ( $tbl_title ne '' ) {
	    &text_emitn ('') unless $tbl_box;
	    &text_emitn (' ' x ($indent+2), &text_string ($tbl_title));
	}
	&text_emitn ('');

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
		&::warn ("Cannot handle inline expert screen");
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
	&emit_text_tabular ("[screen small]\t" . join("\t", @lines));
    }
    else {
	&::err ("Unknown inline code: \"$ctl\"");
    }
}

sub text_init {

    # leader characters for enumerations. Keep in sync with
    # $::LEADER_... defines.
    @ENUM_TAGS = ("", "+", "a", "1", "*", "-");

    $defmargin = 72;
    $indent = $def_indent = 6;
    $par_pending = -1;		# suppress first

    unless ( $::raw ) {
	if ( $::headers[$::HDR_PHONE] && $::headers[$::HDR_FROM] ) {
	    $::headers[$::HDR_FROM] .= " " . $::headers[$::HDR_PHONE];
	    undef $::headers[$::HDR_PHONE];
	}
    }

    foreach $hdr ( 0..$#::hdr_name ) {
	next unless vec ($::dtp_allow[$::document_type], $hdr, 1);
	next unless vec ($::hdr_set, $hdr, 1);
	next unless $::headers[$hdr];
	if ( $hdr == $::HDR_DOCUMENTSTYLE ) {
	    # Strip the default indicator inserted by mmdscvt.
	    $::headers[$hdr] =~ s/^-\s+//;
	}
	&text_text ($::hdr_name[$hdr] . ":", 12, $::headers[$hdr]);
    }
    &text_emit (("-" x 40) . "\n\n");
    &text_emit ("......F" . ("." x 73) . "\n") if $gen_text;

    @header_numbers = ( $::chapnum-1 ) if $::chapnum > 1;
}

# Emit a string, guaranteed ascii.

sub text_emit	{ print STDOUT @_; }
sub text_emitn	{ print STDOUT @_, "\n"; }

# ATF para

sub text_par	{ print STDOUT "\n"; }

# Text string.

sub text_text {
    local ($tag,$indent,$line) = @_;
    if ( $tbl_control && !$::raw ) {
	$t = &text_string ($tag,$indent-$def_indent,$line);
	chop ($t);
	print STDERR "R${tbl_row}C${tbl_col} .= \"",
	substr($t, 0, 30), "\"\n" if $::debug;
	$tbl_text .= $t;
    }
    else {
	&text_emit (&text_string ($tag,$indent,$line));
    }
}

sub text_string {
    local ($tag,$indent,$line) = @_;
    local ($chr, $tally, $tmp, $res);
    $tally = 0;
    $res = "";

    if ( $tag ) {
	$res = $tag;
	$tmp = $tally = length ($tag);
	do { $res .= " "; } while ++$tmp < $indent;
	$tally = $tmp;
    }
    else {
	$res = " " x $indent;
	$tally = $indent;
    }

    # Squish pseudo-ISO characters.
    $line =~ tr/\320\336/"'/;	#"/;
    $line =~ s/\n/\n /g;
    @words = split (/[ 	]+/, $line);

    while ( $#words >= 0 ) {
	$tmp = shift (@words);
	$tmp =~ tr/\240/ / unless $::raw;
	if ( $tally + length ($tmp) > $defmargin ) {
	    $res .= "\n" . (" " x $indent);
	    $tally = $indent;
	}
	if ( $tmp =~ /\n$/ ) {
	    $res .= $tmp . (" " x $indent);
	    $tally = $indent;
	}
	else {
	    $res .= $tmp . " ";
	    $tally += length($tmp) + 1;
	}
    }

    $res .= "\n" if $tally > 0;
    $res;
}

sub text_string_noatt {
    &text_string ('',0,@_[0]);
}

sub flush {
    if ( $par_pending > 0 ) {
	if ( $tbl_control && !$::raw  ) {
	    $tbl_text .= "\n" if $tbl_text;
	}
	else {
	    &text_par;
	}
    }
    $par_pending = 0;
}

sub eval {
    local (@e) = @_;
    print STDERR @e, "\n" if $::debug;
    eval @e;
    print STDERR "-> $@\n" if $@;
    print STDERR "[", $tbl_text, "]\n" if $::debug;
}

print STDERR ("Loading plugin: $my_name $my_version\n") if $::verbose;

1;
