# pyyaml/lib/yaml/scanner.py

# Scanner produces tokens of the following types:
# STREAM-START
# STREAM-END
# DIRECTIVE(name, value)
# DOCUMENT-START
# DOCUMENT-END
# BLOCK-SEQUENCE-START
# BLOCK-MAPPING-START
# BLOCK-END
# FLOW-SEQUENCE-START
# FLOW-MAPPING-START
# FLOW-SEQUENCE-END
# FLOW-MAPPING-END
# BLOCK-ENTRY
# FLOW-ENTRY
# KEY
# VALUE
# ALIAS(value)
# ANCHOR(value)
# TAG(value)
# SCALAR(value, plain, style)
#
# Read comments in the Scanner code for more details.
#

package YAML::Perl::Scanner;
use strict;
use warnings;
use YAML::Perl::Processor -base;

field 'next_layer' => 'reader';

field 'reader_class', -init => '"YAML::Perl::Reader"';
field 'reader', -init => '$self->create("reader")';

use YAML::Perl::Error;
use YAML::Perl::Tokens;

package YAML::Perl::Error::Scanner;
use YAML::Perl::Error::Marked -base;

package YAML::Perl::Scanner::SimpleKey;
use YAML::Perl::Base -base;

field 'token_number';
field 'required';
field 'index';
field 'line';
field 'column';
field 'mark';

package YAML::Perl::Scanner;

field done => False;

field flow_level => 0;

field tokens => [];

sub open {
    my $self = shift;
    $self->SUPER::open(@_);
    $self->fetch_stream_start();
}

field tokens_taken => 0;

field indent => -1;

field indents => [];

field allow_simple_key => True;

field possible_simple_keys => {};

sub scan {
    my $self = shift;
    if (wantarray) {
        my @tokens = ();
        while ($self->check_token()) {
            push @tokens, $self->get_token();
        }
        return @tokens;
    }
    else {
        return $self->check_token() ? $self->get_token() : ();
    }
}

# Public methods.

sub check_token {
    my $self = shift;
    my @choices = @_;
    while ($self->need_more_tokens()) {
        $self->fetch_more_tokens();
    }
    if (@{$self->tokens}) {
        if (not @choices) {
            return True;
        }
        for my $choice (@choices) {
            if ($self->tokens->[0]->isa($choice)) {
                return True;
            }
        }
    }
    return False;
}

sub peek_token {
    my $self = shift;
    while ($self->need_more_tokens()) {
        $self->fetch_more_tokens();
    }
    if (@{$self->tokens}) {
        return $self->tokens->[0];
    }
    return;
}

sub get_token {
    my $self = shift;
    while ($self->need_more_tokens()) {
        $self->fetch_more_tokens();
    }
    if (@{$self->tokens}) {
        $self->tokens_taken($self->tokens_taken + 1);
        return shift @{$self->tokens};
    }
    return;
}

# Private methods.

sub need_more_tokens {
    my $self = shift;
    if ($self->done) {
        return False;
    }
    if (not @{$self->tokens}) {
        return True;
    }
    $self->stale_possible_simple_keys();
    my $next = $self->next_possible_simple_key();
    if (defined($next) and $next == $self->tokens_taken) {
        return True;
    }
    return;
}

sub fetch_more_tokens {
    my $self = shift;

    $self->scan_to_next_token();

    $self->stale_possible_simple_keys();

    $self->unwind_indent($self->reader->column);

    my $ch = $self->reader->peek();

    if ($ch eq "\0") {
        return $self->fetch_stream_end();
    }

    if ($ch eq "%" and $self->check_directive()) {
        return $self->fetch_directive();
    }

    if ($ch eq "-" and $self->check_document_start()) {
        return $self->fetch_document_start;
    }

    if ($ch eq "." and $self->check_document_end()) {
        return $self->fetch_document_end;
    }

    if ($ch eq "[") {
        return $self->fetch_flow_sequence_start();
    }

    if ($ch eq "{") {
        return $self->fetch_flow_mapping_start();
    }

    if ($ch eq "]") {
        return $self->fetch_flow_sequence_end();
    }

    if ($ch eq "}") {
        return $self->fetch_flow_mapping_end();
    }

    if ($ch eq ',') {
        return $self->fetch_flow_entry();
    }

    if ($ch eq '-' and $self->check_block_entry()) {
        return $self->fetch_block_entry();
    }

    if ($ch eq '?' and $self->check_key()) {
        return $self->fetch_key();
    }

    if ($ch eq ':' and $self->check_value()) {
        return $self->fetch_value();
    }

    if ($ch eq '*') {
        return $self->fetch_alias();
    }

    if ($ch eq '&') {
        return $self->fetch_anchor();
    }

    if ($ch eq '!') {
        return $self->fetch_tag();
    }

    if ($ch eq '|' and not $self->flow_level) {
        return $self->fetch_literal();
    }

    if ($ch eq '>' and not $self->flow_level) {
        return $self->fetch_folded();
    }

    if ($ch eq "'") {
        return $self->fetch_single();
    }

    if ($ch eq '"') {
        return $self->fetch_double();
    }

    if ($self->check_plain()) {
        return $self->fetch_plain();
    }

    throw YAML::Perl::Error::Scanner(
        "while scanning for the next token found character '$ch' that cannot start any token"
    );
}

sub next_possible_simple_key {
    my $self = shift;
    my $min_token_number = undef;
    for my $level (keys %{$self->possible_simple_keys}) {
        my $key = $self->possible_simple_keys->{$level};
        if (not defined $min_token_number or
            $key->token_number < $min_token_number
        ) {
            $min_token_number = $key->token_number;
        }
    }
    return $min_token_number;
}

sub stale_possible_simple_keys {
    my $self = shift;
    for my $level (keys %{$self->possible_simple_keys}) {
        my $key = $self->possible_simple_keys->{$level};
        if ($key->line != $self->reader->line or
            $self->reader->index - $key->index > 1024
        ) {
            if ($key->required) {
                throw YAML::Perl::Error::Scanner(
                    "while scanning a simple key ", $key->mark,
                    "could not find expected ':' ", $self->get_mark()
                );
            }
            delete $self->possible_simple_keys->{$level};
        }
    }
}

