#!/usr/bin/Perl
# derived from Synopsis example in KnuthPlass.pm
# REQUIRES PDF::Builder and Text::Hyphen (builds PDF output)
# TBD: command-line selection of line width, which text to format, perhaps
#      choice of font and font size
#      outdented example, or setting for all
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

my $outfile = 'KP';
my $line_dump = 0;  # debug related
my $do_margin_lines = 1;  # debug related

my $raggedRight = 0; # 0 = flush right, 1 = ragged right
my $indentAmount = 0; # ems to indent first line of paragraph. - outdents
#                       upper left corner of paragraph
#my $split_hyphen = '-';  # TBD check if U+2010 narrow hyphen is available
#                         # once font is selected. else use ASCII hyphen.
my $split_hyphen = "\x{2010}";

my $pdf = PDF::Builder->new('compress' => 'none');
my @pageDim = $pdf->mediabox();
my $lineWidth = 300; # Points. get different wrapping effects by varying
#my $lineWidth = $pageDim[2]-2*$xleft; # Points, left margin = right margin
my ($page, $grfx, $text, $ytop);

#my $font = $pdf->ttfont("/Windows/Fonts/arial.ttf");
my $font = $pdf->ttfont("/Windows/Fonts/times.ttf");
my $fontI = $pdf->ttfont("/Windows/Fonts/timesi.ttf");
#my $font = $pdf->corefont("Helvetica-Bold");

my $vmargin = 100; # top and bottom margins, if fill at least one page
my $xleft = 50;
my $font_size = 12;  # be careful not to overlap three sample texts!
my $leading = 1.125; # leading will be 9/8 of the font size

my $pageTop = $pageDim[3]-$vmargin; # each page starts here...
my $ybot = $vmargin;                # and ends here

# HTML entities (elaborate vs ASCII) handled in getPara()

my ($w, $t, $paragraph, @lines, $indent, $end_y);
my ($textChoice, $x, $y, $vertical_size);

fresh_page();

# ---------- actual page content
my $widthHyphen = $text->advancewidth($split_hyphen);
$indent = $indentAmount * $text->advancewidth('M');

# create Knuth-Plass object, build line set with it
$t = Text::KnuthPlass->new(
    'indent' => $indent,
    'measure' => sub { $text->advancewidth(shift) }, 
    'linelengths' => [$lineWidth]
);

for ($textChoice=1; $textChoice < 4; $textChoice++) {
    $paragraph = getPara($textChoice);

    # want to fit entire paragraph on one page
    if ($textChoice == 3) { fresh_page(); }

    @lines = $t->typeset($paragraph);
    dump_lines(@lines) if $line_dump;
    # output @lines to PDF, starting at $xleft, $ytop
    $end_y = write_paragraph(@lines);

    if ($do_margin_lines) { margin_lines(); }
    $ytop = $end_y;

    $end_y -= 2 * $font_size*$leading;
    $ytop = $end_y;
} 

# first three lines break as desired, then it doesn't match sample
# (which I don't know if it was produced with the TeX KP algorithm).

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

# Needs own $lineWidth to precisely control line breaks, and
# possibly its own $font_size, too. We want to break as indicated in
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
"Humphrey Bogart muddled through in "
;
  # italicize The African Queen although it has no real effect here
  # just end at "through in", and if enough space left, change to
  #   italic font and use $text->text() to write.
my $ital = "The African Queen.";
 
$lineWidth -= 15;
@lines = $t->typeset($paragraph, 'linelengths' => [$lineWidth]);
dump_lines(@lines) if $line_dump;
# output @lines to PDF, starting at $xleft, $ytop
$end_y = write_paragraph(@lines);

# add italicized content at $x + one space, position by eyeball. should be on
# last line, so spaces should be normal size
$text->font($fontI, $font_size);
$text->translate( 64, $end_y+$font_size*$leading);
$text->text($ital);

if ($do_margin_lines) { margin_lines(); }
$ytop = $end_y;

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
    my $oelig = "\x{153}";  # oe ligature
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
    "That double-dot you see above some letters ${mdash} they${rsquo}re the ".
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
    return;
}

# --------------------------
# write_paragraph(@lines)
# if y goes below ybot, start new page and finish paragraph
# does NOTHING to check for widows and orphans!
sub write_paragraph {
    my (@lines) = @_;

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
       #my $line_str = '';
	my $ratio = $line->{'ratio'};
        $x = $xleft;
        print "========== new line @ $x,$y ==============\n" if $line_dump;
	$x += $indent; # done separately so debug shows valid $x
	$indent = 0;

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
        for my $node (@{$line->{'nodes'}}) {
            $text->translate($x,$y);
            if ($node->isa("Text::KnuthPlass::Box")) {
                $text->text($node->value());
                $x += $node->width();
            } elsif ($node->isa("Text::KnuthPlass::Glue")) {
                $x += ($node->width() - $reduceGlue) + $line->{'ratio'} *
	        (($raggedRight)? 1:
                    ($line->{'ratio'} < 0 ? $node->shrink() : $node->stretch()));
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
    } # end of handling line element
    return $y;
} # end of write_paragraph()

# --------------------------
sub margin_lines {   # called at end of a paragraph. can't handle breaking
	             # paragraph at end-page (TBD)

   #if (!$do_margin_lines) { return; }

    # draw left and right margin lines
    $grfx->strokecolor("red");
    $grfx->linewidth(0.5);
    $grfx->poly($xleft,$ytop+$font_size, 
	        $xleft,$end_y);
    $grfx->poly($xleft+$lineWidth,$ytop+$font_size, 
	        $xleft+$lineWidth,$end_y);
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

