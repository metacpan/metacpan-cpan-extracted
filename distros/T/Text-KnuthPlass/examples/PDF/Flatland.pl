#!/usr/bin/Perl
# stolen from bramstein/typset (JS source of Text::KnuthPlass) package
# REQUIRES PDF::Builder and Text::Hyphen (builds PDF output)
# Note that the code is not terribly robust, e.g., if a paragraph spills over
#   to the next page, any image within that paragraph will not be properly
#   placed. Therefore there is a lot of hand-tuning on placing images.
# TBD: command-line selection of line width, which text to format, perhaps
#      choice of font and font size
#      Dropped Caps example: 2 or 3 short lines with indent depending on
#        dropped cap, "manual" move line start to right (can't use empty Box?)
# TBD pass indent value, create box (space) with that width. then can
#     pass normal length lines in list. also pass scalar 'linelength' to use
#       if list is empty
#     HOW best to span short line list across multiple paragraphs? w/o manual update
#     can we just set globals once in new() and keep reusing $t with repeated
#       calls to $t->typeset()? have indent=>0 override at section start
#       as well as a new call for line lengths array?
#     a "last line on page" to show where paragraph is expected to be split
#
# WARNING: not yet complete, shows XS problem with line-length array (TBF)
# NOTE: Javascript version indents by gluing a 30px wide empty box to the
#         start of a paragraph (but not the first in a section)
#       <img> in JS done at top of a paragraph, and N lines (N based on height
#         of image) pushed onto any existing line length list, with width 
#         reduction figured from image width. of course, needs a working LL!
#         Pure Perl LL is working, just XS needs fix
# compare to bramstein/typset examples/flatland/index.html
# compare to                  #22 bad line-breaking
# 
use strict;
use warnings;
use PDF::Builder;
use Text::KnuthPlass;
use POSIX qw/ceil/;

# flag to replace fancy punctuation by ASCII characters
my $use_ASCII = 0;
# force use of pure Perl code
my $purePerl = 1; # 0: use XS, 1: use Perl  DOESN'T WORK

my $outfile = 'Flatland';
my $line_dump = 0;  # debug related
my $do_margin_lines = 0;  # debug related
my $raggedRight = 0; # 0 = flush right, 1 = ragged right
my $indentAmount = 2; # ems to indent first line of paragraph. - outdents
#                       upper left corner of paragraph
#my $split_hyphen = '-';  # TBD check if U+2010 narrow hyphen is available
#                         # once font is selected
my $split_hyphen = "\x{2010}";

my $pdf = PDF::Builder->new('compress' => 'none');
my @pageDim = $pdf->mediabox();
my ($page, $grfx, $text, $ytop);

#my $font = $pdf->ttfont("/Windows/Fonts/arial.ttf");
#my $font = $pdf->corefont("Helvetica-Bold");
my $font  = $pdf->ttfont("/Windows/Fonts/times.ttf");
my $fontI = $pdf->ttfont("/Windows/Fonts/timesi.ttf");

my $vmargin = 100; # top and bottom margins
my $xleft = 95;
my $font_size = 13;
my $leading = 1.5; # leading will be 3/2 of the font size

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

my $lineWidth = $pageDim[2]-2*$xleft; # Points, left margin = right margin
my ($w, $t, $paragraph, @lines, $indent, $end_y);

fresh_page();

my $full_indent = $indentAmount * $text->advancewidth('M'); # e.g., 2 ems
my $widthHyphen = $text->advancewidth($split_hyphen);

# create Knuth-Plass object, build line set with it
$t = Text::KnuthPlass->new(
    'indent' => $full_indent,
    'measure' => sub { $text->advancewidth(shift) },
    'linelengths' => [$lineWidth]
);

# ---------- actual page content
# this starts fresh page, so presumably no need to check if first two lines
#   of first paragraph PLUS all the titles and headers fit
# headings and such, in the 19th century style
$text->font($fontI, $font_size*2);  # <h1>
$text->translate($xleft + $lineWidth/2, $ytop);
$w = $text->text_center("FLATLAND.");

