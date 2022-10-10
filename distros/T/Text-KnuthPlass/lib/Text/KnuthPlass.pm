package Text::KnuthPlass;
require XSLoader;
use constant DEBUG => 0;
use constant purePerl => 0; # 1: do NOT load XS routines
use warnings;
use strict;
use List::Util qw/min/;

our $VERSION = '1.07'; # VERSION
our $LAST_UPDATE = '1.07'; # manually update whenever file is edited

use Data::Dumper;

# disable XS usage for debug, etc.
if (!purePerl) {
    eval { XSLoader::load("Text::KnuthPlass", $VERSION); } or die $@;
    # Or else there's a Perl version to fall back on
    #    does camelCase in Perl get automatically changed to camel_case?
    # _computeCost() in Perl vs _compute_cost() in XS
    # _computeSum() in Perl vs _compute_sum() in XS
    # _init_nodelist()
    # _cleanup()
    # _active_to_breaks()
    # _mainloop()
}

package Text::KnuthPlass::Element;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors("width");
sub new { 
    my $self = shift; 
    return bless { 'width' => 0, @_ }, $self; 
}
sub is_penalty { 
    return shift->isa("Text::KnuthPlass::Penalty"); 
}
sub is_glue { 
    return shift->isa("Text::KnuthPlass::Glue"); 
}
sub is_box { 
    return shift->isa("Text::KnuthPlass::Box"); 
}

package Text::KnuthPlass::Box; 
use base 'Text::KnuthPlass::Element';
__PACKAGE__->mk_accessors("value");

sub _txt { # different from other _txt() defs
    return "[".$_[0]->value()."/".$_[0]->width()."]"; 
}

package Text::KnuthPlass::Glue;
use base 'Text::KnuthPlass::Element';
__PACKAGE__->mk_accessors("stretch", "shrink");

sub new { 
    my $self = shift; 
    return $self->SUPER::new('stretch' => 0, 'shrink' => 0, @_);
}
sub _txt { # different from other _txt() defs
    return sprintf "<%.2f+%.2f-%.2f>", $_[0]->width(), $_[0]->stretch(), $_[0]->shrink(); 
}

package Text::KnuthPlass::Penalty;
use base 'Text::KnuthPlass::Element';
__PACKAGE__->mk_accessors("penalty", "flagged", "shrink");
sub new { 
    my $self = shift; 
    return $self->SUPER::new('flagged' => 0, 'shrink' => 0, @_);
}
sub _txt { # different from other _txt() defs
    return "(".$_[0]->penalty().($_[0]->flagged() &&"!").")"; 
}

package Text::KnuthPlass::Breakpoint;
use base 'Text::KnuthPlass::Element';
__PACKAGE__->mk_accessors(qw/position demerits ratio line fitnessClass totals previous/);

package Text::KnuthPlass::DummyHyphenator;
use base 'Class::Accessor';
sub hyphenate { 
    return $_[1]; 
}

package Text::KnuthPlass;
use base 'Class::Accessor';
use Carp qw/croak/;

# these settings are settable via new(%opts)
my %defaults = (
    'infinity' => 10000,
    'tolerance' => 30,  # maximum allowable ratio (way out of reasonable!)
    'hyphenpenalty' => 50,
    'demerits' => { 'line' => 10, 'flagged' => 100, 'fitness' => 3000 },
    'space' => { 'width' => 3, 'stretch' => 6, 'shrink' => 9 },
    'linelengths' => [ 78 ], # character count (fixed pitch)
    'measure' => sub { length $_[0] },
    'hyphenator' => 
        # TBD min_suffix 3 for English and many, but not all, languages. %opt
        eval { require Text::Hyphen }? Text::Hyphen->new('min_suffix' => 3):
                                       Text::KnuthPlass::DummyHyphenator->new(),
    'purePerl' => 0,  # 1: use pure Perl code, not XS CURRENTLY UNUSED
    'const' => 0,  # width (char or points) to reduce line length to allow
                   # for word-split hyphen without overflow into margin
		   # CURRENTLY UNUSED
    'indent' => 0, # global paragraph indentation width
);
__PACKAGE__->mk_accessors(keys %defaults);
sub new { 
    my $self = shift; 
    # hash elements in new() override whatever's in %default

    # tack on any new() overrides of defaults
    return bless {%defaults, @_}, $self;
}

=head1 NAME

Text::KnuthPlass - Breaks paragraphs into lines using the TeX (Knuth-Plass) algorithm

=head1 SYNOPSIS

