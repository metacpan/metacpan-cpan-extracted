#!/usr/bin/Perl
# derived from Synopsis example in KnuthPlass.pm
# REQUIRES PDF::Builder and Text::Hyphen
# TBD: command-line selection of line width, which text to format, perhaps
#        choice of font and font size
#      see Flatland.pl for more items to consider
#      several different "flavors" of triangles: isoceles, right with left
#        vertical, right with right vertical, rights with flipped base,
#        skewed triangle, even rotated triangle!
#      copy and adjust line lengths and positions for circular, etc. examples
#      see Flatland.pl for $ldquo etc. usage for ' and "
use strict;
use warnings;
use utf8;
use PDF::Builder;
use Text::KnuthPlass;
use POSIX qw/ceil floor/;
use List::Util qw/max/;

# flag to replace fancy punctuation by ASCII characters
my $use_ASCII = 1;
# force use of pure Perl code
my $purePerl = 1; # 0: use XS, 1: use Perl  DOESN'T WORK

my $textChoice = 1;  # see getPara() at bottom, for choices of sample text
my $outfile = 'T_Triangle';
my $const = 0; # subtract from lineWidth to allow room for added hyphen
               # 0 for proportional font, 1 for text file, pts for const. width
	       # IGNORED for now, needs fixing
my $line_dump = 0;  # debug related
my $do_margin_lines = 1; # debug... do not change, N/A

my $font_scale = 1.7; # adjust to fill circle example
my $radius = 26; # radius of filled circle

my $vmargin = 2; # top and bottom margins
my $xleft = 5;  # left (and right) margin
my @pageDim = (0,0, 80,66);

my $raggedRight = 0; # 0 = flush right, 1 = ragged right
my $indentAmount = 0; # ems to indent first line of paragraph. - outdents
#                       upper left corner of paragraph MUST BE 0
my $split_hyphen = '-';

my $pdf = PDF::Builder->new('compress' => 'none');
#my $lineWidth = 400; # Points. get different wrapping effects by varying
my $lineWidth = $pageDim[2]-2*$xleft; # Points, left margin = right margin
my ($page, $ytop);
open $page, ">", "$outfile.txt" or die "unable to open output file";
my $start = 1; # empty file at this point
my $end   = 0; # special call to fresh_page to finish out bottom

# as with PDF, 0,0 is bottom left corner
my $pageTop = $pageDim[3]-$vmargin; # each page starts here...
my $ybot = $vmargin;                # and ends here

    # various HTML entities (so to speak)
    # flag to replace by ASCII characters

    my $mdash = "\x{2014}"; # --
    my $lsquo = "\x{2018}"; # '
    my $rsquo = "\x{2019}"; # '
    my $ldquo = "\x{201C}"; # "
    my $rdquo = "\x{201D}"; # "
    my $sect  = "\x{A7}";   # sect
    my $oelig = "\x{153}";  # oe ligature
    if ($use_ASCII) {
	$mdash = '--';
	$lsquo = $rsquo = '\'';
	$ldquo = $rdquo = '"';
	$sect  = 'sect';
	$oelig = 'oe ligature';
    }

my ($w, $t, $paragraph, @lines, $indent, $end_y);
my ($x, $y, $vertical_size);

fresh_page();

# create Knuth-Plass object, build line set with it
$t = Text::KnuthPlass->new(
    'measure' => sub { length(shift) }, 
    'linelengths' => [ $lineWidth ],  # dummy placeholder
    'space' => { 'width' => 3, 'stretch' => 6, 'shrink' => 0 },
    'indent' => 0,
);

# ---------- actual page content
my $widthHyphen = 1;

