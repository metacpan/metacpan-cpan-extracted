package MMDS::Output::Html;

# RCS Info        : $Id: Html.pm,v 1.6 2003-01-09 23:10:14+01 jv Exp $
# Author          : Johan Vromans
# Created On      : Mon Nov 25 20:52:24 2002
# Last Modified By: Johan Vromans
# Last Modified On: Thu Jan  9 23:01:17 2003
# Update Count    : 26
# Status          : Unknown, Use with caution!
# Based On        : gen_html 1.10

use strict;

my $RCS_Id = '$Id: Html.pm,v 1.6 2003-01-09 23:10:14+01 jv Exp $ ';
my $my_name = __PACKAGE__;
my ($my_version) = $RCS_Id =~ /: .+.pm,v ([\d.]+)/;
$my_version .= '*' if length('$Locker:  $ ') > 12;

# Encoding.
my %enctabs = ( "iso-8859-1"  => "Latin1",
		"iso-8859-15" => "Latin9",
	      );

### CONFIG: Can GhostScript produce GIF?
my $gs_gif	   = 0;

sub new {
    return bless {};
}

sub id_type {
    return "html";
}

sub id_tag {
    return "HTML";
}

no strict;

sub emit_header {
    shift;
    local ($depth, $text) = @_;
    local ($prev_depth) = scalar(@header_numbers);

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
	$depth = 5 if $depth > 5;
	# clear all levels above this one
	pop (@header_numbers) while $#header_numbers >= $depth;
	$header_numbers[$depth-1]++;	# increment current level
    }
    $tag = join(".",@header_numbers); # build tag
    $tag .= "." unless $depth > 1; # easteticly pleasing

    if ( $depth < 0 ) {
	$depth = 1;
    }
    $indent = $def_indent;
    $par_pending++;
    &flush;
    while ( $previous >= $::ENUM1 ) {
	&html_emitn ('</', pop(@current_enum), '>');
	$previous--;
    }
    $style = $::STANDARD;
    if ( $depth <= 3 ) {
	local ($stag) = $tag;
	$stag =~ s/\.$//;
	&html_emitn ("<h$depth>",
		     &html_string($text),
		     "</h$depth>");
    }
    elsif ( $depth == 4 ) {
	&html_pair ("em", &html_string($text));
	&html_par;
    }
    elsif ( $depth == 5 ) {
	&html_pair ("strong", &html_string($text));
	&html_par;
    }
    else {
	&html_emit (&html_string($text));
	&html_par;
    }
}

sub emit_enum {
    shift;
    local ($depth, $tag, $text, $para) = @_;
    local ($type);

    # Start an enumeration
    $depth--;
    $depth = 1 if $depth > 1;
    $type = $tag == $::LEADER_NUM ? 'ol' : 'ul';

    if ( $previous == $::STANDARD || $previous == $::ENUM1 && $depth == 1 ) {
	&html_par;
	&html_emitn ('<' . $type, '>');
	push(@current_enum, $type);
    }
    elsif ( $previous == $::ENUM1 + $depth ) {
    }
    elsif ( $previous == $::ENUM2 && $depth == 0 ) {
	&html_par;
	&html_emitn ('</' . pop(@current_enum), '>');
	push(@current_enum, $type);
    }

    $par_pending++ if $para;
    &flush;
    $indent = $def_indent . (' ' x (3 * ($depth+1)));
    &html_emit ('<li>') if $tag;
    &html_text ($indent, $text);
    $previous = $::ENUM1 + $depth;
    $par_pending++ if $para;
}

sub emit_para {
    shift;
    local ($style, $text) = @_;

    while ( $previous >= $::ENUM1 ) {
	&html_emitn ('</', pop(@current_enum), '>');
	$previous--;
    }
    $style = $::STANDARD;

    $par_pending++;
    &flush;

    $indent = $def_indent;
    &html_text ($indent, "$text");
    &html_par;
    $previous = $style;
}

