#!/usr/bin/Perl
# derived from Synopsis example in KnuthPlass.pm
# REQUIRES PDF::Builder and Text::Hyphen
# TBD: command-line selection of line width, which text to format, perhaps
#      choice of font and font size
use strict;
use warnings;
use PDF::Builder;
use Text::KnuthPlass;

my $outfile = 'KP';
my $pdf = PDF::Builder->new(-compress => 'none');
my $page = $pdf->page();
my $grfx = $page->gfx();
my $text = $page->text();
my $font = $pdf->ttfont("/Windows/Fonts/arial.ttf");
#my $font = $pdf->ttfont("/Windows/Fonts/times.ttf");
#my $font = $pdf->corefont("Helvetica-Bold");

my $textChoice = 1;  # see getPara() at bottom, for choices of sample text
my $raggedRight = 0; # 0 = flush right, 1 = ragged right
my $lineWidth = 300; # Points
my $indentAmount = 2; # ems to indent first line of paragraph. - outdents
# upper left corner of paragraph
my $ytop = 500;
my $xleft = 50;
my $font_size = 12;
my $leading = 1.125; # leading will be 9/8 of the font size
my $split_hyphen = '-';  # TBD check if U+2010 narrow hyphen is available
                         # once font is selected

$text->font($font, $font_size);
$text->lead($font_size * $leading);

my $indent = $indentAmount * $text->advancewidth('M');
my $widthHyphen = $text->advancewidth($split_hyphen);
my $paragraph = getPara($textChoice);

# create Knuth-Plass object, build line set with it
my $t = Text::KnuthPlass->new(
    measure => sub { $text->advancewidth(shift) }, 
    linelengths => [$lineWidth-$indent, $lineWidth]  # indented, non-indented
      # could also handle non-rectangular paragraphs, such as with asides,
      # inserts, images, etc. space cut out of paragraph
);

my @lines = $t->typeset($paragraph);
# --------------
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
# --------------

# output @lines to PDF, starting at $xleft, $ytop
my $x;
my $y = $ytop;

for my $line (@lines) {
    $x = $xleft + $indent; 
    print "========== new line @ $x,$y ==============\n";
    $indent = 0;

    # how much to reduce each glue due to adding hyphen at end
    # According to Knuth-Plass article, some designers prefer to have
    #   punctuation (including the word-splitting hyphen) hang over past the
    #   right margin (as the original code did here). However, other
    #   punctuation did NOT hang over, so that would need some work to separate
    #   out line-end punctuation and giving the box a zero width.
    # TBD: if split on a hard hyphen (such as right-hand), a new hyphen is 
    #   added at the end, giving "right--" at the end of the line!
    my $reduceGlue = 0;
    my $useSplitHyphen = 0;
    if ($line->{'nodes'}[-1]->is_penalty()) { 
	# last word in line is split (hyphenated). node[-2] must be a Box?
	my $lastChar = '';
        if ($line->{'nodes'}[-2]->isa("Text::KnuthPlass::Box")) {
	    $lastChar = substr($line->{'nodes'}[-2]->value(), -1, 1);
	    # TBD expand check to all manner of hyphens and dashes
            if ($lastChar eq '-') {
		# fragment already ends with hyphen, so don't add one
		$useSplitHyphen = 0;
	    } else {
                # hyphen added to end of fragment, so reduce glue width
		$useSplitHyphen = 1;
	        my $number_glues = 0;
	        for my $node (@{$line->{'nodes'}}) {
	            if ($node->isa("Text::KnuthPlass::Glue")) { $number_glues++; }
	        }
	        # TBD if no glues in this line, or if reduction amount makes glue
	        # too close to 0 in width, have to do something else!
	        if ($number_glues) {
	            $reduceGlue = $widthHyphen / $number_glues;
	        }
	    }
	}
    }

    # one line of output
    # each node is a box (text) or glue (variable-width space)...ignore penalty
    # output each text and space node in the line
    for my $node (@{$line->{'nodes'}}) {
        $text->translate($x,$y);
        if ($node->isa("Text::KnuthPlass::Box")) {
            $text->text($node->value());
            $x += $node->width();
        } elsif ($node->isa("Text::KnuthPlass::Glue")) {
            $x += ($node->width() - $reduceGlue) + $line->{'ratio'} *
	    (($raggedRight)? 1:
                ($line->{'ratio'} < 0 ? $node->shrink() : $node->stretch()));
        }
    }
    # add hyphen to text ONLY if fragment didn't already end with some
    # sort of hyphen or dash (TBD: only '-' handled here)
    if ($useSplitHyphen) {
	$text->text($split_hyphen); 
    }
    $y -= $text->lead();  # next line down
}
# --------------------------
print "\nThere are ".scalar(@lines)." lines to output, occupying ";
# leading amount (font size * $leading) * number of lines also works
my $vertical_size = $ytop - $y;
print "$vertical_size points vertical space.\n";