# ------------- 1
# right triangle, straight vertical side at left
my @list_LL = (
	    # too narrow a line seems to cause problems
#	            $lineWidth*0.05, $lineWidth*0.10,
                    $lineWidth*0.15, $lineWidth*0.20,
                    $lineWidth*0.25, $lineWidth*0.30,
                    $lineWidth*0.35, $lineWidth*0.40,
                    $lineWidth*0.45, $lineWidth*0.50,
                    $lineWidth*0.55, $lineWidth*0.60,
                    $lineWidth*0.65, $lineWidth*0.70,
                    $lineWidth*0.75, $lineWidth*0.80,
                    $lineWidth*0.85, $lineWidth*0.90,
                    $lineWidth*0.95, $lineWidth*1.00,
	      );

$paragraph = getPara(1);

$t->line_lengths(@list_LL);
@lines = $t->typeset($paragraph);
    dump_lines(@lines) if $line_dump;
    # output @lines to PDF, starting at $xleft, $ytop
    $end_y = write_paragraph('L', @lines);

# skip 2 lines
text(" "); text("  ");

# ------------- 2
# isoceles triangle, use text_center()
$paragraph = getPara(2);

$t->line_lengths(@list_LL);
@lines = $t->typeset($paragraph, 'linelengths' => \@list_LL);
    dump_lines(@lines) if $line_dump;
    # output @lines to PDF, starting at $xleft, $ytop
    $end_y = write_paragraph('C', @lines);

# skip 2 lines
text(" "); text(" ");

# ------------- 3
# right triangle with vertical at right margin, use text_right()
$paragraph = getPara(3);

$t->line_lengths(@list_LL);
@lines = $t->typeset($paragraph);
    dump_lines(@lines) if $line_dump;
    # output @lines to PDF, starting at $xleft, $ytop
    $end_y = write_paragraph('R', @lines);

# skip 2 lines
text(" "); text(" ");

# ------------- 4
# filled circle, can't adjust font_size to fill as much as possible
# (reduce radius instead)
$paragraph = getPara(1);

# xc,yc at xleft+.5*lineWidth (need minimum 2*radius height available)
if (2*$radius > $lineWidth) { $radius = round($lineWidth/2); }
# if ($ytop - 2*$radius < $ybot) { fresh_page(); }

my $baseline_delta = 1;

# figure set of line lengths, plus extra full width for overflow
# text is centered at xc.
my ($delta_x, @circle_LL);
for (my $circle_y = $ytop-$baseline_delta; 
	$circle_y > $ytop-2*$radius; 
	$circle_y -= $baseline_delta) {
    $delta_x = round(sqrt($radius**2 - ($circle_y-$ytop+$radius)**2));
    push @circle_LL, 2*$delta_x;
}
push @circle_LL, $lineWidth*0.8;  # for overflow from circle

$t->line_lengths(@circle_LL);
@lines = $t->typeset($paragraph);
    dump_lines(@lines) if $line_dump;
    # output @lines to PDF, starting at $xleft, $ytop
    $end_y = write_paragraph('C', @lines);

# skip 2 lines
text(" "); text(" ");

# ------------- 5
# rectangle with two circular cutouts
$paragraph = getPara(1);

$baseline_delta = 1;
$radius = 5.0 * $baseline_delta;
$lineWidth = $pageDim[2]-2*$xleft;

# figure set of line lengths, plus extra full width for overflow
my (@odd_LL, @odd_start_x, @odd_end_x);
for (my $odd_y = 0; 
	$odd_y <= $baseline_delta*2+$radius; 
	$odd_y += $baseline_delta) {

    if ($odd_y < $radius) {
	# line starts at delta_x
        $delta_x = round(sqrt($radius**2 - $odd_y**2));
        push @odd_start_x,  $delta_x;
	unshift @odd_end_x, $lineWidth-$delta_x;
    } else {
	# line starts at beginning
        push @odd_start_x, 0;
	unshift @odd_end_x, $lineWidth;
    }
}
	
# line lengths
for (my $row = 0; $row < @odd_start_x; $row++) {
    push @odd_LL, $odd_end_x[$row]-$odd_start_x[$row];
}
push @odd_LL, $lineWidth*0.8;  # for overflow from area