To use with plain text, indentation of 2. NOTE that you should also
set the shrinkability of spaces to 0 in the new() call:

    use Text::KnuthPlass;
    my $typesetter = Text::KnuthPlass->new(
	'indent' => 2, # two characters,
        # set space shrinkability to 0
	'space' => { 'width' => 3, 'stretch' => 6, 'shrink' -> 0 },
	# can let 'measure' default to character count
	# default line lengths to 78 characters
    );
    my @lines = $typesetter->typeset($paragraph);
    ...

    for my $line (@lines) {
        for my $node (@{$line->{'nodes'}}) {
            if ($node->isa("Text::KnuthPlass::Box")) { 
	        # a Box is a word or word fragment (no hyphen on fragment)
                print $node->value();
            } elsif ($node->isa("Text::KnuthPlass::Glue")) {
	        # a Glue is (at least) a single space, but you can look at 
		# the line's 'ratio' to insert additional spaces to 
		# justify the line. we also are glossing over the skipping
		# of any final glue at the end of the line
                print " ";
            }
	    # ignoring Penalty (word split point) within line
        }
        if ($line->{'nodes'}[-1]->is_penalty()) { print "-"; }
        print "\n";
    }

To use with PDF::Builder: (also PDF::API2)

    my $text = $page->text();
    $text->font($font, 12);
    $text->leading(13.5);

    my $t = Text::KnuthPlass->new(
        'indent' => 2*$text->text_width('M'), # 2 ems
        'measure' => sub { $text->text_width(shift) }, 
        'linelengths' => [235]  # points
    );
    my @lines = $t->typeset($paragraph);

    my $y = 500;  # PDF decreases y down the page
    for my $line (@lines) {
        $x = 50;  # left margin
        for my $node (@{$line->{'nodes'}}) {
            $text->translate($x,$y);
            if ($node->isa("Text::KnuthPlass::Box")) {
	        # a Box is a word or word fragment (no hyphen on fragment)
                $text->text($node->value());
                $x += $node->width();
            } elsif ($node->isa("Text::KnuthPlass::Glue")) {
	        # a Glue is a variable-width space
                $x += $node->width() + $line->{'ratio'} *
                    ($line->{'ratio'} < 0 ? $node->shrink(): $node->stretch());
		# we also are glossing over the skipping
		# of any final glue at the end of the line
            }
	    # ignoring Penalty (word split point) within line
        }
	# explicitly add a hyphen at a line-ending split word
        if ($line->{'nodes'}[-1]->is_penalty()) { $text->text("-"); }
        $y -= $text->leading(); # go to next line down
    }

=head1 METHODS

=head2 $t = Text::KnuthPlass->new(%opts)

The constructor takes a number of options. The most important ones are:

=over 

=item measure

A subroutine reference to determine the width of a piece of text. This
defaults to C<length(shift)>, which is what you want if you're
typesetting plain monospaced text. You will need to change this to plug
into your font metrics if you're doing something graphical. For PDF::Builder
(also PDF::API2), this would be the C<advancewidth()> method (alias 
C<text_width()>), which returns the width of a string (in the present font 
and size) in points.

    'measure' => sub { length(shift) },  # default, for character output
    'measure' => sub { $text->advancewidth(shift) }, # PDF::Builder/API2

=item linelengths

This is an array of line lengths. For instance, C< [30,40,50] > will
typeset a triangle-shaped piece of text with three lines. What if the
text spills over to more than three lines? In that case, the final value
in the array is used for all further lines. So to typeset an ordinary
block-shaped column of text, you only need specify an array with one
value: the default is C< [78] >. Note that this default would be the 
character count, rather than points (as needed by PDF::Builder or PDF::API2).

    'linelengths' => [$lw, $lw, $lw-6, $lw-6, $lw],

This would set the first two lines in the paragraph to C<$lw> length, the next
two to 6 less (such as for a float inset), and finally back to full length.
At each line, the first element is consumed, but the last element is never
removed. Any paragraph indentation set will result in a shorter-appearing 
first line, which actually has blank space at its beginning. Start output of
the first line at the same C<x> value as you do the other lines.

Setting C<linelengths> in the C<new()> (constructor) call resets the internal
line length list to the new elements, overwriting anything that was already
there (such as any remaining line lengths left over from a previous C<typeset()> call). Subsequent C<typeset()> calls will continue to consume the existing
line length list, until the last element is reached. You can either reset the
list for the next paragraph with the C<typeset()> call, or call the
C<linelengths()> method to get or set the list.

=item indent

This sets the global (default) paragraph indentation, unless overridden 
on a per-paragraph basis by
an C<indent> entry in a C<typeset()> call. The units are the same as for
C<meaure> and C<linelengths>. A "Box" of value C<''> and width of C<indent> is
inserted before the first node of the paragraph. Your rendering code should
know how to handle this by starting at the same C<x> coordinate as other lines,
and then moving right (or left) by the indicated amount.

    'indent' => 2,  # 2 character indentation
    'indent' => 2*$text->text_width('M'),  # 2 ems indentation
    'indent' => -3,  # 3 character OUTdent