sub save_possible_simple_key {
    my $self = shift;
    my $required = (not $self->flow_level and $self->indent == $self->reader->column);
    assert($self->allow_simple_key or not $required);
    if ($self->allow_simple_key) {
        $self->remove_possible_simple_key();
        my $token_number = $self->tokens_taken + @{$self->tokens};
        my $key = YAML::Perl::Scanner::SimpleKey->new(
            token_number => $token_number,
            required => $required,
            index => $self->reader->index,
            line => $self->reader->line,
            column => $self->reader->column,
            mark => $self->reader->get_mark(),
        );
        $self->possible_simple_keys->{$self->flow_level} = $key;
    }
}

sub remove_possible_simple_key {
    my $self = shift;
    if (exists $self->possible_simple_keys->{$self->flow_level}) {
        my $key = $self->possible_simple_keys->{$self->flow_level};

        if ($key->required) {
            throw YAML::Perl::Scanner::Error->new(
                "while scanning a simple key", $key->mark,
                "could not find expected ':'", $self->get_mark()
            );
        }
        delete $self->possible_simple_keys->{$self->flow_level};
    }
}

sub unwind_indent {
    my $self = shift;
    my $column = shift;
    if ($self->flow_level) {
        return;
    }
    while ($self->indent > $column) {
        my $mark = $self->reader->get_mark();
        $self->indent(pop @{$self->indents});
        push @{$self->tokens}, YAML::Perl::Token::BlockEnd->new(
            start_mark => $mark,
            end_mark => $mark,
        );
    }
}

sub add_indent {
    my $self = shift;
    my $column = shift;
    if ($self->indent < $column) {
        push @{$self->indents}, $self->indent;
        $self->indent($column);
        return True;
    }
    return False;
}

sub fetch_stream_start {
    my $self = shift;
    my $mark = $self->reader->get_mark();
    push @{$self->tokens}, YAML::Perl::Token::StreamStart->new(
        start_mark => $mark,
        end_mark => $mark,
        encoding => $self->reader->encoding,
    );
}

sub fetch_stream_end {
    my $self = shift;
    $self->unwind_indent(-1);
    $self->allow_simple_key(False);
    $self->possible_simple_keys({});
    my $mark = $self->reader->get_mark();
    push @{$self->tokens}, YAML::Perl::Token::StreamEnd->new(
        start_mark => $mark,
        end_mark => $mark,
    );
    $self->done(True);
}

sub fetch_directive {
    my $self = shift;
    $self->unwind_indent(-1);
    $self->remove_possible_simple_key();
    $self->allow_simple_key(False);
    push @{$self->tokens}, $self->scan_directive();
}

sub fetch_document_start {
    my $self = shift;
    $self->fetch_document_indicator('YAML::Perl::Token::DocumentStart');
}

sub fetch_document_end {
    my $self = shift;
    $self->fetch_document_indicator('YAML::Perl::Token::DocumentEnd');
}

sub fetch_document_indicator {
    my $self = shift;
    my $token_class = shift;
    $self->unwind_indent(-1);
    $self->remove_possible_simple_key();
    $self->allow_simple_key(False);
    my $start_mark = $self->reader->get_mark();
    $self->reader->forward(3);
    my $end_mark = $self->reader->get_mark();
    push @{$self->tokens}, $token_class->new(
        start_mark => $start_mark,
        end_mark => $end_mark,
    );
}

sub fetch_flow_sequence_start {
    my $self = shift;
    $self->fetch_flow_collection_start('YAML::Perl::Token::FlowSequenceStart');
}

sub fetch_flow_mapping_start {
    my $self = shift;
    $self->fetch_flow_collection_start('YAML::Perl::Token::FlowMappingStart');
}

sub fetch_flow_collection_start {
    my $self = shift;
    my $token_class = shift;
    $self->save_possible_simple_key();
    $self->flow_level($self->flow_level + 1);
    $self->allow_simple_key(True);
    my $start_mark = $self->reader->get_mark();
    $self->reader->forward();
    my $end_mark = $self->reader->get_mark();
    push @{$self->tokens}, $token_class->new(
        start_mark => $start_mark,
        end_mark => $end_mark,
    );
}

sub fetch_flow_sequence_end {
    my $self = shift;
    $self->fetch_flow_collection_end('YAML::Perl::Token::FlowSequenceEnd');
}

sub fetch_flow_mapping_end {
    my $self = shift;
    $self->fetch_flow_collection_end('YAML::Perl::Token::FlowMappingEnd');
}

sub fetch_flow_collection_end {
    my $self = shift;
    my $token_class = shift;
    $self->remove_possible_simple_key();
    $self->flow_level($self->flow_level - 1);
    $self->allow_simple_key(False);
    my $start_mark = $self->reader->get_mark();
    $self->reader->forward();
    my $end_mark = $self->reader->get_mark();
    push @{$self->tokens}, $token_class->new(
        start_mark => $start_mark,
        end_mark => $end_mark,
    );
}

sub fetch_flow_entry {
    my $self = shift;
    $self->allow_simple_key(True);
    $self->remove_possible_simple_key();
    my $start_mark = $self->reader->get_mark();
    $self->reader->forward();
    my $end_mark = $self->reader->get_mark();
    push @{$self->tokens}, YAML::Perl::Token::FlowEntry->new(
        start_mark => $start_mark,
        end_mark => $end_mark,
    );
}

sub fetch_block_entry {
    my $self = shift;
    if (not $self->flow_level) {
        if (not $self->allow_simple_key) {
            throw YAML::Perl::Error::Scanner(
                undef, undef,
                "sequence entries are not allowed here", $self->get_mark()
            );
        }
        if ($self->add_indent($self->reader->column)) {
            my $mark = $self->reader->get_mark();
            push @{$self->tokens}, YAML::Perl::Token::BlockSequenceStart->new(
                start_mark => $mark,
                end_mark => $mark,
            );
        }
    }
    $self->allow_simple_key(True);
    $self->remove_possible_simple_key();
    my $start_mark = $self->reader->get_mark();
    $self->reader->forward();
    my $end_mark = $self->reader->get_mark();
    push @{$self->tokens}, YAML::Perl::Token::BlockEntry->new(
        start_mark => $start_mark,
        end_mark => $end_mark,
    );
}