sub emit_tabular {
    shift;
    local (@lines) = split (/\t/, @_[0]);

    if ( $lines[0] =~ /^\s*\[(literal|screen)(\s+(small|large|tiny))?\]\s*$/i ) {
	shift (@lines);
	&html_emit ("\n", '<pre>', "\n");
	local ($defmargin) = 999;
	foreach $line ( @lines ) {
	    $line =~ tr/\320\336\325/"''/;	#"/;
	    # Prevent leading space from being absorbed
	    $line =~ s/^ /\240/;
	    &html_emit ((" " x ($def_indent+2)),
			&html_string_noatt ($line), "\n");
	}
	&html_emitn ('</pre>');
	return;
    }

    if ( $lines[0] =~ /^\s*\[emphasis\]\s*$/i ) {
	shift (@lines);
	&html_emit ("\n");
	&html_emit ('<em>');
	&html_text ($indent, join(" ",@lines));
	&html_emit ('</em>');
	return;
    }

    if ( $lines[0] =~ /^\s*\[strong\]\s*$/i ) {
	shift (@lines);
	&html_emit ("\n");
	&html_emit ('<strong>');
	&html_text ($indent, join(" ",@lines));
	&html_emit ('</strong>');
	return;
    }

    if ( $lines[0] =~ /^\s*\[\[epsf\s+(\S+)\s*(\S.*)?\]\]\s*$/i ) {
	local ($eps_file, $title) = ($1, $2);
	local ($ps_file, $gif_file, $tmp1, $tmp2);
	($ps_file = $eps_file) =~ s/\.eps$/.ps/;
	($gif_file = $eps_file) =~ s/\.eps$/.gif/;
	$tmp1 = $::TMPDIR . "/cv$$.1";
	$tmp2 = $::TMPDIR . "/cv$$.2";

	local (*EPS, *PS, *TMP);

	# Open and read the EPS file, copying on the fly to the PS file.
	if ( open (EPS, $eps_file ) ) {
	    open (PS, ">$ps_file")
		&& $::verbose && print STDERR ("Creating $ps_file\n");
	    open (TMP, ">$tmp1");
	    local ($done, $width, $height) = 0;
	    local ($res) = 83;
	    while ( <EPS> ) {
		# Strip CR/LF or NL.
		s/[ \r\n]+$//;
		# Copy.
		print PS ("$_\n");
		# Find bounding box.
		if ( !$done && /%%BoundingBox: (.+)\s+(.+)\s+(.+)\s+(.+)/ ) {
		    # Translate coordinates to zero origin.
		    print TMP ("%!PS\n", -$1, " ", -$2, " translate\n");
		    # Calculate width.
		    $width = $3 - $1;
		    $height = $4 - $2;
		    $width *= $res/72;
		    $height *= $res/72;
		    $width = int ($width + 0.5) + 1;
		    $height = int ($height + 0.5) + 1;
		    $done++;
		}
		next if /^%/;
		print TMP ($_, "\n");
	    }
	    print TMP ("showpage\nquit\n");
	    close (TMP);
	    close (PS);
	    close (EPS);
	    print STDERR ("Creating $gif_file\n") if $::verbose;
	    if ( $gs_gif ) {
		# GhostScript has a GIF driver built-in.
		&system ("gs -q -sDEVICE=gif8 -dNOPAUSE -sOutputFile=$gif_file ".
			 "-r$res -g${width}x$height $tmp1");
	    }
	    else {
		# Otherwise we'll convert to PPM and use some of
		# the PBM converters.
		&system ("gs -q -sDEVICE=ppm -dNOPAUSE -sOutputFile=$tmp2 ".
			 "-r$res -g${width}x$height $tmp1");
		&system ("pnmcrop $tmp2 | ppmtogif > $gif_file");
	    }
	    unlink ($tmp1, $tmp2);

	    if ( $title ne '' ) {
		&html_emitn ("<a href=\"$ps_file\">", 
			     "<img src=\"$gif_file\"><br>\n",
			     &html_string($title), "</a>");
	    }
	    else {
		&html_emitn ("<a href=\"$ps_file\">", 
			     "<img src=\"$gif_file\"></a>");
	    }
	}
	else {
	    &::warn ("Cannot find $eps_file, skipping");
	}

        return;
    }

    # Inline data

    if ( $lines[0] =~ /^\[inline\s+(\S+)\s*(\S.+)?\s*\]$/i ) {
	shift (@lines);
	&inline_data ($1, $2);
	return;
    }

    if ( $lines[0] =~ /^\s*\[\[(tex).*\]\]\s*$/i ) {
	foreach $line ( @lines ) {
            &html_comment (&html_string ($line));
        }
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
	push (@ctl, $&);
	$ctl = $';
    }
    $ctl[$#ctl] .= $ctl;
    print STDERR ":", join (":", @ctl), ":\n" if $::debug;

    $col = 0;
    while ( $#ctl >= 0 ) {
	$c = shift (@ctl);
	if ( $c =~ /^r/i) { $just[$col] = "r"; }
	elsif ( $c =~ /^c/i ) { $just[$col] = "c"; }
	elsif ( $c =~ /^f/i ) { $just[$col] = "f"; }
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
    &html_emit ("\n");


    # Handle a couple of common cases.
    # Case 1: [   ] -> just lines.
    if ( $#width == 0 && $just[0] eq 'l' ) {
	while ( $#lines >= 0 ) {
	    &html_emit (&html_string (shift (@lines)));
	    &html_break;
	}
	return;
    }

    # Case 2: [   l   ] with emtpty left column -> just indenting.
    # Case 3: [   l   ] with emtpty or dashed left column -> itemize.
    # Case 4: [   f   ] with emtpty or dashed left column -> itemize.
    if ( $#width == 1 && ($just[$#width] eq 'l' || $just[$#width] eq 'f') ) {
	local ($all_blank) = 1;
	local ($all_dash) = 1;
	foreach ( @lines ) {
	    @cols = /^$pat$/;
	    if ( $cols[0] =~ /^[\s\240]+$/ ) {
		$all_dash = 0;
		next;
	    }
	    if ( $cols[0] =~ /^\s*--+\s*$/ ) {
		$all_blank = 0;
		next;
	    }
	    $all_blank = $all_dash = -1;
	    last;
	}

	if ( $all_blank > 0 ) {
	    &html_emitn ('<blockquote>');
	    while ( $#lines >= 0 ) {
		@cols = shift(@lines) =~ /^$pat$/;
		if ( $just[$#width] eq 'l' ) {
		    &html_emit (&html_string (pop(@cols)));
		    &html_break;
		}
		else {
		    &html_emitn (&html_string (pop(@cols)));
		}
	    }
	    &html_emitn ('</blockquote>');
	    return;
	}
	elsif ( $all_dash >= 0 ) {
	    &html_emitn ('<ul>');
	    push(@current_enum, 'ul');
	    while ( $#lines >= 0 ) {
		@cols = shift(@lines) =~ /^$pat$/;
		&html_emit ('<li>') unless $cols[0] =~ /^[ \240]+$/;
		if ( $just[1] eq 'l' ) {
		    &html_emit (&html_string (pop(@cols)));
		    &html_break;
		}
		else {
		    &html_emitn (&html_string (pop(@cols)));
		}
	    }
	    &html_emitn ('</', pop(@current_enum), '>');
	    return;
	}
    }

    # Case 5: [   l   ] with other left column -> description list.
    # Case 6: [   f   ] with other left column -> description list.
    if ( $#width == 1 && ($just[$#width] eq 'l' || $just[$#width] eq 'f') ) {
	&html_emitn ('<dl>');
	while ( $#lines >= 0 ) {
	    @cols = shift(@lines) =~ /^$pat$/;
	    if ( $cols[0] =~ /\S/ ) {
		&html_emit ('<dt>');
		&html_emitn (&html_string ($cols[0]));
		&html_emit ('<dd>');
	    }
	    elsif ( $just[$#width] eq 'l' ) {
		&html_emit ('<br>');
	    }
	    &html_emitn (&html_string ($cols[1]));
	}
	&html_emitn ('</dl>');
	return;
    }

    &html_emitn ('<pre>');
    local ($defmargin) = 999;
    while ( $#lines >= 0 ) {
	&html_emit (" " x $indent);
	@cols = shift(@lines) =~ /^$pat$/;
	for ( $c = 0; $c <= $#cols; $c++ ) {
	    $col = $cols[$c];
	    $col =~ s/^\s+//;
	    $col =~ s/\s+$//;
	    if ( $just[$c] eq "l" ) {
		&html_emit (&html_string_noatt($col));
		&html_emit (" " x ($width[$c]-length($col)));
	    }
	    elsif ( $just[$c] eq "r" ) {
		&html_emit (" " x ($width[$c]-length($col)-1));
		&html_emit (&html_string_noatt($col) . " ");
	    }
	    else {
		$fill = ($width[$c] - length($col)) / 2;
		&html_emit ((" " x $fill) . &html_string_noatt($col));
		&html_emit (" " x ($width[$c]-length($col)-$fill));
	    }
	}
	&html_emitn ('');
    }
    &html_emitn ('</pre>');
}

sub emit_tab_control {
    shift;
    local ($ctl) = shift (@_);

    if ( $ctl == $::TBCTL_INIT ) {
	local ($par) = shift(@_);
	&flush;
	return "cannot nest columns" if $tbl_control > 0;

	$tbl_control = 1;
	$tbl_row = $tbl_col = 1;
	$tbl_columns = $tbl_offset = 0;
	if ( $par =~ /\s+/ ) {
	    $ctl = $`;
	    $par = $';
	}
	else {
	    $ctl = $par;
	    $par = '';
	}
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
	    elsif ( $w =~ /^c/i ) {
		$w = $';
		$j = '|';
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

	foreach $w ( split (' ', $par) ) {
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
	if ( $retain_ctl ) {
	    &html_emit ((" " x $indent) . "[table $cmd]");
	}
        return "";
    }
    elsif ( $tbl_control == 0 ) {
	die ("Illegal call to tex_tabcontrol = ", $ctl, "\n");
    }

    if ( $ctl == $::TBCTL_COL ) {
	return "too many columns in this row"
	    if $tbl_col == $tbl_columns;
	if ( $retain_ctl ) {
	    &flush;
	    &html_emit ((" " x $indent) . "//");
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
	if ( $retain_ctl ) {
	    &flush;
	    &html_emit ((" " x $indent) . "[row]");
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
	if ( $retain_ctl ) {
	    &flush;
	    &html_par;
	    &html_emit ((" " x $def_indent) . "[end table]");
	    &html_par;
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
		$t0 = &html_string_noatt ($cols[$i]);
		$t0 =~ s/&[^;]+;/./g;
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

	&html_emitn ('<listing>');
	&html_emitn ('  +', '-' x $twidth, '+') if $tbl_box;
	foreach $line ( @lines ) {
	    if ( $line eq "_" ) {
		&html_emit ('  ');
		&html_emit ($tbl_box ? '+-' : ' ');
		for ( $i=0; $i <= $ncols; $i++ ) {
		    &html_emit ('-' x ($width[$i]));
		    &html_emit ($tbl_box ? '-+-' : '--') if $i < $ncols;
		}
		&html_emit ('-+') if $tbl_box;
		&html_emitn ('');
		next;
	    }
	    @cols = split (/$tbl_tab/, $line);
	    $cols[$ncols] .= '';
	    &html_emit ('  ');
	    for ( $i=0; $i <= $ncols; $i++ ) {
		&html_emit ($tbl_box ? '| ' : ' ');
		$t0 = &html_string_noatt ($cols[$i]);
		$t0 =~ s/^\s+//;
		$t0 =~ s/\s+$//;
		($t1 = $t0) =~ s/&[^;]+;/./g;
		$w0 = length ($t1);
		if ( $just[$i] eq 'l' ) {
		    &html_emit ($t0, ' ' x ($width[$i] - $w0));
		}
		elsif ( $just[$i] eq 'r' ) {
		    &html_emit (' ' x ($width[$i] - $w0), $t0);
		}
		else {
		    $w1 = int ($w0/2);
		    &html_emit (' ' x $w1, $t0, ' ' x ($width[$i] - $w1 - $w0));
		}
		&html_emit (' ');
	    }
	    &html_emit ('|') if $tbl_box;
	    &html_emitn ('');
	}
	&html_emitn ('  +', '-' x $twidth, '+') if $tbl_box;
	if ( $tbl_title ne '' ) {
	    &html_emitn ('') unless $tbl_box;
	    &html_emitn ('  ', &html_string ($tbl_title));
	}
	&html_emitn ('</listing>');

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

	if ( !$scr_expert ) {
	    &emit_html_tabular ("[screen small]\t" . join("\t", @lines));
	}
	elsif ( open (SCR, ">$scrfile") ) { 
	    foreach ( @lines ) {
		print SCR ($_, "\n");
	    }
	    close (SCR);
	    local ($cmd) = "scr2eps -quiet";
	    $cmd .= " -noborder" unless $scr_border;
	    $cmd .= " -grid" if $scr_grid;
	    $cmd .= " " . $scrfile;
	    &system ($cmd);
	    unlink ($scrfile);
	    $scrfile =~ s/\.scr$/.eps/;
	    &::feedbacka ('tempfiles', $scrfile);
	    &emit_html_tabular ("[[epsf $scrfile".
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
    shift;
    &emit_html_wrapup (0);
    &html_init;
}

sub init {
    shift;
    &html_init;
}

sub wrapup {
    shift;
    local ($fail) = @_;
    &html_emitn ('</body>');
    &html_emitn ('</html>');
    $fail;
}

################ private routines ################

sub html_init {

    # leader characters for enumerations. Keep in sync with
    # $::LEADER_... defines.
    @ENUM_TAGS = ("", "+", "a", "1", "*", "-");

    $defmargin = 72;
    $indent = $def_indent = 0;
    $par_pending = -1;		# suppress first
    my $dtbl = $enctabs{lc($::inputencoding)};
    ::loadpkg($dtbl."Html"); # e.g, Latin1Html

    $ENV{"PATH"} .= ':/usr/local/lib/pbmplus' unless $gs_gif;
    $A_NORMAL = 0;
    $A_BOLD = 1;
    $A_ITALIC = 2;
    $A_UNDERLINE = 4;
    $A_SMALLCAPS = 8;
    $A_TTY = 16;
    $A_FOOTNOTE = 32;
    $curattrib = $A_NORMAL;
    $a_ctl = "\252";		# ord feminine

    $tmp = localtime(time);

    &html_emitn ('<html>');
    &html_emitn ("<!-- HTML Generated by $my_name $my_version, $tmp -->");
    &html_emitn ('<head>');

    if ( $::headers[$::HDR_TITLE] ) {
	&html_emitn ('<title>', &html_string($::headers[$::HDR_TITLE]), 
		     '</title>');
    }
}

# Emit a string, guaranteed ascii.
sub html_emit	{ print STDOUT (@_); }
sub html_emitn	{ print STDOUT (@_, "\n"); }

# (End of) Paragraph.
sub html_par	{ print STDOUT ('<p>', "\n"); }
sub html_break	{ print STDOUT ('<br>', "\n"); }

# Text between HTML codes.
sub html_pair {
    local ($tag, $text) = @_;
    $tag = "\L$tag";
    $text =~ s/\s+$//;
    &html_emitn ("<$tag>$text</$tag>");
}

sub html_comment {
    local ($text) = @_;
    $text =~ s/\s+$//;
    &html_emitn ("<!-- $text -->");
}

sub html_text {
    local ($indent,$line) = @_;
    if ( $tbl_control && !$retain_ctl ) {
	$t = &html_string ($line);
	chop ($t);
	print STDERR ("R${tbl_row}C${tbl_col} .= \"",
		      substr($t, 0, 30), "\"\n") if $::debug;
	$tbl_text .= $t;
    }
    else {
	&html_emit (&html_string ($line));
    }
}

sub html_string_noatt {
    local ($line) = @_;
    $line = &html_string ($line);
    $line =~ s/<[^>]*>//g;
    $line;
}

sub html_string {
    local ($line) = @_;
    local ($chr, $prev, $tmp);
    local ($tally) = 0;
    local ($res) = "";
    local ($att) = $A_NORMAL;
    local (@astack) = ();


    # Squish pseudo-ISO characters.
    $line =~ tr/\320\336/"'/;	#"/;
    $line =~ s/\n/\n /g;

    while ( $line =~ /[ <>&#\200-\377]/ ) {
	
	$chr = $&;		# the special character
	$line = $';		# what comes after it
	$tmp = $`;		# what came before it
	$prev = (length ($`) > 0) ? 
		       substr($`,length($`)-1,1) :
		       substr($res,length($res)-1,1);
				# the character that came before

	if ( length($tmp) > 0 ) {
	    if ( $att & $A_SMALLCAPS ) {
		$res .= "\U$tmp";
	    }
	    else {
		$res .= $tmp;
	    }
	    $tally += length ($tmp);
	}

        if ( $tally > $defmargin && $chr eq ' ' ) {
	    $res .= "\n";
	    $tally = 0;
	}

	if ( $chr eq ' ' ) {
	    if ( $tally > 0 ) {
		$res .= ' ';
		$tally++;
	    }
	    next;
	}

	# Parse index entries. Not supported yet in HTML.
	if ( $chr eq '#' && !$noindex 
	     && $line =~ /^\[/ && (($tmp = index ($line, ']#', 1)) >= $[) ) {
	    $tag = substr ($line, 1, $tmp-1);
	    $tmp = substr ($line, $tmp+2);
	    $tag =~ s/::/\000/g;
	    $tag =~ s/:/!/g;
	    $tag =~ s/\000/:/g;
	    if ( $tag =~ /!/ ) {
		$tag =~ s/!+$//;
		$line = $tmp;
	    }
	    else {
		$line = $tag.$tmp;
	    }
	    if ( 0 && ($index || $makeindex) ) {
		$tmp = '\index{' . &tex_string ($tag) . '}';
		$res .= $tmp;
		$tally += length ($tmp);
	    }
	    next;
	}

	# Parse character attributes.
	if ( $chr eq $a_ctl && $line =~ /^([bifsut~]+)$a_ctl/o ) {
	    local ($new) = '';
	    local ($neg) = 0;

	    # Close current attibute scope.
	    while ( $tmp = pop (@astack) ) {
		$new .= '</' . $tmp . '>';
	    }

	    $line = $';
	    $tmp = $1;
	    foreach $a ( split (/(.)/, $tmp) ) {
		if ( $a eq '~' ) {
		    $neg = 2;
		}
		else {
		    $ca = 
			($a eq 'b') ? $A_BOLD :
			($a eq 'i') ? $A_ITALIC : 
			($a eq 'u') ? $A_UNDERLINE :
			($a eq 't') ? $A_TTY :
			($a eq 's') ? $A_SMALLCAPS :
			# ($a eq 'f') ? $A_FOOTNOTE :
			$A_NORMAL;
		    if ( $neg ) {
			$neg = 1;
			$att &= ~$ca;
		    }
		    else {
			$att |= $ca;
		    }
		}
	    }

	    # neg == 2 -> reset all
	    $att = $A_NORMAL if $neg == 2;

	    # Open new attribute scope.
	    if ( $att != $A_NORMAL ) {
		$new .= '<u>', push(@astack, 'u') if $att & $A_UNDERLINE;
		$new .= '<tt>', push(@astack, 'tt') if $att & $A_TTY;
		$new .= '<b>', push(@astack, 'b') if $att & $A_BOLD;
		$new .= '<i>', push(@astack, 'i') if $att & $A_ITALIC;
	    }

	    # Append to output.
	    if ( $new ne '' ) {
		$res .= $new;
		$tally += length ($new);
	    }
	    next;
	}

	# Special characters.
	if ( $chr eq "\240" ) {		# Non-breaking space
	    $chr = '&nbsp;';
	}
	elsif ( $chr eq '#' ) {
	    # It's okay...
	}
	elsif ( $chr ne ' ' ) {
	    # Mostly ISO characters, e.g. "\353" -> &eacute;
	    # The HTML exception characters, < > & are also handled here.
	    if ( defined ($tmp = $::iso2html{$chr}) ) {
		$res .= '&' . $tmp . ';';
		$tally += length ($tmp) + 2;
		next;
	    }
	    else {
		# ignore it
		&::warn (sprintf ('unknown ISO character \%o (ignored)', ord($chr)));
		next;
	    }
	}

	$res .= $chr;
	$tally += length ($chr);

    }

    # Close current attibute scope.
    while ( $tmp = pop (@astack) ) {
	$line .= '</' . $tmp . '>';
    }

    $res . $line;
}

sub flush {
    if ( $par_pending > 0 ) {
	if ( $tbl_control && !$retain_ctl  ) {
	    $tbl_text .= "\n" if $tbl_text;
	}
	else {
	    &html_par;
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

sub system {
    local ($cmd) = @_;
    print STDERR ("+ $cmd\n") if $::opt_trace;
    system ($cmd);
}

print STDERR ("Loading plugin: $my_name $my_version\n") if $::verbose;

1;