If the value is negative, a negative-width space Box is added. The overall line
will be longer than other lines, by that amount. Again, your rendering code
should handle this in a similar manner as with a positive indentation, but
move I<left> by the indicated amount. Be careful to have your starting C<x>
value far enough to the right that text will not end up being written off-page.

=item tolerance

How much leeway we have in leaving wider spaces than the algorithm
would prefer. The C<tolerance> is the maximum C<ratio> glue expansion value to
I<tolerate> in a possible solution, before discarding this solution as so
infeasible as to be a waste of time to pursue further. Most of the time, the 
C<tolerance> is going to have a value in the 1 to 3 range. One approach is to 
try with C<tolerance =E<gt> 1>, and if no successful layout is found, try 
again with 2, and then 3 and perhaps even 4.

=item hyphenator

An object which hyphenates words. If you have the C<Text::Hyphen> product 
installed (which is highly recommended), then a C<Text::Hyphen> object is 
instantiated by default; if not, an object of the class
C<Text::KnuthPlass::DummyHyphenator> is instantiated - this simply finds
no hyphenation points at all. So to turn hyphenation off, set

    'hyphenator' => Text::KnuthPlass::DummyHyphenator->new()

To typeset non-English text, pass in a C<Text::Hyphen>-like object which 
responds to the C<hyphenate> method, returning a list of hyphen positions for
that particular language (native C<Text::Hyphen> defaults to American English
hyphenation rules). (See C<Text::Hyphen> for the interface.)

=item space

Fine tune space (glue) width, stretchability, and shrinkability. 

    'space' => { 'width' => 3, 'stretch' => 6, 'shrink' => 9 },

For typesetting
constant width text or output to a text file (characters), we suggest setting
the C<shrink> value to 0. This prevents the glue spaces from being shrunk to
less than one character wide, which could result in either no spaces between 
words, or overflow into the right margin.

    'space' => { 'width' => 3, 'stretch' => 6, 'shrink' => 0 },

=item infinity

The default value for I<infinity> is, as is customary in TeX, 10000. While this
is a far cry from the real infinity, so long as it is substantially larger than
any other demerit or penalty, it should take precedence in calculations. Both
positive and negative C<inifinity> are used in the code for various purposes,
including a C<+inf> penalty for something absolutely forbidden, and C<-inf> for 
something absolutely required (such as a line break at the end of a paragraph).

    'infinity' => 10000,

=item hyphenpenalty

Set the penalty for an end-of-line hyphen at 50. You may want to try a somewhat
higher value, such as 100+, if you see too much hyphenation on output. Remember
that excessively short lines are prone to splitting words and being hyphenated,
no matter what the penalty is.

    'hyphenpenalty' => 50,

There does not appear to be anything in the code to find and prevent multiple
contiguous (adjacent) hyphenated lines, nor to prevent the penultimate 
(next-to-last) line from being hyphenated, nor to prevent the hyphenation of
a line where you anticipate the paragraph to be split between columns.
Something may be done in the future about these three special cases, which
are considered to not be good typesetting.

=item demerits

Various demerits used in calculating penalties, including I<fitness>, which is
used when line tightness (C<ratio>) changes by more than one class between two
lines.

    'demerits' => { 'line' => 10, 'flagged' => 100, 'fitness' => 3000 },

=back

There may be other options for fine-tuning the output. If you know your way
around TeX, dig into the source to find out what they are. At some point,
this package will support additional tuning by allowing the setting of more 
parameters which are currently hard-coded. Please let us know if you found any
more parameters that would be useful to allow additional tuning!

=cut

# more options, not currently implemented
#   'purePerl' => 0,  # 1: use pure Perl code, not XS. currently is hard-coded
#                       at top, as new() appears to be too late to call xload()
#   'const' => 0,  # width (char or points) to reduce line length to allow
#                    hyphenated word's hyphen not to overhang into right
#                    margin (constant width or character output), or result
#                    in slight tightening that may end up too much (ratio too
#                    negative). Still looking at it.
# TBD
#   'hangingp' => 0,  # use hanging punctuation (last character in a line is
#                     punctuation, including split-word hyphen) to write
#                     that punctuation over into the right margin. Some "very
#                     fine" typesetting overhangs a per-character (and font)
#                     percentage on left and right, and even letters too.
#   'dropcap' => { 'lines' => 3, 'scale' => 2.5, .... },
#                     indent first 'lines' lines of the paragraph to provide
#                     space for an oversized letter with some movement up and
#                     left. Letter is taken from $paragraph text. If paragraph
#                     doesn't have enough lines, pad with blank lines so that
#                     no need to indent following paragraph! Usually just for 
#                     first paragraph in a section (as with SC), so need a way 
#                     to cancel for subsequent paragraphs (if on by default). 
# TBD but this one might better belong in PDF::Builder
#   'smallcap' => { 'words' => 1, ... },
#                     small caps on first line text. 'words' is 1 to SC first
#                     word (or remainder after DropCap does its thing), 0 is
#                     no SC, -1 is entire line, >0 is that many words (up to
#                     end of first line). Usually just for first paragraph in
#                     a section (as with DC), so need a way to cancel for
#                     subsequent paragraphs (if on by default).
# Note that your rendering code should take care of any additional top margin
# (interparagraph space). Settings may be added for other things to fine-tune
# the output.