sub fetch_key {
    my $self = shift;
    if (not $self->flow_level) {
        if (not $self->allow_simple_key) {
            throw YAML::Perl::Error::Scanner(
                undef, undef,
                "mapping keys are not allowed here", $self->get_mark()
            );
        }
        if ($self->add_indent($self->reader->column)) {
            my $mark = $self->reader->get_mark();
            push @{$self->tokens}, YAML::Perl::Token::BlockMappingStart->new(
                start_mark=> $mark,
                end_mark => $mark,
            );
        }
    }
    $self->allow_simple_key(not($self->flow_level));
    $self->remove_possible_simple_key();
    my $start_mark = $self->reader->get_mark();
    $self->reader->forward();
    my $end_mark = $self->reader->get_mark();
    push @{$self->tokens}, YAML::Perl::Token::Key->new(
        start_mark => $start_mark,
        end_mark => $end_mark,
    );
}

sub fetch_value {
    my $self = shift;

    if (exists $self->possible_simple_keys->{$self->flow_level}) {
        my $key = $self->possible_simple_keys->{$self->flow_level};
        delete $self->possible_simple_keys->{$self->flow_level};
        splice @{$self->tokens},
            ($key->token_number - $self->tokens_taken), 0,
            YAML::Perl::Token::Key->new(
                start_mark => $key->mark, 
                end_mark => $key->mark,
            );
        if (not $self->flow_level) {
            if ($self->add_indent($key->column)) {
                splice @{$self->tokens},
                    ($key->token_number - $self->tokens_taken), 0,
                    YAML::Perl::Token::BlockMappingStart->new(
                        start_mark => $key->mark, 
                        end_mark => $key->mark,
                    );
            }
        }
        $self->allow_simple_key(False);
    }
    else {
        # Block context needs additional checks.
        # (Do we really need them? They will be catched by the parser
        # anyway.)
        if (not $self->flow_level) {

            # We are allowed to start a complex value if and only if
            # we can start a simple key.
            if (not $self->allow_simple_key) {
                throw YAML::Perl::Error::Scanner(
                    undef,
                    undef,
                    "mapping values are not allowed here",
                    $self->reader->get_mark(),
                );
            }
        }

        # If this value starts a new block mapping, we need to add
        # BLOCK-MAPPING-START.  It will be detected as an error later by
        # the parser.
        if (not $self->flow_level) {
            if ($self->add_indent($self->reader->column)) {
                my $mark = $self->reader->get_mark();
                push @{$self->tokens}, 
                    YAML::Perl::Token::BlockMappingStart(
                        start_mark => $mark,
                        end_mark => $mark,
                    );
            }
        }

        # Simple keys are allowed after ':' in the block context.
        $self->allow_simple_key(not $self->flow_level);

        # Reset possible simple key on the current level.
        $self->remove_possible_simple_key();
    }
    my $start_mark = $self->reader->get_mark();
    $self->reader->forward();
    my $end_mark = $self->reader->get_mark();
    push @{$self->tokens},
        YAML::Perl::Token::Value->new(
            start_mark => $start_mark, 
            end_mark => $end_mark,
        );
}

sub fetch_alias {
    my $self = shift;
    $self->save_possible_simple_key();
    $self->allow_simple_key(False);
    push @{$self->tokens}, $self->scan_anchor('YAML::Perl::Token::Alias');
}

sub fetch_anchor {
    my $self = shift;
    $self->save_possible_simple_key();
    $self->allow_simple_key(False);
    push @{$self->tokens}, $self->scan_anchor('YAML::Perl::Token::Anchor');
}

sub fetch_tag {
    my $self = shift;
    $self->save_possible_simple_key();
    $self->allow_simple_key(False);
    push @{$self->tokens}, $self->scan_tag();
}

sub fetch_literal {
    my $self = shift;
    $self->fetch_block_scalar('|');
}

sub fetch_folded {
    my $self = shift;
    $self->fetch_block_scalar('>');
}

sub fetch_block_scalar {
    my $self = shift;
    my $style = shift;

    # A simple key may follow a block scalar.
    $self->allow_simple_key(True);

    # Reset possible simple key on the current level.
    $self->remove_possible_simple_key();

    # Scan and add SCALAR.
    push @{$self->tokens}, $self->scan_block_scalar($style);
}

sub fetch_single {
    my $self = shift;
    $self->fetch_flow_scalar('\'');
}

sub fetch_double {
    my $self = shift;
    $self->fetch_flow_scalar('"');
}

sub fetch_flow_scalar {
    my $self = shift;
    my $style = shift;

    # A flow scalar could be a simple key.
    $self->save_possible_simple_key();

    # No simple keys after flow scalars.
    $self->allow_simple_key(False);

    # Scan and add SCALAR.
    push @{$self->tokens}, $self->scan_flow_scalar($style);
}

sub fetch_plain {
    my $self = shift;
    $self->save_possible_simple_key();
    $self->allow_simple_key(False);
    push @{$self->tokens}, $self->scan_plain();
}

sub check_directive {
    my $self = shift;
    if ($self->reader->column == 0) {
        return True;
    }
    return;
}

sub check_document_start {
    my $self = shift;
    if ($self->reader->column == 0) {
        if ($self->reader->prefix(3) eq '---' and
            $self->reader->peek(3) =~ /^[\0\ \t\r\n\x85\x{2028}\x{2029}]$/
        ) {
            return True;
        }
    }
    return;
}

sub check_document_end {
    my $self = shift;
    if ($self->reader->column == 0) {
        if ($self->reader->prefix(3) eq '...' and
            $self->reader->peek(3) =~ /^[\0\ \t\r\n\x85\x{2028}\x{2029}]$/
        ) {
            return True;
        }
    }
    return;
}

