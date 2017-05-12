package Text::Amuse::Document;

use strict;
use warnings;
use Text::Amuse::Element;
use constant {
    IMAJOR => 1,
    IEQUAL => 0,
    IMINOR => -1,
};

# use Data::Dumper;

=head1 NAME

Text::Amuse::Document - core parser for L<Text::Amuse> (internal)

=head1 SYNOPSIS

The module is used internally by L<Text::Amuse>, so everything here is
pretty much internal only (and underdocumented). The useful stuff is
accessible via the L<Text::Amuse> class.

=head1 METHODS

=head3 new(file => $filename)

=cut

sub new {
    my $class = shift;
    my %args;
    my $self = {};
    if (@_ % 2 == 0) {
        %args = @_;
    }
    elsif (@_ == 1) {
        $args{file} = shift;
    }
    else {
        die "Wrong arguments! The constructor accepts only a filename\n";
    }
    if (-f $args{file}) {
        $self->{filename} = $args{file};
    } else {
        die "Wrong argument! $args{file} doesn't exist!\n"
    }
    $self->{debug} = 1 if $args{debug};
    bless $self, $class;
}


sub _debug {
    my $self = shift;
    my @args = @_;
    if ((@args) && $self->{debug}) {
        print join("\n", @args), "\n";
    }
}


=head3 filename

Return the filename of the processed file

=cut

sub filename {
    my $self = shift;
    return $self->{filename}
}

=head3 attachments

Return the list of the filenames of the attached files, as linked.
With an optional argument, store that file in the list.


=cut

sub attachments {
    my ($self, $arg) = @_;
    unless (defined $self->{_attached_files}) {
        $self->{_attached_files} = {};
    }
    if (defined $arg) {
        $self->{_attached_files}->{$arg} = 1;
        return;
    }
    else {
        return sort(keys %{$self->{_attached_files}});
    }
}


=head3 get_lines

Returns the raw input lines as a list, reading from the filename if
it's the first time we call it. Tabs, \r and trailing whitespace are
cleaned up.

=cut

sub get_lines {
    my $self = shift;
    my $file = $self->filename;
    $self->_debug("Reading $file");
    open (my $fh, "<:encoding(utf-8)", $file) or die "Couldn't open $file! $!\n";
    my @lines;
    while (my $l = <$fh>) {
        # EOL
        $l =~ s/\r\n/\n/gs;
        $l =~ s/\r/\n/gs;
        # TAB
        $l =~ s/\t/    /g;
        # trailing
        $l =~ s/ +$//mg;
        push @lines, $l;
    }
    close $fh;
    # store the lines in the object
    return \@lines;
}


sub _split_body_and_directives {
    my $self = shift;
    my (%directives, @body);
    my $in_meta = 1;
    my $lastdirective;
    my $input = $self->get_lines;
    # scan the line
    while (@$input) {
        my $line = shift @$input;
        if ($in_meta) {
            # reset the directives on blank lines
            if ($line =~ m/^\s*$/s) {
                $lastdirective = undef;
            } elsif ($line =~ m/^\#([A-Za-z0-9]+)(\s+(.+))?$/s) {
                my $dir = $1;
                if ($2) {
                    $directives{$dir} = $3;
                }
                else {
                    $directives{$dir} = '';
                }
                $lastdirective = $dir;
            } elsif ($lastdirective) {
                $directives{$lastdirective} .= $line;
            } else {
                $in_meta = 0
            }
        }
        next if $in_meta;
        push @body, $line;
    }
    push @body, "\n"; # append a newline
    # before returning, let's clean the %directives from EOLs
    foreach my $key (keys %directives) {
        $directives{$key} =~ s/\s/ /gs;
        $directives{$key} =~ s/\s+$//gs;
    }
    $self->{raw_body}   = \@body;
    $self->{raw_header} = \%directives;
}

=head3 raw_header

Accessor to the raw header of the muse file. The header is returned as
hash, with key/value pairs. Please note: NOT an hashref.

=cut

sub raw_header {
    my $self = shift;
    unless (defined $self->{raw_header}) {
        $self->_split_body_and_directives;
    }
    return %{$self->{raw_header}}
}

=head3 raw_body

Accessor to the raw body of the muse file. The body is returned as a
list of lines.

=cut

sub raw_body {
    my $self = shift;
    unless (defined $self->{raw_body}) {
        $self->_split_body_and_directives;
    }
    return @{$self->{raw_body}}
}

