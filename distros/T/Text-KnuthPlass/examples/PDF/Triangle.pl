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
use POSIX qw/ceil/;

# flag to replace fancy punctuation by ASCII characters
my $use_ASCII = 0;
# force use of pure Perl code
my $purePerl = 1; # 0: use XS, 1: use Perl  DOESN'T WORK

my $textChoice = 1;  # see getPara() at bottom, for choices of sample text
my $outfile = 'Triangle';
my $line_dump = 0;  # debug related
my $do_margin_lines = 0; # debug... do not change, N/A

my $font_scale = 1.7; # adjust to fill circle example
my $radius = 200; # radius of filled circle

my $xleft = 50;  # left (and right) margin
my $raggedRight = 0; # 0 = flush right, 1 = ragged right
my $indentAmount = 0; # ems to indent first line of paragraph. - outdents
#                       upper left corner of paragraph MUST BE 0
#my $split_hyphen = '-';  # TBD check if U+2010 narrow hyphen is available
                         # once font is selected
my $split_hyphen = "\x{2010}";

my $pdf = PDF::Builder->new('compress' => 'none');
my @pageDim = $pdf->mediabox();
#my $lineWidth = 400; # Points. get different wrapping effects by varying
my $lineWidth = $pageDim[2]-2*$xleft; # Points, left margin = right margin
my ($page, $grfx, $text, $ytop);

#my $font = $pdf->ttfont("/Windows/Fonts/arial.ttf");
my $font = $pdf->ttfont("/Windows/Fonts/times.ttf");
my $fontI = $pdf->ttfont("/Windows/Fonts/timesi.ttf");
#my $font = $pdf->corefont("Helvetica-Bold");

my $vmargin = 100; # top and bottom margins, if fill at least one page
my $font_size = 12;
my $leading = 1.125; # leading will be 9/8 of the font size

my $pageTop = $pageDim[3]-$vmargin; # each page starts here...
my $ybot = $vmargin;                # and ends here

# HTML entities (elaborate vs ASCII) handled in getPara()

my ($w, $t, $paragraph, @lines, $indent, $end_y);
my ($x, $y, $vertical_size);

fresh_page();

# create Knuth-Plass object, build line set with it
$t = Text::KnuthPlass->new(
    'measure' => sub { $text->advancewidth(shift) }, 
    'linelengths' => [ $lineWidth ],  # dummy placeholder
    'indent' => 0,
);

# ---------- actual page content
my $widthHyphen = $text->advancewidth($split_hyphen);

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

    $ytop = $end_y;

# skip 2 lines
$ytop -= 2 * $font_size*$leading;

# -------------
# isoceles triangle, use text_center()
$paragraph = getPara(2);

$t->line_lengths(@list_LL);
@lines = $t->typeset($paragraph, 'linelengths' => \@list_LL);
    dump_lines(@lines) if $line_dump;
    # output @lines to PDF, starting at $xleft, $ytop
    $end_y = write_paragraph('C', @lines);

    $ytop = $end_y;

# skip 2 lines
$ytop -= 2 * $font_size*$leading;

# -------------
# right triangle with vertical at right margin, use text_right()
$paragraph = getPara(3);

$t->line_lengths(@list_LL);
@lines = $t->typeset($paragraph);
    dump_lines(@lines) if $line_dump;
    # output @lines to PDF, starting at $xleft, $ytop
    $end_y = write_paragraph('R', @lines);

    $ytop = $end_y;

# skip 2 lines
$ytop -= 2 * $font_size*$leading;

# -------------
# filled circle, adjust font_size to fill as much as possible
$paragraph = getPara(1);

# xc,yc at xleft+.5*lineWidth (need minimum 2*radius height available)
if (2*$radius > $lineWidth) { $radius = $lineWidth/2; }
if ($ytop - 2*$radius < $ybot) { fresh_page(); }

$text->font($font, $font_size*$font_scale);
my $baseline_delta = $font_size * $font_scale * $leading;
$text->leading($baseline_delta);