sub check_block_entry {
    my $self = shift;
    return $self->reader->peek(1) =~ /^[\0\ \t\r\n\x85\x{2028}\x{2029}]$/;
}

sub check_key {
    my $self = shift;
    # KEY(flow context):    '?'
    if ($self->flow_level) {
        return True;
    }

    # KEY(block context):   '?' (' '|'\n')
    else {
        return ($self->reader->peek(1) =~ /^[\0\ \t\r\n\x85\x{2028}\x{2029}]$/);
    }
}

sub check_value {
    my $self = shift;
    if ($self->flow_level) {
        return True;
    }
    else {
        return ($self->reader->peek(1) =~ /^[\0\ \t\r\n]$/) ? True : False;
    }
}

sub check_plain {
    my $self = shift;
    my $ch = $self->reader->peek();
    return(
        $ch !~ /^[\0\ \r\n\x85\x{2028}\x{2029}\-\?\:\,\[\]\{\}\#\&\*\!\|\>\'\"\%\@\`]$/ or
        $self->reader->peek(1) !~ /^[\0\ \t\r\n\x85\x{2028}\x{2029}]$/ and
        ($ch eq '-' or (not $self->flow_level and $ch =~ /^[\?\:]$/))
    );
}

sub scan_to_next_token {
    my $self = shift;
    if ($self->reader->index == 0 and $self->reader->peek() eq "\uFEFF") {
        $self->reader->forward();
    }
    my $found = False;
    while (not $found) {
        $self->reader->forward()
            while $self->reader->peek() eq ' ';
        if ($self->reader->peek() eq '#') {
            while ($self->reader->peek() !~ /^[\0\r\n\x85]$/) {
                $self->reader->forward();
            }
        }
        if ($self->scan_line_break()) {
            if (not $self->flow_level) {
                $self->allow_simple_key(True);
            }
        }
        else {
            $found = True;
        }
    }
}

sub scan_directive {
    my $self = shift;
    my $start_mark = $self->reader->get_mark();
    $self->reader->forward();
    my $name = $self->scan_directive_name($start_mark);
    my $value = undef;
    my $end_mark;
    if ($name eq 'YAML') {
        $value = $self->scan_yaml_directive_value($start_mark);
        $end_mark = $self->reader->get_mark();
    }
    elsif ($name eq 'TAG') {
        $value = $self->scan_tag_directive_value($start_mark);
        $end_mark = $self->reader->get_mark();
    }
    else {
        $end_mark = $self->reader->get_mark();
        while ($self->reader->peek() !~ /^[\0\r\n\x85\u2028\u2029]$/) {
            $self->reader->forward();
        }
    }
    $self->scan_directive_ignored_line($start_mark);
    return YAML::Perl::Token::Directive->new(
        name       => $name,
        value      => $value,
        start_mark => $start_mark,
        end_mark   => $end_mark
    );
}

sub scan_directive_name {
    my $self = shift;
    my $start_mark = shift;
    my $length = 0;
    my $ch = $self->reader->peek($length);
    while ($ch =~ /^[0-9A-Za-z-_]$/) {
        $length += 1;
        $ch = $self->reader->peek($length);
    }
    if (not $length) {
        throw YAML::Perl::Error::Scanner("while scanning a directive $start_mark "
            . " expected alphabetic or numeric character, but found $ch ", $self->get_mark());
    }
    my $value = $self->reader->prefix($length);
    $self->reader->forward($length);
    $ch = $self->reader->peek();
    if ($ch !~ /^[\0 \r\n\x85\u2028\u2029]$/) {
        throw YAML::Perl::Error::Scanner("while scanning a directive $start_mark "
            . " expected alphabetic or numeric character, but found $ch ", $self->get_mark());
    }
    return $value;
}

sub scan_yaml_directive_value {
    my $self = shift;
    my $start_mark = shift;
    while ($self->reader->peek() eq ' ') {
        $self->reader->forward();
    }
    my $major = $self->scan_yaml_directive_number($start_mark);
    if ($self->reader->peek() ne '.') {
        throw YAML::Perl::Error::Scanner("while scanning a directive $start_mark "
            . " expected a digit or '.' but found ", $self->reader->peek(), $self->reader->get_mark());
    }
    $self->reader->forward();
    my $minor = $self->scan_yaml_directive_number($start_mark);
    if ($self->reader->peek() !~ /^[\0 \r\n\x85\u2028\u2029]$/) {
        throw YAML::Perl::Error::Scanner("while scanning a directive $start_mark "
            . " expected alphabetic or numeric character, but found ", $self->reader->peek(),
            $self->get_mark());
    }
    return "$major.$minor"; # XXX this is a tuple in python but...
}

sub scan_yaml_directive_number {
    my $self = shift;
    my $start_mark = shift;
    my $ch = $self->reader->peek();
    if ($ch !~ /^[0-9]$/) {
        throw YAML::Perl::Error::Scanner("while scanning a directive $start_mark "
            . " expected a digit but found $ch", $self->reader->get_mark());
    }
    my $length = 0;
    while ($self->reader->peek($length) =~ /^[0-9]$/) {
        $length += 1;
    }
    my $value = int($self->reader->prefix($length));
    $self->reader->forward($length);
    return $value;
}

sub scan_tag_directive_value {
    my $self = shift;
    my $start_mark = shift;
    while ($self->reader->peek() eq ' ') {
        $self->reader->forward();
    }
    my $handle = $self->scan_tag_directive_handle($start_mark);
    while ($self->reader->peek() eq ' ') {
        $self->reader->forward();
    }
    my $prefix = $self->scan_tag_directive_prefix($start_mark);
    return [$handle, $prefix];
}

sub scan_tag_directive_handle {
    my $self = shift;
    my $start_mark = shift;
    my $value = $self->scan_tag_handle('directive', $start_mark);
    my $ch = $self->reader->peek();
    if ($ch ne ' ') {
        throw YAML::Perl::Error::Scanner(
            "while scanning a directive",
            $start_mark,
            "expected ' ', but found %r", $ch->encode('utf-8'),
            $self->get_mark()
        );
    }
    return $value;
}

sub scan_tag_directive_prefix {
    my $self = shift;
    my $start_mark = shift;
    my $value = $self->scan_tag_uri('directive', $start_mark);
    my $ch = $self->reader->peek();
    if ($ch !~ /^[\0\ \r\n\x85\x{2028}\x{2029}]$/) {
        throw YAML::Perl::Error::Scanner(
            "while scanning a directive",
            $start_mark,
            "expected ' ', but found %r", $ch->encode('utf-8'),
            $self->get_mark()
        );
    }
    return $value;
}

sub scan_directive_ignored_line {
    my $self = shift;
    my $start_mark = shift;
    while ($self->reader->peek() eq ' ') {
        $self->reader->forward();
    }
    if ($self->reader->peek() eq '#') {
        while ($self->reader->peek !~ /^[\0\r\n]$/) {
            $self->reader->forward();
        }
    }
    my $ch = $self->reader->peek();
    if ($ch !~ /^[\0\r\n\x85\u2028\u2029]$/) {
        throw YAML::Perl::Error::Scanner("while scanning a directive $start_mark "
            . "expected a comment or a line break, but found $ch", $self->reader->get_mark());
    }
    return $self->scan_line_break();
}

sub scan_anchor {
    my $self = shift;
    my $token_class = shift;
    my $start_mark = $self->reader->get_mark();
    my $indicator = $self->reader->peek();
    my $name;
    if ($indicator eq '*') {
        $name = 'alias';
    } else {
        $name = 'anchor';
    }
    $self->reader->forward();
    my $length = 0;
    my $ch = $self->reader->peek($length);
    while ($ch =~ /^[0-9A-Za-z-_]$/) {
        $length += 1;
        $ch = $self->reader->peek($length);
    }
    if (not $length) {
        throw YAML::Perl::Error::Scanner("while scanning an $name $start_mark expected "
            . "alphabetic or numeric character, but found " . $self->get_mark());
    }
    my $value = $self->reader->prefix($length);
    $self->reader->forward($length);
    $ch = $self->reader->peek();
    if ($ch !~ /^[\0 \t\r\n\x85\u2028\u2029?:,\]}%@]$/) {
        throw YAML::Perl::Error::Scanner("while scanning an $name $start_mark expected "
            . "alphabetic or numeric character, but found " . $self->get_mark());
    }
    my $end_mark = $self->reader->get_mark();
    return $token_class->new(value => $value, start_mark => $start_mark, end_mark => $end_mark);
}

