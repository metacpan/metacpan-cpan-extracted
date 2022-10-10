#!/usr/bin/Perl
# derived from Synopsis example in KnuthPlass.pm
# REQUIRES PDF::Builder and Text::Hyphen (builds PDF output)
# TBD: command-line selection of line width, which text to format, perhaps
#      choice of font and font size
#      indent value
#      see Flatland.pl for more items to address
use strict;
use warnings;
use Text::KnuthPlass;
use POSIX qw/ceil floor/;
    # Also POSIX character classes such as [[:punct:]] are used. I can't find
    # which Perl they first appeared in, but the documentation for 5.10 suggests
    # that it was already around by then. If someone discovers that they first
    # appeared in something more recent, I will put an appropriate "use"
    # statement here.
use List::Util qw(max);

# flag to replace fancy punctuation by ASCII characters
my $use_ASCII = 1;
# force use of pure Perl version (not XS), if value 1
my $purePerl = 1;

my $do_margin_lines = 1;  # draw vertical lines indicating margins
my $outfile = 'T_KP';
my $const = 0; # subtract from lineWidth to allow room for added hyphen
               # 0 for proportional font, 1 for text file, pts for const. width
	       # IGNORED for now, needs fixing
my $line_dump = 0;  # debug related
my $raggedRight = 0; # 0 = flush right, 1 = ragged right
my $indentAmount = 0; # chars to indent first line of paragraph
                      # - outdents upper left corner of paragraph
my $split_hyphen = '-';  # can't use non-ASCII characters

my $vmargin = 2; # top and bottom margins
my $xleft = 5;
my @pageDim = (0,0, 80,66);
# output is expected to be a single "page"

my ($textChoice, $x, $y, $vertical_size);
my ($page, $ytop);
open $page, ">", "$outfile.txt" or die "unable to open output file";
my $start = 1; # empty file at this point
my $end   = 0; # special call to fresh_page to finish out bottom

# as with PDF, 0,0 is bottom left corner
my $pageTop = $pageDim[3]-$vmargin; # each page starts here...
my $ybot = $vmargin;                # and ends here

# various HTML entities (so to speak)
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

# should allow 80-2*5 = 70 columns of text, from 6 to 75
my $lineWidth = $pageDim[2]-2*$xleft; # Points, left margin = right margin
my ($w, $t, $paragraph, @lines, $indent, $end_y);

fresh_page();

    # create Knuth-Plass object, build line set with it
    $t = Text::KnuthPlass->new(
	'indent' => 0,
        'space' => { 'width' => 3, 'stretch' => 6, 'shrink' => 0 },
        'measure' => sub { length(shift) }, 
        'linelengths' => [$lineWidth]  
    );

# ---------- actual page content
#   three selections, at given line width and indentation
for ($textChoice=1; $textChoice<=3; $textChoice++) {
    # $ytop already set
    $indent = $indentAmount;
    $paragraph = getPara($textChoice);

    # split up the paragraph's lines, start writing on this page, may continue.
    @lines = $t->typeset($paragraph);
    dump_lines(@lines);
    # output @lines to file, starting at $xleft, $ytop
    $end_y = write_paragraph(@lines);

    text(" "); text(" ");  # skip two lines
}

# You can see three-line rivers near the left and right margins.

# ---------- 
# A paragraph about the Pearl River (China) used to illustrate "rivers" of
# whitespace running down a paragraph. Unfortunately, this is difficult to
# detect by algorithm, so parameters need to be adjusted manually after rivers
# are discovered accidentally.
#
# this was given in https://tex.stackexchange.com/questions/4507/avoiding-rivers-in-successive-lines-of-type
# to illustrate a "river" that runs vertically from top to bottom when the text
# parameters are just right (large indent, first line ends at "total", second
# at "the"). note that in general, detecting and eliminating rivers is a
# computationally difficult task that TeX does not really handle.
#
# Example apparently from James Felici, _The Complete Manual of Typography_
# (2003), p. 161 via "lockstep". lines split where they were in example.

# Needs own $lineWidth to precisely control line breaks, and
# can't give a $font_size, too. We want to break as indicated in
# the following lines, which hopefully should show the rivers.