$ytop -= 1.2 * $leading * $font_size*2;
$grfx->move($xleft + ($lineWidth-$w)/2, $ytop);  # <hr>
$grfx->hline($xleft + ($lineWidth-$w)/2 + $w);
$grfx->stroke();

$ytop -= 1.5 * $leading * $font_size*2;
$text->font($font, $font_size*1.4);  # <h3>
$text->translate($xleft + $lineWidth/2, $ytop);
$w = $text->text_center("PART I.");

$ytop -= 1.5 * $leading * $font_size*1.4;
$text->font($font, $font_size*1.6);  # <h2>
$text->translate($xleft + $lineWidth/2, $ytop);
$w = $text->text_center("THIS WORLD.");

$ytop -= 2.1 * $leading * $font_size*1.6;
$text->font($font, $font_size*1.4);  # <h3>
# want italic to start with "Of", so need to change font in middle of
# centered text, so fake the centering
my $left_text = "${sect} 1. ${mdash} ";
my $right_text = "Of the Nature of Flatland.";
my $len_left = $text->advancewidth($left_text);
$text->font($fontI, $font_size*1.4);  # <h3>
my $len_right = $text->advancewidth($right_text);
$text->translate($xleft + ($lineWidth - $len_left - $len_right)/2, $ytop);
$text->font($font, $font_size*1.4);  # <h3>
$w = $text->text($left_text);
$text->font($fontI, $font_size*1.4);  # <h3>
$w = $text->text($right_text);

$ytop -= 1.5 * $leading * $font_size*1.4;
# now for the body text. note that first paragraph of a section NOT indented
$text->font($font, $font_size);
$text->leading($font_size * $leading);

# ---- <p>
# $ytop already set
$paragraph = "I call our world Flatland, not because we call it so, but to make its nature clearer to you, my happy readers, who are privileged to live in Space.";

# split up the paragraph's lines, start writing on this page, may continue.
# override indent at section start
@lines = $t->typeset($paragraph, 'indent' => 0);
dump_lines(@lines);
# output @lines to PDF, starting at $xleft, $ytop
$end_y = write_paragraph(@lines);

# ---- <p>
$ytop = $end_y;
$paragraph = "Imagine a vast sheet of paper on which straight Lines, Triangles, Squares, Pentagons, Hexagons, and other figures, instead of remaining fixed in their places, move freely about, on or in the surface, but without the power of rising above or sinking below it, very much like shadows $mdash only hard and with luminous edges $mdash and you will then have a pretty correct notion of my country and countrymen. Alas, a few years ago, I should have said ${ldquo}my universe;${rdquo} but now my mind has been opened to higher views of things.";

@lines = $t->typeset($paragraph);
dump_lines(@lines);
# output @lines to PDF, starting at $xleft, $ytop
$end_y = write_paragraph(@lines);

# ---- <p>
$ytop = $end_y;
$paragraph = "In such a country, you will perceive at once that it is impossible that there should be anything of what you call a ${ldquo}solid${rdquo} kind; but I dare say you will suppose that we could at least distinguish by sight the Triangles, Squares, and other figures, moving about as I have described them. On the contrary, we could see nothing of the kind, not at least so as to distinguish one figure from another. Nothing was visible, nor could be visible, to us, except Straight Lines; and the necessity of this I will speedily demonstrate.";

@lines = $t->typeset($paragraph);
dump_lines(@lines);
# output @lines to PDF, starting at $xleft, $ytop
$end_y = write_paragraph(@lines);

# ---- <p>
$ytop = $end_y;
$paragraph = "Place a penny on the middle of one of your tables in Space; and leaning over it, look down upon it. It will appear a circle.";

@lines = $t->typeset($paragraph);
dump_lines(@lines);
# output @lines to PDF, starting at $xleft, $ytop
$end_y = write_paragraph(@lines);