# draw left and right margin lines
$grfx->strokecolor("red");
$grfx->linewidth(0.5);
$grfx->poly($xleft,$ytop+$font_size, $xleft,$y+$font_size);
$grfx->poly($xleft+$lineWidth,$ytop+$font_size, $xleft+$lineWidth,$y+$font_size);
$grfx->stroke();

$pdf->saveas("$outfile.pdf");

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
    "shone in her face. Close by the king’s castle lay a great dark forest, ".
    "and under an old lime-tree in the forest was a well, and when the day ".
    "was very warm, the king’s child went out into the forest and sat down ".
    "by the side of the cool fountain; and when she was bored she took a ".
    "golden ball, and threw it up on high and caught it; and this ball was ".
    "her favorite plaything.".
    ""; }

  if ($choice == 2) {
    # 2. a paragraph from page 16 of the Knuth-Plass article
    # note that at lineWidth=300, "right-hand" is split at the "-"
    return
    "Some people prefer to have the right edge of their text look ‘solid’, ".
    "by setting periods, commas, and other punctuation marks (including ".
    "inserted hyphens) in the right-hand margin. For example, this practice ".
    "is occasionally used in contemporary advertising. It is easy to get ".
    "inserted hyphens into the margin: We simply let the  width of the ".
    "corresponding penalty item be zero. And it is almost as easy to do the ".
    "same for periods and other symbols, by putting every such character in a ".
    "box of width zero and adding the actual symbol width to the glue that ".
    "follows. If no break occurs at this glue, the accumulated width is the ".
    "same as before; and if a break does occur, the line will be justified ".
    "as if  the period  or other symbol were not  present.".
    ""; }

  if ($choice == 3) {
    # 3. from a forum post of mine
    # note that at lineWidth=265 or so, there should be a split after the 
    # em-dash, but it refuses to split there (TBD)
    return
    "That double-dot you see above some letters\x{2014}they're the same ".
    "thing, right? No! Although they look the same, the two are actually very ".
    "different, and not at all interchangeable. An umlaut is used in Germanic ".
    "languages, and merely means that the primary vowel (a, o, or u) is ".
    "followed by an e. It is a shorthand for (initially) handwriting: \xE4 is ".
    "more or less interchangeable with ae (not to be confused with the \xE6 ".
    "ligature), \xF6 is oe (again, not \x{0153}), and ü is ue. This, of course, ".
    "changes the pronunciation of the vowel, just as adding an e to an ".
    "English word (at the end) shifts the vowel sound (e.g., mat to mate). ".
    "Some word spellings, especially for proper names, may prefer one or the ".
    "other form (usually _e). Whether to use the umlaut form or the ".
    "two-letter form is usually an arbitrary choice in electronic ".
    "typesetting, unless the chosen font lacks the umlaut form (as well as a ".
    "combining \"dieresis\" character). It is more common in English-language ".
    "cold metal typesetting to lack the umlaut form, and require the ".
    "two-letter form. See also thorn and \"ye\", where the \"e\" was ".
    "originally written as a superscript to the thorn (\xFE).".
    ""; }

}