sub scan_tag {
    my $self = shift;
    my $start_mark = $self->reader->get_mark();
    my $ch = $self->reader->peek(1);
    my ($suffix, $handle);
    if ($ch eq '<') {
        my $handle = undef;
        $self->forward(2);
        $suffix = $self->scan_tag_uri('tag', $start_mark);
        if ($self->reader->peek() ne '>') {
            throw YAML::Perl::Error::Scanner(
                "while parsing a tag",
                $start_mark,
                "expected '>', but found %r",
                $self->peek()->encode('utf-8'),
                $self->reader->get_mark(),
            );
        }
        $self->forward();
    }
    elsif ($ch =~ /^[\0 \t\r\n\x85\x{2028}\x{2029}]$/) {
        $handle = undef;
        $suffix = '!';
        $self->reader->forward();
    }
    else {
        my $length = 1;
        my $use_handle = False;
        while ($ch !~ /^[\0 \r\n\x85\x{2028}\x{2029}]$/) {
            if ($ch eq '!') {
                $use_handle = True;
                last;
            }
            $length += 1;
            $ch = $self->reader->peek($length);
        }
        $handle = '!';
        if ($use_handle) {
            $handle = $self->scan_tag_handle('tag', $start_mark);
        }
        else {
            $handle = '!';
            $self->reader->forward();
        }
        $suffix = $self->scan_tag_uri('tag', $start_mark);
    }
    $ch = $self->reader->peek();
    if ($ch !~ /^[\0 \r\n\x85\x{2028}\x{2029}]$/) {
        throw YAML::Perl::Error::Scanner(
            "while scanning a tag",
            $start_mark,
            "expected ' ', but found %r",
            $ch->encode('utf-8'),
            $self->reader->get_mark()
        );
    }
    my $value = [$handle, $suffix];
    my $end_mark = $self->reader->get_mark();
    return YAML::Perl::Token::Tag->new(
        value => $value,
        start_mark => $start_mark,
        end_mark => $end_mark,
    );
}