$paragraph =
"Though the Pearl measures less than 50 miles in total " .
"length from its modest source as a cool mountain spring to the " .
"screaming cascades and steaming estuary of its downstream " .
"reaches, over those miles, the river has in one place or another " .
"everything you could possibly ask for. You can roam among " .
"lush temperate rain forests, turgid white water canyons, contemplative " .
  # should hyphenate con-templative
"meanders among aisles of staid aspens (with trout " .
"leaping to slurp all the afternoon insects from its calm surface), " .
  # should hyphenate sur-face
"and forbidding swamp land as formidable as any that " .
  # can't italicize The African Queen 
"Humphrey Bogart muddled through in The African Queen."
;
 
$lineWidth -= 10;
@lines = $t->typeset($paragraph, 'linelengths' => [$lineWidth]);
dump_lines(@lines) if $line_dump;
# output @lines to PDF, starting at $xleft, $ytop
$end_y = write_paragraph(@lines);

$ytop = $end_y;

text(" "); text(" ");  # skip two lines

# ---- do once at very end
$end = 1;
fresh_page();
close $page;

# END

# --------------------------
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
    # note that at lineWidth=300, "right-hand" is split at the "-"
    # linewidth 400, presen-t on last line!
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
    # note that at lineWidth=265 or so, there should be a split after the 
    # em-dash, but it refuses to split there (TBD)
    # linewidth 400, vow-el split (tail end s/b min 3, too?)
    return
    "That double-dot you see above some letters${mdash}they${rsquo}re the ".
    "same thing, right? No! Although they look the same, the two are actually ".
    "very different, and not at all interchangeable. An umlaut is used in ".
    "Germanic languages, and merely means that the primary vowel (a, o, or u) ".
    "is followed by an e. It is a shorthand for (initially) handwriting: \xE4 ".
    "is more or less interchangeable with ae (not to be confused with the ".
    "ae ligature), \xF6 is oe (again, not ${oelig}), and \xFC is ue. This, ".
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

# END

# ======================================================================
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
    print $page ' ' x ($xleft+$empty/2) . $string . "\n";
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

# need to carve out space for floats (images) on right?
sub space_for_image {
    # return an array reference containing the lengths need for the 
    # listlengths array in the new() method. $margin_r can be less than
    # zero to have the image stick out into the right margin
    # $start is number of full-length entries to stick at the beginning,
    #   as the image starts that many lines down
    my ($indent, $lineWidth, $img_w, $img_h,
	$margin_l, $margin_t, $margin_r, $margin_b, $leading, $start) = @_;

    my @list;
    $img_w += $margin_l; $img_w += $margin_r;
    $img_h += $margin_t; $img_h += $margin_b;
    # width and height now include a margin around the image, to account
    # (in part) for variation in inked descenders at the top and ascenders
    # at the bottom

    # if $start > 0, push that many full lines
    for (my $i = 0; $i < $start; $i++) {
        push @list, $lineWidth;
    }

    # figure how many lines ($leading amount) to shorten, one element for
    # each shortened line
    my $num_lines = ceil($img_h / $leading);
     
    for (my $i = 0; $i < $num_lines; $i++) {
	push @list, $lineWidth-$img_w;
    }
    # add full width line at end
    push @list, $lineWidth;

    return \@list;
}

# --------------------------
# write_paragraph(@lines)
# if y goes below ybot, start new page and finish paragraph
# does NOTHING to check for widows and orphans, or for float inset across
#   page break! you'll need to manually clean up those.
sub write_paragraph {
    my (@lines) = @_;

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
        $x = $xleft; 
        print "========== new line @ $x,$y ==============\n" if $line_dump;
	$x += $indent; # done separately so debug shows valid $x
	$line_str .= ' ' x $x; 
	$indent = 0;

        # how much to reduce each glue due to adding hyphen at end
        # According to Knuth-Plass article, some designers prefer to have
        #   punctuation (including the word-splitting hyphen) hang over past the
        #   right margin (as the original code did here). However, other
        #   punctuation did NOT hang over, so that would need some work to 
	#   separate out line-end punctuation and giving the box a zero width.

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

        # one line of output
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
        $add_spaces /= 2;
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

# --------------
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

