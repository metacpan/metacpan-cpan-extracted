package Text::Amuse::Output;
use strict;
use warnings;
use utf8;
use Text::Amuse::Output::Image;
use Text::Amuse::InlineElement;
# use Data::Dumper::Concise;
use constant DEBUG => 0;

=head1 NAME

Text::Amuse::Output - Internal module for L<Text::Amuse> output

=head1 SYNOPSIS

The module is used internally by L<Text::Amuse>, so everything here is
pretty much internal only (and underdocumented).

=head2 Basic LaTeX preamble

  \documentclass[DIV=9,fontsize=10pt,oneside,paper=a5]{scrbook}
  \usepackage{graphicx}
  \usepackage{alltt}
  \usepackage{verbatim}
  \usepackage[hyperfootnotes=false,hidelinks,breaklinks=true]{hyperref}
  \usepackage{bookmark}
  \usepackage[stable]{footmisc}
  \usepackage{enumerate}
  \usepackage{longtable}
  \usepackage[normalem]{ulem}
  \usepackage{wrapfig}

  % avoid breakage on multiple <br><br> and avoid the next [] to be eaten
  \newcommand*{\forcelinebreak}{~\\\relax}
  % this also works
  % \newcommand*{\forcelinebreak}{\strut\\{}}

  \newcommand*{\hairline}{%
    \bigskip%
    \noindent \hrulefill%
    \bigskip%
  }

  % reverse indentation for biblio and play

  \newenvironment{amusebiblio}{
    \leftskip=\parindent
    \parindent=-\parindent
    \bigskip
    \indent
  }{\bigskip}

  \newenvironment{amuseplay}{
    \leftskip=\parindent
    \parindent=-\parindent
    \bigskip
    \indent
  }{\bigskip}

  \newcommand{\Slash}{\slash\hspace{0pt}}

=head1 CONSTRUCTORS

=over 4

=item Text::Amuse::Output->new(document => $obj, format => "ltx")

Constructor. Format can be C<ltx> or C<html>, while document must be a
L<Text::Amuse::Document> object.

=cut

sub new {
    my $class = shift;
    my %opts = @_;
    die "Missing document object!\n" unless $opts{document};
    die "Missing or wrong format!\n" unless ($opts{format} and ($opts{format} eq 'ltx' or
                                                                $opts{format} eq 'html'));
    my $self = { document => $opts{document},
                 fmt => $opts{format} };
    if (ref($self->{document}) and $self->{document}->can('language_code')) {
        $self->{_lang} = $self->{document}->language_code;
    }
    bless $self, $class;
}

=back

=head1 METHODS

=over 4

=item _lang

=cut

sub _lang { shift->{_lang} };

=item document