# ---- <p>
$ytop = $end_y;
$paragraph = "But now, drawing back to the edge of the table, gradually lower your eye (thus bringing yourself more and more into the condition of the inhabitants of Flatland), and you will find the penny becoming more and more oval to your view; and at last when you have placed your eye exactly on the edge of the table (so that you are, as it were, actually a Flatlander) the penny will then have ceased to appear oval at all, and will have become, so far as you can see, a straight line.";

@lines = $t->typeset($paragraph);
dump_lines(@lines);
# output @lines to PDF, starting at $xleft, $ytop
$end_y = write_paragraph(@lines);

# ---- <p>
# insert Fig-1. 162x284 end_y is at 5th line of THIS paragraph
# and image is flush with paragraph's 5th line
my $img = $pdf->image_png('examples/resources/Figure-1.png');
$grfx->image($img, $xleft+$lineWidth-162,$end_y-284-4*$leading*$font_size, 
	     162,284);
# calculate lineLengths array from position and size and margins of image
my $narrowed = space_for_image($lineWidth, 162, 284,
	                       40, 10, 0, 10, $leading*$font_size, 4);

$ytop = $end_y;
$paragraph = "The same thing would happen if you were to treat in the same way a Triangle, or Square, or any other figure cut out of pasteboard. As soon as you look at it with your eye on the edge on the table, you will find that it ceases to appear to you a figure, and that it becomes in appearance a straight line. Take for example an equilateral Triangle $mdash who represents with us a Tradesman of the respectable class. Fig. 1 represents the Tradesman as you would see him while you were bending over him from above; figs. 2 and 3 represent the Tradesman, as you would see him if your eye were close to the level, or all but on the level of the table; and if your eye were quite on the level of the table (and that is how we see him in Flatland) you would see nothing but a straight line.";

@lines = $t->typeset($paragraph, 'linelengths' => $narrowed);
dump_lines(@lines);
# output @lines to PDF, starting at $xleft, $ytop
$end_y = write_paragraph(@lines);

# ---- <p>
# 1st part of paragraph is narrower to accomodate Fig-1. 

$ytop = $end_y;
$paragraph = "When I was in Spaceland I heard that your sailors have very similar experiences while they traverse your seas and discern some distant island or coast lying on the horizon. The far-off land may have bays, forelands, angles in and out to any number and extent; yet at a distance you see none of these (unless indeed your sun shines bright upon them revealing the projections and retirements by means of light and shade), nothing but a grey unbroken line upon the water.";

@lines = $t->typeset($paragraph);
dump_lines(@lines);
# output @lines to PDF, starting at $xleft, $ytop
$end_y = write_paragraph(@lines);

# ---- <p>
$ytop = $end_y;
$paragraph = "Well, that is just what we see when one of our triangular or other acquaintances comes toward us in Flatland. As there is neither sun with us, nor any light of such a kind as to make shadows, we have none of the helps to the sight that you have in Spaceland. If our friend comes closer to us we see his line becomes larger; if he leaves us it becomes smaller: but still he looks like a straight line; be he a Triangle, Square, Pentagon, Hexagon, Circle, what you will $mdash a straight Line he looks and nothing else. You may perhaps ask how under these disadvantageous circumstances we are able to distinguish our friends from one another: but the answer to this very natural question will be more fitly and easily given when I come to describe the inhabitants of Flatland. For the present let me defer this subject, and say a word or two about the climate and houses in our country.";

@lines = $t->typeset($paragraph);
dump_lines(@lines);
# output @lines to PDF, starting at $xleft, $ytop
$end_y = write_paragraph(@lines);

$ytop = $end_y - 1.5 * $leading * $font_size*1.4;
# ---- new section titles
# headings and such, in the 19th century style
$text->font($font, $font_size*1.4);  # <h3>
# want italic to start with "Of", so need to change font in middle of
# centered text, so fake the centering
$left_text = "${sect} 2. ${mdash} ";
$right_text = "Of the Climate and Houses in Flatland.";
$len_left = $text->advancewidth($left_text);
$text->font($fontI, $font_size*1.4);  # <h3>
$len_right = $text->advancewidth($right_text);
$text->translate($xleft + ($lineWidth - $len_left - $len_right)/2, $ytop);
$text->font($font, $font_size*1.4);  # <h3>
$w = $text->text($left_text);
$text->font($fontI, $font_size*1.4);  # <h3>
$w = $text->text($right_text);

