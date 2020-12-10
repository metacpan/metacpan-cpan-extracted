package Text::KnuthPlass;
require XSLoader;
use constant DEBUG => 0;
use warnings;
use strict;

our $VERSION = '1.03'; # VERSION
my $LAST_UPDATE = '1.03'; # manually update whenever file is edited

eval { XSLoader::load("Text::KnuthPlass", $VERSION); } or die $@;
# Or else there's a Perl version
use Data::Dumper;

package Text::KnuthPlass::Element;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors("width");
sub new { 
    my $self = shift; 
    return bless { width => 0, @_ }, $self; 
}
sub is_penalty { 
    return shift->isa("Text::KnuthPlass::Penalty"); 
}
sub is_glue { 
    return shift->isa("Text::KnuthPlass::Glue"); 
}

package Text::KnuthPlass::Box; 
use base 'Text::KnuthPlass::Element';
__PACKAGE__->mk_accessors("value");

sub _txt { 
    return "[".$_[0]->value."/".$_[0]->width."]"; 
}

package Text::KnuthPlass::Glue;
use base 'Text::KnuthPlass::Element';
__PACKAGE__->mk_accessors("stretch", "shrink");

sub new { 
    my $self = shift; 
    return $self->SUPER::new(stretch => 0, shrink => 0, @_);
}
sub _txt { 
    return sprintf "<%.2f+%.2f-%.2f>", $_[0]->width, $_[0]->stretch, $_[0]->shrink; 
}