sub scan_block_scalar {
    my $self = shift;
    my $style = shift;
    # See the specification for details.

    my $folded;
    if ($style eq '>') {
        $folded = True;
    }
    else {
        $folded = False;
    }

    my $chunks = [];
    my $start_mark = $self->reader->get_mark();

    # Scan the header.
    $self->reader->forward();
    my ($chomping, $increment) = $self->scan_block_scalar_indicators($start_mark);
    $self->scan_block_scalar_ignored_line($start_mark);

    # Determine the indentation level and go to the first non-empty line.
    my $min_indent = $self->indent + 1;
    if ($min_indent < 1) {
        $min_indent = 1;
    }
    my ($breaks, $max_indent, $end_mark, $indent);
    if (not defined $increment) {
        ($breaks, $max_indent, $end_mark) = $self->scan_block_scalar_indentation();
        $indent = $min_indent > $max_indent ? $min_indent : $max_indent;
    }
    else {
        $indent = $min_indent + $increment - 1;
        ($breaks, $end_mark) = $self->scan_block_scalar_breaks($indent);
    }
    my $line_break = '';

    # Scan the inner part of the block scalar.
    while ($self->reader->column == $indent and $self->reader->peek() ne "\0") {
        push @$chunks, @$breaks;
        my $leading_non_space = ($self->reader->peek() !~ /^[\ \t]$/);
        my $length = 0;
        while ($self->reader->peek($length) !~ /^[\0\r\n\x85\x{2028}\x{2029}]$/) {
            $length += 1;
        }
        push @$chunks, $self->reader->prefix($length);
        $self->reader->forward($length);
        $line_break = $self->scan_line_break();
        ($breaks, $end_mark) = $self->scan_block_scalar_breaks($indent);
        if ($self->reader->column == $indent and $self->reader->peek() ne "\0") {

            # Unfortunately, folding rules are ambiguous.
            #
            # This is the folding according to the specification:
            
            if ($folded and
                $line_break eq "\n" and
                $leading_non_space and
                $self->reader->peek() !~ /^[\ \t]$/
            ) {
                if (not @$breaks) {
                    push @$chunks, ' ';
                }
            }
            else {
                push @$chunks, $line_break;
            }
            
            # This is Clark Evans's interpretation (also in the spec
            # examples):
            #
            #if folded and line_break == u'\n':
            #    if not breaks:
            #        if self.peek() not in ' \t':
            #            chunks.append(u' ')
            #        else:
            #            chunks.append(line_break)
            #else:
            #    chunks.append(line_break)
        }
        else {
            last;
        }
    }

    # Chomp the tail.
    if (not defined $chomping or $chomping == True) {
        push @$chunks, $line_break;
    }
    if (defined $chomping and $chomping == True) {
        push @$chunks, @$breaks;
    }

    # We are done.
    return YAML::Perl::Token::Scalar->new(
        value => join('', @$chunks),
        plain => False,
        start_mark => $start_mark,
        end_mark => $end_mark,
        style => $style,
    );
}

sub scan_block_scalar_indicators {
    my $self = shift;
    my $start_mark = shift;

    # See the specification for details.
    my $chomping = undef;
    my $increment = undef;
    my $ch = $self->reader->peek();
    if ($ch =~ /^[\+\-]$/) {
        if ($ch eq '+') {
            $chomping = True;
        }
        else {
            $chomping = False;
        }
        $self->reader->forward();
        $ch = $self->reader->peek();
        if ($ch =~ /^[0-9]$/) {
            $increment = $ch;
            if ($increment == 0) {
                throw YAML::Perl::Error::Scanner(
                    "while scanning a block scalar",
                    $start_mark,
                    "expected indentation indicator in the range 1-9, but found 0",
                    $self->reader->get_mark()
                );
            }
            $self->reader->forward();
        }
    }
    elsif ($ch =~ /^[0-9]$/) {
        $increment = $ch;
        if ($increment == 0) {
            raise ScannerError(
                "while scanning a block scalar",
                $start_mark,
                "expected indentation indicator in the range 1-9, but found 0",
                $self->reader->get_mark(),
            );
        }
        $self->reader->forward();
        $ch = $self->reader->peek();
        if ($ch =~ /^[\+\-]$/) {
            if ($ch eq '+') {
                $chomping = True;
            }
            else {
                $chomping = False;
            }
            $self->reader->forward();
        }
    }
    $ch = $self->reader->peek();
    if ($ch !~ /^[\0\ \r\n\x85\x{2028}\x{2029}]$/) {
        throw YAML::Perl::Error::Scanner(
            "while scanning a block scalar",
            $start_mark,
            "expected chomping or indentation indicators, but found %r",
            $ch, #.encode('utf-8'),
            $self->reader->get_mark(),
        );
    }
    return ($chomping, $increment);
}

sub scan_block_scalar_ignored_line {
    my $self= shift;
    my $start_mark = shift;
    # See the specification for details.
    while ($self->reader->peek() eq ' ') {
        $self->reader->forward();
    }
    if ($self->reader->peek() eq '#') {
        while ($self->reader->peek() !~ /^[\0\r\n\x85\x{2028}\x{2029}]$/) {
            $self->reader->forward();
        }
    }
    my $ch = $self->reader->peek();
    if ($ch !~ /^[\0\r\n\x85\x{2028}\x{2029}]$/) {
        throw YAML::Perl::Error::Scanner(
            "while scanning a block scalar",
            $start_mark,
            "expected a comment or a line break, but found %r",
            $ch, #.encode('utf-8'),
            $self->get_mark(),
        );
    }
    $self->scan_line_break();
}

sub scan_block_scalar_indentation {
    my $self = shift;
    my $chunks = [];
    my $max_indent = 0;
    my $end_mark = $self->reader->get_mark();
    while ($self->reader->peek() =~ /^[\ \r\n\x85\x{2028}\x{2029}]$/) {
        if ($self->reader->peek() ne ' ') {
            push @$chunks, $self->scan_line_break();
            $end_mark = $self->reader->get_mark();
        }
        else {
            $self->reader->forward();
            if ($self->reader->column > $max_indent) {
                $max_indent = $self->reader->column;
            }
        }
    }
    return $chunks, $max_indent, $end_mark;
}

sub scan_block_scalar_breaks {
    my $self = shift;
    my $indent = shift;
    # See the specification for details.
    my $chunks = [];
    my $end_mark = $self->reader->get_mark();
    while ($self->reader->column < $indent and $self->reader->peek() eq ' ') {
        $self->reader->forward();
    }
    while ($self->reader->peek() =~ /^[\r\n\x85\x{2028}\x{2029}]$/) {
        push @$chunks, $self->scan_line_break();
        $end_mark = $self->reader->get_mark();
        while ($self->reader->column < $indent and $self->reader->peek() eq ' ') {
            $self->reader->forward();
        }
    }
    return ($chunks, $end_mark)

}

sub scan_flow_scalar {
    my $self = shift;
    my $style = shift;
    # See the specification for details.
    # Note that we loose indentation rules for quoted scalars. Quoted
    # scalars don't need to adhere indentation because " and ' clearly
    # mark the beginning and the end of them. Therefore we are less
    # restrictive then the specification requires. We only need to check
    # that document separators are not included in scalars.
    my $double;
    if ($style eq '"') {
        $double = True;
    }
    else {
        $double = False;
    }
    my $chunks = [];
    my $start_mark = $self->reader->get_mark();
    my $quote = $self->reader->peek();
    $self->reader->forward();
    push @$chunks, @{$self->scan_flow_scalar_non_spaces($double, $start_mark)};
    while ($self->reader->peek() ne $quote) {
        push @$chunks, @{$self->scan_flow_scalar_spaces($double, $start_mark)};
        push @$chunks, @{$self->scan_flow_scalar_non_spaces($double, $start_mark)};
    }
    $self->reader->forward();
    my $end_mark = $self->reader->get_mark();
    return YAML::Perl::Token::Scalar->new(
        value => join('', @$chunks),
        plain => False,
        start_mark => $start_mark,
        end_mark => $end_mark,
        style => $style,
    );
}

