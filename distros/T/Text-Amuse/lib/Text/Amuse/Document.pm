package Text::Amuse::Document;

use strict;
use warnings;
use Text::Amuse::Element;
use Text::Amuse::Utils;
use File::Spec;
use constant {
    IMAJOR => 1,
    IEQUAL => 0,
    IMINOR => -1,
};

use Data::Dumper;

=head1 NAME

Text::Amuse::Document - core parser for L<Text::Amuse> (internal)

=head1 SYNOPSIS

The module is used internally by L<Text::Amuse>, so everything here is
pretty much internal only (and underdocumented). The useful stuff is
accessible via the L<Text::Amuse> class.

=head1 METHODS

=over 4

=item new(file => $filename, include_paths => \@paths )

=cut

sub new {
    my $class = shift;
    my %args;
    my $self = {
                _raw_footnotes => {},
                _current_footnote_indent => 0,
                _current_footnote_number => undef,
                _current_footnote_stack  => [],
                _list_element_pile => [],
                _list_parsing_output => [],
                _bidi_document => 0,
                _has_ruby => 0,
                include_paths => [],
                included_files => [],
                _other_doc_language_codes => [],
               };
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
    if ($args{include_paths}) {
        my @includes;
        if (ref($args{include_paths}) eq 'ARRAY') {
            push @includes, @{$args{include_paths}};
        }
        else {
            push @includes, $args{include_paths};
        }
        $self->{include_paths} = [ grep { length($_) && -d $_  } @includes ];
    }
    $self->{debug} = 1 if $args{debug};
    bless $self, $class;
}


=item include_paths

The return the list of directories where the included files need to be searched.

=item included_files

The return the list of files actually included.

=cut

sub include_paths {
    return @{ shift->{include_paths} };
}

sub included_files {
    return @{ shift->{included_files} };
}

sub _add_to_included_files {
    my ($self, @files) = @_;
    push @{shift->{included_files}}, @files;
}

sub _list_index_map {
    # numerals
    my $self = shift;
    unless ($self->{_list_index_map}) {
        my %map = map { $_ => $_ } (1..200); # never seen lists so long
        # this is a bit naif but will do. Generated with Roman module. We
        # support them to 89, otherwise you have to use i. i. i.

        my @romans = (qw/i ii iii iv v vi vii viii ix x xi xii xiii
                         xiv xv xvi xvii xviii xix xx xxi xxii xxiii
                         xxiv xxv xxvi xxvii xxviii xxix xxx xxxi
                         xxxii xxxiii xxxiv xxxv xxxvi xxxvii xxxviii
                         xxxix xl xli xlii xliii xliv xlv xlvi xlvii
                         xlviii xlix l li lii liii liv lv lvi lvii
                         lviii lix lx lxi lxii lxiii lxiv lxv lxvi
                         lxvii lxviii lxix lxx lxxi lxxii lxxiii lxxiv
                         lxxv lxxvi lxxvii lxxviii lxxix lxxx lxxxi
                         lxxxii lxxxiii lxxxiv lxxxv lxxxvi lxxxvii
                         lxxxviii lxxxix/);
        my @alpha = ('a'..'z');
        # we will need to take care of 'i', 'x', 'v', 'l', which can be both alpha or roman
        foreach my $list (\@alpha, \@romans) {
            my $lcount = 0;
            foreach my $letter (@$list) {
                $lcount++;
                $map{$letter} = $lcount;
                $map{uc($letter)} = $lcount;
            }
        }
        $self->{_list_index_map} = \%map;
    }
    return $self->{_list_index_map};
}


sub _debug {
    my $self = shift;
    my @args = @_;
    if ((@args) && $self->{debug}) {
        print join("\n", @args), "\n";
    }
}


=item filename

Return the filename of the processed file

=cut

sub filename {
    my $self = shift;
    return $self->{filename}
}

=item attachments

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

=item bidi_document

Return true if the document uses a bidirectionl marker.

=item set_bidi_document