sub _parse_body {
    my $self = shift;
    $self->_debug("Parsing body");

    # be sure to start with a null block and reset the state
    my @parsed = ($self->_construct_element(""));
    $self->_current_el(undef);

    foreach my $l ($self->raw_body) {
        # if doesn't return anything, the thing got merged
        if (my $el = $self->_construct_element($l)) {
            push @parsed, $el;
        }
    }
    # turn the versep into verse now that the merging is done
    foreach my $el (@parsed) {
        if ($el->type eq 'versep') {
            $el->type('verse');
        }
    }
    my @out;
    my @listpile;
  LISTP:
    while (@parsed) {
        my $el = shift @parsed;
        if ($el->type eq 'li' or $el->type eq 'dd') {
            if (@listpile) {
                # indentation is major, open a new level
                if (_indentation_kinda_major($el, $listpile[-1])) {
                    push @out, $self->_opening_blocks_new_level($el);
                    push @listpile, $self->_closing_blocks_new_level($el);
                }
                else {
                    # close the lists until we get the the right level
                    while(@listpile and _indentation_kinda_minor($el, $listpile[-1])) {
                        push @out, pop @listpile;
                    }
                    if (@listpile) { # continue if open
                        if (_element_is_same_kind_as_in_list($el, \@listpile)) {
                            push @out, pop @listpile, $self->_opening_blocks($el);
                            push @listpile, $self->_closing_blocks($el);
                        }
                        else {
                            my $top = $listpile[-1];
                            while (@listpile and _indentation_kinda_equal($top, $listpile[-1])) {
                                # empty the pile until the indentation drops.
                                push @out, pop @listpile;
                            }
                            # and open a new level
                            push @out, $self->_opening_blocks_new_level($el);
                            push @listpile, $self->_closing_blocks_new_level($el);
                        }
                    }
                    else { # if by chance, we emptied all, start anew.
                        push @out, $self->_opening_blocks_new_level($el);
                        push @listpile, $self->_closing_blocks_new_level($el);
                    }
                }
            }
            # no list pile, this is the first element
            elsif ($self->_list_element_can_be_first($el)) {
                push @out, $self->_opening_blocks_new_level($el);
                push @listpile, $self->_closing_blocks_new_level($el);
            }
            else {
                # reparse and should become quote/center/right
                push @out, $self->_reparse_nolist($el);
                # call next to avoid being mangled.
                next LISTP;
            }
            $el->become_regular;
        }
        elsif ($el->type eq 'regular') {
            # the type is regular: It can only close or continue
            while (@listpile and _indentation_kinda_minor($el, $listpile[-1])) {
                push @out, pop @listpile;
            }
            if (@listpile) {
                $el->become_regular;
            }
        }
        elsif ($el->type ne 'null') { # something else: close the pile
            while (@listpile) {
                push @out, pop @listpile;
            }
        }
        push @out, $el;
    }
    # end of input?
    while (@listpile) {
        push @out, pop @listpile;
    }

    # now we use parsed as output
    my %footnotes;
    while (@out) {
        my $el = shift @out;
        if ($el->type eq 'footnote') {
            if ($el->removed =~ m/\A\[([0-9]+)\]\s+\z/) {
                warn "Overwriting footnote number $1" if exists $footnotes{$1};
                $footnotes{$1} = $el;
            }
            else { die "Something is wrong here! <" . $el->removed . ">"
                     . $el->string . "!" }
        }
        else {
            push @parsed, $el;
        }
    }
    $self->_raw_footnotes(\%footnotes);

    # unroll the quote/center/right blocks
    while (@parsed) {
        my $el = shift @parsed;
        if ($el->can_be_regular) {
            my $open =  $self->_create_block(open => $el->block, $el->indentation);
            my $close = $self->_create_block(close => $el->block, $el->indentation);
            $el->block("");
            push @out, $open, $el, $close;
        }
        else {
            push @out, $el;
        }
    }

    my @pile;
    while (@out) {
        my $el = shift @out;
        if ($el->type eq 'startblock') {
            push @pile, $self->_create_block(close => $el->block, $el->indentation);
            $self->_debug("Pushing " . $el->block);
            die "Uh?\n" unless $el->block;
        }
        elsif ($el->type eq 'stopblock') {
            my $exp = pop @pile;
            unless ($exp and $exp->block eq $el->block) {
                warn "Couldn't retrieve " . $el->block . " from the pile\n";
                # put it back
                push @pile, $exp if $exp;
                # so what to do here? just removed it
                next;
            }
        }
        elsif (@pile and $el->should_close_blocks) {
            while (@pile) {
                my $block = pop @pile;
                warn "Forcing the closing of " . $block->block . "\n";
                push @parsed, $block;
            }
        }
        push @parsed, $el;
    }
    # do we still have things into the pile?
    while (@pile) {
        push @parsed, pop @pile;
    }
    return \@parsed;
}

