#!/usr/bin/Perl
# stolen from bramstein/typset (JS source of Text::KnuthPlass) package
# REQUIRES PDF::Builder and Text::Hyphen (builds PDF output)
# Note that the code is not terribly robust, e.g., if a paragraph spills over
#   to the next page, any image within that paragraph will not be properly
#   placed. Therefore there is a lot of hand-tuning on placing images.
# TBD: command-line selection of line width
#      Outdented paragraph example
# TBD: pass indent value, create box (space) with that width. then can
#     pass normal length lines in list. also pass scalar 'linelength' to use
#       if list is empty
#     HOW best to span short line list across multiple paragraphs? w/o manual 
#       update
#     can we just set globals once in new() and keep reusing $t with repeated
#       calls to $t->typeset()? have indent=>0 override at section start
#       as well as a new call for line lengths array?
#     a "last line on page" to show where paragraph is expected to be split
#
# TBD: not yet complete, shows XS problem with line-length array (TBF)
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
my $outfile = 'T_Flatland';
my $const = 0; # subtract from lineWidth to allow room for added hyphen
               # 0 for proportional font, 1 for text file, pts for const. width
	       # IGNORED for now, needs fixing
my $line_dump = 0;  # debug related
my $raggedRight = 0; # 0 = flush right, 1 = ragged right
my $indentAmount = 2; # chars to indent first line of paragraph, except first
#                       in a section. - outdents upper left corner of paragraph
my $split_hyphen = '-';  # can't use non-ASCII characters

my $vmargin = 2; # top and bottom margins
my $xleft = 5;
my @pageDim = (0,0, 80,66);

my ($page, $ytop, $inset_list);
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
my ($w, $t, $paragraph, @lines, $end_y);

my $full_indent = $indentAmount * 1; # e.g., 2 ems
my $widthHyphen = 1;

fresh_page();

# create Knuth-Plass object, build line set with it
$t = Text::KnuthPlass->new(
    'measure' => sub { length(shift) },
    'linelengths' => [$lineWidth],
    'indent' => $full_indent,
    'space' => { 'width' => 3, 'stretch' => 6, 'shrink' => 0 },
);

# ---------- actual page content
# headings and such, in the 19th century style
text_center("FLATLAND.");  # <h1>
text_center("---------");  # <hr>
text_center("PART I.");  # <h3>
text(" ");
text_center("THIS WORLD.");  # <h2>
# don't forget that blank lines have to be explicitly written out, can't
# just decrement $ytop!

text_center(" ");
text_center("${sect} 1. ${mdash} Of the Nature of Flatland."); # <h3>
text_center(" ");

# now for the body text. note that first paragraph of a section NOT indented

# ---- <p>
# $ytop already set in fresh_page(), and decremented in text*()
$paragraph = "I call our world Flatland, not because we call it so, but to make its nature clearer to you, my happy readers, who are privileged to live in Space.";

# split up the paragraph's lines, start writing on this page, may continue.
# override: no indent at section start
@lines = $t->typeset($paragraph, 'indent' => 0);
dump_lines(@lines);
# output @lines to file, starting at $xleft, $ytop
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
# image_png('examples/resources/Figure-1.png');

# calculate lineLengths array from position and size and margins of image
$inset_list = space_for_image($lineWidth, 14, 15, 1, 1, 0, 1, 1, 4);

$ytop = $end_y;
$paragraph = "The same thing would happen if you were to treat in the same way a Triangle, or Square, or any other figure cut out of pasteboard. As soon as you look at it with your eye on the edge on the table, you will find that it ceases to appear to you a figure, and that it becomes in appearance a straight line. Take for example an equilateral Triangle $mdash who represents with us a Tradesman of the respectable class. Fig. 1 represents the Tradesman as you would see him while you were bending over him from above; figs. 2 and 3 represent the Tradesman, as you would see him if your eye were close to the level, or all but on the level of the table; and if your eye were quite on the level of the table (and that is how we see him in Flatland) you would see nothing but a straight line.";

@lines = $t->typeset($paragraph, 'linelengths' => $inset_list);
dump_lines(@lines);
# output @lines to PDF, starting at $xleft, $ytop
$end_y = write_paragraph(@lines);

# ---- <p>
# 2nd part of paragraph is narrower to accomodate Fig-1. 
# whatever is left of line lengths list gets used in subsequent calls

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

# ---- new section titles
# headings and such, in the 19th century style
# <h3>
text(" ");
text_center("${sect} 2. ${mdash} Of the Climate and Houses in Flatland.");
text(" ");

# now for the body text. note that first paragraph of a section NOT indented

# ---- <p>
# $ytop set already, inherited from prev section plus text*() decrements
$paragraph = "As with you, so also with us, there are four points of the compass North, South, East, and West.";

# section start, so 0 indentation
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
# image_png('examples/resources/Figure-2.png');

# calculate lineLengths array from position and size and margins of image
$inset_list = space_for_image($lineWidth, 24, 10, 1, 1, 0, 1, 1, 0);
# this is last paragraph, but if there were more, they would inherit the
# remainder of the lineLengths array

$ytop = $end_y;
$paragraph = "At this period, square houses were still everywhere permitted, though discouraged by a special tax. But, about three centuries afterwards, the Law decided that in all towns containing a population above ten thousand, the angle of a Pentagon was the smallest house-angle that could be allowed consistently with the public safety. The good sense of the community has seconded the efforts of the Legislature; and now, even in the country, the pentagonal construction has superseded every other. It is only now and then in some very remote and backward agricultural district that an antiquarian may still discover a square house.";

@lines = $t->typeset($paragraph, 'linelengths' => $inset_list);
dump_lines(@lines);
# output @lines to PDF, starting at $xleft, $ytop
$end_y = write_paragraph(@lines);

# ---- do once at very end
$end = 1;
fresh_page();
close $page;

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