$t->line_lengths(@odd_LL);
@lines = $t->typeset($paragraph);
    dump_lines(@lines) if $line_dump;
    # output @lines to PDF, starting at $xleft, $ytop
    $end_y = write_paragraph('X', \@odd_start_x, @lines);

#fresh_page();
# ------------- 6
# "A Mouse's Tale" layout
#
# See PDF/Triangle.pl. can't do it here because it requires both variably
# sized fonts and fine control over line placement.

# ---- do once at very end
$end = 1;
fresh_page();
$pdf->saveas("$outfile.txt");

# END

sub getPara {
    my ($choice) = @_;  

    # original text for both used MS Smart Quotes for open and close single
    # quotes. replaced by ASCII single quotes ' so will work anywhere.
    if ($choice == 1) {
      # 1. a paragraph from "The Frog King" (Grimms)
    return 
    "In olden times when wishing still helped one, there lived a king ".
    "whose daughters were all beautiful; and the youngest was so beautiful ".
    "that the sun itself, which has seen so much, was astonished whenever it ".
    "shone in her face. Close by the king${rsquo}s castle lay a great dark ".
    "forest, and under an old lime-tree in the forest was a well, and when ".
    "the day was very warm, the king${rsquo}s child went out into the forest ".
    "and sat down by the side of the cool fountain; and when she was bored ".
    "she took a golden ball, and threw it up on high and caught it; and this ".
    "ball was her favorite plaything.".
    ""; }

    if ($choice == 2) {
      # 2. a paragraph from page 16 of the Knuth-Plass article
    return
    "Some people prefer to have the right edge of their text look ".
    "${lsquo}solid${rsquo}, by setting periods, commas, and other punctuation ".
    "marks (including inserted hyphens) in the right-hand margin. For ".
    "example, this practice is occasionally used in contemporary advertising. ".
    "It is easy to get inserted hyphens into the margin: We simply let the ".
    "width of the corresponding penalty item be zero. And it is almost as ".
    "easy to do the same for periods and other symbols, by putting every such ".
    "character in a box of width zero and adding the actual symbol width to ".
    "the glue that follows. If no break occurs at this glue, the accumulated ".
    "width is the same as before; and if a break does occur, the line will be ".
    "justified as if the period or other symbol were not present.".
    ""; }

    if ($choice == 3) {
      # 3. from a forum post of mine
      # fix UTF-8 characters to Latin-1 equivalent
    return
    "That double-dot you see above some letters${mdash}they${rsquo}re the ".
    "same thing, right? No! Although they look the same, the two are actually ".
    "very different, and not at all interchangeable. An umlaut is used in ".
    "Germanic languages, and merely means that the primary vowel (a, o, or u) ".
    "is followed by an e. It is a shorthand for (initially) handwriting: \xE4 ".
    "is more or less interchangeable with ae (not to be confused with the ".
    "\xE6 ligature), \xF6 is oe (again, not ${oelig}), and \xFC is ue. This, ".
    "of course, changes the pronunciation of the vowel, just as adding an e ".
    "to an English word (at the end) shifts the vowel sound (e.g., mat to ".
    "mate). Some word spellings, especially for proper names, may prefer one ".
    "or the other form (usually _e). Whether to use the umlaut form or the ".
    "two-letter form is usually an arbitrary choice in electronic ".
    "typesetting, unless the chosen font lacks the umlaut form (as well as a ".
    "combining ${ldquo}dieresis${rdquo} character). It is more common in ".
    "English-language cold metal typesetting to lack the umlaut form, and ".
    "require the two-letter form. See also thorn and ${ldquo}ye${rdquo}, ".
    "where the ${ldquo}e${rdquo} was originally written as a superscript to ".
    "the thorn (\xFE).".
    ""; }

}
# --------------------------
sub fresh_page {
    # set up a new page, with no content
    # $start = 1: flag to suppress BoP 
    # $end   = 1; flag to suppress ToP

    # bottom margin, unless very first page
    if ($start) {
	$start = 0; # first page, no previous page to fill bottom
    } else {
        for (my $i=$ytop; $i > 0; $i--) { print $page "\n"; }
        print $page "------------ bottom of page -----------\n";
    }
    # top margin
    if (!$end) {
        print $page "------------ top of page --------------\n";
        for (my $i=$pageDim[3]; $i > $pageTop; $i--) { print $page "\n"; }
    }

    $ytop = $pageTop;
    return;
}