# figure set of line lengths, plus extra full width for overflow
# text is centered at xc.
my ($delta_x, @circle_LL);
for (my $circle_y = $ytop-$baseline_delta; 
	$circle_y > $ytop-2*$radius; 
	$circle_y -= $baseline_delta) {
    $delta_x = sqrt($radius**2 - ($circle_y-$ytop+$radius)**2);
    push @circle_LL, 2*$delta_x;
}
push @circle_LL, $lineWidth*0.8;  # for overflow from circle

$t->line_lengths(@circle_LL);
@lines = $t->typeset($paragraph);
    dump_lines(@lines) if $line_dump;
    # output @lines to PDF, starting at $xleft, $ytop
    $end_y = write_paragraph('C', @lines);

    $ytop = $end_y;

# skip 2 lines
$ytop -= 2 * $font_size*$leading;

# -------------
# rectangle with two circular cutouts
$paragraph = getPara(1);

$font_scale = 1.0;
$text->font($font, $font_size*$font_scale);
$baseline_delta = $font_size*$font_scale * $leading;
$text->leading($baseline_delta);
$radius = 5.0 * $baseline_delta;
$xleft = 100;
$lineWidth = $pageDim[2]-2*$xleft;

# figure set of line lengths, plus extra full width for overflow
my (@odd_LL, @odd_start_x, @odd_end_x);
for (my $odd_y = 0; 
	$odd_y <= $baseline_delta*2+$radius; 
	$odd_y += $baseline_delta) {

    if ($odd_y < $radius) {
	# line starts at delta_x
        $delta_x = sqrt($radius**2 - $odd_y**2);
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

    $ytop = $end_y;

# -------------
fresh_page();
# "A Mouse's Tale" layout
#
# From Lewis Carroll's "Alice's Adventures in Wonderland" (1865).
#
# This is only using KP to adjust the second paragraph until it ends in the
# middle of the page. From there on out (the tail/tale itself) is following
# the offset and font size used in http://bootless.net/mouse.html, a most
# readable version of the segment. This seemed much easier than trying to 
# curve fit (polynomial or decreasing amplitude sine waves) the left side or
# the centerline of the "tail". The font size would be a function of the 
# vertical displacement. Undoubtedly, the original printing had to use fixed
# conventional sized type, so it's not smoothly decreasing in size.
#
#    like this:--
#       "Fury said to
 
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

$font_size = 10;
$leading = 1.05;
$xleft = 105;
$lineWidth = $pageDim[2] - 2*$xleft;
my $px_to_pt = 0.80;   # trial and error
$t->line_lengths($lineWidth);

# two headings, centered
$text->font($font, $font_size*1.6);  # <h2>
$ytop -= 1.6 * $font_size * $leading;
$text->translate($xleft + $lineWidth/2, $ytop);
$text->text_center("The Mouse${rsquo}s Tale");

$text->font($font, $font_size*1.4);  # <h3>
$ytop -= 1.4 * $font_size * $leading;
$text->translate($xleft + $lineWidth/2, $ytop);
$text->text_center("by Lewis Carroll");

$text->font($font, $font_size);
$ytop -= 2 * $font_size * $leading;
$paragraph = "${ldquo}Mine is a long and a sad tale!${rdquo} said the Mouse, turning to Alice, and sighing.";
@lines = $t->typeset($paragraph);
    dump_lines(@lines) if $line_dump;
    # output @lines to PDF, starting at $xleft, $ytop
    $end_y = write_paragraph('L', @lines);

    $ytop = $end_y;

# skip 1 lines
$ytop -= 1 * $font_size*$leading;

$paragraph = "${ldquo}It is a long tail, certainly,${rdquo} said Alice, looking down with wonder at the Mouse${rsquo}s tail; ${ldquo}but why do you call it sad?${rdquo} And she kept on puzzling about it while the Mouse was speaking, so that her idea of the tale was something like this:${mdash}";
@lines = $t->typeset($paragraph);
    dump_lines(@lines) if $line_dump;
    # output @lines to PDF, starting at $xleft, $ytop
    $end_y = write_paragraph('L', @lines);

    $ytop = $end_y;

# each element is one line. 'text' is of course the text, 'left' is the
# leftward displacement in pixels (convert to points), 'size' is the percentage
# of the normal text size. 'italic' is a list of subelements (words) to 
# italicize.
my @tale = (
{ 'text' => "${ldquo}Fury said to",    'left' => -60, 'size' => 105 },
{ 'text' => "a mouse, that",           'left' => -40, 'size' => 100 },
{ 'text' => "he met",                  'left' => 0,   'size' => 100 },
{ 'text' => "in the",                  'left' => 10,  'size' => 100 },
{ 'text' => "house,",                  'left' => 20,  'size' => 100 },
{ 'text' => "${lsquo}Let us",          'left' => 17,  'size' => 100 },
{ 'text' => "both go",                 'left' => 5,   'size' => 100 },
{ 'text' => "to law:",                 'left' => -7,  'size' => 100 },
{ 'text' => "I will",                  'left' => -23, 'size' => 100, 'italic' => [ 0 ] },
{ 'text' => "prosecute",               'left' => -26, 'size' => 100 },
{ 'text' => "you.${mdash}",            'left' => -40, 'size' => 90,  'italic' => [ 0 ] },
{ 'text' => "Come, I${rsquo}ll",       'left' => -30, 'size' => 90  },
{ 'text' => "take no",                 'left' => -20, 'size' => 90  },
{ 'text' => "denial;",                 'left' => -7,  'size' => 90  },
{ 'text' => "We must",                 'left' => 19,  'size' => 90  },
{ 'text' => "have a",                  'left' => 45,  'size' => 90  },
{ 'text' => "trial:",                  'left' => 67,  'size' => 90  },
{ 'text' => "For",                     'left' => 80,  'size' => 90  },
{ 'text' => "really",                  'left' => 70,  'size' => 80  },
{ 'text' => "this",                    'left' => 57,  'size' => 80  },
{ 'text' => "morning",                 'left' => 75,  'size' => 80  },
{ 'text' => "I${rsquo}ve",             'left' => 95,  'size' => 80  },
{ 'text' => "nothing",                 'left' => 77,  'size' => 80  },
{ 'text' => "to do.${rsquo}",          'left' => 57,  'size' => 80  },
{ 'text' => "Said the",                'left' => 38,  'size' => 70  },
{ 'text' => "mouse to",                'left' => 30,  'size' => 70  },
{ 'text' => "the cur,",                'left' => 18,  'size' => 70  },
{ 'text' => "${lsquo}Such a",          'left' => 22,  'size' => 70  },
{ 'text' => "trial,",                  'left' => 37,  'size' => 70  },
{ 'text' => "dear sir,",               'left' => 27,  'size' => 70  },
{ 'text' => "With no",                 'left' => 9,   'size' => 70  },
{ 'text' => "jury or",                 'left' => -8,  'size' => 70  },
{ 'text' => "judge,",                  'left' => -18, 'size' => 70  },
{ 'text' => "would be",                'left' => -6,  'size' => 70  },
{ 'text' => "wasting",                 'left' => 7,   'size' => 70  },
{ 'text' => "our breath.${rsquo}",     'left' => 25,  'size' => 70  },
{ 'text' => "${lsquo}I${rsquo}ll be",  'left' => 30,  'size' => 60  },
{ 'text' => "judge,",                  'left' => 24,  'size' => 60  },
{ 'text' => "I${rsquo}ll be",          'left' => 15,  'size' => 60  },
{ 'text' => "jury,${rsquo}",           'left' => 2,   'size' => 60  },
{ 'text' => "Said",                    'left' => -4,  'size' => 60  },
{ 'text' => "cunning",                 'left' => 17,  'size' => 60  },
{ 'text' => "old Fury;",               'left' => 29,  'size' => 60  },
{ 'text' => "${lsquo}I${rsquo}ll try", 'left' => 37,  'size' => 60  },
{ 'text' => "the whole",               'left' => 51,  'size' => 60  },
{ 'text' => "cause,",                  'left' => 70,  'size' => 60  },
{ 'text' => "and",                     'left' => 65,  'size' => 60  },
{ 'text' => "condemn",                 'left' => 60,  'size' => 60  },
{ 'text' => "you",                     'left' => 60,  'size' => 60  },
{ 'text' => "to",                      'left' => 68,  'size' => 60  },
{ 'text' => "death.${rsquo} ${rdquo}", 'left' => 82,  'size' => 60  },
           );

# what is current text position? interested in x value. position() doesn't
# seem to work, due to not using standard text*() methods, so eyeball it
#my ($xpos, $ypos) = $text->position();
my $xpos = $xleft + $lineWidth/2 - 40;
# ytop must be brought back up to the last line
$ytop += $font_size*$leading;

for my $tline (@tale) {
    my $ltext = $tline->{'text'};
    my $left  = $tline->{'left'};
    my $size  = $tline->{'size'};
    my $italic;
    $italic = $tline->{'italic'} if defined $tline->{'italic'};

    $ytop -= $size/100 * $font_size * $leading;
    $text->translate($xpos + $left*$px_to_pt, $ytop);

    # italics are first 1 or 2 characters, so split line
    if ($italic) {
	my @words = split /\s/, $ltext; # may be entire line in [0]
        # currently only word[0] is italicized, so cheat
	$text->font($fontI, $font_size*$size/100);
        $text->text($words[0].' ');
	if (@words > 1) {
	    shift @words;
            $text->font($font, $font_size*$size/100);
            $text->text(join(' ', @words));
	}

	$italic = undef;
    } else { # entire line in standard Roman font
        $text->font($font, $font_size*$size/100);
        $text->text($ltext);
    }

}

# five short paragraphs follow, if there is room on the page. I don't
# think it will QUITE fit, unfortunately, unless I reduce the font size
# even more.

#$paragraph = "${ldquo}You are not attending!${rdquo} said the Mouse to Alice, severely. ${ldquo}What are you thinking of?${rdquo}";

#$paragraph = "${ldquo}I beg your pardon,${rdquo} said Alice very humbly, ${ldquo}you had got to the fifth bend, I think?${rdquo}";

#$paragraph = "${ldquo}I had not!${rdquo} cried the Mouse sharply and very angrily.";

#$paragraph = "${ldquo}A knot!${rdquo} said Alice, always ready to make herself useful, and looking anxiously about her. ${ldquo}Oh, let me help to undo it!${rdquo}";

#$paragraph = "${ldquo}I shall do nothing of the sort,${rdquo} said the Mouse, getting up and walking away. ${ldquo}You insult me by talking such nonsense!${rdquo}";

# ---- do once at very end
$pdf->saveas("$outfile.pdf");

# END

sub getPara {
    my ($choice) = @_;  

    # various HTML entities (so to speak)
    # flag to replace by ASCII characters

    my $mdash = "\x{2014}"; # --
    my $lsquo = "\x{2018}"; # '
    my $rsquo = "\x{2019}"; # '
    my $ldquo = "\x{201C}"; # "
    my $rdquo = "\x{201D}"; # "
    my $sect  = "\x{A7}";   # sect
    my $oelig = "\x{153}";  # oe lig
    if ($use_ASCII) {
	$mdash = '--';
	$lsquo = $rsquo = '\'';
	$ldquo = $rdquo = '"';
	$sect  = 'sect';
	$oelig = 'oe ligature';
    }

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
    $page = $pdf->page();
    $grfx = $page->gfx();
    $text = $page->text();
    $ytop = $pageTop;
    # default font
    $text->font($font, $font_size);
    $text->leading($font_size * $leading);
   #margin_lines();
    return;
}

# --------------------------
# write_paragraph(@lines)
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
        my $ratio = $line->{'ratio'};
        $x = $xleft; 
	if ($align eq 'X' && @offsets) {
	    $x += shift(@offsets);
	}
        print "========== new line @ $x,$y ==============\n" if $line_dump;
	$x += $indent; # done separately so debug shows valid $x
        $indent = 0; # resets globally, so need to keep setting
	my $x_offset = 0;

        # how much to reduce each glue due to adding hyphen at end
        # According to Knuth-Plass article, some designers prefer to have
        #   punctuation (including the word-splitting hyphen) hang over past the
        #   right margin (as the original code did here). However, other
        #   punctuation did NOT hang over, so that would need some work to 
	#   separate out line-end punctuation and giving the box a zero width.
	
        my $reduceGlue = 0;
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
	            if ($number_glues) {
	                $reduceGlue = $widthHyphen / $number_glues;
	            }

	        } # whether or not to add a hyphen at end (word IS split)
	    } # examined node needs to be a Box
        } # there IS a penalty on this line

        # one line of output
        # each node is a box (text) or glue (variable-width space)...
	#   ignore penalty
        # output each text and space node in the line
	# TBD: alternative is to assemble blank-separated text, and use
	#   PDF's wordspace() to adjust glue lengths. if doing hanging 
	#   punctuation, would have to adjust value so line overhangs right
	#   by size of punctuation.
	
	# what is the total line length?
	
        my $length = 0;
        for my $node (@{$line->{'nodes'}}) {
            if ($node->isa("Text::KnuthPlass::Box")) {
                $length += $node->width();
            } elsif ($node->isa("Text::KnuthPlass::Glue")) {
                $length +=
                  ($node->width() - $reduceGlue) + $line->{'ratio'} *
	            (($raggedRight)? 1:
                    ($line->{'ratio'} < 0? $node->shrink(): $node->stretch()));
            } elsif ($node->isa("Text::KnuthPlass::Penalty")) {
	        # no action at this time (common at hyphenation points, is
		# of interest if hyphenated word at end of line)
             }
        }
        # add hyphen to text ONLY if fragment didn't already end with some
        # sort of hyphen or dash 
        if ($useSplitHyphen) {
	    $length += $widthHyphen;
        }
        # now have $length, how long line is

	# set starting offset of full string per alignment
	if      ($align eq 'L' || $align eq 'X') {
            $x_offset = 0;
	} elsif ($align eq 'C') {
            $x_offset = ($lineWidth-$length)/2;
	} else { # 'R'
            $x_offset = $lineWidth-$length;
	}

        for my $node (@{$line->{'nodes'}}) {
	    $text->translate($x+$x_offset,$y);
            if ($node->isa("Text::KnuthPlass::Box")) {
                $text->text($node->value());
                $x += $node->width();
            } elsif ($node->isa("Text::KnuthPlass::Glue")) {
                $x += ($node->width() - $reduceGlue) + $line->{'ratio'} *
	        (($raggedRight)? 1:
                    ($line->{'ratio'} < 0? $node->shrink(): $node->stretch()));
            } elsif ($node->isa("Text::KnuthPlass::Penalty")) {
	        # no action at this time (common at hyphenation points, is
	        # of interest if hyphenated word at end of line)
            }
	}
	
        # add hyphen to text ONLY if fragment didn't already end with some
        # sort of hyphen or dash 
        if ($useSplitHyphen) {
	    $text->text($split_hyphen); 
        }
        $y -= $text->leading();  # next line down
	if ($y < $ybot) { 
	    fresh_page();
	    $y = $pageTop;
	}
    } # end of handling a line
    return $y;
} # end of write_paragraph()

# --------------------------
sub margin_lines {

    if (!$do_margin_lines) { return; }

    # draw left and right margin lines
    $grfx->strokecolor("red");
    $grfx->linewidth(0.5);
    $grfx->poly($xleft,$ytop+$font_size, 
	        $xleft,$end_y+$font_size);
    $grfx->poly($xleft+$lineWidth,$ytop+$font_size, 
	        $xleft+$lineWidth,$end_y+$font_size);
    $grfx->stroke();
    # done with this sample
    return;
}

# --------------------------
# dump @lines (diagnostics)
sub dump_lines {
    my @lines = @_;

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

    return;
} # end of dump_lines()

