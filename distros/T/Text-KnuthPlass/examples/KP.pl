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

my $raggedRight = 0; # 0 = flush right, 1 = ragged right
my $lineWidth = 300; # Points
my $indentAmount = 2; # ems to indent first line of paragraph. - outdents
# upper left corner of paragraph
my $ytop = 500;
my $xleft = 50;
my $font_size = 12;
my $leading = 1.125; # leading will be 9/8 of the font size

$text->font($font, $font_size);
$text->lead($font_size * $leading);

my $indent = $indentAmount * $text->advancewidth('M');
my $widthHyphen = $text->advancewidth('-');
my $paragraph = getPara();

# create Knuth-Plass object, build line set with it
my $t = Text::KnuthPlass->new(
    measure => sub { $text->advancewidth(shift) }, 
    linelengths => [$lineWidth-$indent, $lineWidth]  # indented, non-indented
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
    if ($line->{nodes}[-1]->is_penalty) { 
        # hyphen added to end, so reduce glue width
	my $number_glues = 0;
	for my $node (@{$line->{nodes}}) {
	    if ($node->isa("Text::KnuthPlass::Glue")) { $number_glues++; }
	}
	# TBD if no glues in this line, or if reduction amount makes glue
	# too close to 0 in width, have to do something else!
	if ($number_glues) {
	    $reduceGlue = $widthHyphen / $number_glues;
	}
    }

    for my $node (@{$line->{nodes}}) {
        $text->translate($x,$y);
        if ($node->isa("Text::KnuthPlass::Box")) {
            $text->text($node->value);
            $x += $node->width;
        } elsif ($node->isa("Text::KnuthPlass::Glue")) {
            $x += ($node->width - $reduceGlue) + $line->{ratio} *
	    (($raggedRight)? 1:
                ($line->{ratio} < 0 ? $node->shrink : $node->stretch));
        }
    }
    if ($line->{nodes}[-1]->is_penalty) { $text->text("-") }
    $y -= $text->lead();
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
  my $choice = 2; # 1, 2,...

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

}