# the following direct text output are assumed to be single lines. if used for
# multiple line strings (e.g., embedded \n), would need to update ytop dec.
sub text_center {
    my ($string) = @_;
    my $empty = $pageDim[2]-2*$xleft-length($string);
    $ytop--;
    print $page ' ' x ($xleft+round($empty/2)) . $string . "\n";
    return;
}

sub text {  # left justified
    my ($string) = @_;
    $ytop--;
    print $page ' ' x $xleft . $string . "\n";
    return;
}

sub text_right {  # right-justified
    my ($string) = @_;
    my $empty = $pageDim[2]-2*$xleft-length($string);
    $ytop--;
    print $page ' ' x ($xleft+$empty) . $string . "\n";
    return;
}

# --------------------------
# write_paragraph($align, @lines)
# if y goes below ybot, start new page and finish paragraph
# does NOTHING to check for widows and orphans!
sub write_paragraph {
    my $align = shift;
    my @offsets;  # extra offsets for custom effects
    if ($align eq 'X') {
        @offsets = @{ shift(@_) };
    }
    my @lines = @_;

    my $x;
    my $y = $ytop;  # current starting y
    # $ybot is checked, too
    my $LTR = 1; # LTR/RTL switch for line filling

    print STDERR ">>>>>>>>>>>>>>> start paragraph\n"; # reassure user
    # first line, see if first box is value '' with non-zero width. would be
    # + or - indent amount. if negative indent, xleft+indent better be >= 0
    my $indent = 0;
    my $node1 = $lines[0]->{'nodes'}->[0]; 
    if ($node1->isa("Text::KnuthPlass::Box") && $node1->value() eq '') {
	# we have an indent value (for first line) + or -
	$indent = $node1->width();
	shift @{ $lines[0]->{'nodes'} }; # get rid of indent box
    }

    for my $line (@lines) {
	my $line_str = '';
	my $ratio = $line->{'ratio'};
        $x = 0;  # we do xleft later after centering or right align
	if ($align eq 'X' && @offsets) {
	    my $xoffset = shift(@offsets);
	    $x += $xoffset;
	    $line_str .= ' ' x $xoffset;
	}
        if ($indent > 0) {
	    $x += $indent;
	    $line_str .= ' ' x $indent;
	    $indent = 0;
        }

        print "========== new line @ $x,$y ==============\n" if $line_dump;
	# done separately so debug shows valid $x. later we add xleft and ind.
	$indent = 0;

        # how much to reduce each glue due to adding hyphen at end
        # According to Knuth-Plass article, some designers prefer to have
        # punctuation (including the word-splitting hyphen) hang over past the
        # right margin (as the original code did here). However, other
        # punctuation did NOT hang over, so that would need some work to 
	# separate out line-end punctuation and giving the box a zero width.

        my $useSplitHyphen = 0;
        if ($line->{'nodes'}[-1]->is_penalty()) { 
	    # last word in line is split (hyphenated). node[-2] must be a Box?
	    my $lastChar = '';
            if ($line->{'nodes'}[-2]->isa("Text::KnuthPlass::Box")) {
	        $lastChar = substr($line->{'nodes'}[-2]->value(), -1, 1);
                if ($lastChar eq '-'      || # ASCII hyphen
		    $lastChar eq '\x2010' || # hyphen
		    $lastChar eq '\x2011' || # non-breaking hyphen
	            $lastChar eq '\x2012' || # figure dash
	            $lastChar eq '\x2013' || # en dash
	            $lastChar eq '\x2014' || # em dash
	            $lastChar eq '\x2015' || # quotation dash
	            0) {
		    # fragment already ends with hyphen, so don't add one
		    $useSplitHyphen = 0;
	        } else {
                    # hyphen added to end of fragment, so reduce glue width
		    $useSplitHyphen = 1;
	            my $number_glues = 0;
	            for my $node (@{$line->{'nodes'}}) {
	                if ($node->isa("Text::KnuthPlass::Glue")) { $number_glues++; }
	            }
	            # TBD if no glues in this line, or if reduction amount makes
		    #   glue too close to 0 in width, have to do something else!

	        } # whether or not to add a hyphen at end (word IS split)
	    } # examined node needs to be a Box
        } # there IS a penalty on this line (split word)

        # prepare one line of output
        # each node is a box (text) or glue (variable-width space)...
	#   ignore penalty
	my $node;
	
	# determine how many extra spaces (minimum 1 space) and how to 
	#   distribute them among glue nodes
	my @spaces_list; # space count per glue node 1,2,3,...
	@spaces_list = get_spaces($line, $useSplitHyphen, $const, $LTR);
	$LTR = 1 - $LTR;  # flip switch
	
	# output each text and space(s) node in the line
	my $spaces_node = 0; # index into spaces_list[]
        my $node_count = @{ $line->{'nodes'} };
	my $node_num = 0;
        for my $node (@{$line->{'nodes'}}) {
	    $node_num++;
            if      ($node->isa("Text::KnuthPlass::Box")) {
                $line_str .= $node->value();
                $x += $node->width();
            } elsif ($node->isa("Text::KnuthPlass::Glue")) {
	        # remove last node (it's useless glue)
                if ($node_num == $node_count) { last; }

                my $width = $spaces_list[$spaces_node++];
	        $x += $width;
		$line_str .= ' ' x $width;
            } elsif ($node->isa("Text::KnuthPlass::Penalty")) {
	        # no action at this time (common at hyphenation points, is
		# of interest if hyphenated word at end of line)
	    }
        }
	# now have raw output (including any positive indent) before addng 
	# center/right alignment, then xleft added in

	my $length = length($line_str);
	my $x_offset = 0;
	# set starting offset of full string per alignment
	if      ($align eq 'L' || $align eq 'X') {
            $x_offset = 0;
	} elsif ($align eq 'C') {
            $x_offset = round(($lineWidth-$length)/2);
	} else { # 'R'
            $x_offset = $lineWidth-$length;
	}
	# take care of any negative indent here
	$x_offset = max(0, $x_offset + $xleft + $indent);
	$x += $x_offset;
	$line_str = (' ' x $x_offset) . $line_str;

        # add hyphen to text ONLY if fragment didn't already end with some
        # sort of hyphen or dash 
        if ($useSplitHyphen) {
	    $line_str .= $split_hyphen; 
        }

	$line_str = margin_lines($line_str);
	print $page $line_str . "\n";

        $y--;  # next line down
	$ytop = $y;
	if ($y <= $ybot) { 
	    fresh_page();
	    $ytop = $y = $pageTop;
	}
    } # end of handling line element
    return $y;
} # end of write_paragraph()