$ytop -= 1.5 * $leading * $font_size*1.4;
# now for the body text. note that first paragraph of a section NOT indented
$text->font($font, $font_size);
$text->leading($font_size * $leading);

# ---- <p>
# $ytop set already
$paragraph = "As with you, so also with us, there are four points of the compass North, South, East, and West.";

@lines = $t->typeset($paragraph, 'indent' => 0);
dump_lines(@lines);
# output @lines to PDF, starting at $xleft, $ytop
$end_y = write_paragraph(@lines);

# ---- <p>
$ytop = $end_y;
$paragraph = "There being no sun nor other heavenly bodies, it is impossible for us to determine the North in the usual way; but we have a method of our own. By a Law of Nature with us, there is a constant attraction to the South; and, although in temperate climates this is very slight $mdash so that even a Woman in reasonable health can journey several furlongs northward without much difficulty $mdash yet the hampering effect of the southward attraction is quite sufficient to serve as a compass in most parts of our earth. Moreover, the rain (which falls at stated intervals) coming always from the North, is an additional assistance; and in the towns we have the guidance of the houses, which of course have their side-walls running for The most part North and South, so that the roofs may keep off the rain from the North. In the country, where there are no houses, the trunks of the trees serve as some sort of guide. Altogether, we have not so much difficulty as might be expected in determining our bearings.";

@lines = $t->typeset($paragraph);
dump_lines(@lines);
# output @lines to PDF, starting at $xleft, $ytop
$end_y = write_paragraph(@lines);

# ---- <p>
$ytop = $end_y;
$paragraph = "Yet in our more temperate regions, in which the southward attraction is hardly felt, walking sometimes in a perfectly desolate plain where there have been no houses nor trees to guide me, I have been occasionally compelled to remain stationary for hours together, waiting till the rain came before continuing my journey. On the weak and aged, and especially on delicate Females, the force of attraction tells much more heavily than on the robust of the Male Sex, so that it is a point of breeding, if you meet a Lady in the street, always to give her the North side of the way $mdash by no means an easy thing to do always at short notice when you are in rude health and in a climate where it is difficult to tell your North from your South.";

dump_lines(@lines);
# output @lines to PDF, starting at $xleft, $ytop
$end_y = write_paragraph(@lines);

# ---- <p>
$ytop = $end_y;
$paragraph = "Windows there are none in our houses: for the light comes to us alike in our homes and out of them, by day and by night, equally at all times and in all places, whence we know not. It was in old days, with our learned men, an interesting and oft-investigated question, ${ldquo}What is the origin of light?$rdquo and the solution of it has been repeatedly attempted, with no other result than to crowd our lunatic asylums with the would-be solvers. Hence, after fruitless attempts to suppress such investigations indirectly by making them liable to a heavy tax, the Legislature, in comparatively recent times, absolutely prohibited them. I $mdash alas; I alone in Flatland $mdash know now only too well the true solution of this mysterious problem; but my knowledge cannot be made intelligible to a single one of my countrymen; and I am mocked at $mdash I, the sole possessor of the truths of Space and of the theory of the introduction of Light from the world of three Dimensions $mdash as if I were the maddest of the mad! But a truce to these painful digressions: let me return to our houses.";

@lines = $t->typeset($paragraph);
dump_lines(@lines);
# output @lines to PDF, starting at $xleft, $ytop
$end_y = write_paragraph(@lines);

# ---- <p>
$ytop = $end_y;
$paragraph = "The most common form for the construction of a house is five-sided or pentagonal, as in the annexed figure. The two Northern sides RO, OF, constitute the roof, and for the most part have no doors; on the East is a small door for the Women; on the West a much larger one for the Men; the South side or floor is usually doorless.";

@lines = $t->typeset($paragraph);
dump_lines(@lines);
# output @lines to PDF, starting at $xleft, $ytop
$end_y = write_paragraph(@lines);