Internal, set the bidi flag on.

=item has_ruby

Return true if the document uses the ruby

=item set_has_ruby

Internal, set the ruby flag on.

=cut

sub bidi_document {
    shift->{_bidi_document};
}

sub set_bidi_document {
    shift->{_bidi_document} = 1;
}

sub set_has_ruby {
    shift->{_has_ruby} = 1;
}

sub has_ruby {
    shift->{_has_ruby};
}



=item language_code

The language code of the document. This method will looks into the
header of the document, searching for the keys C<lang> or C<language>,
defaulting to C<en>.

=item other_language_codes

Same as above, but for other languages declared with the experimental
tag C<<[en>>

=item language

Same as above, but returns the human readable version, notably used by
Babel, Polyglossia, etc.

=item other_languages

Same as above, for the other languages

=cut

sub _language_mapping {
    return Text::Amuse::Utils::language_mapping();
}

sub language_code {
    my $self = shift;
    unless (defined $self->{_doc_language_code}) {
        my %header = $self->raw_header;
        my $lang = $header{lang} || $header{language} || "en";
        my $real = "en";
        # check if language exists;
        if ($self->_language_mapping->{$lang}) {
            $real = $lang;
        }
        $self->{_doc_language_code} = $real;
    }
    return $self->{_doc_language_code};
}

sub language {
    my $self = shift;
    unless (defined $self->{_doc_language}) {
        my $lc = $self->language_code;
        # guaranteed not to return undef
        $self->{_doc_language} = $self->_language_mapping->{$lc};
    }
    return $self->{_doc_language};
}

sub other_language_codes {
    my $self = shift;
    my @out =  @{ $self->{_other_doc_language_codes} };
    return @out ? \@out : undef;
}

sub other_languages {
    my $self = shift;
    my $map = $self->_language_mapping;
    my @out = map { $map->{$_} } @{ $self->other_language_codes || [] };
    return @out ? \@out : undef;
}

sub _add_to_other_language_codes {
    my ($self, $lang) = @_;
    return unless $lang;
    $lang = lc($lang);
    if ($self->_language_mapping->{$lang}) {
        if ($lang ne $self->language_code) {
            unless (grep { $_ eq $lang } @{ $self->other_language_codes || [] }) {
                push @{$self->{_other_doc_language_codes}}, $lang;
                return $lang;
            }
        }
    }
    else {
        warn "Unknown language $lang";
    }
    return 'en';
}

=item parse_directives

Return an hashref with the directives found in the document.

=cut

sub parse_directives {
    my $self = shift;
    my ($directives, $body) = $self->_parse_body_and_directives(directives_only => 1);
    return $directives;
}


sub _parse_body_and_directives {
    my ($self, %options) = @_;
    my $file = $self->filename;
    open (my $fh, "<:encoding(UTF-8)", $file) or die "Couldn't open $file! $!\n";

    my $in_meta = 1;
    my ($lastdirective, %directives, @body);
    my @directives_array;
  RAWLINE:
    while (my $line = <$fh>) {
        # EOL
        $line =~ s/\r\n/\n/gs;
        $line =~ s/\r/\n/gs;
        # TAB
        $line =~ s/\t/    /g;
        # trailing
        $line =~ s/ +$//mg;

        if ($in_meta) {
            # reset the directives on blank lines
            if ($line =~ m/^\s*$/s) {
                $lastdirective = undef;
            } elsif ($line =~ m/^\#([A-Za-z0-9_-]+)(\s+(.+))?$/s) {
                my ($dir, $material) = ($1, $3);

                # remove underscore and dashes from directive names to
                # keep compatibility with Emacs Muse, so e.g.
                # #disable-tables will be parsed as directive, not as
                # a line.

                $dir =~ s/[_-]//g;
                unless (length($dir)) {
                    warn "$file: Found empty directive $line, it will be removed\n";
                }
                if (exists $directives{$dir}) {
                    warn "$file: Overwriting directive '$dir' $directives{$dir} with $line\n";
                }
                if (defined $material) {
                    $directives{$dir} = $material;
                }
                else {
                    $directives{$dir} = '';
                }
                push @directives_array, [ $dir, $directives{$dir} ];

                $lastdirective = $dir;
            } elsif ($lastdirective) {
                $directives{$lastdirective} .= $line;
                $directives_array[-1][1] .= $line;
            } else {
                $in_meta = 0
            }
        }
        if ($in_meta) {
            next RAWLINE;
        }
        elsif ($options{directives_only}) {
            last RAWLINE;
        }
        else {
            push @body, $line;
        }
    }
    push @body, "\n"; # append a newline
    close $fh;

    # before returning, let's clean the %directives from EOLs and from
    # empty ones, e.g. #---------------------
    delete $directives{''};

    foreach my $key (keys %directives) {
        $directives{$key} =~ s/\s+/ /gs;
        $directives{$key} =~ s/\s+\z//gs;
        $directives{$key} =~ s/\A\s+//gs;
    }
    return (\%directives, \@body, \@directives_array);
}

sub _split_body_and_directives {
    my $self = shift;
    my ($directives, $body, $dir_array) = $self->_parse_body_and_directives;

    if (my @include_paths = $self->include_paths) {
        # rescan the body and do the inclusion
        my @full_body;
      LINE:
        foreach my $l (@$body) {
            if ($l =~ m/^#include\s+(.+?)\s*$/) {
                if (my $lines = $self->_resolve_include($1, \@include_paths)) {
                    push @full_body, @$lines;
                    next LINE;
                }
            }
            push @full_body, $l;
        }
        $body = \@full_body;
    }
    $self->{raw_body}   = $body;
    $self->{raw_header} = $directives;
    $self->{directives_array} = $dir_array;
}

sub _resolve_include {
    my ($self, $filename, $include_paths) = @_;
    my ($volume, $directories, $file) = File::Spec->splitpath($filename);
    my @dirs = grep { length $_ } File::Spec->splitdir($directories);
    # if hidden files or traversals are passed, bail out.
    if (grep { /^\./ } @dirs, $file) {
        warn "Directory traversal or hidden file found in included $filename!";
        return;
    }
    # if we have slash (unix) or backslash (windows), it's not good
    if (grep { /[\/\\]/ } @dirs, $file) {
        warn "Invalid file or directory name (slashes?) found in included $filename!";
        return;
    }
    # just in case
    return unless $file;

    # the base directory are set by the object, not by the user, so
    # they are considered safe.
    my @out;

  INCLUDEFILE:
    foreach my $base (@$include_paths) {
        my $final = File::Spec->catfile($base, @dirs, $file);
        if (-e $final && -T $final) {
            open (my $fh, "<:encoding(UTF-8)", $final) or die "Couldn't open $final! $!\n";
            while (my $line = <$fh>) {
                $line =~ s/\r\n/\n/gs;
                $line =~ s/\r/\n/gs;
                # TAB
                $line =~ s/\t/    /g;
                # trailing
                $line =~ s/ +$//mg;
                push @out, $line;
            }
            close $fh;
            $self->_add_to_included_files($final);
            last INCLUDEFILE;
        }
    }
    if (@out) {
        return \@out;
    }
    else {
        return;
    }
}

=item raw_header

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

=item raw_body

Accessor to the raw body of the muse file. The body is returned as a
list of lines.

=item directives_array

This is very similar to raw_header, but store them in an array, so the
header can be rewritten.

=cut

sub raw_body {
    my $self = shift;
    unless (defined $self->{raw_body}) {
        $self->_split_body_and_directives;
    }
    return @{$self->{raw_body}}
}

sub directives_array {
    my $self = shift;
    unless (defined $self->{directives_array}) {
        $self->_split_body_and_directives;
    }
    return @{$self->{directives_array}}
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
    $self->_debug(Dumper(\@parsed));

    # turn the versep into verse now that the merging is done
    foreach my $el (@parsed) {
        if ($el->type eq 'versep') {
            $el->type('verse');
        }
    }
    # turn the direction switching into proper open/close blocks
    {
        my $current_direction = '';
        my %dirs = (
                    '<<<' => 'rtl',
                    '>>>' => 'ltr',
                   );
        foreach my $el (@parsed) {
            if ($el->type eq 'bidimarker') {
                $self->set_bidi_document;
                my $dir = $dirs{$el->block} or die "Invalid bidimarker " . $el->block;
                if ($current_direction and $current_direction ne $dir) {
                    $el->type('stopblock');
                    $el->block($current_direction);
                    $current_direction = '';
                }
                else {
                    warn "Direction already set to $current_direction!" if $current_direction;
                    $el->type('startblock');
                    $el->block($dir);
                    $current_direction = $dir;
                }
            }
        }
    }
    $self->_reset_list_parsing_output;
  LISTP:
    while (@parsed) {
        my $el = shift @parsed;
        if ($el->type eq 'li' or $el->type eq 'dd') {
            if ($self->_list_pile_count) {
                # indentation is major, open a new level
                if (_indentation_kinda_major($el, $self->_list_pile_last_element)) {
                    $self->_list_open_new_list_level($el);
                }
                else {
                    # close the lists until we get the right level
                    $self->_list_close_until_indentation($el);
                    if ($self->_list_pile_count) { # continue if open
                        if ($self->_list_element_is_same_kind_as_in_list($el) and
                            $self->_list_element_is_a_progression($el)) {
                            $self->_list_continuation($el);
                        }
                        else {
                            my $top = $self->_list_pile_last_element;
                            while ($self->_list_pile_count and
                                   _indentation_kinda_equal($top, $self->_list_pile_last_element)) {
                                # empty the pile until the indentation drops.
                                $self->_close_list_level;
                            }
                            # and open a new level
                            $self->_list_open_new_list_level($el);
                        }
                    }
                    else { # if by chance, we emptied all, start anew.
                        $self->_list_open_new_list_level($el);
                    }
                }
            }
            # no list pile, this is the first element
            elsif ($self->_list_element_can_be_first($el)) {
                $self->_list_open_new_list_level($el);
            }
            else {
                # reparse and should become quote/center/right
                $self->_append_element_to_list_parsing_output($self->_reparse_nolist($el));
                next LISTP; # call next to avoid being mangled.
            }
            $el->become_regular;
        }
        elsif ($el->type eq 'regular') {
            # the type is regular: It can only close or continue
            $self->_list_close_until_indentation($el);
            if ($self->_list_pile_count) {
                $el->become_regular;
            }
        }
        elsif ($el->type ne 'null') { # something else: close the pile
            $self->_list_flush;
        }
        $self->_append_element_to_list_parsing_output($el);
    }
    # end of input, flush what we have.
    $self->_list_flush;

    # now we use parsed as output
    $self->_flush_current_footnote;
    my @out;
    my $elnum = 0;
    while (@{$self->_list_parsing_output}) {
        my $el = shift @{$self->_list_parsing_output};
        $elnum++;
        $el->_set_element_number($elnum);
        if ($el->type eq 'footnote' or $el->type eq 'secondary_footnote') {
            $self->_register_footnote($el);
        }
        elsif (my $fn_indent = $self->_current_footnote_indent) {
            if ($el->type eq 'null') {
                push @parsed, $el;
            }
            elsif ($el->can_be_regular and
                   $el->indentation and
                   _kinda_equal($el->indentation, $fn_indent)) {
                push @{$self->_current_footnote_stack}, Text::Amuse::Element->new($self->_parse_string("<br>\n")), $el;
            }
            else {
                $self->_flush_current_footnote;
                push @parsed, $el;
            }
        }
        else {
            push @parsed, $el;
        }
    }
    $self->_flush_current_footnote;

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

            my @carry_on;
            my %close_rtl = map { $_ => 1 } (qw/h1 h2 h3 h4 h5 h6 newpage/);

            while (@pile) {
                my $block = pop @pile;
                if (($block->block eq 'rtl' || $block->block eq 'ltr') and !$close_rtl{$el->type}) {
                    push @carry_on, $block;
                }
                else {
                    warn "Forcing the closing of " . $block->block . "\n";
                    push @parsed, $block;
                }
            }
            push @pile, reverse @carry_on;
        }
        push @parsed, $el;
    }
    # do we still have things into the pile?
    while (@pile) {
        push @parsed, pop @pile;
    }
    return \@parsed;
}