use constant ESCAPE_REPLACEMENTS => {
    '0' => "\0",
    'a' => "\x07",
    'b' => "\x08",
    't' => "\x09",
    '\t' => "\x09",
    'n' => "\x0A",
    'v' => "\x0B",
    'f' => "\x0C",
    'r' => "\x0D",
    'e' => "\x1B",
    ' ' => "\x20",
    '\"' => "\"",
    '\\' => "\\",
    'N' => "\x85",
    '_' => "\xA0",
    'L' => "\u2028",
    'P' => "\u2029",
};

use constant ESCAPE_CODES => {
    'x' => 2,
    'u' => 4,
    'U' => 8,
};

sub scan_flow_scalar_non_spaces {
    my $self = shift;
    my $double = shift;
    my $start_mark = shift;

    # See the specification for details.
    my $chunks = [];
    while (True) {
        my $length = 0;
        while ($self->reader->peek($length) !~
            /^[\'\"\\\0\ \t\r\n\x85\x{2028}\x{2029}]$/
        ) {
            $length += 1;
        }
        if ($length) {
            push @$chunks, $self->reader->prefix($length);
            $self->reader->forward($length);
        }
        my $ch = $self->reader->peek();
        if (not $double and $ch eq '\'' and $self->reader->peek(1) eq '\'') {
            push @$chunks, '\'';
            $self->reader->forward(2);
        }
        elsif (($double and $ch eq '\'') or (not $double and $ch =~ /^[\"\\]$/)) {
            push @$chunks, $ch;
            $self->reader->forward();
        }
        elsif ($double and $ch eq '\\') {
            $self->reader->forward();
            $ch = $self->reader->peek();
            if (exists ESCAPE_REPLACEMENTS->{$ch}) {
                push @$chunks, ESCAPE_REPLACEMENTS->{$ch};
                $self->reader->forward();
            }
            elsif (exists ESCAPE_CODES->{$ch}) {
                $length = ESCAPE_CODES->{$ch};
                $self->reader->forward();
                for my $k (0 .. ($length - 1)) {
                    if ($self->reader->peek($k) !~ /^[0123456789ABCDEFabcdef]$/) {
                        throw YAML::Perl::Error::Scanner(
                            "while scanning a double-quoted scalar",
                            $start_mark,
                            "expected escape sequence of %d hexdecimal numbers, but found %r",
                            ($length, $self->reader->peek($k)), #.encode('utf-8')),
                            $self->get_mark(),
                        );
                    }
                }
                # XXX - Review this for multibyte and unicode
                my $code = ord(pack "H*", $self->reader->prefix($length));
                push @$chunks, chr($code);

                $self->reader->forward($length);
            }
            elsif ($ch =~ /^[\r\n\x85\x{2028}\x{2029}]$/) {
                $self->scan_line_break();
                push @$chunks,
                    @{$self->scan_flow_scalar_breaks($double, $start_mark)};
            }
            else {
                throw YAML::Perl::Error::Scanner(
                    "while scanning a double-quoted scalar",
                    $start_mark,
                    "found unknown escape character %r",
                    $ch, #.encode('utf-8'),
                    $self->reader->get_mark()
                );
            }
        }
        else {
            return $chunks
        }
    }
}

sub scan_flow_scalar_spaces {
    my $self = shift;
    my $double = shift;
    my $start_mark = shift;

    # See the specification for details.
    my $chunks = [];
    my $length = 0;
    while ($self->reader->peek($length) =~ /^[\ \t]$/) {
        $length += 1;
    }
    my $whitespaces = $self->reader->prefix($length);
    $self->reader->forward($length);
    my $ch = $self->reader->peek();
    if ($ch eq "\0") {
        throw YAML::Perl::Error::Scanner(
            "while scanning a quoted scalar",
            $start_mark,
            "found unexpected end of stream",
            $self->get_mark(),
        );
    }
    elsif ($ch =~ /^[\r\n\x85\x{2028}\x{2029}]$/) {
        my $line_break = $self->scan_line_break();
        my $breaks = $self->scan_flow_scalar_breaks($double, $start_mark);
        if ($line_break ne "\n") {
            push @$chunks, $line_break;
        }
        elsif (not @$breaks) {
            push @$chunks, ' ';
        }
        push @$chunks, @$breaks;
    }
    else {
        push @$chunks, $whitespaces;
    }
    return $chunks;
}

sub scan_flow_scalar_breaks {
    my $self = shift;
    my $double = shift;
    my $start_mark = shift;

    # See the specification for details.
    my $chunks = [];
    while (True) {
        # Instead of checking indentation, we check for document
        # separators.
        my $prefix = $self->reader->prefix(3);
        if (
            ($prefix eq '---' or $prefix eq '...') and
            $self->reader->peek(3) =~ /^[\0\ \t\r\n\x85\x{2028}\x{2029}]$/
        ) {
            throw YAML::Perl::Error::Scanner(
                "while scanning a quoted scalar",
                $start_mark,
                "found unexpected document separator",
                $self.get_mark()
            );
        }
        while ($self->reader->peek() =~ /^[\ \t]$/) {
            $self->reader->forward();
        }
        if ($self->reader->peek() =~ /^[\r\n\x85\x{2028}\x{2029}]$/) {
            push @$chunks, $self->scan_line_break();
        }
        else {
            return $chunks;
        }
    }
}

sub scan_plain {
    my $self = shift;

    my $chunks = [];
    my $start_mark = $self->reader->get_mark();
    my $end_mark = $start_mark;
    my $indent = $self->indent + 1;

    my $spaces = [];

    while (True) {
        my $length = 0;
        if ($self->reader->peek() eq '#') {
            last;
        }
        my $ch;
        while (True) {
            $ch = $self->reader->peek($length);

            if (
                ($ch =~ /^[\0\ \t\r\n]$/) or
                (
                    not $self->flow_level and $ch eq ':' and
                    $self->reader->peek($length + 1) =~ /^[\0\ \t\r\n]$/
                ) or
                ($self->flow_level and $ch =~ /^[\,\:\?\[\]\{\}]$/)
            ) {
                last;
            }
            $length++;
        }
        if ($self->flow_level and
            $ch eq ':' and
            $self->reader->peek($length + 1) !~ /^[\0\ \t\r\n\,\[\]\{\}]$/
        ) {
            $self->reader->forward($length);
            throw YAML::Perl::Error::Scanner(
                "while scanning a plain scalar", $start_mark,
                "found unexpected ':'", $self->reader->get_mark(),
                "Please check http://pyyaml.org/wiki/YAMLColonInFlowContext for details.",
            );
        }
        if ($length == 0) {
            last;
        }
        $self->allow_simple_key(False);
        push @$chunks, @$spaces;
        push @$chunks, $self->reader->prefix($length);
        $self->reader->forward($length);
        $end_mark = $self->reader->get_mark();
        $spaces = $self->scan_plain_spaces($indent, $start_mark);
        if (not defined $spaces or not @$spaces or
            $self->reader->peek() eq '#' or
            (not $self->flow_level and $self->reader->column < $indent)
        ) {
            last;
        }
    }
    return YAML::Perl::Token::Scalar->new(
        value => join('', @$chunks),
        plain => True,
        start_mark => $start_mark,
        end_mark => $end_mark,
    );
}

#   ... ch in u'\r\n\x85\u2028\u2029':
# XXX needs unicode linefeeds 
my $linefeed = qr/^[\r\n\x85]$/;

sub scan_plain_spaces {
    my $self = shift;
    my $indent = shift;
    my $start_mark = shift;

    my $chunks = [];
    my $length = 0;
    while ($self->reader->peek( $length ) eq ' ') {
        $length++;
    }
    my $whitespaces = $self->reader->prefix($length);
    $self->reader->forward($length);
    my $ch = $self->reader->peek();
    if ($ch =~ $linefeed) {
        my $line_break = $self->scan_line_break();
        $self->allow_simple_key(True);
        my $prefix = $self->reader->prefix(3);
        if (($prefix eq '---' or $prefix eq '...') and
            $self->reader->peek(3) =~ $linefeed
        ) {
            return;
        }
        my $breaks = [];
        while ($self->reader->peek() =~ $linefeed) {
            if ($self->reader->peek() eq ' ') {
                $self->reader->forward();
            }
            else {
                push @$breaks, $self->scan_line_break();
                my $prefix = $self->reader->prefix(3);
                if (($prefix eq '---' or $prefix eq '...') and
                    $self->reader->peek(3) =~ $linefeed
                ) {
                    return;
                }
            }
        }
        if ($line_break ne "\n") {
            push @$chunks, $line_break;
        }
        elsif (not @$breaks) {
            push @$chunks, ' ';
        }
        push @$chunks, @$breaks;
    }
    elsif ($whitespaces) {
        push @$chunks, $whitespaces;
    }
    return $chunks; 
}

sub scan_tag_handle {
    my $self = shift;
    my $name = shift;
    my $start_mark = shift;
    my $ch = $self->reader->peek();
    if ($ch ne '!') {
        throw YAML::Perl::Error::Scanner(
            "while scanning a %s",
            $name,
            $start_mark,
            "expected '!', but found %r",
            $ch->encode('utf-8'),
            $self->get_mark(),
        );
    }
    my $length = 1;
    $ch = $self->reader->peek($length);
    if ($ch ne ' ') {
        while ($ch =~ /^[0-9A-Za-z\-\_]$/) {
            $length += 1;
            $ch = $self->reader->peek($length);
        }
        if ($ch ne '!') {
            $self->reader->forward($length);
            throw YAML::Perl::Error::Scanner(
                "while scanning a %s",
                $name,
                $start_mark,
                "expected '!', but found %r",
                $ch->encode('utf-8'),
                self->reader->get_mark(),
            );
        }
        $length += 1;
    }
    my $value = $self->reader->prefix($length);
    $self->reader->forward($length);
    return $value;
}

sub scan_tag_uri {
    my $self = shift;
    my $name = shift;
    my $start_mark = shift;
    my $chunks = [];
    my $length = 0;
    my $ch = $self->reader->peek($length);
    while ($ch =~ /^[0-9A-Za-z\-\;\/\?\:\@\&\=\+\$\,\_\.\!\~\*\'\(\)\[\]\%]$/) {
        if ($ch eq '%') {
            push @$chunks, $self->reader->prefix($length);
            $self->reader->forward($length);
            $length = 0;
            push @$chunks, $self->scan_uri_escapes($name, $start_mark);
        }
        else {
            $length += 1;
        }
        $ch = $self->reader->peek($length);
    }
    if ($length) {
        push @$chunks, $self->reader->prefix($length);
        $self->reader->forward($length);
        $length = 0;
    }
    if (not @$chunks) {
        throw YAML::Perl::Error::Scanner("while parsing a %s",
            $name,
            $start_mark,
            "expected URI, but found %r",
            $ch->encode('utf-8'),
            $self->get_mark(),
        );
    }
    return join '', @$chunks;
}

sub scan_uri_escapes {
    my $self = shift;
    die "scan_uri_escapes";
}

sub scan_line_break {
    my $self = shift;
    my $ch = $self->reader->peek();
    if ($ch =~ /[\r\n]/) {
        if ($self->reader->prefix(2) eq "\r\n") {
            $self->reader->forward(2);
        }
        else {
            $self->reader->forward(1);
        }
        return "\n"
    }
    return '';
}

1;