package Text::KnuthPlass::Penalty;
use base 'Text::KnuthPlass::Element';
__PACKAGE__->mk_accessors("penalty", "flagged", "shrink");
sub new { 
    my $self = shift; 
    return $self->SUPER::new(flagged => 0, shrink => 0, @_);
}
sub _txt { 
    return "(".$_[0]->penalty.($_[0]->flagged &&"!").")"; 
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

my %defaults = (
    infinity => 10000,
    tolerance => 30,
    hyphenpenalty => 50,
    demerits => { line => 10, flagged => 100, fitness => 3000 },
    space => { width => 3, stretch => 6, shrink => 9 },
    linelengths => [78],
    measure => sub { length $_[0] },
    hyphenator => 
        eval { require Text::Hyphen } ? Text::Hyphen->new() :
        Text::KnuthPlass::DummyHyphenator->new()
);
__PACKAGE__->mk_accessors(keys %defaults);
sub new { 
    my $self = shift; 
    return bless {%defaults, @_}, $self;
}

=head1 NAME

Text::KnuthPlass - Breaks paragraphs into lines using the TeX algorithm

=head1 SYNOPSIS

    use Text::KnuthPlass;
    my $typesetter = Text::KnuthPlass->new();
    my @lines = $typesetter->typeset($paragraph);
    ...

To use with plain text:

    for (@lines) {
        for (@{$_->{nodes}}) {
            if ($_->isa("Text::KnuthPlass::Box")) { print $_->value }
            elsif ($_->isa("Text::KnuthPlass::Glue")) { print " " }
        }
        if ($_->{nodes}[-1]->is_penalty) { print "-" }
        print "\n";
    }

To use with PDF::Builder: (as well as PDF::API2)

    my $text = $page->text;
    $text->font($font, 12);
    $text->lead(13.5);

    my $t = Text::KnuthPlass->new(
        measure => sub { $text->advancewidth(shift) }, 
        linelengths => [235]
    );
    my @lines = $t->typeset($paragraph);

    my $y = 500;
    for my $line (@lines) {
        $x = 50; 
        for my $node (@{$line->{nodes}}) {
            $text->translate($x,$y);
            if ($node->isa("Text::KnuthPlass::Box")) {
                $text->text($node->value);
                $x += $node->width;
            } elsif ($node->isa("Text::KnuthPlass::Glue")) {
                $x += $node->width + $line->{ratio} *
                    ($line->{ratio} < 0 ? $node->shrink : $node->stretch);
            }
        }
        if ($line->{nodes}[-1]->is_penalty) { $text->text("-") }
        $y -= $text->lead();
    }

=head1 METHODS

=head2 new

The constructor takes a number of options. The most important ones are:

=over 3

=item measure

A subroutine reference to determine the width of a piece of text. This
defaults to C<length(shift)>, which is what you want if you're
typesetting plain monospaced text. You will need to change this to plug
into your font metrics if you're doing something graphical.

=item linelengths

This is an array of line lengths. For instance, C< [30,40,50] > will
typeset a triangle-shaped piece of text with three lines. What if the
text spills over to more than three lines? In that case, the final value
in the array is used for all further lines. So to typeset an ordinary
block-shaped column of text, you only need specify an array with one
value: the default is C< [78] >.

=item tolerance

How much leeway we have in leaving wider spaces than the algorithm
would prefer. 

=item hyphenator

An object which hyphenates words. If you have C<Text::Hyphen> installed
(highly recommended) then a C<Text::Hyphen> object is instantiated by
default; if not, an object of the class
C<Text::KnuthPlass::DummyHyphenator> is instantiated - this simply finds
no hyphenation points at all. So to turn hyphenation off, set

    hyphenator => Text::KnuthPlass::DummyHyphenator->new()

To typeset non-English text, pass in an object which responds to the
C<hyphenate> method, returning a list of hyphen positions. (See
C<Text::Hyphen> for the interface.)

=back

There are other options for fine-tuning the output. If you know your way
around TeX, dig into the source to find out what they are.

=head2 typeset

This is the main interface to the algorithm, made up of the constituent
parts below. It takes a paragraph of text and returns a list of lines if
suitable breakpoints could be found.

The list has the following structure:

    (
        { nodes => \@nodes, ratio => $ratio },
        { nodes => \@nodes, ratio => $ratio },
        ...
    )

The node list in each element will be a list of objects. Each object
will be either C<Text::KnuthPlass::Box>, C<Text::KnuthPlass::Glue>
or C<Text::KnuthPlass::Penalty>. See below for more on these.

The C<ratio> is the amount of stretch or shrink which should be applied to
each glue element in this line. The corrected width of each glue node
should be:

    $node->width + $line->{ratio} *
        ($line->{ratio} < 0 ? $node->shrink : $node->stretch);

Each box, glue or penalty node has a C<width> attribute. Boxes have
C<value>s, which are the text which went into them; glue has C<stretch>
and C<shrink> to determine how much it should vary in width. That should
be all you need for basic typesetting; for more, see the source, and see
the original Knuth-Plass paper in "Digital Typography".

This method is a thin wrapper around the three methods below.

=cut

sub typeset {
    my ($t, $paragraph, @args) = @_;
    my @nodes = $t->break_text_into_nodes($paragraph, @args);
    my @breakpoints = $t->break(\@nodes);
    return unless @breakpoints;
    my @lines = $t->breakpoints_to_lines(\@breakpoints, \@nodes);
    # Remove final penalty and glue
    if (@lines) { 
        pop @{ $lines[-1]->{nodes} } ;
        pop @{ $lines[-1]->{nodes} } ;
    }
    return @lines;
}

=head2 break_text_into_nodes

This turns a paragraph into a list of box/glue/penalty nodes. It's
fairly basic, and designed to be overloaded. It should also support
multiple justification styles (centering, ragged right, etc.) but this
will come in a future release; right now, it just does full
justification. 

If you are doing clever typography or using non-Western languages you
may find that you will want to break text into nodes yourself, and pass
the list of nodes to the methods below, instead of using this method.

=cut

sub _add_word {
    my ($self, $word, $nodes_r) = @_;
    my @elems = $self->hyphenator->hyphenate($word);
    for (0..$#elems) {
        push @{$nodes_r}, Text::KnuthPlass::Box->new(
            width => $self->measure->($elems[$_]), 
            value => $elems[$_]
        );
        if ($_ != $#elems) {
            push @{$nodes_r}, Text::KnuthPlass::Penalty->new(
                flagged => 1, penalty => $self->hyphenpenalty);
        }
    }
    return;
}

sub break_text_into_nodes {
    my ($self, $text, $style) = @_;
    my @nodes;
    my @words = split /\s+/, $text;

    $self->{emwidth}      = $self->measure->("M");
    $self->{spacewidth}   = $self->measure->(" ");
    $self->{spacestretch} = $self->{spacewidth} * $self->space->{width} / $self->space->{stretch};
    $self->{spaceshrink}  = $self->{spacewidth} * $self->space->{width} / $self->space->{shrink};

    $style ||= "justify";
    my $spacing_type = "_add_space_$style";
    my $start = "_start_$style";
    $self->$start(\@nodes);

    for (0..$#words) { my $word = $words[$_];
        $self->_add_word($word, \@nodes);
        $self->$spacing_type(\@nodes,$_ == $#words);
    }
    return @nodes;
}

sub _start_justify { 
    return;
}
sub _add_space_justify {
    my ($self, $nodes_r, $final) = @_;
    if ($final) { 
       push @{$nodes_r}, 
           $self->glueclass->new(
               width => 0, 
               stretch => $self->infinity, 
               shrink => 0),
           $self->penaltyclass->new(width => 0, penalty => -$self->infinity, flagged => 1);
    } else {
       push @{$nodes_r}, $self->glueclass->new(
               width => $self->{spacewidth},
               stretch => $self->{spacestretch},
               shrink => $self->{spaceshrink}
           );
   }
   return;
}

sub _start_center {
    my ($self, $nodes_r) = @_;
    push @{$nodes_r}, 
        Text::KnuthPlass::Box->new(value => ""),
        Text::KnuthPlass::Glue->new(
            width => 0, 
            stretch => 2*$self->{emwidth},
            shrink => 0);
    return;
}

sub _add_space_center {
    my ($self, $nodes_r, $final) = @_;
    if ($final) {
        push @{$nodes_r}, 
            Text::KnuthPlass::Glue->new( width => 0, stretch => 2*$self->{emwidth}, shrink => 0),
            Text::KnuthPlass::Penalty->new(width => 0, penalty => -$self->infinity, flagged => 0);
    } else {
        push @{$nodes_r}, 
            Text::KnuthPlass::Glue->new( width => 0, stretch => 2*$self->{emwidth}, shrink => 0),
            Text::KnuthPlass::Penalty->new(width => 0, penalty => 0, flagged => 0),
            Text::KnuthPlass::Glue->new( width => $self->{spacewidth}, stretch => -4*$self->{emwidth}, shrink => 0),
            Text::KnuthPlass::Box->new(value => ""),
            Text::KnuthPlass::Penalty->new(width => 0, penalty => $self->infinity, flagged => 0),
            Text::KnuthPlass::Glue->new( width => 0, stretch => 2*$self->{emwidth}, shrink => 0),
    }
    return;
}

=head2 break

This implements the main body of the algorithm; it turns a list of nodes
(produced from the above method) into a list of breakpoint objects.

=cut

sub _init_nodelist { # Overridden by XS
    shift->{activeNodes} = [
        Text::KnuthPlass::Breakpoint->new(position => 0,
            demerits => 0,
            ratio => 0,
            line => 0,
            fitnessClass => 0,
            totals => { width => 0, stretch => 0, shrink => 0}
        )
    ];
    return;
}

sub break {
    my ($self, $nodes) = @_;
    $self->{sum} = {width => 0, stretch => 0, shrink => 0 };
    $self->_init_nodelist();
    if (!$self->{linelengths} || ref $self->{linelengths} ne "ARRAY") {
        croak "No linelengths set";
    }

    for (0..$#$nodes) { 
        my $node = $nodes->[$_];
        if ($node->isa("Text::KnuthPlass::Box")) {
            $self->{sum}{width} += $node->width;
        } elsif ($node->isa("Text::KnuthPlass::Glue")) {
            if ($_ > 0 and $nodes->[$_-1]->isa("Text::KnuthPlass::Box")) {
                $self->_mainloop($node, $_, $nodes);
            }
            $self->{sum}{width}   += $node->width;
            $self->{sum}{stretch} += $node->stretch;
            $self->{sum}{shrink}  += $node->shrink;
        } elsif ($node->is_penalty and $node->penalty != $self->infinity) {
            $self->_mainloop($node, $_, $nodes);
        }
    }

    my @retval = reverse $self->_active_to_breaks;
    $self->_cleanup;
    return @retval;
}

sub _cleanup { return; } 

sub _active_to_breaks { # Overridden by XS
    my $self = shift;
    return unless @{$self->{activeNodes}};
    my @breaks;
    my $tmp = Text::KnuthPlass::Breakpoint->new(demerits => ~0);
    for (@{$self->{activeNodes}}) { $tmp = $_ if $_->demerits < $tmp->demerits }
    while ($tmp) {
        push @breaks, { position => $tmp->position,
                        ratio => $tmp->ratio
                      };
        $tmp = $tmp->previous
    }
    return @breaks;
}

sub _mainloop {
    my ($self, $node, $index, $nodes) = @_;
    my $next; my $ratio = 0; my $demerits = 0; my @candidates;
    my $badness; my $currentLine = 0; my $tmpSum; my $currentClass = 0;
    my $active = $self->{activeNodes}[0];
    my $ptr = 0;
    while ($active) { 
        @candidates = ( {demerits => ~0}, {demerits => ~0},{demerits => ~0},{demerits => ~0} ); 
        warn  "Outer\n" if DEBUG;
        while ($active) { 
            my $next = $self->{activeNodes}[++$ptr];
            warn  "Inner loop\n" if DEBUG;
            $currentLine = $active->line+1;
            $ratio = $self->_computeCost($active->position, $index, $active, $currentLine, $nodes);
            warn  "Got a ratio of $ratio, node is ".$node->_txt."\n" if DEBUG;
            if ($ratio < -1 or 
                ($node->is_penalty and $node->penalty == -$self->infinity)) {
                warn  "Dropping a node\n" if DEBUG;
                $self->{activeNodes} = [ grep {$_ != $active} @{$self->{activeNodes}} ];
                $ptr--;
            }
            if (-1 <= $ratio and $ratio <= $self->tolerance) {
                $badness = 100 * $ratio**3;
                warn  "Badness is $badness\n" if DEBUG;
                if ($node->is_penalty and $node->penalty > 0) {
                    $demerits = ($self->demerits->{line} + $badness +
                        $node->penalty)**2;
                } elsif ($node->is_penalty and $node->penalty != -$self->infinity) {
                    $demerits = ($self->demerits->{line} + $badness -
                        $node->penalty)**2;
                } else {
                    $demerits = ($self->demerits->{line} + $badness)**2;
                }

                if ($node->is_penalty and $nodes->[$active->position]->is_penalty) {
                    $demerits += $self->demerits->{flagged} *
                        $node->flagged *
                        $nodes->[$active->position]->flagged;
                }

                if    ($ratio < -0.5) { $currentClass = 0 }
                elsif ($ratio <= 0.5) { $currentClass = 1 }
                elsif ($ratio <= 1  ) { $currentClass = 2 }
                else                  { $currentClass = 3 }

                $demerits += $self->demerits->{fitness}
                    if abs($currentClass - $active->fitnessClass) > 1;

                $demerits += $active->demerits;
                if ($demerits < $candidates[$currentClass]->{demerits}) {
                    warn "Setting c $currentClass\n" if DEBUG;
                    $candidates[$currentClass] = { active => $active,
                        demerits => $demerits,
                        ratio => $ratio
                    };
                }
            }
            $active = $next;
            #warn "Active is now $active" if DEBUG;
            last if !$active || 
                $active->line >= $currentLine;
        }
        warn  "Post inner loop\n" if DEBUG;
        $tmpSum = $self->_computeSum($index, $nodes);
        for (0..3) { my $c = $candidates[$_];
            if ($c->{demerits} < ~0) { 
                my $newnode = Text::KnuthPlass::Breakpoint->new(
                    position => $index,
                    demerits => $c->{demerits},
                    ratio => $c->{ratio},
                    line => $c->{active}->line + 1,
                    fitnessClass => $_,
                    totals => $tmpSum,
                    previous => $c->{active}
                );
                if ($active) { 
                    warn  "Before\n" if DEBUG;
                    my @newlist;
                    for (@{$self->{activeNodes}}) {
                        if ($_ == $active) { push @newlist, $newnode }
                         push @newlist, $_;
                    }
                    $ptr++;
                    $self->{activeNodes} = [ @newlist ];
                    #    grep {;
                    #       ($_ == $active) ? ($newnode, $active) : ($_)
                    #} @{$self->{activeNodes}}
                    # ];
                }
                else { 
                    warn  "After\n" if DEBUG;
                    push @{$self->{activeNodes}}, $newnode 
                }
                #warn  @{$self->{activeNodes}} if DEBUG;
            }
        }
    }
    return;
}

sub _computeCost {
    my ($self, $start, $end, $active, $currentLine, $nodes) = @_;
    warn  "Computing cost from $start to $end\n" if DEBUG;
    warn sprintf "Sum width: %f\n", $self->{sum}{width} if DEBUG;
    warn sprintf "Total width: %f\n", $self->{totals}{width} if DEBUG;
    my $width = $self->{sum}{width} - $active->totals->{width};
    my $stretch = 0; my $shrink = 0;
    my $linelength = $currentLine < @{$self->linelengths} ? 
                        $self->{linelengths}[$currentLine-1] :
                        $self->{linelengths}[-1];

    warn "Adding penalty width" if($nodes->[$end]->is_penalty) and DEBUG;
    $width += $nodes->[$end]->width if $nodes->[$end]->is_penalty;
    warn sprintf "Width %f, linelength %f\n", $width, $linelength if DEBUG;
    if ($width < $linelength) {
        $stretch = $self->{sum}{stretch} - $active->totals->{stretch};
        warn sprintf "Stretch %f\n", $stretch if DEBUG;
        if ($stretch > 0) {
            return ($linelength - $width) / $stretch;
        } else { return $self->infinity(); }
    } elsif ($width > $linelength) {
        $shrink = $self->{sum}{shrink} - $active->totals->{shrink};
        warn sprintf "Shrink %f\n", $shrink if DEBUG;
        if ($shrink > 0) {
            return ($linelength - $width) / $shrink;
        } else { return $self->infinity}
    } else { return 0; }
}

sub _computeSum {
    my ($self, $index, $nodes) = @_;
    my $result = { width => $self->{sum}{width}, 
        stretch => $self->{sum}{stretch}, shrink => $self->{sum}{shrink} };
    for ($index..$#$nodes) {
        if ($nodes->[$_]->isa("Text::KnuthPlass::Glue")) {
            $result->{width} += $nodes->[$_]->width;
            $result->{stretch} += $nodes->[$_]->stretch;
            $result->{shrink} += $nodes->[$_]->shrink;
        } elsif ($nodes->[$_]->isa("Text::KnuthPlass::Box") or
                ($nodes->[$_]->is_penalty and $nodes->[$_]->penalty ==
                -$self->infinity and $_ > $index)) { last }
    }
    return $result;
}

=head2 breakpoints_to_lines

And this takes the breakpoints and the nodes, and assembles them into
lines.

=cut

sub breakpoints_to_lines {
    my ($self, $breakpoints, $nodes) = @_;
    my @lines;
    my $linestart = 0;
    for my $x (1 .. $#$breakpoints) { $_ = $breakpoints->[$x];
        my $position = $_->{position};
        my $r = $_->{ratio};
        for ($linestart..$#$nodes) {
            if ($nodes->[$_]->isa("Text::KnuthPlass::Box") or
            ($nodes->[$_]->is_penalty and $nodes->[$_]->penalty ==-$self->infinity)) {
                $linestart = $_;
                last;
            }
        }
        push @lines, { ratio => $r, position => $_->{position},
                nodes => [ @{$nodes}[$linestart..$position] ]};
        $linestart = $_->{position};
    }
    #if ($linestart < $#$nodes) { 
    #    push @lines, { ratio => 1, position => $#$nodes,
    #            nodes => [ @{$nodes}[$linestart+1..$#$nodes] ]};
    #}
    return @lines;
}

=head2 glueclass

=head2 penaltyclass

For subclassers.

=cut

sub glueclass { 
    return "Text::KnuthPlass::Glue";
}
sub penaltyclass { 
    return "Text::KnuthPlass::Penalty";
}

=head1 AUTHOR

originally written by Simon Cozens, C<< <simon at cpan.org> >>

since 2020, maintained by Phil Perry C<< <pmperry at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

This module is a Perl translation of Bram Stein's Javascript Knuth-Plass
implementation. Any bugs, however, are probably my fault.

=head1 BUGS

Please report any bugs or feature requests to the _issues_ section of 
C<https://github.com/PhilterPaper/Text-KnuthPlass>, or via email (please see
C<README.md> for details).

=head1 COPYRIGHT & LICENSE

Copyright (c) 2011 Simon Cozens.

Copyright (c) 2020 Phil M Perry.

This program is released under the following license: Perl, GPL

=cut

1; # End of Text::KnuthPlass