=head2 $t->typeset($paragraph_string, %opts)

This is the main interface to the algorithm, made up of the constituent
parts below. It takes a paragraph of text and returns a list of lines (array
of hashes) if suitable breakpoints could be found.

The typesetter currently allows several options:

=over 

=item indent

Override the global paragraph indentation value B<just for this paragraph.> 
This can be useful for
instances such as I<not> indenting the first paragraph in a section.

    'indent' => 0,  # default set in new() is 2ems

=item linelengths

The array of line lengths may be set here, in C<typeset>. As with C<new()>, it
will override whatever existing line lengths array is left over from
earlier operations.

=back

Possibly (in the future) many other global settings set in C<new()> may be
overridden on a per-paragraph basis in C<typeset()>.

The returned list has the following structure:

    (
        { 'nodes' => \@nodes, 'ratio' => $ratio },
        { 'nodes' => \@nodes, 'ratio' => $ratio },
        ...
    )

The node list in each element will be a list of objects. Each object
will be either C<Text::KnuthPlass::Box>, C<Text::KnuthPlass::Glue>
or C<Text::KnuthPlass::Penalty>. See below for more on these.

The C<ratio> is the amount of stretch or shrink which should be applied to
each glue element in this line. The corrected width of each glue node
should be:

    $node->width() + $line->{'ratio'} *
        ($line->{'ratio'} < 0 ? $node->shrink() : $node->stretch());

Each box, glue or penalty node has a C<width> attribute. Boxes have
C<value>s, which are the text which went into them (including a wide null
blank for paragraph indentation, a special case); glue has C<stretch>
and C<shrink> to determine how much it should vary in width. That should
be all you need for basic typesetting; for more, see the source, and see
the original Knuth-Plass paper in "Digital Typography".

Why I<typeset> rather than something like I<linesplit>? Per 
L</ACKNOWLEDGEMENTS>, this code is ported from the Javascript product 
B<typeset>.

This method is a thin wrapper around the three methods below.

=cut

# indent entry in options applies only to this paragraph.
# linelengths OK to change global value.
sub typeset {
    my ($t, $paragraph, %opts) = @_;

    # if give linelengths, need to set (replace) global value
    if (defined $opts{'linelengths'}) {
	$t->{'linelengths'} = $opts{'linelengths'};
    }

    # break up the text into a collection (list) of box, glue, penalty nodes
    my @nodes = $t->break_text_into_nodes($paragraph, %opts);

    # if indenting first line of paragraph, add a Box for that blank
    my $indent = $t->{'indent'}; # global indent
    $indent = $opts{'indent'} if defined $opts{'indent'}; # local override
    if ($indent) { # non-zero amount? could be + or -
        unshift @nodes, Text::KnuthPlass::Box->new(
            'width' => $indent,
            'value' => ''
        );
    }

    # figure best set of breakpoints (lowest cost)
    my @breakpoints = $t->break(\@nodes);

    # quit if nothing found (need to increase tolerance)
    return unless @breakpoints;

    # group nodes into lines according to breakpoints
    my @lines = $t->breakpoints_to_lines(\@breakpoints, \@nodes);

    # Remove final penalty and glue from last line in paragraph
    if (@lines) { 
        pop @{ $lines[-1]->{'nodes'} } ;
        pop @{ $lines[-1]->{'nodes'} } ;
    }

    # trim off one linelengths element per line output, but keep last one
    my @temp = @{ $t->{'linelengths'} };
    splice(@temp, 0, min(scalar(@lines), scalar(@temp)-1));
    $t->{'linelengths'} = \@temp;

    return @lines;
}

=head2 $t->line_lengths()

=over

=item @list = $t->line_lengths()  # Get

=item $t->line_lengths(@list)  # Set