=item elements

Return the list of the elements which compose the body, once they have
properly parsed and packed. Footnotes are removed. (To get the
footnotes use the accessor below).

=cut

sub elements {
    my $self = shift;
    unless (defined $self->{_parsed_document}) {
        $self->{_parsed_document} = $self->_parse_body;
    }
    if (defined wantarray) {
        return @{$self->{_parsed_document}};
    }
    else {
        return;
    }
}

=item get_footnote

Accessor to the internal footnotes hash. You can access the footnote
with a numerical argument or even with a string like [123]

=cut

sub get_footnote {
    my ($self, $arg) = @_;
    return undef unless $arg;
    if ($arg =~ m/(\{[1-9][0-9]*\}|\[[1-9][0-9]*\])/) {
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
    return $self->{_raw_footnotes};
}

sub _current_footnote_stack {
    return shift->{_current_footnote_stack};
}

sub _current_footnote_number {
    my $self = shift;
    if (@_) {
        $self->{_current_footnote_number} = shift;
    }
    return $self->{_current_footnote_number};
}

sub _current_footnote_indent {
    my $self = shift;
    if (@_) {
        $self->{_current_footnote_indent} = shift;
    }
    return $self->{_current_footnote_indent};
}



sub _parse_string {
    my ($self, $l, %opts) = @_;
    die unless defined $l;
    my %element = (
                   rawline => $l,
                   raw_without_anchors => $l,
                  );
    if ($l =~ m/\A
                (\s*)
                (\#([A-Za-z][A-Za-z0-9-]+)\x{20}*)
                (.*)
                \z
                /sx) {
        $element{anchor} = $3;
        $l = $1 . $4;
        $element{raw_without_anchors} = $l;
    }
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
    if ($l =~ m/^((\<\<\<|\>\>\>)\s*)$/s) {
        # here turn them into language switch
        $element{type} = "bidimarker";
        $element{removed} = $1;
        $element{block} = $2;
        return %element;
    }
    if ($l =~ m/^(
                    (
                        \<
                        (\/?)
                        \[
                        ([a-zA-Z-]+)
                        \]
                        \>
                    )
                    \s*
                )$/sx) {
        my ($all, $full, $close, $lang) = ($1, $2, $3, $4);
        $element{type} = $close ? "stopblock" : "startblock";
        $element{language} = $lang;
        $element{removed} = $l;
        $self->_add_to_other_language_codes($lang);
        $element{block} = "languageswitch";
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
    # line starting with pipe, gh-markdown style
    if ($l =~ m/^\|+(\x{20}+|\+)/s) {
        $element{type} = "table";
        $element{string} = $l;
        return %element;
    }
    if ($l =~ m/^(\;)(\x{20}+(.*))?$/s) {
        $element{removed} = $1;
        $element{string} = $3;
        unless (defined ($element{string})) {
            $element{string} = '';
        }
        $element{type} = "inlinecomment";
        return %element;
    }
    if ($l =~ m/^((\[([1-9][0-9]*)\])\x{20}+)(.+)$/s) {
        $element{type} = "footnote";
        $element{removed} = $1;
        $element{footnote_symbol} = $2;
        $element{footnote_number} = $3;
        $element{footnote_index} = $3;
        $element{string} = $4;
        return %element;
    }
    if ($l =~ m/^((\{([1-9][0-9]*)\})\x{20}+)(.+)$/s) {
        $element{type} = "secondary_footnote";
        $element{removed} = $1;
        $element{footnote_symbol} = $2;
        $element{footnote_number} = $3;
        $element{footnote_index} = 'b'. $3;
        $element{string} = $4;
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
        $element{indentation} = length($1) + 2;
        $element{start_list_index} = 1;
        return %element;
    }
    if (!$opts{nolist}) {
        if ($l =~ m/^((\x{20}+)\-\x{20}+)(.*)/s) {
            $element{type} = "li";
            $element{removed} = $1;
            $element{string} = $3;
            $element{block} = "ul";
            $element{indentation} = length($2) + 2;
            $element{start_list_index} = 1;
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

            # validate roman numbers, so we don't end up with random strings
            if (my $list_index = $self->_get_start_list_index($prefix)) {
                $element{type} = "li";
                $element{removed} = $remove;
                $element{string} = $text;
                my $list_type = $self->_identify_list_type($prefix);
                $element{indentation} = length($whitespace) + 2;
                $element{block} = $list_type;
                $element{start_list_index} = $list_index;
                return %element;
            }
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

sub _get_start_list_index {
    my ($self, $prefix) = @_;
    my $map = $self->_list_index_map;
    if (exists $map->{$prefix}) {
        return $map->{$prefix};
    }
    else {
        warn "$prefix doesn't map exactly to a list index!\n";
        return 0;
    }
}

sub _list_element_can_be_first {
    my ($self, $el) = @_;
    # every dd can be the first
    return 1 if $el->type eq 'dd';
    return unless $el->type eq 'li';
    # first element, can't be too indented
    if ($el->indentation > 8) {
        return 0;
    }
    else {
        return $el->start_list_index;
    }
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

    if ($current and ($current->type eq 'null' or $current->type eq 'startblock') and $current->anchors) {
        # previous element is null, carry on
        $current->move_anchors_to($element);
    }
    if ($element->type eq 'null' and
        $element->anchors and
        $current->type ne 'null' and
        $current->type ne 'example') {
        # incoming has anchors
        $element->move_anchors_to($current);
        # null element with anchors. it was fully merged, so return
        return;
    }

    # catch the examples, comments and the verse in bloks.
    # <example> is greedy, and will stop only at another </example> or
    # at the end of input. Same is true for verse and comments.

    foreach my $block (qw/example comment verse/) {
        if ($current && $current->type eq $block) {
            if ($element->is_stop_element($current)) {
                $self->_current_el(undef);
                return Text::Amuse::Element->new(type => 'null',
                                                 removed => $element->rawline,
                                                 anchors => [ $element->anchors ],
                                                 rawline => $element->rawline);
            }
            else {
                # remove inlined comments from verse environments
                if ($current->type eq 'verse' and
                    $element->type eq 'inlinecomment') {
                }
                else {
                    $current->append($element);
                }
                return;
            }
        }
        elsif ($element->is_start_block($block)) {
            $current = Text::Amuse::Element->new(type => $block,
                                                 style => $element->style,
                                                 anchors => [ $element->anchors ],
                                                 removed => $element->rawline,
                                                 raw_without_anchors => $element->raw_without_anchors,
                                                 rawline => $element->rawline);
            $self->_current_el($current);
            return $current;
        }
    }
    # Pack the lines
    if ($current && $current->can_append($element)) {
        # print "Packing " . Dumper($element) . ' into ' . Dumper($current);
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
    if (my $list_index = $el->start_list_index) {
        $out[0]->start_list_index($list_index);
        $out[1]->start_list_index($list_index);
    }
    return @out;
}
sub _closing_blocks_new_level {
    my ($self, $el) = @_;
    my @out = ($self->_create_block(close => $el->block, $el->indentation),
               $self->_closing_blocks($el));
    return @out;
}

sub _indentation_kinda_minor {
    return _indentation_compare(@_) == IMINOR;
}

sub _indentation_kinda_major {
    return _indentation_compare(@_) == IMAJOR;
}

sub _indentation_kinda_equal {
    return _indentation_compare(@_) == IEQUAL;
}

sub _kinda_equal {
    return _compare_tolerant(@_) == IEQUAL;
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


sub _list_element_is_same_kind_as_in_list {
    my ($self, $el) = @_;
    my $list = $self->_list_element_pile;
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

sub _register_footnote {
    my ($self, $el) = @_;
    my $fn_num = $el->footnote_symbol;
    if (defined $fn_num) {
        if ($self->_raw_footnotes->{$fn_num}) {
            warn "Overwriting footnote number $fn_num!\n";
        }
        $self->_flush_current_footnote;
        $self->_current_footnote_indent($el->indentation);
        $self->_current_footnote_number($fn_num);
        $self->_raw_footnotes->{$fn_num} = $el;
    }
    else {
        die "Something is wrong here! <" . $el->removed . ">"
          . $el->string . "!";
    }
}

sub _flush_current_footnote {
    my $self = shift;
    if (@{$self->_current_footnote_stack}) {
        my $footnote = $self->get_footnote($self->_current_footnote_number);
        die "Missing current footnote to append " . Dumper($self->_current_footnote_stack) unless $footnote;
        while (@{$self->_current_footnote_stack}) {
            my $append = shift @{$self->_current_footnote_stack};
            $footnote->append($append);
        }
    }
    $self->_current_footnote_indent(0);
    $self->_current_footnote_number(undef)
}

# list parsing

sub _list_element_pile {
    return shift->{_list_element_pile};
}

sub _list_parsing_output {
    return shift->{_list_parsing_output};
}

sub _list_pile_count {
    my $self = shift;
    return scalar(@{$self->_list_element_pile});
}

sub _list_pile_last_element {
    my $self = shift;
    return $self->_list_element_pile->[-1];
}

sub _reset_list_parsing_output {
    my $self = shift;
    $self->{_list_parsing_output} = [];
}

sub _list_open_new_list_level {
    my ($self, $el) = @_;
    push @{$self->_list_parsing_output}, $self->_opening_blocks_new_level($el);
    my @pile = $self->_closing_blocks_new_level($el);
    if (my $list_index = $el->start_list_index) {
        $_->start_list_index($list_index) for @pile;
    }
    push @{$self->_list_element_pile}, @pile;
}

sub _list_continuation {
    my ($self, $el) = @_;
    my $current = $self->_list_pile_last_element->start_list_index + 1;
    push @{$self->_list_parsing_output}, pop @{$self->_list_element_pile}, $self->_opening_blocks($el);
    my @pile = $self->_closing_blocks($el);
    if (my $list_index = $el->start_list_index) {
        $_->start_list_index($current) for @pile;
    }
    push @{$self->_list_element_pile}, @pile;
}

sub _close_list_level {
    my $self = shift;
    push @{$self->_list_parsing_output}, pop @{$self->_list_element_pile};
}

sub _append_element_to_list_parsing_output {
    my ($self, $el) = @_;
    push @{$self->_list_parsing_output}, $el;
}

sub _list_close_until_indentation {
    my ($self, $el) = @_;
    while ($self->_list_pile_count and
           _indentation_kinda_minor($el, $self->_list_pile_last_element)) {
        $self->_close_list_level;
    }
}

sub _list_flush {
    my $self = shift;
    while ($self->_list_pile_count) {
        $self->_close_list_level;
    }
}

sub _list_element_is_a_progression {
    my ($self, $el) = @_;
    # not defined, not needed.
    my $last = $self->_list_pile_last_element->start_list_index;
    my $current = $el->start_list_index;
    # no index from one or another, we can't compare
    if (!$last or !$current) {
        return 1;
    }
    elsif ($last > 0 and $current > 1) {
        if (($current - $last) == 1) {
            return 1;
        }
        else {
            return 0;
        }
    }
    else {
        return 1;
    }
}

=back

=cut

1;