# ---- <p>
$ytop = $end_y;
$paragraph = "Square and triangular houses are not allowed, and for this reason. The angles of a Square (and still more those of an equilateral Triangle,) being much more pointed than those of a Pentagon, and the lines of inanimate objects (such as houses) being dimmer than the lines of Men and Women, it follows that there is no little danger lest the points of a square or triangular house residence might do serious injury to an inconsiderate or perhaps absent-minded traveller suddenly therefore, running against them: and as early as the eleventh century of our era, triangular houses were universally forbidden by Law, the only exceptions being fortifications, powder-magazines, barracks, and other state buildings, which it is not desirable that the general public should approach without circumspection.";

@lines = $t->typeset($paragraph);
dump_lines(@lines);
# output @lines to PDF, starting at $xleft, $ytop
$end_y = write_paragraph(@lines);

# ---- <p>
# insert Fig-2. 257x250 end_y is at line 1 of THIS paragraph
# image is flush with the top of this paragraph
$img = $pdf->image_png('examples/resources/Figure-2.png');
$grfx->image($img, $xleft+$lineWidth-257,$end_y-250-0*$leading*$font_size, 
	     257,250);
# calculate lineLengths array from position and size and margins of image
$narrowed = space_for_image($lineWidth, 257, 250,
                            40, 10, 0, 10, $leading*$font_size, 0);

$ytop = $end_y;
$paragraph = "At this period, square houses were still everywhere permitted, though discouraged by a special tax. But, about three centuries afterwards, the Law decided that in all towns containing a population above ten thousand, the angle of a Pentagon was the smallest house-angle that could be allowed consistently with the public safety. The good sense of the community has seconded the efforts of the Legislature; and now, even in the country, the pentagonal construction has superseded every other. It is only now and then in some very remote and backward agricultural district that an antiquarian may still discover a square house.";

@lines = $t->typeset($paragraph, 'linelengths' => $narrowed);
dump_lines(@lines);
# output @lines to PDF, starting at $xleft, $ytop
$end_y = write_paragraph(@lines);

# ---- do once at very end
$pdf->saveas("$outfile.pdf");

# END

sub fresh_page {
    # set up a new page, with no content
    $page = $pdf->page();
    $grfx = $page->gfx();
    $text = $page->text();
    $ytop = $pageTop;
    # default font
    $text->font($font, $font_size);
    $text->leading($font_size * $leading);
    margin_lines();
    return;
}

sub space_for_image {
    # return an array reference containing the lengths need for the 
    # listlengths array in the new() method. $margin_r can be less than
    # zero to have the image stick out into the right margin
    # $start is number of full-length entries to stick at the beginning,
    #   as the image starts that many lines down
    my ($lineWidth, $img_w, $img_h,
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

    # TBD: widows and orphans check. assumes same leading for each
    #   if one line in @lines, OK. if two lines, check y-leading*2 < ybot 
    #   and if so, do fresh_page now. if three lines, check if all three can
    #   fit on this page and if not, fresh_page. if four or more lines, check
    #   if at least two can fit on this page.
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
        } # there IS a penalty on this line (split word)

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
	# TBD: widows and orphans. if two lines remaining to output, and
	#   room for one, fresh_page now.
	if ($y < $ybot) { 
	    fresh_page();
	    $y = $pageTop;
	}
    } # end of handling line element
    return $y;
} # end of write_paragraph()

# --------------------------
sub margin_lines {  # entire page less top, bottom margins

    if (!$do_margin_lines) { return; }

    # draw left and right margin lines
    $grfx->strokecolor("red");
    $grfx->linewidth(0.5);
    $grfx->poly($xleft,$pageDim[3]-$vmargin+$font_size, 
	        $xleft,$ybot);
    $grfx->poly($xleft+$lineWidth,$pageDim[3]-$vmargin+$font_size, 
	        $xleft+$lineWidth,$ybot);
    $grfx->stroke();
    return;
}

# --------------
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

# --------------