Get or set the C<linelengths> list of allowed line lengths. This permits you to
do more elaborate operations on this array than simply replacing (resetting) it,
as done in the C<new()> and C<typeset()> methods. For example, at the bottom of
a page, you might cancel any further inset for a float, by deleting all but the 
last element of the list.

    my @temp_LL = $t->line_lengths();
    # cancel remaining line shortening
    splice(@temp_LL, 0, scalar(@temp_LL)-1);
    $t->line_lengths(@temp_LL);

On a "Set" request, you must have at least one length element in the list. If 
the list is empty, it is assumed to be a "Get" request.

=back

=cut

sub line_lengths {
    my $self = shift;

    if (@_) {  # Set
	$self->{'linelengths'} = \@_;
	return;

    } else {       # Get
	return @{ $self->{'linelengths'} };
    }
}

=head2 $t->break_text_into_nodes($paragraph_string, %opts)

This turns a paragraph into a list of box/glue/penalty nodes. It's
fairly basic, and designed to be overloaded. It should also support
multiple justification styles (centering, ragged right, etc.) but this
will come in a future release; right now, it just does full
justification. 

=head3 'style' => "string_name"

=over

=item "justify"

Fully justify the text (flush left I<and> right). This is the B<default>,
and currently I<the only choice implemented.>

=item "left"

Not yet implemented. This will be flush left, ragged right (reversed for
RTL scripts).

=item "right"

Not yet implemented. This will be flush right, ragged left (reversed for 
RTL scripts).

=item "center"

Implemented, but not yet fully tested. 
This is centered text within the indicated line width.

=back

If you are doing clever typography or using non-Western languages you
may find that you will want to break text into nodes yourself, and pass
the list of nodes to the methods below, instead of using this method.

=cut

sub _add_word {
    my ($self, $word, $nodes_r) = @_;
    my @elems = $self->hyphenator()->hyphenate($word);
    for (0..$#elems) {
        push @{$nodes_r}, Text::KnuthPlass::Box->new(
            'width' => $self->measure()->($elems[$_]), 
            'value' => $elems[$_]
        );
        if ($_ != $#elems) {
            push @{$nodes_r}, Text::KnuthPlass::Penalty->new(
                'flagged' => 1, 'penalty' => $self->hyphenpenalty());
        }
    }
    return;
}