=head2 elements

Return the list of the elements which compose the body, once they have
properly parsed and packed. Footnotes are removed. (To get the
footnotes use the accessor below).

=cut

sub elements {
    my $self = shift;
    unless (defined $self->{_parsed_document}) {
        $self->{_parsed_document} = $self->_parse_body;
    }
    return @{$self->{_parsed_document}}
}

=head3 get_footnote

Accessor to the internal footnotes hash. You can access the footnote
with a numerical argument or even with a string like [123]

=cut

sub get_footnote {
    my ($self, $arg) = @_;
    return undef unless $arg;
    # ignore the brackets, if they are passed
    if ($arg =~ m/([0-9]+)/) {
        $arg = $1;
    }
    else {
        return undef;
    }
    if (exists $self->_raw_footnotes->{$arg}) {
        return $self->_raw_footnotes->{$arg};
    }
    else { return undef }
}


sub _raw_footnotes {
    my $self = shift;
    if (@_) {
        $self->{_raw_footnotes} = shift;
    }
    return $self->{_raw_footnotes};
}

sub _parse_string {
    my ($self, $l, %opts) = @_;
    die unless defined $l;
    my %element = (
                   rawline => $l,
                  );
    my $blockre = qr{(
                         biblio   |
                         play     |
                         comment  |
                         verse    |
                         center   |
                         right    |
                         example  |
                         quote
                     )}x;

    # null line is default, do nothing
    if ($l =~ m/^[\n\t ]*$/s) {
        # do nothing, already default
        $element{removed} = $l;
        return %element;
    }
    if ($l =~ m!^(<($blockre)>\s*)$!s) {
        $element{type} = "startblock";
        $element{removed} = $1;
        $element{block} = $2;
        return %element;
    }
    if ($l =~ m/^(\{\{\{)\s*$/s) {
        $element{type} = "startblock";
        $element{removed} = $l;
        $element{block} = 'example';
        $element{style} = '{{{}}}';
        return %element;
    }
    if ($l =~ m/^(\}\}\})\s*$/s) {
        $element{type} = "stopblock";
        $element{removed} = $l;
        $element{block} = 'example';
        $element{style} = '{{{}}}';
        return %element;
    }
    if ($l =~ m!^(</($blockre)>\s*)$!s) {
        $element{type} = "stopblock";
        $element{removed} = $1;
        $element{block} = $2;
        return %element;
    }
    # headers
    if ($l =~ m!^((\*{1,5}) )(.+)$!s) {
        $element{type} = "h" . length($2);
        $element{removed} = $1;
        $element{string} = $3;
        return %element;
    }
    if ($l =~ m/^(\> )(.*)/s) {
        $element{string} = $2;
        $element{removed} = $1;
        $element{type} = "versep";
        return %element;
    }
    if ($l =~ m/^(\>)$/s) {
        $element{string} = "\n";
        $element{removed} = ">";
        $element{type} = "versep";
        return %element;
    }
    if ($l =~ m/^(\x{20}+)/s and $l =~ m/\|/) {
        $element{type} = "table";
        $element{string} = $l;
        return %element;
    }
    if ($l =~ m/^(\; (.+))$/s) {
        $element{removed} = $l;
        $element{type} = "comment";
        return %element;
    }
    if ($l =~ m/^((\[[0-9]+\])\x{20}+)(.+)$/s) {
        $element{type} = "footnote";
        $element{string} = $3;
        $element{removed} = $1;
        return %element;
    }
    if ($l =~ m/^((\x{20}{6,})((\*\x{20}?){5})\s*)$/s) {
        $element{type} = "newpage";
        $element{removed} = $2;
        $element{string} = $3;
        return %element;
    }
    if ($l =~ m/\A
                (\x{20}+) # 1. initial space and indentation
                (.+) # 2. desc title
                (\x{20}+) # 3. space
                (\:\:) # 4 . separator
                ((\x{20}?)(.*)) # 5 6. space 7. text
                \z
               /xs) {
        $element{block} = 'dl';
        $element{type} = 'dd';
        $element{string} = $7;
        $element{attribute} = $2;
        $element{attribute_type} = 'dt';
        $element{removed} = $1 . $2 . $3 . $4 . $6;
        $element{indentation} = length($1);
        return %element;
    }
    if (!$opts{nolist}) {
        if ($l =~ m/^((\x{20}+)\-\x{20}+)(.*)/s) {
            $element{type} = "li";
            $element{removed} = $1;
            $element{string} = $3;
            $element{block} = "ul";
            $element{indentation} = length($2);
            return %element;
        }
        if ($l =~ m/^((\x{20}+)  # leading space and type $1
                        (  # the type               $2
                            [0-9]+   |
                            [a-zA-Z] |
                            [ixvl]+  |
                            [IXVL]+
                        )
                        \. #  single dot
                        \x{20}+)  # space
                    (.*) # the string itself $4
                   /sx) {
            my ($remove, $whitespace, $prefix, $text) = ($1, $2, $3, $4);
            $element{type} = "li";
            $element{removed} = $remove;
            $element{string} = $text;
            my $list_type = $self->_identify_list_type($prefix);
            $element{indentation} = length($whitespace);
            $element{block} = $list_type;
            return %element;
        }
    }
    if ($l =~ m/^(\x{20}{20,})([^ ].+)$/s) {
        $element{block} = "right";
        $element{type} = "regular";
        $element{removed} = $1;
        $element{string} = $2;
        return %element;
    }
    if ($l =~ m/^(\x{20}{6,})([^ ].+)$/s) {
        $element{block} = "center";
        $element{type} = "regular";
        $element{removed} = $1;
        $element{string} = $2;
        return %element;
    }
    if ($l =~ m/^(\x{20}{2,})([^ ].+)$/s) {
        $element{block} = "quote";
        $element{type} = "regular";
        $element{removed} = $1;
        $element{string} = $2;
        return %element;
    }
    # anything else is regular
    $element{type} = "regular";
    $element{string} = $l;
    return %element;
}