# --------------------------
sub margin_lines {
    my ($line) = @_;

    if ($do_margin_lines) {
        # draw left and right margin lines
	
	# right: pad out with blanks to xleft+lineWidth, write |
	# (only if overwriting a blank)
	my $pad = $xleft + $lineWidth + 1 - length($line);
	if ($pad > 0) { $line .= ' ' x $pad; }
	if (substr($line, $xleft + $lineWidth, 1) eq ' ') {
	    substr($line, $xleft + $lineWidth, 1) = '|';
	}

	# left:  if xleft==0, insert at first. otherwise at overwrite xleft-1
	if ($xleft > 0) {
	    substr($line, $xleft - 1, 1) = '|';
	} else {
	    $line = '|'.$line;
	}
    }
    return $line;
}

# --------------------------
# input is one line, a collection of nodes
sub get_spaces {
    my ($line, $adding_hyphen, $const, $LTR) = @_;

    $const = 0; # ignore for now
    my @list = (); # array of space counts at each glue, to return
    my $node_count = @{ $line->{'nodes'} };
    my $node_num = 0;
    my $glue_num = 0; # current glue number index
    my @spaces_type; # 0: no punct., 1=non-stop punct. (comma, etc.),
                     # 2: full stop (., ?, !) gets priority
    my @spaces_count = (0, 0, 0); # running count of type
    my @spaces_index = ([], [], []); # which node is of which type

    my $type = 0; # tiers: 0 plain words, 1 non-full-stop punct., 2 full-stop
    my $ratio = $line->{'ratio'};  # line expansion amount. for text or constant
                                   # width output, s/b >= 0

    # for nodes in line, build various glue/space-related counters and lists
    for my $node (@{$line->{'nodes'}}) {
        if ($node->isa("Text::KnuthPlass::Glue")) {
	    # ignore if glue after last box
	    # we're also not going to examine box's text, but it's at the end
	    #   of the line, so it's irrelevant for our space-counting effort.
	    if ($node_num == $node_count - 1) { last; }

	    $type = 0; # type of preceeding Box
	    # push 1 to list, push 0..2 to type
	    push @list, 1;

	    # either previous node or the one before it should be Box
	    # note that a hyphenated (split) word is overlooked at this point,
	    #   but since we DO see the last syllable, that's all we need.
	    my $nodeB = $line->{'nodes'}->[$node_num-1];
	    # probably shouldn't see a Box two back, but just in case...
	    if (!$nodeB->isa("Text::KnuthPlass::Box")) {
	        $nodeB = $line->{'nodes'}->[$node_num-2];
	    }
	    my $text = $nodeB->value(); # text in Box this Glue applies to

	    if ($text =~ m/([[:punct:]]+)$/x) {
	        # Box ends with punctuation. does it contain a full stop?
	        $text = $1;
	        $type = 1;
	        # for now "full stop" is . ? ! within stream of one or
	        # more punctuation characters. these get priority in
	        # distributing spaces
	        if ($text =~ m/[.?!]/) { $type = 2; }
	    } else {
	        # leave type as 0 (is alphanumeric, not punctuation)
	    }
	    push @spaces_type, $type;
	    $spaces_count[$type]++;

            # push glue_num on to index list
	    my @existing_tlist = @{ $spaces_index[$type] };
	    push @existing_tlist, $glue_num++;
            $spaces_index[$type] = \@existing_tlist;
        }

        $node_num++;
    } # end of building various glue/space-related counters and lists

    # have arrays of space types, list (count); and total of each type
    # now, how many spaces do we need to sprinkle around?
    # for text output, should never see a ratio < 0
    if (scalar(@spaces_type) && 
	($ratio > 0 || $const > 0 && $adding_hyphen)) {
        # there is at least one space (glue node) in line
        my $add_spaces = 0;
        $add_spaces = $ratio * scalar(@spaces_type);
        # likely to be just over or under an even integer
        $add_spaces = floor($add_spaces + 0.5);
        # for some reason, it's always twice what we need (is even, too)
        $add_spaces = round($add_spaces/2);
        # if going to add a hyphen at end, reduce by 1
        if ($adding_hyphen) { $add_spaces--; }

        # maybe should check, but add_spaces s/b integer >= 0
        if (floor($add_spaces) != $add_spaces ||
	    $add_spaces < 0) {
	    # um Houston, we have a problem. bad add_spaces
            print STDERR "bad add_spaces: $add_spaces\n";
	    $add_spaces = max(0, floor($add_spaces));
        }

	# line width may have been shortened by $const -- if didn't add
	# a hyphen, we have an extra space to add
	if ($const > 0 && !$adding_hyphen) { $add_spaces++; }
	 
        # distribute this count of spaces around the line, with priority
        # to type 2, then type 1, then type 0
	while ($add_spaces) {
	    # usually add_spaces will go to 0 in one loop, but just in case...
	    for (my $tier = 2; $tier >= 0; $tier--) {
                if ($spaces_count[$tier]) {
	            # there is at least one type $tier glue
		    if ($add_spaces >= $spaces_count[$tier]) {
		        # can completely fill this tier
		        for (my $j = 0; $j < $spaces_count[$tier]; $j++) {
		            $list[$spaces_index[$tier][$j]]++;
		            $add_spaces--;
		        }
		    } else {
		        # can't completely fill this tier... 
		#############################################################
		# Don't want to introduce visual artefacts by bunching up   #
		# all the newly added spaces on one side or the other.      #
		# The best would be a random seeding over the spaces_index  #
		# array until add_spaces used up, but this can be slow and  #
		# complicated. For time being, since this is just a sample, #
		# alternate filling LTR 0..add_spaces-1 and RTL             #
		# -add_spaces..-1.                                          #
		#############################################################
			if ($LTR) {
			    # filling LTR 0..add_spaces-1
		            for (my $j = 0; ; $j++) {
		                $list[$spaces_index[$tier][$j]]++;
			        if (--$add_spaces == 0) { last; }
			    }
			} else {
			    # filling RTL -1..-add_spaces-1
		            for (my $j = -1; ; $j--) {
		                $list[$spaces_index[$tier][$j]]++;
			        if (--$add_spaces == 0) { last; }
			    }
		        }
			# don't forget to have call flip LTR switch!
		    } # tier NOT filled (else)
		} # at least one glue entry this tier
		last if !$add_spaces;
	    } # tier loop
        } # while add_spaces > 0, distribute them
    } # there is at least one glue, and ratio > 0

    if ($ratio <= 0 && !($const > 0 && $adding_hyphen)) {
        # one space per glue, and we're done
        # note that some lines may overflow right margin, KP is a little
        # flaky when trying to handle constant width fonts or text
        for my $node (@{$line->{'nodes'}}) {
            if ($node->isa("Text::KnuthPlass::Glue")) {
	        push @list, 1;
	    }
        }
    } # we do have spaces to distribute for ratio == 0 (or < 0)

    return @list;
} # end of get_spaces()

# --------------------------
# dump @lines (diagnostics)
sub dump_lines {
    my (@lines) = @_;

    if ($line_dump) {
        # dump @lines
         foreach (@lines) { 
           # $_ is a hashref
           print "========== new line ==============\n";
           foreach my $key (sort keys %$_) { 
             my $value = $_->{$key};
             if ($key eq 'nodes') {
               print "$key:\n";
               my @content = @{ $value };
               foreach my $item ( @content ) {
	         print "\n" if (ref($item) =~ m/::Box/);
	         print ref($item)."\n";
	         foreach my $subitem ( sort keys %$item ) {
                   print "$subitem = $item->{$subitem}\n";
	           # box value = 'text fragment'
	           #     width = width in Points
	           # glue shrink = factor ~1
	           #      stretch = facctor ~1
	           #      width = width in Points (whitespace)
	           # penalty flagged = 0 or 1
	           #         penalty = value of penalty
	           #         shrink = factor
	           #         width = width in Points
	         }
               }
             } else {
               # not sure what position is (x position at raw end of line?)
               print "$key = $value, ";
             }
           } 
           print "\n";
         }
    }
    return;
} # end of dump_lines()

sub round {
    my $fvalue = shift;
    return floor($fvalue + 0.5);
}