sub break_text_into_nodes {
    my ($self, $text, %opts) = @_;
    my @nodes;
    my @words = split /\s+/, $text;

    my $style;
    $style = $opts{'style'} if defined $opts{'style'};
    $style ||= "justify"; # default

    $self->{'emwidth'}      = $self->measure()->("M");
    $self->{'spacewidth'}   = $self->measure()->(" ");
    $self->{'spacestretch'} = $self->{'spacewidth'} * $self->space()->{'width'} / $self->space()->{'stretch'};
    # shrink of 0 desired in constant width or text output
    if ($self->space()->{'shrink'} == 0) {
	    $self->{'spaceshrink'} = 0;
    } else {
        $self->{'spaceshrink'}  = $self->{'spacewidth'} * $self->space()->{'width'} / $self->space()->{'shrink'};
    }

    my $spacing_type = "_add_space_$style";
    my $start = "_start_$style";
    $self->$start(\@nodes);

    for (0..$#words) { my $word = $words[$_];
        $self->_add_word($word, \@nodes);
        $self->$spacing_type(\@nodes,$_ == $#words);
    }
    return @nodes;
}

# fully justified (flush left and right)
sub _start_justify { 
    return;
}
sub _add_space_justify {
    my ($self, $nodes_r, $final) = @_;
    if ($final) { 
        # last line of paragraph, ends with required break (-inf)
        push @{$nodes_r}, 
            $self->glueclass()->new(
               'width' => 0, 
               'stretch' => $self->infinity(), 
               'shrink' => 0
            ),
            $self->penaltyclass()->new(
	       'width' => 0, 
	       'penalty' => -$self->infinity(), 
	       'flagged' => 1
            );
    } else {
        # NOT last line of paragraph
        push @{$nodes_r}, $self->glueclass()->new(
               'width' => $self->{'spacewidth'},
               'stretch' => $self->{'spacestretch'},
               'shrink' => $self->{'spaceshrink'}
        );
   }
   return;
}

# centered within line (NOT TESTED)
sub _start_center {
    my ($self, $nodes_r) = @_;
    push @{$nodes_r}, 
        Text::KnuthPlass::Box->new('value' => ""),
        Text::KnuthPlass::Glue->new(
            'width' => 0, 
            'stretch' => 2*$self->{'emwidth'},
            'shrink' => 0
        );
    return;
}

sub _add_space_center {
    my ($self, $nodes_r, $final) = @_;
    if ($final) {
        # last line of paragraph, ends with required break (-inf)
        push @{$nodes_r}, Text::KnuthPlass::Glue->new( 
		'width' => 0, 
		'stretch' => 2*$self->{'emwidth'}, 
		'shrink' => 0
	    ),
            Text::KnuthPlass::Penalty->new(
		'width' => 0, 
		'penalty' => -$self->infinity(), 
		'flagged' => 0
	    );
    } else {
        # NOT last line of paragraph
        push @{$nodes_r}, Text::KnuthPlass::Glue->new( 
		'width' => 0, 
		'stretch' => 2*$self->{'emwidth'}, 
		'shrink' => 0
	    ),
            Text::KnuthPlass::Penalty->new(
		'width' => 0, 
		'penalty' => 0, 
		'flagged' => 0
	    ),
            Text::KnuthPlass::Glue->new( 
		'width' => $self->{'spacewidth'}, 
		'stretch' => -4*$self->{'emwidth'}, 
		'shrink' => 0
	    ),
            Text::KnuthPlass::Box->new('value' => ""),
            Text::KnuthPlass::Penalty->new(
		'width' => 0, 
		'penalty' => $self->infinity(), 
		'flagged' => 0
	    ),
            Text::KnuthPlass::Glue->new( 
		'width' => 0, 
		'stretch' => 2*$self->{'emwidth'}, 
		'shrink' => 0
	    ),
    }
    return;
}

# left justified (ragged right) not yet implemented, just handle as 'justified'
sub _start_left { 
   #my ($self, $nodes_r) = @_;
   #return; 
    return _start_justify(@_);
}

sub _add_space_left {
   #my ($self, $nodes_r, $final) = @_;
   #return; 
    return _add_space_justify(@_);
}

# right justified (ragged left) not yet implemented, just handle as 'justified'
sub _start_right { 
   #my ($self, $nodes_r) = @_;
   #return; 
    return _start_justify(@_);
}

sub _add_space_right {
   #my ($self, $nodes_r, $final) = @_;
   #return; 
    return _add_space_justify(@_);
}

=head2 break

This implements the main body of the algorithm; it turns a list of nodes
(produced from the above method) into a list of breakpoint objects.

=cut

sub break {
    my ($self, $nodes) = @_;
    $self->{'sum'} = {'width' => 0, 'stretch' => 0, 'shrink' => 0 };
    $self->_init_nodelist();
    # shouldn't ever happen, but just in case...
    if (!$self->{'linelengths'} || ref $self->{'linelengths'} ne "ARRAY") {
        croak "No linelengths set";
    }

    for (0..$#$nodes) { 
        my $node = $nodes->[$_];
        if ($node->isa("Text::KnuthPlass::Box")) {
            $self->{'sum'}{'width'} += $node->width();
        } elsif ($node->isa("Text::KnuthPlass::Glue")) {
            if ($_ > 0 and $nodes->[$_-1]->isa("Text::KnuthPlass::Box")) {
                $self->_mainloop($node, $_, $nodes);
            }
            $self->{'sum'}{'width'}   += $node->width();
            $self->{'sum'}{'stretch'} += $node->stretch();
            $self->{'sum'}{'shrink'}  += $node->shrink();
        } elsif ($node->is_penalty() and $node->penalty() != $self->infinity()) {
            $self->_mainloop($node, $_, $nodes);
        }
    }

    my @retval = reverse $self->_active_to_breaks();
    $self->_cleanup();
    return @retval;
}

sub _computeCost {  # _compute_cost() in XS
    my ($self, $start, $end, $active, $currentLine, $nodes) = @_;
    warn  "Computing cost from $start to $end\n" if DEBUG;
    warn sprintf "Sum width: %f\n", $self->{'sum'}{'width'} if DEBUG;
    warn sprintf "Total width: %f\n", $self->{'totals'}{'width'} if DEBUG;
    my $width = $self->{'sum'}{'width'} - $active->totals()->{'width'};
    my $stretch = 0; my $shrink = 0;
    my $linelength = $currentLine <= @{$self->linelengths()}? 
                        $self->{'linelengths'}[$currentLine-1]:
                        $self->{'linelengths'}[-1];
   #$linelength -= $self->{'const'}; # allow space for split word hyphen
                                     # allow for in renderer

    warn "Adding penalty width" if($nodes->[$end]->is_penalty()) and DEBUG;
    warn sprintf "Width %f, linelength %f\n", $width, $linelength if DEBUG;

    if ($width < $linelength) {
        $stretch = $self->{'sum'}{'stretch'} - $active->totals()->{'stretch'};
        warn sprintf "Stretch %f\n", $stretch if DEBUG;
        if ($stretch > 0) {
            return ($linelength - $width) / $stretch;
        } else { return $self->infinity(); }
    } elsif ($width > $linelength) {
        $shrink = $self->{'sum'}{'shrink'} - $active->totals()->{'shrink'};
        warn sprintf "Shrink %f\n", $shrink if DEBUG;
        if ($shrink > 0) {
            return ($linelength - $width) / $shrink;
        } else { return $self->infinity(); }
    } else { return 0; }
}

sub _computeSum {  # _compute_sum() in XS
    my ($self, $index, $nodes) = @_;
    my $result = { 
	'width' => $self->{'sum'}{'width'}, 
        'stretch' => $self->{'sum'}{'stretch'}, 
	'shrink' => $self->{'sum'}{'shrink'}
    };
    for ($index..$#$nodes) {
        if ($nodes->[$_]->isa("Text::KnuthPlass::Glue")) {
            $result->{'width'} += $nodes->[$_]->width();
            $result->{'stretch'} += $nodes->[$_]->stretch();
            $result->{'shrink'} += $nodes->[$_]->shrink();
        } elsif ($nodes->[$_]->isa("Text::KnuthPlass::Box") or
                 ($nodes->[$_]->is_penalty() and $nodes->[$_]->penalty() ==
                  -$self->infinity() and $_ > $index)) {
	    last;
        }
    }
    return $result;
}

sub _init_nodelist { # Overridden by XS, same name in XS
    my $self = shift;
    $self->{'activeNodes'} = [
        Text::KnuthPlass::Breakpoint->new(
	    'position' => 0,
            'demerits' => 0,
            'ratio' => 0,
            'line' => 0,
            'fitnessClass' => 0,
            'totals' => { 'width' => 0, 'stretch' => 0, 'shrink' => 0}
        )
    ];
    return;
}

# same name in XS, but has quite a bit of code
sub _cleanup { return; } 

sub _active_to_breaks { # Overridden by XS, same name in XS
    my $self = shift;
    return unless @{$self->{'activeNodes'}};
    my @breaks;
    my $best = Text::KnuthPlass::Breakpoint->new('demerits' => ~0);
    for (@{$self->{'activeNodes'}}) { 
	$best = $_ if $_->demerits() < $best->demerits();
    }
    while ($best) {
        push @breaks, { 'position' => $best->position(),
                        'ratio' => $best->ratio()
                      };
        $best = $best->previous();
    }
    return @breaks;
}

sub _mainloop {  # same name in XS
    my ($self, $node, $index, $nodes) = @_;
    my $next; my $ratio = 0; my $demerits = 0; my @candidates;
    my $badness; my $currentLine = 0; my $tmpSum; my $currentClass = 0;
    my $active = $self->{'activeNodes'}[0];
    my $ptr = 0;
    while ($active) { 
        my @candidates = ( # four fitness classes? 
		           # (tight, normal, loose, very loose)
	    {'demerits' => ~0},
	    {'demerits' => ~0},
	    {'demerits' => ~0},
	    {'demerits' => ~0}
        ); 
        warn  "Outer\n" if DEBUG;
        while ($active) { 
            my $next = $self->{'activeNodes'}[++$ptr];
            warn  "Inner loop\n" if DEBUG;
            $currentLine = $active->line()+1;
            $ratio = $self->_computeCost($active->position(), 
		                         $index, 
					 $active, 
					 $currentLine, 
					 $nodes);
            warn  "Got a ratio of $ratio, node is ".$node->_txt()."\n" if DEBUG;
            if ($ratio < -1 or 
                ($node->is_penalty() and 
		 $node->penalty() == -$self->infinity())) {
                warn  "Dropping a node\n" if DEBUG;
                $self->{'activeNodes'} = [ grep {$_ != $active} @{$self->{'activeNodes'}} ];
                $ptr--;
            }
            if (-1 <= $ratio and $ratio <= $self->tolerance()) {
                $badness = 100 * $ratio**3;
                warn  "Badness is $badness\n" if DEBUG;
                if ($node->is_penalty() and $node->penalty() > 0) {
                    $demerits = $self->demerits()->{'line'} + $badness +
                        $node->penalty();
                } elsif ($node->is_penalty() and $node->penalty() != -$self->infinity()) {
                    $demerits = $self->demerits()->{'line'} + $badness -
                        $node->penalty();
                } else {
                    $demerits = $self->demerits()->{'line'} + $badness;
                }
		$demerits *= $demerits; # demerits**2

                if ($node->is_penalty() and $nodes->[$active->position()]->is_penalty()) {
                    $demerits += $self->demerits()->{'flagged'} *
                        $node->flagged() *
                        $nodes->[$active->position()]->flagged();
                }

                if    ($ratio < -0.5) { $currentClass = 0; } # tight
                elsif ($ratio <= 0.5) { $currentClass = 1; } # normal
                elsif ($ratio <= 1  ) { $currentClass = 2; } # loose
                else                  { $currentClass = 3; } # very loose

		# bad fitness if changes by more than 1 class
                $demerits += $self->demerits()->{'fitness'}
                    if abs($currentClass - $active->fitnessClass()) > 1;

                $demerits += $active->demerits();
                if ($demerits < $candidates[$currentClass]->{'demerits'}) {
                    warn "Setting c $currentClass\n" if DEBUG;
                    $candidates[$currentClass] = { 
			'active' => $active,
                        'demerits' => $demerits,
                        'ratio' => $ratio
                    };
                }
            }
            $active = $next;
            #warn "Active is now $active" if DEBUG;
            last if !$active || 
                $active->line() >= $currentLine;
        }
        warn  "Post inner loop\n" if DEBUG;

        $tmpSum = $self->_computeSum($index, $nodes);
        for (0..3) { 
	    my $c = $candidates[$_];
            if ($c->{'demerits'} < ~0) { 
                my $newnode = Text::KnuthPlass::Breakpoint->new(
                    'position' => $index,
                    'demerits' => $c->{'demerits'},
                    'ratio' => $c->{'ratio'},
                    'line' => $c->{'active'}->line() + 1,
                    'fitnessClass' => $_,
                    'totals' => $tmpSum,
                    'previous' => $c->{'active'}
                );
                if ($active) { 
                    warn  "Before\n" if DEBUG;
                    my @newlist;
                    for (@{$self->{'activeNodes'}}) {
                        if ($_ == $active) { push @newlist, $newnode; }
                        push @newlist, $_;
                    }
                    $ptr++;
                    $self->{'activeNodes'} = [ @newlist ];
                    #    grep {;
                    #       ($_ == $active) ? ($newnode, $active) : ($_)
                    #} @{$self->{'activeNodes'}}
                    # ];
                } else { 
                    warn  "After\n" if DEBUG;
                    push @{$self->{'activeNodes'}}, $newnode;
                }
                #warn  @{$self->{'activeNodes'}} if DEBUG;
            } # demerits check
        } # fitness class 0..3 loop
    } # while $active loop
    return;
}

=head2 @lines = $t->breakpoints_to_lines(\@breakpoints, \@nodes)

And this takes the breakpoints and the nodes, and assembles them into
lines.

=cut

sub breakpoints_to_lines {
    my ($self, $breakpoints, $nodes) = @_;
    my @lines;
    my $linestart = 0;
    for my $x (1 .. $#$breakpoints) { $_ = $breakpoints->[$x];
        my $position = $_->{'position'};
        my $r = $_->{'ratio'};
        for ($linestart..$#$nodes) {
            if ($nodes->[$_]->isa("Text::KnuthPlass::Box") or
                ($nodes->[$_]->is_penalty() and 
		 $nodes->[$_]->penalty() ==-$self->infinity())) {
                $linestart = $_;
                last;
            }
        }
        push @lines, { 
	    'ratio' => $r, 
	    'position' => $_->{'position'},
            'nodes' => [ @{$nodes}[$linestart..$position] ]
        };
        $linestart = $_->{'position'};
    }
    #if ($linestart < $#$nodes) { 
    #    push @lines, { 'ratio' => 1, 'position' => $#$nodes,
    #            'nodes' => [ @{$nodes}[$linestart+1..$#$nodes] ]};
    #}
    return @lines;
}

=head2 boxclass()

=head2 glueclass()

=head2 penaltyclass()

For subclassers.

=cut

sub boxclass { 
    return "Text::KnuthPlass::Box";
}
sub glueclass { 
    return "Text::KnuthPlass::Glue";
}
sub penaltyclass { 
    return "Text::KnuthPlass::Penalty";
}

=head1 AUTHOR

originally written by Simon Cozens, C<< <simon at cpan.org> >>

since 2020, maintained by Phil Perry

=head1 ACKNOWLEDGEMENTS

This module is a Perl translation (originally by Simon Cozens) of Bram Stein's 
"Typeset" Javascript Knuth-Plass implementation.

=head1 BUGS

Please report any bugs or feature requests to the I<issues> section of 
C<https://github.com/PhilterPaper/Text-KnuthPlass>.

Do NOT under ANY circumstances open a PR (Pull Request) to report a bug. It is 
a waste of both your and our time and effort. Open a regular ticket (issue), 
and attach a Perl (.pl) program illustrating the problem, if possible. If you
believe that you have a program patch, and offer to share it as a PR, we may
give the go-ahead. Unsolicited PRs may be closed without further action.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2011 Simon Cozens.

Copyright (c) 2020-2022 Phil M Perry.

This program is released under the following license: Perl, GPL

=cut

1; # End of Text::KnuthPlass