sub _identify_list_type {
    my ($self, $list_type) = @_;
    my $type;
    if ($list_type =~ m/\A[0-9]+\z/) {
        $type = "oln";
    } elsif ($list_type =~ m/\A[ixvl]+\z/) {
        $type = "oli";
    } elsif ($list_type =~ m/\A[IXVL]+\z/) {
        $type = "olI";
    } elsif ($list_type =~ m/\A[a-z]\z/) {
        $type = "ola";
    } elsif ($list_type =~ m/\A[A-Z]\z/) {
        $type = "olA";
    } else {
        die "$list_type unrecognized, fix your code\n";
    }
    return $type;
}

sub _list_element_can_be_first {
    my ($self, $el) = @_;
    # every dd can be the first
    return 1 if $el->type eq 'dd';
    return unless $el->type eq 'li';
    my $type = $el->block;
    my $prefix = $el->removed;
    if ($prefix =~ m/^\s{1,6}  # leading space
                     (  # the type               $1
                         - | ((1|a|A|i|I)\.)
                     )
                     \s+  # space
                     $/sx) {
        my $id = $1;
        if    ($type eq 'ul'  and $id eq '-' ) { return 1; }
        elsif ($type eq 'oln' and $id eq '1.') { return 1; }
        elsif ($type eq 'ola' and $id eq 'a.') { return 1; }
        elsif ($type eq 'olA' and $id eq 'A.') { return 1; }
        elsif ($type eq 'oli' and $id eq 'i.') { return 1; }
        elsif ($type eq 'olI' and $id eq 'I.') { return 1; }
    }
    return;
}

sub _current_el {
    my $self = shift;
    if (@_) {
        $self->{_current_el} = shift;
    }
    return $self->{_current_el};
}

sub _reparse_nolist {
    my ($self, $element) = @_;
    my %args = $self->_parse_string($element->rawline, nolist => 1);
    my $el = Text::Amuse::Element->new(%args);
    if ($el->type eq 'regular') {
        return $el;
    }
    else {
        die "Reparsing of " . $element->rawline . " led to " . $el->type;
    }
}

