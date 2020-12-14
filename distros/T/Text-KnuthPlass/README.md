# Text-KnuthPlass

'Text::KnuthPlass' is a Perl and XS (C) implementation of the well-known TeX
paragraph-shaping (a.k.a. line-breaking) algorithm, as created by Donald E.
Knuth and Michael F. Plass in 1981.

Given a long string containing the text of a paragraph, this module decides
where to split a line (possibly hyphenating a word in the process), while
attempting to:

* maintain fairly consistent text "tightness"
* minimize hyphenation overall
* not have two or more hyphenated lines in a row
* not have entire words "floating" over the next line
* not hyphenate the penultimate line

What it **doesn't** do:

* attempt to avoid widows and orphans. This is the job of the calling routine, as 'Text::KnuthPlass' doesn't know how much of the paragraph fits on this page (or column) and how much has to be spilled to the next page or column.
* attempt to avoid hyphenating the last word of the last line of a _split_ paragraph on a page or column (as before, it doesn't know where you're going to be splitting the paragraph between columns or pages).

The Knuth-Plass algorithm does this by defining "boxes", "glue", and
"penalties" for the paragraph text, and fiddling with line break points to
minimize the overall sum of penalties. This can result in the "breaking" of one
or more of the listed rules, if it results in an overall better score ("better
looking" layout).

`Text::KnuthPlass` handles word widths by either character count, or a user-
supplied width function (such as based on the current font and font size). It
can also handle varying-length lines, if your column is not a perfect rectangle.

## Installation

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

## Documentation

After installation, documentation can be found via

    perldoc Text::KnuthPlass

or

    pod2html lib/Text/KnuthPlass.pm > KnuthPlass.html

## Support

Bug tracking is via

    "https://github.com/PhilterPaper/Text-KnuthPlass/issues?q=is%3Aissue+sort%3Aupdated-desc+is%3Aopen"

(you will need a GitHub account to create or contribute to a discussion, but
anyone can read tickets.) If you do not have a GitHub account, we can accept
the occasional email (pmperry at cpan.org) or via _Post without Account_ at

    "https://www.catskilltech.com/forum/index.html"

Please do not abuse these email-based support offerings. If you are going to
be asking questions or making bug reports more than once in a blue moon,
please register at github.com -- it's free.

## License

This product is licensed under the Perl license. You may redistribute under
the GPL license, if desired, but you will have to add a copy of that license
to your distribution, per its terms.

## An Example

Find this file in `examples/KP.pl`. It assumes that Text::Hyphen is installed.

    # derived from Synopsis example in KnuthPlass.pm
    use strict;
    use warnings;
    use PDF::Builder;
    use Text::KnuthPlass;

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

        for my $node (@{$line->{nodes}})
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

    $pdf->saveas("KP.pdf");

    sub getPara {
      my $choice = 2; # 1, 2,...

      if ($choice == 1) {
        # 1. a paragraph from "The Frog King" (Brothers Grimm)
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
        "";
      }

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
        "";
      }
    }