Accessor to the L<Text::Amuse::Document> object (read-only, but you
may call its method on that.

=cut

sub document {
    return shift->{document};
}

=item fmt

Accessor to the current format (read-only);

=cut

sub fmt {
    return shift->{fmt};
}

=item is_html

True if the format is html

=item is_latex

True if the format is latex

=cut

sub is_latex {
    return shift->fmt eq 'ltx';
}

sub is_html {
    return shift->fmt eq 'html';
}

=item process

This method returns a array ref with the processed chunks. To get
a sensible output you will have to join the pieces yourself.

We don't return a joined string to avoid copying large amounts of
data.

  my $splat_pages = $obj->process(split => 1);
  foreach my $html (@$splat_pages) {
      # ...templating here...
  }

If the format is C<html>, the option C<split> may be passed. Instead
of a arrayref of chunks, an arrayref with html pages will be
returned. Each page usually starts with an heading, and it's without
<head> <body>. Footnotes are flushed and inserted at the end of each
pages.

E.g.

  print @{$obj->process};

=cut

sub process {
    my ($self, %opts) = @_;
    my (@pieces, @splat);
    my $split = $opts{split};
    my $imagere = $self->image_re;
    $self->reset_toc_stack;
    # loop over the parsed elements
    foreach my $el ($self->document->elements) {
        if ($el->type eq 'null') {
            push @pieces, $self->format_anchors($el) if $el->anchors;
            next;
        }
        if ($el->type eq 'startblock') {
            die "startblock with string passed!: " . $el->string if $el->string;
            push @pieces, $self->blkstring(start => $el->block, start_list_index => $el->start_list_index),
              $self->format_anchors($el);
        }
        elsif ($el->type eq 'stopblock') {
            die "stopblock with string passed!:" . $el->string if $el->string;
            push @pieces, $self->format_anchors($el), $self->blkstring(stop => $el->block);
        }
        elsif ($el->type eq 'regular') {
            # manage the special markup
            if ($el->string =~ m/\A\s*-----*\s*\z/s) {
                push @pieces, $self->manage_hr($el), $self->format_anchors($el);
            }
            # an image by itself, so avoid it wrapping with <p></p>,
            # but only if just 1 is found. With multiple one, we get
            # incorrect output anyway, so who cares?
            elsif ($el->string =~ m/\A\s*\[\[\s*$imagere\s*\]
                                    (\[[^\]\[]+?\])?\]\s*\z/sx and
                   $el->string !~ m/\[\[.*\[\[/s) {
                push @pieces, $self->format_anchors($el), $self->manage_regular($el);
            }
            else {
                push @pieces, $self->manage_paragraph($el);
            }
        }
        elsif ($el->type eq 'standalone') {
            push @pieces, $self->manage_regular($el);
        }
        elsif ($el->type eq 'dt') {
            push @pieces, $self->manage_regular($el);
        }
        elsif ($el->is_header) {
            # if we want a split html, we cut here and flush the footnotes
            if ($el->type =~ m/h[1-4]/ and $split and @pieces) {
                
                if ($self->is_html) {
                    foreach my $fn ($self->flush_footnotes) {
                        push @pieces, $self->manage_html_footnote($fn);
                    }
                    foreach my $nested ($self->flush_secondary_footnotes) {
                        push @pieces, $self->manage_html_footnote($nested);
                    }
                    die "Footnotes still in the stack!" if $self->flush_footnotes;
                    die "Secondary footnotes still in the stack!" if $self->flush_secondary_footnotes;
                }
                push @splat, join("", @pieces);
                @pieces = ();
                # all done
            }

            # then continue as usual
            push @pieces, $self->manage_header($el);
        }
        elsif ($el->type eq 'verse') {
            push @pieces, $self->format_anchors($el), $self->manage_verse($el);
        }
        elsif ($el->type eq 'inlinecomment') {
            push @pieces, $self->manage_inline_comment($el);
        }
        elsif ($el->type eq 'comment') {
            push @pieces, $self->manage_comment($el);
        }
        elsif ($el->type eq 'table') {
            push @pieces, $self->format_anchors($el), $self->manage_table($el);
        }
        elsif ($el->type eq 'example') {
            push @pieces, $self->format_anchors($el), $self->manage_example($el);
        }
        elsif ($el->type eq 'newpage') {
            push @pieces, $self->manage_newpage($el), $self->format_anchors($el);
        }
        else {
            die "Unrecognized element: " . $el->type;
        }
    }
    if ($self->is_html) {
        foreach my $fn ($self->flush_footnotes) {
            push @pieces, $self->manage_html_footnote($fn);
        }
        foreach my $nested ($self->flush_secondary_footnotes) {
            push @pieces, $self->manage_html_footnote($nested);
        }
        die "Footnotes still in the stack!" if $self->flush_footnotes;
        die "Secondary footnotes still in the stack!" if $self->flush_secondary_footnotes;
    }

    if ($split) {
        # catch the last
        push @splat, join("", @pieces);
        # and return
        return \@splat;
    }
    return \@pieces;
}

=item header

Return the formatted header as an hashref with key/value
pairs.

=cut

sub header {
    my $self = shift;
    my %directives = $self->document->raw_header;
    my %out;
    while (my ($k, $v) = each %directives) {
        $out{$k} = $self->manage_regular($v);
    }
    return \%out;
}

=back

=head2 Internal Methods

=over 4

=item add_footnote($element)

Add the footnote to the internal list of found footnotes.

=cut

sub add_footnote {
    my ($self, $fn) = @_;
    return unless defined($fn);
    if ($fn->type eq 'footnote') {
        $self->_add_primary_footnote($fn);
    }
    elsif ($fn->type eq 'secondary_footnote') {
        $self->_add_secondary_footnote($fn);
    }
    else {
        die "Wrong element type passed: " . $fn->type . " " . $fn->string;
    }
}

sub _add_primary_footnote {
    my ($self, $fn) = @_;
    unless (defined $self->{_fn_list}) {
        $self->{_fn_list} = [];
    }
    push @{$self->{_fn_list}}, $fn;
}

sub _add_secondary_footnote {
    my ($self, $fn) = @_;
    unless (defined $self->{_sec_fn_list}) {
        $self->{_sec_fn_list} = [];
    }
    push @{$self->{_sec_fn_list}}, $fn;
}

=item flush_footnotes

Return the list of primary footnotes found as a list of elements.

=item flush_secondary_footnotes

Return the list of secondary footnotes found as a list of elements.

=cut

sub flush_footnotes {
    my $self = shift;
    return unless (defined $self->{_fn_list});
    # if we flush, we flush and forget, so we don't collect them again
    # on the next call
    return sort { $a->footnote_number <=> $b->footnote_number } @{delete $self->{_fn_list}};
}

sub flush_secondary_footnotes {
    my $self = shift;
    # as above
    return unless (defined $self->{_sec_fn_list});
    return sort { $a->footnote_number <=> $b->footnote_number } @{delete $self->{_sec_fn_list}};
}

=item manage_html_footnote

=cut

sub manage_html_footnote {
    my ($self, $element) = @_;
    return unless $element;
    my $anchors = $self->format_anchors($element);
    my $fn_num = $element->footnote_index;
    my $fn_symbol = $element->footnote_symbol;
    my $class;
    if ($element->type eq 'footnote') {
        $class = 'fnline';
    }
    elsif ($element->type eq 'secondary_footnote') {
        $class = 'secondary-fnline';
    }
    else {
        die "wrong type " . $element->type . '  ' . $element->string;
    }
    my $chunk = qq{\n<p class="$class"><a class="footnotebody"} . " "
      . qq{href="#fn_back${fn_num}" id="fn${fn_num}">$fn_symbol</a>$anchors }
      . $self->manage_regular($element) .
          qq{</p>\n};
}

=item blkstring

=cut

sub blkstring  {
    my ($self, $start_stop, $block, %attributes) = @_;
    die "Wrong usage! Missing params $start_stop, $block"
      unless ($start_stop && $block);
    die "Wrong usage!\n" unless ($start_stop eq 'stop' or
                                 $start_stop eq 'start');
    my $table = $self->blk_table;
    die "Table is missing an element $start_stop  $block "
      unless exists $table->{$block}->{$start_stop}->{$self->fmt};
    my $string = $table->{$block}->{$start_stop}->{$self->fmt};
    if (ref($string)) {
        return $string->(%attributes);
    }
    else {
        return $string;
    }
}

=item manage_regular($element_or_string, %options)

Main routine to transform a string to the given format

Options:

=over 4

=item nolinks

If set to true, do not parse the links and consider them plain strings

=item anchors

If set to true, parse the anchors and return two elements, the first
is the processed string, the second is the processed anchors string.

=back

=item inline_elements($string)

Parse the provided string into a list of L<Text::Amuse::InlineElement>
objects.

=cut

sub inline_elements {
    my ($self, $string) = @_;
    return unless length($string);
    my @list;
    if ($string =~ m{\A\s*\<br */*\>\s*\z}) {
        return Text::Amuse::InlineElement->new(string => $string,
                                               type => 'bigskip',
                                               last_position => length($string),
                                               fmt => $self->fmt,
                                               lang => $self->_lang,
                                              );
    }
    pos($string) = 0;
    while ($string =~ m{\G # last match
                        (?<text>.*?) # something not greedy, even nothing
                        (?<raw>
                            # these are OR, so order matters.
                            # link is the most greedy, as it could have inline markup in the second argument.
                            (?<link>         \[\[[^\[].*?\]\])      |

                            # please note: verbatim, code, = =, are
                            # greedy, the first will slurp up to the
                            # next matching. one

                            (?<verbatim>      \<verbatim\> .*? \<\/verbatim\>      ) |
                            (?<verbatim_code> \<code\>     .*? \<\/code\>          ) |
                            (?<verbatim_code> (?<![[:alnum:]])\=(?=\S)  .+? (?<=\S)\=(?![[:alnum:]]) ) |
                            (?<bidimarker>   (?:\<\<\<|\>\>\>) ) |
                            (?<pri_footnote> \s*\[[1-9][0-9]*\]) |
                            (?<sec_footnote> \s*\{[1-9][0-9]*\}) |
                            (?<tag> \<
                                (?<close>\/?)
                                (?<tag_name> strong | em |  strike | del | sup |  sub )
                                \>
                            ) |
                            (?<nobreakspace>  \~\~         ) |
                            (?<inline>(?:\*\*\*|\*\*|\*)   ) |
                            (?<br> \x{20}*\< br \x{20}* \/?\>)
                        )}gcxms) {
        # this is a mammuth, but hey
        my %captures = %+;
        my $text = delete $captures{text};
        my $raw = delete $captures{raw};
        my $position = pos($string);
        if (length($text)) {
            push @list, Text::Amuse::InlineElement->new(string => $text,
                                                        type => 'text',
                                                        last_position => $position - length($raw),
                                                        fmt => $self->fmt,
                                                        lang => $self->_lang,
                                                       );
        }
        my %args = (
                    string => $raw,
                    last_position => $position,
                    fmt => $self->fmt,
                    lang => $self->_lang,
                   );

        if (delete $captures{tag}) {
            my $close = delete $captures{close};
            $args{type} = $close ? 'close' : 'open';
            $args{tag} = delete $captures{tag_name} or die "Missing tag_name, this is a bug:  <$string>";
        }
        elsif (my $tag = delete $captures{inline}) {
            $args{type} = 'inline';
            $args{tag} = $tag;
        }
        elsif (delete $captures{close_inline}) {
            $args{type} = 'close_inline';
            $args{tag} = delete $captures{close_inline_name} or die "Missing close_inline_name in <$string>";
        }
        else {
            my ($type, @rest) = keys %captures;
            die "Too many keys in <$string> the capture hash: @rest" if @rest;
            delete $captures{$type};
            $args{type} = $type;
        }
        die "Unprocessed captures %captures in <$string>" if %captures;
        push @list, Text::Amuse::InlineElement->new(%args);
    }
    my $offset = (@list ? $list[-1]->last_position : 0);
    my $last_chunk = substr $string, $offset;
    push @list, Text::Amuse::InlineElement->new(string => $last_chunk,
                                                type => 'text',
                                                fmt => $self->fmt,
                                                lang => $self->_lang,
                                                last_position => $offset + length($last_chunk),
                                               );
    die "Chunks lost during processing <$string>" unless $string eq join('', map { $_->string } @list);
    if (@list and $list[0] and $list[0]->type eq 'br') {
        $list[0]->type('noindent');
    }
    return @list;
}

sub manage_regular {
    my ($self, $el, %opts) = @_;
    my $string;
    my $insert_primary_footnote = 1;
    my $insert_secondary_footnote = 1;
    my $el_object;
    # we can accept even plain string;
    if (ref($el) eq "") {
        $string = $el;
    } else {
        $el_object = $el;
        $string = $el->string;
        if ($el->type eq 'footnote') {
            $insert_primary_footnote = 0;
        }
        elsif ($el->type eq 'secondary_footnote') {
            $insert_primary_footnote = 0;
            $insert_secondary_footnote = 0;
        }
    }
    unless (defined $string) {
        $string = '';
    }

    # we do the processing in more steps. It may be more expensive,
    # but at least the code should be clearer.

    my @pieces = $self->inline_elements($string);
    my @processed;
    my $current_direction = '';
  BIDIPROC:
    while (@pieces) {
        my $piece = shift @pieces;
        my %dirs = (
                    '<<<' => 'rtl',
                    '>>>' => 'ltr',
                   );
        if ($piece->type eq 'bidimarker') {
            $self->document->set_bidi_document;
            my $dir = $dirs{$piece->string} or die "Invalid bidimarker " . $piece->string;
            # we need to close
            if ($current_direction) {
                if ($dir ne $current_direction) {
                    push @processed, Text::Amuse::InlineElement->new(string => '',
                                                                     fmt => $self->fmt,
                                                                     lang => $self->_lang,
                                                                     tag => $current_direction,
                                                                     type => 'close');
                    $current_direction = '';
                }
                else {
                    warn "$string is trying to set direction to $dir twice!, ignoring\n";
                }
            }
            # we need to open
            else {
                $current_direction = $dir;
                push @processed, Text::Amuse::InlineElement->new(string => '',
                                                                 fmt => $self->fmt,
                                                                 lang => $self->_lang,
                                                                 tag => $current_direction,
                                                                 type => 'open');
            }
        }
        else {
            push @processed, $piece;
        }
    }
    if ($current_direction) {
        push @processed, Text::Amuse::InlineElement->new(string => '',
                                                         fmt => $self->fmt,
                                                         lang => $self->_lang,
                                                         tag => $current_direction,
                                                         type => 'close');
        $current_direction = '';
    }

    # now we decide what to do with the inline elements: either turn
    # them into open/close tag via unroll, or turn them into regular
    # text

    # given the way we parsed the string, we have to do another round
    # to check if the open/close are legit. This would have been
    # probably done better with regexp, but we're down this road now
    # and no turning back.

  CHECK_LEGIT:
    {
        for (my $i = 0; $i <= $#processed; $i++) {

            my $el = $processed[$i];
            if ($el->type eq 'inline') {
                if ($i > 0 and $i < $#processed) {
                    if ($processed[$i - 1]->string =~ m/[[:alnum:]]\z/ and
                        $processed[$i + 1]->string =~ m/\A[[:alnum:]]/) {
                        $el->type('text');
                        $el->tag('');
                    }
                }
            }
        }
    }


    # print Dumper(\@processed);
    my @tracking;
  MARKUP:
    while (@processed) {
        my $piece = shift @processed;
        if ($piece->type eq 'inline') {
            my $previous = @pieces ? $pieces[-1] : undef;
            my $next = @processed ? $processed[0] : undef;

            # first element can only open if there is a next one.
            if (!$previous) {
                if ($next and
                    scalar(grep { $_->tag eq $piece->tag } @processed) and
                    $next->string =~ m/\A\S/) {
                    print "Opening initial " . $piece->string . "\n" if DEBUG;
                    $piece->type('open_inline');
                    push @pieces, $piece;
                    push @tracking, $piece->tag;
                    next MARKUP;
                }
            }
            elsif (!$next) {
                # last element, can only close
                if (@tracking and
                    $piece->tag eq $tracking[-1] and
                    $previous->string =~ m/\S\z/) {
                    print "Closing final " . $piece->string . "\n" if DEBUG;
                    $piece->type('close_inline');
                    push @pieces, $piece;
                    pop @tracking;
                    next MARKUP;

                }
            }
            # in the middle.
            else {
                print $piece->string . " is in the middle\n" if DEBUG;
                # print Dumper([ \@processed, \@pieces, \@tracking, $next, $previous ]);
                if (@tracking and
                    $piece->tag eq $tracking[-1] and
                    $previous->string =~ m/\S\z/) {
                    if ($previous->type ne 'open_inline') {
                        $piece->type('close_inline');
                        print "Closing " . $piece->string . "\n" if DEBUG;
                        push @pieces, $piece;
                        pop @tracking;
                        next MARKUP;
                    }
                }
                elsif ($next->string =~ m/\A\S/ and
                    $previous->string =~ m/[[:^alnum:]]\z/ and
                    scalar(grep { $_->tag eq $piece->tag } @processed)) {
                    print "Opening " . $piece->string . "\n" if DEBUG;
                    $piece->type('open_inline');
                    push @pieces, $piece;
                    push @tracking, $piece->tag;
                    next MARKUP;
                }
            }
            print "Nothing to do for " . $piece->string . "\n" if DEBUG;
            # default to text
            $piece->type('text');
        }
        push @pieces, $piece;
    }

    # we need to do another pass to assert there is a match. Sometime
    # I regret to solve everything with s/<code>.+</code>/.../ but
    # that has other problems.

    @tracking = ();
    # print Dumper(\@pieces);

    my $warning = 'Found %s tag %s '
                  . " in <$string> without a matching closing tag. "
                  . "Leaving it as-is, but it's unlikely you want this. "
                  . "To suppress this warning, wrap it around <verbatim>\n";

  UNROLL:
    while (@pieces) {
        my $piece = shift @pieces;
        if ($piece->type eq 'open_inline') {
            # check if we have a matching close in the rest of the string
            if (grep { $_->type eq 'close_inline' and $_->tag eq $piece->tag } @pieces) {
                push @tracking, $piece->tag;
                push @processed, $piece->unroll;
                next UNROLL;
            }
            else {
                warn sprintf($warning, $piece->type, $piece->tag);
                $piece->type('text');
            }
        }
        elsif ($piece->type eq 'close_inline') {
            if (@tracking and $tracking[-1] eq $piece->tag) {
                push @processed, $piece->unroll;
                pop @tracking;
                next UNROLL;
            }
            else {
                warn sprintf($warning, $piece->type, $piece->tag);
                $piece->type('text');
            }
        }
        push @processed, $piece;
    }

    # print Dumper(\@processed);

    # now validate the tags: open and close
    my @tagpile;
  INLINETAG:
    while (@processed) {
        my $piece = shift @processed;
        if ($piece->type eq 'open') {
            # look forward for a matching tag
            if (grep { $_->type eq 'close' and $_->tag eq $piece->tag } @processed) {
                push @tagpile, $piece->tag;
            }
            else {
                warn sprintf($warning, $piece->type, $piece->tag);
                $piece->type('text');
            }
        }
        elsif ($piece->type eq 'close') {
            # check if there is a matching opening
            if (@tagpile and $tagpile[-1] eq $piece->tag) {
                # all match, can go
                # and remove from the pile
                pop @tagpile;
                if ($pieces[-1]->type eq 'open' and
                    $pieces[-1]->tag eq $piece->tag) {
                    pop @pieces;
                    next INLINETAG;
                }
            }
            else {
                warn sprintf($warning, $piece->type, $piece->tag);
                $piece->type('text');
            }
        }
        push @pieces, $piece;
    }

    # print Dumper(\@pieces);

    while (@tagpile) {
        my $unclosed = pop @tagpile;
        warn "Found unclosed tag $unclosed in string <$string>, closing it\n";
        push @pieces, Text::Amuse::InlineElement->new(string => '',
                                                      fmt => $self->fmt,
                                                      lang => $self->_lang,
                                                      tag => $unclosed,
                                                      type => 'close');
    }

    # now we're hopefully set.
    my @out;
  CHUNK:
    while (@pieces) {
        my $piece = shift @pieces;
        if ($piece->type eq 'link') {
            if ($opts{nolinks}) {
                $piece->type('text');
            }
            else {
                push @out, $self->linkify($piece->string);
                next CHUNK;
            }
        }
        elsif ($piece->type eq 'pri_footnote') {
            if ($insert_primary_footnote and
                my $pri_fn = $self->document->get_footnote($piece->string)) {
                if ($self->is_html and $piece->string =~ m/\A(\s+)/) {
                    push @out, $1;
                }
                push @out, $self->_format_footnote($pri_fn);
                next CHUNK;
            }
            else {
                $piece->type('text');
            }
        }
        elsif ($piece->type eq 'sec_footnote') {
            if ($insert_secondary_footnote and
                my $sec_fn = $self->document->get_footnote($piece->string)) {
                if ($self->is_html and $piece->string =~ m/\A(\s+)/) {
                    push @out, $1;
                }
                push @out, $self->_format_footnote($sec_fn);
                next CHUNK;
            }
            else {
                $piece->type('text');
            }
        }
        push @out, $piece->stringify;
    }
    return join('', @out);
}

sub _format_footnote {
    my ($self, $element) = @_;
    if ($self->is_latex) {
        # print "Calling manage_regular from format_footnote " . Dumper($element);
        my $footnote = $self->manage_regular($element);
        my $anchors = $self->format_anchors($element);
        $footnote =~ s/\s+/ /gs;
        $footnote =~ s/ +$//s;
        # covert <br> to \par in latex. those \\ in the footnotes are
        # pretty much ugly. Also the syntax doesn't permit to have
        # multiple paragraphs separated by a blank line in a footnote.
        # However, this is going to fail with footnotes in the
        # headings, so we have to call \endgraf instead
        # https://tex.stackexchange.com/questions/248620/footnote-of-several-paragraphs-length-to-section-title
        $footnote =~ s/\\forcelinebreak /\\protect\\endgraf /g;
        if ($element->type eq 'secondary_footnote') {
            return '\footnoteB{' . $anchors . $footnote . '}';
        }
        else {
            return '\footnote{' . $anchors . $footnote . '}';
        }
    } elsif ($self->is_html) {
        # in html, just remember the number
        $self->add_footnote($element);
        my $fn_num = $element->footnote_index;
        my $fn_symbol = $element->footnote_symbol;
        return
          qq(<a href="#fn${fn_num}" class="footnote" ) .
          qq(id="fn_back${fn_num}">$fn_symbol</a>);
    }
    else {
        die "Not reached"
    }
}

=item safe($string)

Be sure that the strings passed are properly escaped for the current
format, to avoid command injection.

=cut

sub safe {
    my ($self, $string) = @_;
    return Text::Amuse::InlineElement->new(fmt => $self->fmt,
                                           lang => $self->_lang,
                                    string => $string,
                                    type => 'safe')->stringify;
}


=item manage_paragraph

=cut


sub manage_paragraph {
    my ($self, $el) = @_;
    my $body = $self->manage_regular($el);
    chomp $body;
    return $self->blkstring(start  => "p") . $self->format_anchors($el) . $body . $self->blkstring(stop => "p");
}

=item manage_header

=cut

sub manage_header {
    my ($self, $el) = @_;
    # print Dumper([$el->anchors]);
    my $body_with_no_footnotes = $el->string;
    my $has_fn;
    my $catch_fn = sub {
        if ($self->document->get_footnote($_[0])) {
            $has_fn++;
            return ''
        } else {
            return $1;
        }
    };
    $body_with_no_footnotes =~ s/(
                                     \{ [1-9][0-9]* \}
                                 |
                                     \[ [1-9][0-9]* \]
                                 )
                                /$catch_fn->($1)/gxe;
    undef $catch_fn;
    my $anchors = $self->format_anchors($el);
    my ($body_for_toc);
    if ($has_fn) {
        ($body_for_toc) = $self->manage_regular($body_with_no_footnotes, nolinks => 1);
    }
    my ($body) = $self->manage_regular($el, nolinks => 1);
    chomp $body;
    if (defined $body_for_toc) {
        $body_for_toc =~ s/\s+/ /g;
        $body_for_toc =~ s/\s+\z//;
    }
    my $leading = $self->blkstring(start => $el->type,
                                   toc_entry => ($has_fn ? $body_for_toc : undef));
    my $trailing = $self->blkstring(stop => $el->type);
    if ($anchors) {
        if ($self->is_html) {
            #insert the <a> before the text
            $leading .= $anchors;
        }
        elsif ($self->is_latex) {
            # latex doesn't like it inside \chapter{}
            $trailing .= $anchors;
        }
        else { die "Not reached" }
    }
    # add them to the ToC for html output;
    if ($el->type =~ m/h([1-4])/) {
        my $level = $1;
        my $tocline = $body;
        my $index = $self->add_to_table_of_contents($level => (defined($body_for_toc) ? $body_for_toc : $body));
        $level++; # increment by one
        die "wtf, no index for toc?" unless $index;

        # inject the id into the html ToC (and the anchor)
        if ($self->is_html) {
            $leading = "<h" . $level .
              qq{ id="toc$index">} . $anchors;
        }
    }
    return $leading . $body . $trailing . "\n";
}

=item add_to_table_of_contents

When we catch an header, we save it in the Output object, so we can
emit the ToC. Level 5 is excluded as per doc.

It returns the numerical index (so you can inject the id).

=cut

sub add_to_table_of_contents {
    my ($self, $level, $string) = @_;
    return unless ($level and defined($string));
    unless (defined $self->{_toc_entries}) {
        $self->{_toc_entries} = [];
    }
    my $index = scalar(@{$self->{_toc_entries}});
    push @{$self->{_toc_entries}}, { level => $level,
                                     string => $string,
                                     index => ++$index,
                                   };
    return $index;
}

=item reset_toc_stack

Clear out the list. This is called at the beginning of the main loop,
so we don't collect duplicates over multiple runs.

=cut

sub reset_toc_stack {
    my $self = shift;
    delete $self->{_toc_entries} if defined $self->{_toc_entries};
}

=item table_of_contents

Emit the formatted ToC (if any). Please note that this method works
even for the LaTeX format, even if does not produce usable output.

This because we can test if we need to emit a table of contents
looking at this without searching the whole output.

The output is a list of hashref, where each hashref has the following keys:

=over 4

=item level

The level of the header. Currently we store only levels 1-4, defining
part(1), chapter(2), section(3) and subsection(4). Any other value
means something is off (a.k.a., you found a bug).

=item index

The index of the entry, starting from 1.

=item string

The output.

=back

The hashrefs are returned as copies, so they are safe to
manipulate.

=cut

sub table_of_contents {
    my $self = shift;
    my $internal_toc = $self->{_toc_entries};
    my @toc;
    return @toc unless $internal_toc; # no ToC gets undef
    # do a deep copy and return;
    foreach my $entry (@$internal_toc) {
        push @toc, { %$entry };
    }
    return @toc;
}

=item manage_verse

=cut

sub manage_verse {
    my ($self, $el) = @_;
    my ($lead, $stanzasep);
    if ($self->is_html) {
        $lead = '&#160;';
        $stanzasep = "\n<br /><br />\n";
    }
    elsif ($self->is_latex) {
        $lead = "~";
        $stanzasep = "\n\n";
    }
    else { die "Not reached" }

    my (@chunks) = split(/\n/, $el->string);
    my (@out, @stanza);
    foreach my $l (@chunks) {
        if ($l =~ m/\A( *)(.+?)\z/s) {
            my $leading = $lead x length($1);
            my $text = $self->manage_regular($2);
            if (length($text)) {
                push @stanza, $leading . $text;
            }
        }
        elsif ($l =~ m/\A\s*\z/s) {
            push @out, $self->_format_stanza(\@stanza);
            die "wtf" if @stanza;
        }
        else {
            die "wtf?";
        }
    }
    # flush the stanzas
    push @out, $self->_format_stanza(\@stanza) if @stanza;
    die "wtf" if @stanza;

    # process
    return $self->blkstring(start => $el->type) .
      join($stanzasep, @out) . $self->blkstring(stop => $el->type);
}

sub _format_stanza {
    my ($self, $stanza) = @_;

    my $eol;
    if ($self->is_html) {
        $eol = "<br />\n";
    }
    elsif ($self->is_latex) {
        $eol = " \\\\\n";
    }
    else { die "Not reached" };

    my $stanza_string = '';
    if (@$stanza) {
        $stanza_string = join($eol, @$stanza);
        @$stanza = ();
    }
    return $stanza_string;
}


=item manage_comment

=item manage_inline_comment

=cut

sub manage_inline_comment {
    my ($self, $el) = @_;
    my $body = $self->safe($el->string);
    $body =~ s/\n\z//;
    $body =~ s/\s/ /g; # remove eventual newlines, even we don't expect any

    if ($self->is_html) {
        return q{<div class="comment" style="display:none">} . $body . qq{</div>\n};
    }
    elsif ($self->is_latex) {
        return q{% } . $body . "\n";
    }
    else {
        die "Not reached";
    }
}

sub manage_comment {
    my ($self, $el) = @_;
    my $body = $self->safe($el->string);
    chomp $body;
    return $self->blkstring(start => $el->type) .
      $body . $self->blkstring(stop => $el->type);
}

=item manage_table

=cut

sub manage_table {
    my ($self, $el) = @_;
    my $thash = $self->_split_table_in_hash($el->string);
    if ($self->is_html) {
        return $self->manage_table_html($thash);
    }
    elsif ($self->is_latex) {
        return $self->manage_table_ltx($thash);
    }
    else { die "Not reached" }
}

=item manage_table_html

=cut

sub manage_table_html {
    my ($self, $table) = @_;
    my @out;
    my $map = $self->html_table_mapping;
    # here it's full of hardcoded things, but it can't be done differently
    push @out, "\n<table>";

    # the hash is always defined
    if ($table->{caption} ne "") {
        push @out, "<caption>"
          . $self->manage_regular($table->{caption})
            . "</caption>";
    }

    foreach my $tablepart (qw/head foot body/) {
        next unless @{$table->{$tablepart}};
        push @out, $map->{$tablepart}->{b};
        while (@{$table->{$tablepart}}) {
            my $cells = shift @{$table->{$tablepart}};

            push @out, $map->{btr};
            while (@$cells) {
                my $cell = shift @$cells;
                push @out, $map->{$tablepart}->{bcell},
                  $self->manage_regular($cell),
                    $map->{$tablepart}->{ecell},
                }
            push @out, $map->{etr};
        }
        push @out, $map->{$tablepart}->{e};
    }
    push @out, "</table>\n";
    return join("\n", @out);
}

=item manage_table_ltx

=cut

sub manage_table_ltx {
    my ($self, $table) = @_;

    my $out = {
               body => [],
               head => [],
               foot => [],
              };
    foreach my $t (qw/body head foot/) {
        foreach my $rt (@{$table->{$t}}) {
            my @row;
            foreach my $cell (@$rt) {
                # escape all!
                push @row, $self->manage_regular($cell);
            }
            my $texrow = join(q{ & }, @row);
            push @{$out->{$t}}, "\\relax " . $texrow . "  \\\\\n"
        }
    }
    # then we loop over what we have. First head, then body, and
    # finally foot
    my $has_caption;
    if (defined $table->{caption} and $table->{caption} ne '') {
        $has_caption = 1;
    }
    my $textable = '';
    if ($has_caption) {
        $textable .= "\\begin{table}[htbp!]\n";
    }
    else {
        $textable .= "\\bigskip\n\\noindent\n";
    }
    $textable .= " \\begin{minipage}[t]{\\textwidth}\n";
    $textable .= "\\begin{tabularx}{\\textwidth}{" ;
    $textable .= "|X" x $table->{counter};
    $textable .= "|}\n";
    if (my @head = @{$out->{head}}) {
        $textable .= "\\hline\n" . join("", @head);
    }
    if (my @body = @{$out->{body}}) {
        $textable .= "\\hline\n" . join("", @body);
    }
    if (my @foot = @{$out->{foot}}) {
        $textable .= "\\hline\n" . join("", @foot);
    }
    $textable .= "\\hline\n\\end{tabularx}\n";
    if ($has_caption) {
        $textable .= "\n\\caption[]{" .
          $self->manage_regular($table->{caption})
          . "}\n";
    }
    $textable .= "\\end{minipage}\n";
    if ($has_caption) {
        $textable .= "\\end{table}\n";
    }
    else {
        $textable .= "\\bigskip\n";
    }
    $textable .= "\n";
    # print $textable;
    return $textable;
}

=item _split_table_in_hash

=cut

sub _split_table_in_hash {
    my ($self, $table) = @_;
    return {} unless $table;
    my $output = {
                  caption => "",
                  body => [],
                  head => [],
                  foot => [],
                  counter => 0,
                 };
    foreach my $row (split "\n", $table) {
        if ($row =~ m/\A\s*\|\+\s*(.+?)\s*\+\|\s*\z/) {
            $output->{caption} = $1;
            next
        }
        my $dest;
        my @cells = split /\|+/, $row;
        if ($output->{counter} < scalar(@cells)) {
            $output->{counter} = scalar(@cells);
        }
        if ($row =~ m/\|\|\|/) {
            push @{$output->{foot}}, \@cells;
        } elsif ($row =~ m/\|\|/) {
            push @{$output->{head}}, \@cells;
        } else {
            push @{$output->{body}}, \@cells;
        }
    }
    # pad the cells with " " if their number doesn't match
    foreach my $part (qw/body head foot/) {
        foreach my $row (@{$output->{$part}}) {
            while (@$row < $output->{counter}) {
                # warn "Found uneven table: " . join (":", @$row), "\n";
                push @$row, " ";
            }
        }
    }
    return $output;
}

=item manage_example

=cut

sub manage_example {
    my ($self, $el) = @_;
    my $body = $self->safe($el->string);
    return $self->blkstring(start => $el->type) .
      $body . $self->blkstring(stop => $el->type);
}

=item manage_hr

Put an horizontal rule

=cut

sub manage_hr {
    my ($self, $el) = @_;
    die "Wtf?" if $el->string =~ m/\w/s; # don't eat chars by mistake
    if ($self->is_html) {
        return "\n<hr />\n";
    }
    elsif ($self->is_latex) {
        return "\n\\hairline\n\n";
    }
    else { die "Not reached" }
}

=item manage_newpage

If it's LaTeX, insert a newpage

=cut

sub manage_newpage {
    my ($self, $el) = @_;
    die "Wtf? " . $el->string if $el->string =~ m/\w/s; # don't eat chars by mistake
    if ($self->is_html) {
        my $out = $self->blkstring(start => 'center') .
          $self->manage_paragraph($el) .
            $self->blkstring(stop => 'center');
        return $out;
    }
    elsif ($self->is_latex) {
        return "\n\\clearpage\n\n";
    }
    else { die "Not reached" }
}

=back

=head2 Links management

=over 4

=item linkify($link)

Here we see if it's a single one or a link/desc pair. Then dispatch

=cut

sub linkify {
    my ($self, $link) = @_;
    die "no link passed" unless defined $link;
    # warn "Linkifying $link";
    if ($link =~ m/\A\[\[
                     \s*
                     (.+?) # link
                     \s*
                     \]\[
                     \s*
                     (.+?) # desc
                     \s*
                     \]\]\z
                    /sx) {
        return $self->format_links($1, $2);
    }

    elsif ($link =~ m/\[\[
		   \s*
		   (.+?) # link
		   \s*
		   \]\]/sx) {
        return $self->format_single_link($1);
    }

    else {
        die "Wtf??? $link"
    }
}

=item format_links

=cut

sub format_links {
    my ($self, $link, $desc) = @_;
    $desc = $self->manage_regular($desc);
    # first the images
    if (my $image = $self->find_image($link)) {
        my $src = $image->filename;
        $self->document->attachments($src);
        $image->desc($desc);
        return $image->output;
    }
    # links
    if ($link =~ m/\A\#([A-Za-z][A-Za-z0-9-]*)\z/) {
        my $linkname = $1;
        if ($self->is_html) {
            $link = "#text-amuse-label-$linkname";
        }
        elsif ($self->is_latex) {
            return "\\hyperref{}{amuse}{$linkname}{$desc}";
        }
    }

    if ($self->is_html) {
        $link = $self->_url_safe_escape($link);
        return qq{<a class="text-amuse-link" href="$link">$desc</a>};
    }
    elsif ($self->is_latex) {
        return qq/\\href{/ .
          $self->_url_safe_escape($link) .
            qq/}{$desc}/;
    }
    else { die "Not reached" }
}

=item format_single_link

=cut

sub format_single_link {
    my ($self, $link) = @_;
    # the re matches only clean names, no need to escape anything
    if (my $image = $self->find_image($link)) {
        $self->document->attachments($image->filename);
        return $image->output;
    }
    if ($link =~ m/\A\#([A-Za-z][A-Za-z0-9]+)\z/) {
        my $linkname = $1;
        # link is sane and safe
        if ($self->is_html) {
            $link = "#text-amuse-label-$linkname";
            return qq{<a class="text-amuse-link" href="$link">$linkname</a>};
        }
        elsif ($self->is_latex) {
            return "\\hyperref{}{amuse}{$linkname}{$linkname}";
        }
    }

    my $url = $self->_url_safe_escape($link);
    my $desc = $self->safe($link);
    if ($self->is_html) {
        return qq{<a class="text-amuse-link text-amuse-is-single-link" href="$url">$desc</a>};
    }
    elsif ($self->is_latex) {
        return "\\href{$url}{\\texttt{$desc}}";
    }
    else { die "Not reached" }
}

=item _url_safe_escape

=cut

sub _url_safe_escape {
  my ($self, $string) = @_;
  utf8::encode($string);
  $string =~ s/([^0-9a-zA-Z\.\/\:\;_\%\&\#\?\=\-])
	      /sprintf("%%%02X", ord ($1))/gesx;
  my $escaped = $self->safe($string);
  return $escaped;
}

=back

=head1 HELPERS

Methods providing some fixed values

=over 4

=item blk_table

=cut

sub blk_table {
    my $self = shift;
    unless ($self->{_block_table_map}) {
        $self->{_block_table_map} = $self->_build_blk_table;
    }
    return $self->{_block_table_map};
}

sub _build_blk_table {
    my $table = {
            'rtl' => {
                      start => {
                                html => '<div dir="rtl">',
                                # ltx => "\n\\setRTL\%",
                                ltx => "\n\\begin{RTL}\n",
                              },
                      stop => {
                                html => "</div>\n",
                                ltx => "\n\\end{RTL}\n",
                               # ltx => "\n\\setLTR\%",
                               },
                     },
            'ltr' => {
                      start => {
                                html => '<div dir="ltr">',
                                ltx => "\n\\begin{LTR}\n",
                                # ltx => "\n\\setLTR\%",
                              },
                      stop => {
                               html => "</div>\n", #  RLM (U+200F RIGHT-TO-LEFT MARK)
                               ltx => "\n\\end{LTR}\n",
                               # ltx => "\n\\setRTL\%",
                               },
                     },
                                  p =>  { start => {
                                                    ltx => "\n",
                                                    html => "\n<p>\n",
                                                   },
                                          stop => {
                                                   ltx => "\n\n",
                                                   html => "\n</p>\n",
                                                  },
                                        },
                                  h1 => {
                                         start => {
                                                   ltx => sub {
                                                       _latex_header(part => @_);
                                                   },
                                                   html => "<h2>",
                                                  },
                                         stop => {
                                                  ltx => "}\n",
                                                  html => "</h2>\n"
                                                 }
                                        },
                                  h2 => {
                                         start => {
                                                   ltx => sub {
                                                       _latex_header(chapter => @_);
                                                   },
                                                   html => "<h3>",
                                                  },
                                         stop => {
                                                  ltx => "}\n",
                                                  html => "</h3>\n"
                                                 }
                                        },
                                  h3 => {
                                         start => {
                                                   ltx => sub {
                                                       _latex_header(section => @_);
                                                   },
                                                   html => "<h4>",
                                                  },
                                         stop => {
                                                  ltx => "}\n",
                                                  html => "</h4>\n"
                                                 }
                                        },
                                  h4 => {
                                         start => {
                                                   ltx => sub {
                                                       _latex_header(subsection => @_);
                                                   },
                                                   html => "<h5>",
                                                  },
                                         stop => {
                                                  ltx => "}\n",
                                                  html => "</h5>\n"
                                                 }
                                        },
                                  h5 => {
                                         start => {
                                                   ltx => sub {
                                                       _latex_header(subsubsection => @_);
                                                   },
                                                   html => "<h6>",
                                                  },
                                         stop => {
                                                  ltx => "}\n",
                                                  html => "</h6>\n"
                                                 }
                                        },
                                  example => { 
                                              start => { 
                                                        html => "\n<pre class=\"example\">\n",
                                                        ltx => "\n\\begin{alltt}\n",
                                                       },
                                              stop => {
                                                       html => "</pre>\n",
                                                       ltx => "\\end{alltt}\n\n",
                                                      },
                                             },
                                  
                                  comment => {
                                              start => { # we could also use a more
                                                        # stable startstop hiding
                                                        html => qq{\n<!-- start comment -->\n<div class="comment" style="display:none">\n},
                                                        ltx => "\n\n\\begin{comment}\n",
                                                       },
                                              stop => {
                                                       html => "\n</div>\n<!-- stop comment -->\n",
                                                       ltx => "\n\\end{comment}\n\n",
                                                      },
                                             },
                                  verse => {
                                            start => {
                                                      html => "<div class=\"verse\">\n",
                                                      ltx => "\n\n\\begin{verse}\n",
                                                     },
                                            stop => {
                                                     html => "\n</div>\n",
                                                     ltx => "\n\\end{verse}\n\n",
                                                    },
                                           },
                               quote => {
                                         start => {
                                                   html => "\n<blockquote>\n",
                                                   ltx => "\n\n\\begin{quote}\n\n",
                                                  },
                                         stop => {
                                                  html => "\n</blockquote>\n",
                                                  ltx => "\n\n\\end{quote}\n\n",
                                                 },
                                        },
	      
                               biblio => {
                                          start => {
                                                    html => "\n<div class=\"biblio\">\n",
                                                    ltx => "\n\n\\begin{amusebiblio}\n\n",
                                                   },
                                          stop => {
                                                   html => "\n</div>\n",
                                                   ltx => "\n\n\\end{amusebiblio}\n\n",
                                                  },
                                         },
                               play => {
                                        start => {
                                                  html => "\n<div class=\"play\">\n",
                                                  ltx => "\n\n\\begin{amuseplay}\n\n",
                                                 },
                                        stop => {
                                                 html => "\n</div>\n",
                                                 ltx => "\n\n\\end{amuseplay}\n\n",
                                                },
                                       },

                               center => {
                                          start => {
                                                    html => "\n<div class=\"center\">\n",
                                                    ltx => "\n\n\\begin{center}\n",
                                                   },
                                          stop => {
                                                   html => "\n</div>\n",
                                                   ltx => "\n\\end{center}\n\n",
                                                  },
                                         },
                               right => {
                                         start => {
                                                   html => "\n<div class=\"right\">\n",
                                                   ltx => "\n\n\\begin{flushright}\n",
                                                  },
                                         stop => {
                                                  html => "\n</div>\n",
                                                  ltx => "\n\\end{flushright}\n\n",
                                                 },
                                        },

                               ul => {
                                      start => {
                                                html => "\n<ul>\n",
                                                ltx => "\n\\begin{itemize}\n",
                                               },
                                      stop => {
                                               html => "\n</ul>\n",
                                               ltx => "\n\\end{itemize}\n",
                                              },
                                     },

                               ol => {
                                      start => {
                                                html => sub {
                                                    _html_ol_element(n => @_);
                                                },
                                                ltx => sub {
                                                    _ltx_enum_element(1 => @_);
                                                },
                                               },
                                      stop => {
                                               html => "\n</ol>\n",
                                               ltx => "\n\\end{enumerate}\n",
                                              },
                                     },

                               oln => {
                                       start => {
                                                 html => sub {
                                                     _html_ol_element(n => @_);
                                                 },
                                                 ltx => sub {
                                                     _ltx_enum_element(1 => @_);
                                                 },
                                                },
                                       stop => {
                                                html => "\n</ol>\n",
                                                ltx => "\n\\end{enumerate}\n",
                                               },
                                      },

                               oli => {
                                       start => {
                                                 html => sub {
                                                     _html_ol_element(i => @_);
                                                 },
                                                 ltx => sub {
                                                     _ltx_enum_element(i => @_);
                                                 },
                                                },
                                       stop => {
                                                html => "\n</ol>\n",
                                                ltx => "\n\\end{enumerate}\n",
                                               },
                                      },

                               olI => {
                                       start => {
                                                 html => sub {
                                                     _html_ol_element(I => @_);
                                                 },
                                                 ltx => sub {
                                                     _ltx_enum_element(I => @_);
                                                 },
                                                },
                                       stop => {
                                                html => "\n</ol>\n",
                                                ltx => "\n\\end{enumerate}\n",
                                               },
                                      },

                               olA => {
                                       start => {
                                                 html => sub {
                                                     _html_ol_element(A => @_);
                                                 },
                                                 ltx => sub {
                                                     _ltx_enum_element(A => @_);
                                                 },
                                                },
                                       stop => {
                                                html => "\n</ol>\n",
                                                ltx => "\n\\end{enumerate}\n",
                                               },
                                      },

                               ola => {
                                       start => {
                                                 html => sub {
                                                     _html_ol_element(a => @_);
                                                 },
                                                 ltx => sub {
                                                     _ltx_enum_element(a => @_);
                                                 },
                                                },
                                       stop => {
                                                html => "\n</ol>\n",
                                                ltx => "\n\\end{enumerate}\n",
                                               },
                                      },

                               li => {
                                      start => {
                                                html => "<li>",
                                                ltx => "\\item\\relax ",
                                               },
                                      stop => {
                                               html => "\n</li>\n",
                                               ltx => "\n\n",
                                              },
                                     },
                 dl => {
                        start => {
                                  ltx => "\n\\begin{description}\n",
                                  html => "\n<dl>\n",
                                 },
                        stop => {
                                 ltx => "\n\\end{description}\n",
                                 html => "\n</dl>\n",
                                },
                       },
                 dt => {
                        start => {
                                  ltx => "\n\\item[{",
                                  html => "<dt>",
                                 },
                        stop => {
                                 ltx => "}] ",
                                 html => "</dt>",
                                },
                       },
                 dd => {
                        start => {
                                  ltx => "",
                                  html => "\n<dd>",
                                 },
                        stop => {
                                 ltx => "",
                                 html => "</dd>\n",
                                },
                       },
                };
    return $table;
}


=item image_re

Regular expression to match image links.

=cut

sub image_re {
    return qr{([0-9A-Za-z][0-9A-Za-z/-]+ # basename
                                    \. # dot
                                    (png|jpe?g)) # extension $2
                                ([ ]+
                                    ([0-9]+)? # width in percent
                                    ([ ]*([rlf]))?
                                )?}x;
}


=item find_image($link)

Given the input string $link, return undef if it's not an image. If it
is, return a Text::Amuse::Output::Image object.

=cut

sub find_image {
    my ($self, $link) = @_;
    my $imagere = $self->image_re;
    if ($link =~ m/\A$imagere\z/s) {
        my $filename = $1;
        my $width = $4;
        my $float = $6;
        return Text::Amuse::Output::Image->new(filename => $filename,
                                               width => $width,
                                               wrap => $float,
                                               fmt => $self->fmt);
    }
    else {
        # warn "Not recognized\n";
        return;
    }
}


=item url_re

=cut

sub url_re {
    return qr!((www\.|https?:\/\/)
                              \w[\w\-\.]+\.\w+ # domain
                              (:\d+)? # the port
                              # everything else, but start with a
                              # slash and end with a a \w, and don't
                              # tolerate spaces
                              (/(\S*\w)?)?)
                             !x;
}


=item html_table_mapping

=cut

sub html_table_mapping {
    return {
            head => {
                     b => " <thead>",
                     e => " </thead>",
                     bcell => "   <th>",
                     ecell => "   </th>",
                    },
            foot => {
                     b => " <tfoot>",
                     e => " </tfoot>",
                     bcell => "   <td>",
                     ecell => "   </td>",
                    },
            body => {
                     b => " <tbody>",
                     e => " </tbody>",
                     bcell => "   <td>",
                     ecell => "   </td>",
                    },
            btr => "  <tr>",
            etr => "  </tr>",
           };
}

sub _html_ol_element {
    my ($type, %attributes) = @_;
    my %map = (
               ol => '',
               n => '',
               i => 'lower-roman',
               I => 'upper-roman',
               A => 'upper-alpha',
               a => 'lower-alpha',
              );
    my $ol_type = '';
    if ($map{$type}) {
        $ol_type = qq{ style="list-style-type:$map{$type}"};
    }
    my $start = $attributes{start_list_index};
    my $start_string = '';
    if ($start and $start =~ m/\A[0-9]+\z/ and $start > 1) {
        $start_string = qq{ start="$start"};
    }
    return "\n<ol" . $ol_type . $start_string . ">\n";
}

sub _ltx_enum_element {
    my ($type, %attributes) = @_;
    my %map = (
               1 => '1',
               i => 'i',
               I => 'I',
               A => 'A',
               a => 'a',
              );
    my $string = "\n\\begin{enumerate}[";
    my $type_string = $map{$type} || '1';

    my $start = $attributes{start_list_index};
    my $start_string = '';
    if ($start and $start =~ m/\A[0-9]+\z/ and $start > 1) {
        $start_string = qq{, start=$start};
    }
    return $string . $type_string . '.' . $start_string . "]\n";
}

sub _latex_header {
    # All sectioning commands take the same general form, e.g.,
    # \chapter[TOCTITLE]{TITLE}
    my ($name, %attributes) = @_;
    if (defined $attributes{toc_entry}) {
        # we use the grouping here, to avoid chocking on [ ]
        return "\\" . $name . '[{' . $attributes{toc_entry} . '}]{'
    }
    else {
        return "\\" . $name . '{';
    }
}

=item format_anchors($element)

Return a formatted string with the anchors found in the element.

=cut

sub format_anchors {
    my ($self, $el) = @_;
    my $out = '';
    if (my @anchors = map { Text::Amuse::InlineElement->new(string => $_,
                                                            type => 'anchor',
                                                            lang => $self->_lang,
                                                            fmt => $self->fmt)->stringify } $el->anchors) {
        return join('', @anchors);
    }
    return $out;
}

=back

=cut

1;