sub _construct_element {
    my ($self, $line) = @_;
    my $current = $self->_current_el;
    my %args = $self->_parse_string($line);
    my $element = Text::Amuse::Element->new(%args);

    # catch the examples. and the verse
    # <example> is greedy, and will stop only at another </example> or
    # at the end of input. Same is true for verse

    foreach my $block (qw/example verse/) {
        if ($current && $current->type eq $block) {
            if ($element->is_stop_element($current)) {
                # print Dumper($element) . " is closing\n";

                $self->_current_el(undef);
                return Text::Amuse::Element->new(type => 'null',
                                                 removed => $element->rawline,
                                                 rawline => $element->rawline);
            }
            else {
                # maybe check if we want to stop at headings if verse?
                # print Dumper($element) . " is appending\n";;
                $current->append($element);
                return;
            }
        }
        elsif ($element->is_start_block($block)) {
            $current = Text::Amuse::Element->new(type => $block,
                                                 style => $element->style,
                                                 removed => $element->rawline,
                                                 rawline => $element->rawline);
            $self->_current_el($current);
            return $current;
        }
    }

    # Pack the lines
    if ($current && $current->can_append($element)) {
        $current->append($element);
        return;
    }

    $self->_current_el($element);
    return $element;
}

sub _create_block {
    my ($self, $open_close, $block, $indentation) = @_;
    die unless $open_close && $block;
    my $type;
    if ($open_close eq 'open') {
        $type = 'startblock';
    }
    elsif ($open_close eq 'close') {
        $type = 'stopblock';
    }
    else {
        die "$open_close is not a valid op";
    }
    my $removed = '';
    if ($indentation) {
        $removed = ' ' x $indentation;
    }
    return Text::Amuse::Element->new(block => $block,
                                     type => $type,
                                     removed => $removed);
}

sub _opening_blocks {
    my ($self, $el) = @_;
    my @out;
    if ($el->attribute && $el->attribute_type) {
        @out = ($self->_create_block(open => $el->attribute_type, $el->indentation),
                Text::Amuse::Element->new(type => 'dt', string => $el->attribute),
                $self->_create_block(close => $el->attribute_type, $el->indentation));
    }
    push @out, $self->_create_block(open => $el->type, $el->indentation);
    return @out;
}

sub _closing_blocks {
    my ($self, $el) = @_;
    my @out = ($self->_create_block(close => $el->type, $el->indentation));
    return @out;
}
sub _opening_blocks_new_level {
    my ($self, $el) = @_;
    my @out = ($self->_create_block(open => $el->block, $el->indentation),
               $self->_opening_blocks($el));
    return @out;
}
sub _closing_blocks_new_level {
    my ($self, $el) = @_;
    my @out = ($self->_create_block(close => $el->block, $el->indentation),
               $self->_closing_blocks($el));
    return @out;
}

sub _indentation_kinda_minor {
    my $result = _indentation_compare(@_);
    if ($result == IMINOR) {
        return 1;
    }
    return 0;
}

sub _indentation_kinda_major {
    my $result = _indentation_compare(@_);
    if ($result == IMAJOR) {
        return 1;
    }
    return 0;
}

sub _indentation_kinda_equal {
    my $result = _indentation_compare(@_);
    if ($result == IEQUAL) {
        return 1;
    }
    return 0;
}

sub _indentation_compare {
    my ($first, $second) = @_;
    my $one_indent = $first->indentation;
    my $two_indent = $second->indentation;
    return _compare_tolerant($one_indent, $two_indent);
}

sub _compare_tolerant {
    my ($one_indent, $two_indent) = @_;
    # tolerance is zero if one of them is 0
    my $tolerance = 0;
    if ($one_indent && $two_indent) {
        $tolerance = 1;
    }
    my $diff = $one_indent - $two_indent;
    if ($diff - $tolerance > 0) {
        return IMAJOR;
    }
    elsif ($diff + $tolerance < 0) {
        return IMINOR;
    }
    else {
        return IEQUAL;
    }
}

sub _element_is_same_kind_as_in_list {
    my ($el, $list) = @_;
    my $find = $el->block;
    my $found = 0;
    for (my $i = $#$list; $i >= 0; $i--) {
        my $block = $list->[$i]->block;
        next if ($block eq 'li' or $block eq 'dd');
        if ($block eq $find) {
            $found = 1;
        }
        last;
    }
    return $found;
}


1;
