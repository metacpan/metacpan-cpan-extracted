# pyyaml/lib/yaml/parser.py

# The following YAML grammar is LL(1) and is parsed by a recursive descent
# parser.
#
# stream            ::= STREAM-START implicit_document? explicit_document* STREAM-END
# implicit_document ::= block_node DOCUMENT-END*
# explicit_document ::= DIRECTIVE* DOCUMENT-START block_node? DOCUMENT-END*
# block_node_or_indentless_sequence ::=
#                       ALIAS
#                       | properties (block_content | indentless_block_sequence)?
#                       | block_content
#                       | indentless_block_sequence
# block_node        ::= ALIAS
#                       | properties block_content?
#                       | block_content
# flow_node         ::= ALIAS
#                       | properties flow_content?
#                       | flow_content
# properties        ::= TAG ANCHOR? | ANCHOR TAG?
# block_content     ::= block_collection | flow_collection | SCALAR
# flow_content      ::= flow_collection | SCALAR
# block_collection  ::= block_sequence | block_mapping
# flow_collection   ::= flow_sequence | flow_mapping
# block_sequence    ::= BLOCK-SEQUENCE-START (BLOCK-ENTRY block_node?)* BLOCK-END
# indentless_sequence   ::= (BLOCK-ENTRY block_node?)+
# block_mapping     ::= BLOCK-MAPPING_START
#                       ((KEY block_node_or_indentless_sequence?)?
#                       (VALUE block_node_or_indentless_sequence?)?)*
#                       BLOCK-END
# flow_sequence     ::= FLOW-SEQUENCE-START
#                       (flow_sequence_entry FLOW-ENTRY)*
#                       flow_sequence_entry?
#                       FLOW-SEQUENCE-END
# flow_sequence_entry   ::= flow_node | KEY flow_node? (VALUE flow_node?)?
# flow_mapping      ::= FLOW-MAPPING-START
#                       (flow_mapping_entry FLOW-ENTRY)*
#                       flow_mapping_entry?
#                       FLOW-MAPPING-END
# flow_mapping_entry    ::= flow_node | KEY flow_node? (VALUE flow_node?)?
#
# FIRST sets:
#
# stream: { STREAM-START }
# explicit_document: { DIRECTIVE DOCUMENT-START }
# implicit_document: FIRST(block_node)
# block_node: { ALIAS TAG ANCHOR SCALAR BLOCK-SEQUENCE-START BLOCK-MAPPING-START FLOW-SEQUENCE-START FLOW-MAPPING-START }
# flow_node: { ALIAS ANCHOR TAG SCALAR FLOW-SEQUENCE-START FLOW-MAPPING-START }
# block_content: { BLOCK-SEQUENCE-START BLOCK-MAPPING-START FLOW-SEQUENCE-START FLOW-MAPPING-START SCALAR }
# flow_content: { FLOW-SEQUENCE-START FLOW-MAPPING-START SCALAR }
# block_collection: { BLOCK-SEQUENCE-START BLOCK-MAPPING-START }
# flow_collection: { FLOW-SEQUENCE-START FLOW-MAPPING-START }
# block_sequence: { BLOCK-SEQUENCE-START }
# block_mapping: { BLOCK-MAPPING-START }
# block_node_or_indentless_sequence: { ALIAS ANCHOR TAG SCALAR BLOCK-SEQUENCE-START BLOCK-MAPPING-START FLOW-SEQUENCE-START FLOW-MAPPING-START BLOCK-ENTRY }
# indentless_sequence: { ENTRY }
# flow_collection: { FLOW-SEQUENCE-START FLOW-MAPPING-START }
# flow_sequence: { FLOW-SEQUENCE-START }
# flow_mapping: { FLOW-MAPPING-START }
# flow_sequence_entry: { ALIAS ANCHOR TAG SCALAR FLOW-SEQUENCE-START FLOW-MAPPING-START KEY }
# flow_mapping_entry: { ALIAS ANCHOR TAG SCALAR FLOW-SEQUENCE-START FLOW-MAPPING-START KEY }

package YAML::Perl::Parser;
use strict;
use warnings;

use YAML::Perl::Error;
use YAML::Perl::Tokens;
use YAML::Perl::Events;
use YAML::Perl::Scanner;

package YAML::Perl::Error::Parser;
use YAML::Perl::Error::Marked -base;

package YAML::Perl::Parser;
use YAML::Perl::Processor -base;

use constant DEFAULT_TAGS => {
    '!' => '!',
    '!!' => 'tag:yaml.org,2002:',
};

field 'next_layer' => 'scanner';

field 'scanner_class', -init => '"YAML::Perl::Scanner"';
field 'scanner', -init => '$self->create("scanner")';

field 'current_event';
field 'yaml_version';
field 'tag_handles' => {};
field 'states' => [];
field 'marks' => [];
field 'state' => 'parse_stream_start';

sub parse {
    my $self = shift;
    if (wantarray) {
        my @events = ();
        while ($self->check_event()) {
            push @events, $self->get_event();
        }
        return @events;
    }
    else {
        return $self->check_event() ? $self->get_event() : ();
    }
}

sub check_event {
    my $self = shift;
    my @choices = @_;
    if (not defined $self->current_event) {
        if ($self->state) {
            my $state = $self->state;
            $self->current_event($self->$state());
        }
    }
    if (defined $self->current_event) {
        if (not @choices) {
            return True;
        }
        for my $choice (@choices) {
            if ($self->current_event->isa($choice)) {
                return True;
            }
        }
    }
    return False;
}

sub peek_event {
    my $self = shift;
    if (not defined $self->current_event) {
        if (my $state = $self->state) {
            $self->current_event($self->$state());
        }
    }
    return $self->current_event;
}

sub get_event {
    my $self = shift;
    if (not defined $self->current_event) {
        if (my $state = $self->state) {
            $self->current_event($self->$state());
        }
    }
    my $value = $self->current_event;
    $self->current_event(undef);
    return $value;
}

# stream    ::= STREAM-START implicit_document? explicit_document* STREAM-END
# implicit_document ::= block_node DOCUMENT-END*
# explicit_document ::= DIRECTIVE* DOCUMENT-START block_node? DOCUMENT-END*

sub parse_stream_start {
    my $self = shift;
    my $token = $self->scanner->get_token();
    my $event = YAML::Perl::Event::StreamStart->new(
        start_mark => $token->start_mark,
        end_mark => $token->end_mark,
        encoding => $token->encoding,
    );
    $self->state('parse_implicit_document_start');
    return $event;
}

sub parse_implicit_document_start {
    my $self = shift;
    if (not $self->scanner->check_token(qw(
        YAML::Perl::Token::Directive
        YAML::Perl::Token::DocumentStart
        YAML::Perl::Token::StreamEnd
    ))) {
        $self->tag_handles(DEFAULT_TAGS);
        my $token = $self->scanner->peek_token();
        my $start_mark = $token->start_mark;
        my $end_mark = $start_mark;
        my $event = YAML::Perl::Event::DocumentStart->new(
            start_mark => $start_mark,
            end_mark => $end_mark,
            explicit => False,
        );

        push @{$self->states}, 'parse_document_end';
        $self->state('parse_block_node');
        return $event;
    }
    return $self->parse_document_start();
}

sub parse_document_start {
    my $self = shift;
    my $event;
    while ($self->scanner->check_token('YAML::Perl::Token::DocumentEnd')) {
        $self->scanner->get_token();
    }

    if (not $self->scanner->check_token('YAML::Perl::Token::StreamEnd')) {
        my $token = $self->scanner->peek_token();
        my $start_mark = $token->start_mark;
        my ($version, $tags) = $self->process_directives();
        if (not $self->scanner->check_token('YAML::Perl::Token::DocumentStart')) {
            throw YAML::Perl::Error::Parser(
                "expected '<document start>', but found " .
                    $self->scanner->peek_token->id,
            );
        }
        $token = $self->scanner->get_token();
        my $end_mark = $token->end_mark;
        $event = YAML::Perl::Event::DocumentStart->new(
            start_mark => $start_mark,
            end_mark => $end_mark,
            explicit => 1,
            version => $version,
            tags => $tags,
        );
        push @{$self->states}, 'parse_document_end';
        $self->state('parse_document_content');
    }
    else {
        my $token = $self->scanner->get_token();
        $event = YAML::Perl::Event::StreamEnd->new(
            start_mark => $token->start_mark,
            end_mark => $token->end_mark,
        );
        assert not scalar @{$self->states};
        assert not scalar @{$self->marks};
        $self->state(undef);
    }
    return $event;
}

sub parse_document_end {
    my $self = shift;
    my $token = $self->scanner->peek_token();
    my $start_mark = $token->start_mark;
    my $end_mark = $start_mark;
    my $explicit = 0;
    while ($self->scanner->check_token('YAML::Perl::Token::DocumentEnd')) {
        $token = $self->scanner->get_token();
        $end_mark = $token->end_mark;
        $explicit = 1;
    }
    my $event = YAML::Perl::Event::DocumentEnd->new(
        start_mark => $start_mark,
        end_mark => $end_mark,
        explicit => $explicit,
    );
    $self->state('parse_document_start');
    return $event;
}

sub parse_document_content {
    my $self = shift;
    if ( $self->scanner->check_token( 
        'YAML::Perl::Token::Directive',
        'YAML::Perl::Token::DocumentStart',
        'YAML::Perl::Token::DocumentEnd',
        'YAML::Perl::Token::StreamEnd',
    ) ) {
        my $event = $self->process_empty_scalar( $self->scanner->peek_token()->start_mark() );
        $self->state( pop @{ $self->states() } );
        return $event;
    }
    else {
        return $self->parse_block_node();
    }
}

sub process_directives {
    my $self = shift;
    $self->yaml_version(undef);
    $self->tag_handles({});
    while ($self->scanner->check_token('YAML::Perl::Token::Directive')) {
        my $token = $self->scanner->get_token();
        if ($token->name eq 'YAML') {
            if (defined($self->yaml_version)) {
                throw YAML::Perl::Error::Parser(
                    "found duplicate YAML directive", $token->start_mark);
            }
            my ($major, $minor) = split('\.', $token->value);
            if ($major != 1) {
                throw YAML::Perl::Error::Parser(
                    "found incompatible YAML document (version 1.* is required)",
                    $token->start_mark);
            }
            $self->yaml_version($token->value);
        }
        elsif ($token->name eq 'TAG') {
            my ($handle, $prefix) = @{$token->value};
            if (defined $self->tag_handles->{$handle}) {
                throw YAML::Perl::Error::Parser(
                    undef,
                    undef,
                    "duplicate tag handle %r",
                    $handle->encode('utf-8'),
                    $token->start_mark,
                );
            }
            $self->tag_handles->{$handle} = $prefix;
        }
    }
    my @value;
    if (keys(%{$self->tag_handles})) {
        @value = ($self->yaml_version, {%{$self->tag_handles}});
    }
    else {
        @value = ($self->yaml_version, undef);
    }
    for my $key (keys %{$self->DEFAULT_TAGS}) {
        if (not exists $self->tag_handles->{$key}) {
            $self->tag_handles->{$key} = $self->DEFAULT_TAGS->{$key};
        }
    }
    return @value;
}

sub parse_block_node {
    my $self = shift;
    return $self->parse_node(block => True);
}

sub parse_flow_node {
    my $self = shift;
    return $self->parse_node();
}

sub parse_block_node_or_indentless_sequence {
    my $self = shift;
    return $self->parse_node(block => True, indentless_sequence => True);
}

sub parse_node {
    my $self = shift;
    my ($block, $indentless_sequence) = @{{@_}}{qw(block indentless_sequence)};
    
    my $event;
    if ($self->scanner->check_token('YAML::Perl::Token::Alias')) {
        my $token = $self->scanner->get_token();
        $event = YAML::Perl::Event::Alias->new(
            anchor     => $token->value,
            start_mark => $token->start_mark,
            end_mark   => $token->end_mark,
        );
        $self->state(pop @{$self->states});
    }
    else {
        my $anchor = undef;
        my $tag = undef;
        my $implicit = undef;
        my ($start_mark, $end_mark, $tag_mark) = (undef, undef, undef);
        if ($self->scanner->check_token('YAML::Perl::Token::Anchor')) {
            my $token = $self->scanner->get_token();
            $start_mark = $token->start_mark;
            $end_mark = $token->end_mark;
            $anchor = $token->value;

            if ($self->scanner->check_token('YAML::Perl::Token::Tag')) {
                my $token = $self->scanner->get_token();
                $tag_mark = $token->start_mark;
                $end_mark = $token->end_mark;
                $tag = $token->value;
            }
        }
        elsif ($self->scanner->check_token('YAML::Perl::Token::Tag')) {
            my $token = $self->scanner->get_token();
            $start_mark = $token->start_mark;
            $tag_mark = $start_mark;
            $end_mark = $token->end_mark;
            $tag = $token->value;
            if ($self->scanner->check_token('YAML::Perl::Token::Anchor')) {
                my $token = $self->scanner->get_token();
                $end_mark = $token->end_mark;
                $anchor = $token->value;
            }
        }
        if (defined $tag) {
            my ($handle, $suffix) = @$tag;
            if (defined $handle) {
                if (not exists $self->tag_handles->{$handle}) {
                    throw "while parsing a node... XXX finish this error msg";
                }
                $tag = $self->tag_handles->{$handle} . $suffix;
            }
            else {
                $tag = $suffix;
            }
        }
        if (not defined $start_mark) {
            $start_mark = $self->scanner->peek_token()->start_mark;
            $end_mark = $start_mark;
        }
        $event = undef;
        $implicit = (not defined $tag) || ($tag eq '!');
        if ($indentless_sequence and
            $self->scanner->check_token('YAML::Perl::Token::BlockEntry')
        ) {
            $end_mark = $self->scanner->peek_token()->end_mark;
            $event = YAML::Perl::Event::SequenceStart->new(
                anchor => $anchor,
                tag => $tag,
                implicit => $implicit,
                start_mark => $start_mark,
                end_mark => $end_mark,
            );
            $self->state('parse_indentless_sequence_entry');
        }
        else {
            if ($self->scanner->check_token('YAML::Perl::Token::Scalar')) {
                my $token = $self->scanner->get_token();
                $end_mark = $token->end_mark;
                if (($token->plain and not defined $tag) or ($tag || '') eq '!') {
                    $implicit = [True, False];
                }
                elsif (not defined $tag) {
                    $implicit = [False, True];
                }
                else {
                    $implicit = [False, False];
                }
                $event = YAML::Perl::Event::Scalar->new(
                    anchor => $anchor,
                    tag => $tag,
                    implicit => $implicit,
                    value => $token->value,
                    start_mark => $start_mark,
                    end_mark => $end_mark,
                    style => $token->style,
                );
                $self->state(pop @{$self->states});
            }
            elsif ($self->scanner->check_token('YAML::Perl::Token::FlowSequenceStart')) {
                $end_mark = $self->scanner->peek_token()->end_mark;
                $event = YAML::Perl::Event::SequenceStart->new(
                    anchor => $anchor,
                    tag => $tag,
                    implicit => $implicit,
                    start_mark => $start_mark,
                    end_mark => $end_mark,
                    flow_style => True,
                );
                $self->state('parse_flow_sequence_first_entry');
            }
            elsif ($self->scanner->check_token('YAML::Perl::Token::FlowMappingStart')) {
                $end_mark = $self->scanner->peek_token()->end_mark;
                $event = YAML::Perl::Event::MappingStart->new(
                    anchor => $anchor,
                    tag => $tag,
                    implicit => $implicit,
                    start_mark => $start_mark,
                    end_mark => $end_mark,
                    flow_style => True,
                );
                $self->state('parse_flow_mapping_first_key');
            }
            elsif ($self->scanner->check_token('YAML::Perl::Token::BlockSequenceStart')) {
                $end_mark = $self->scanner->peek_token()->end_mark;
                $event = YAML::Perl::Event::SequenceStart->new(
                    anchor => $anchor,
                    tag => $tag,
                    implicit => $implicit,
                    start_mark => $start_mark,
                    end_mark => $end_mark,
                    flow_style => False,
                );
                $self->state('parse_block_sequence_first_entry');
            }
            elsif ($self->scanner->check_token('YAML::Perl::Token::BlockMappingStart')) {
                $end_mark = $self->scanner->peek_token()->end_mark;
                $event = YAML::Perl::Event::MappingStart->new(
                    anchor => $anchor,
                    tag => $tag,
                    implicit => $implicit,
                    start_mark => $start_mark,
                    end_mark => $end_mark,
                    flow_style => False,
                );
                $self->state('parse_block_mapping_first_key');
            }
            elsif (defined $anchor or defined $tag) {
                $event = YAML::Perl::Event::Scalar->new(
                    anchor => $anchor,
                    tag => $tag,
                    implicit => [$implicit, False],
                    value => '',
                    start_mark => $start_mark,
                    end_mark => $end_mark,
                );
                $self->state(pop @{$self->states});
            }
            else {
                my $node = $block ? 'block' : 'flow';
                my $token = $self->scanner->peek_token();
                throw YAML::Perl::Error::Parser(
                    "while parsing a $node node, XXX - finish error msg"
                );
            }
        }
    }
    return $event;
}

sub parse_block_sequence_first_entry {
    my $self = shift;
    my $token = $self->scanner->get_token();
    push @{$self->marks}, $token->start_mark;
    return $self->parse_block_sequence_entry();
}

sub parse_block_sequence_entry {
    my $self = shift;
    if ($self->scanner->check_token('YAML::Perl::Token::BlockEntry')) {
        my $token = $self->scanner->get_token();
        if (not $self->scanner->check_token(qw(
            YAML::Perl::Token::BlockEntry
            YAML::Perl::Token::BlockEnd
        ))) {
            push @{$self->states}, 'parse_block_sequence_entry';
            return $self->parse_block_node();
        }
        else {
            $self->state('parse_block_sequence_entry');
            return $self->process_empty_scalar($token->end_mark);
        }
    }
    if (not $self->scanner->check_token('YAML::Perl::Token::BlockEnd')) {
        my $token = $self->scanner->peek_token();
        throw YAML::Perl::Error::Parser(
            "while parsing a block collection", $self->marks->[-1],
            "expected <block end>, but found ", $token->id, $token->start_mark
        );
    }
    my $token = $self->scanner->get_token();
    my $event = YAML::Perl::Event::SequenceEnd->new(
        start_mark => $token->start_mark,
        end_mark => $token->end_mark,
    );
    $self->state(pop @{$self->states});
    pop @{$self->marks};
    return $event;
}

sub parse_indentless_sequence_entry {
    my $self = shift;
    my $token;
    if ($self->scanner->check_token('YAML::Perl::Token::BlockEntry')) {
        $token = $self->scanner->get_token();
        if (not $self->scanner->check_token(
                'YAML::Perl::Token::BlockEntry',
                'YAML::Perl::Token::Key',
                'YAML::Perl::Token::Value',
                'YAML::Perl::Token::BlockEnd',
            )) {
            push @{$self->states}, 'parse_indentless_sequence_entry';
            return $self->parse_block_node();
        }
        else {
            $self->state('parse_indentless_sequence_entry');
            return $self->process_empty_scalar($token->end_mark);
        }
    }
    $token = $self->scanner->peek_token();
    my $event = YAML::Perl::Event::SequenceEnd->new(
        start_mark => $token->start_mark,
        end_mark => $token->end_mark,
    );
    $self->state(pop @{$self->states});
    return $event;
}

sub parse_block_mapping_first_key {
    my $self = shift;
    my $token = $self->scanner->get_token();
    push @{$self->marks}, $token->start_mark;
    return $self->parse_block_mapping_key();
}

sub parse_block_mapping_key {
    my $self = shift;
    if ($self->scanner->check_token('YAML::Perl::Token::Key')) {
        my $token = $self->scanner->get_token();
        if (not $self->scanner->check_token(qw(
            YAML::Perl::Token::Key
            YAML::Perl::Token::Value
            YAML::Perl::Token::BlockEnd
        ))) {
            push @{$self->states}, 'parse_block_mapping_value';
            return $self->parse_block_node_or_indentless_sequence();
        }
        else {
            $self->state('parse_block_mapping_value');
            return $self->process_empty_scalar($token->end_mark);
        }
    }
    if (not $self->scanner->check_token('YAML::Perl::Token::BlockEnd')) {
        my $token = $self->scanner->peek_token();
        throw YAML::Perl::Error::Parser(
            "while parsing a block mapping", $self->marks->[-1],
            "expected <block end>, but found ", $token->id, $token->start_mark
        );
    }
    my $token = $self->scanner->get_token();
    my $event = YAML::Perl::Event::MappingEnd->new(
        start_mark => $token->start_mark,
        end_mark => $token->end_mark,
    );
    $self->state(pop @{$self->states});
    pop @{$self->marks};
    return $event;
}

sub parse_block_mapping_value {
    my $self = shift;
    if ($self->scanner->check_token('YAML::Perl::Token::Value')) {
        my $token = $self->scanner->get_token();
        if (not $self->scanner->check_token(qw(
            YAML::Perl::Token::Key
            YAML::Perl::Token::Value
            YAML::Perl::Token::BlockEnd
        ))) {
            push @{$self->states}, 'parse_block_mapping_key';
            return $self->parse_block_node_or_indentless_sequence();
        }
        else {
            $self->state('parse_block_mapping_key');
            return $self->process_empty_scalar($token->end_mark);
        }
    }
    else {
        $self->state($self->parse_block_mapping_key);
        my $token = $self->scanner->peek_token();
        return $self->process_empty_scalar($token->start_mark);
    }
}

sub parse_flow_sequence_first_entry {
    my $self = shift;
    my $token = $self->scanner->get_token();
    push @{$self->marks}, $token->start_mark;
    return $self->parse_flow_sequence_entry(True);
}

sub parse_flow_sequence_entry {
    my $self = shift;
    my $first = @_ ? shift : False;
    if (not $self->scanner->check_token('YAML::Perl::Token::FlowSequenceEnd')) {
        if (not $first) {
            if ($self->scanner->check_token('YAML::Perl::Token::FlowEntry')) {
                $self->scanner->get_token();
            }
            else {
                my $token = $self->scanner->peek_token();
                throw YAML::Perl::Error::Parser(
                    "while parsing a flow sequence",
                    $self->marks->[-1],
                    "expected ',' or ']', but got %r",
                    $token->id,
                    $token->start_mark
                );
            }
        }
        
        if ($self->scanner->check_token('YAML::Perl::Token::Key')) {
            my $token = $self->scanner->peek_token();
            my $event = YAML::Perl::Event::MappingStart->new(
                anchor => undef,
                tag => undef,
                implicit => True,
                start_mark => $token->start_mark,
                end_mark => $token->end_mark,
                flow_style => True,
            );
            $self->state('parse_flow_sequence_entry_mapping_key');
            return $event;
        }
        elsif (not $self->scanner->check_token('YAML::Perl::Token::FlowSequenceEnd')) {
            push @{$self->states}, 'parse_flow_sequence_entry';
            return $self->parse_flow_node();
        }
    }
    my $token = $self->scanner->get_token();
    my $event = YAML::Perl::Event::SequenceEnd->new(
        start_mark => $token->start_mark,
        end_mark => $token->end_mark,
    );
    $self->state(pop @{$self->states});
    pop @{$self->marks};
    return $event;
}

sub parse_flow_sequence_entry_mapping_key {
    my $self = shift;
    my $token = $self->scanner->get_token();
    if (not $self->scanner->check_token(
        'YAML::Perl::Token::Value',
        'YAML::Perl::Token::FlowEntry',
        'YAML::Perl::Token::FlowSequenceEnd',
    )) {
        push @{$self->states}, 'parse_flow_sequence_entry_mapping_value';
        return $self->parse_flow_node();
    }
    else {
        $self->state('parse_flow_sequence_entry_mapping_value');
        return $self->process_empty_scalar($token->end_mark);
    }
}

sub parse_flow_sequence_entry_mapping_value {
    my $self = shift;
    if ($self->scanner->check_token('YAML::Perl::Token::Value')) {
        my $token = $self->scanner->get_token();
        if (not $self->scanner->check_token(
            'YAML::Perl::Token::FlowEntry',
            'YAML::Perl::Token::FlowSequenceEnd'
        )) {
            push @{$self->states}, 'parse_flow_sequence_entry_mapping_end';
            return $self->parse_flow_node();
        }
        else {
            $self->state('parse_flow_sequence_entry_mapping_end');
            return $self->process_empty_scalar($token->end_mark);
        }
    }
    else {
        $self->state('parse_flow_sequence_entry_mapping_end');
        my $token = $self->scanner->peek_token();
        return $self->process_empty_scalar($token->start_mark);
    }
}

sub parse_flow_sequence_entry_mapping_end {
    my $self = shift;
    $self->state('parse_flow_sequence_entry');
    my $token = $self->scanner->peek_token();
    return YAML::Perl::Event::MappingEnd->new(
        start_mark => $token->start_mark,
        end_mark => $token->start_mark,
    );
}

sub parse_flow_mapping_first_key {
    my $self = shift;
    my $token = $self->scanner->get_token();
    push @{$self->marks}, $token->start_mark;
    return $self->parse_flow_mapping_key(True)
}

sub parse_flow_mapping_key {
    my $self = shift;
    my $first = @_ ? shift : False;

    if (not $self->scanner->check_token('YAML::Perl::Token::FlowMappingEnd')) {
        if (not $first) {
            if ($self->scanner->check_token('YAML::Perl::Token::FlowEntry')) {
                $self->scanner->get_token();
            }
            else {
                my $token = $self->scanner->peek_token();
                throw YAML::Perl::Error::Parser(
                    "while parsing a flow mapping",
                    $self->marks->[-1],
                    "expected ',' or '}', but got %r",
                    $token->id,
                    $token->start_mark
                );
            }
        }
        if ($self->scanner->check_token('YAML::Perl::Token::Key')) {
            my $token = $self->scanner->get_token();
            if (not $self->scanner->check_token(
                'YAML::Perl::Token::Value',
                'YAML::Perl::Token::FlowEntry',
                'YAML::Perl::Token::FlowMappingEnd',
            )) {
                push @{$self->states}, 'parse_flow_mapping_value';
                return $self->parse_flow_node();
            }
            else {
                $self->state('parse_flow_mapping_value');
                return $self->process_empty_scalar($token->end_mark);
            }
        }
        elsif (not $self->scanner->check_token('YAML::Perl::Token::FlowMappingEnd')) {
            push @{$self->states}, 'parse_flow_mapping_empty_value';
            return $self->parse_flow_node();
        }
    }
    my $token = $self->scanner->get_token();
    my $event = YAML::Perl::Event::MappingEnd->new(
        start_mark => $token->start_mark,
        end_mark => $token->end_mark,
    );
    $self->state(pop @{$self->states});
    pop @{$self->marks};
    return $event;
}

sub parse_flow_mapping_value {
    my $self = shift;

    if ($self->scanner->check_token('YAML::Perl::Token::Value')) {
        my $token = $self->scanner->get_token();
        if (not $self->scanner->check_token(
            'YAML::Perl::Token::FlowEntry',
            'YAML::Perl::Token::FlowMappingEnd',
        )) {
            push @{$self->states}, 'parse_flow_mapping_key';
            return $self->parse_flow_node();
        }
        else {
            $self->state('parse_flow_mapping_key');
            return $self->process_empty_scalar($token->end_mark);
        }
    }
    else {
        $self->state('parse_flow_mapping_key');
        my $token = $self->scanner->peek_token();
        return $self->process_empty_scalar($token->start_mark);
    }
}

sub parse_flow_mapping_empty_value {
    my $self = shift;
    $self->state('parse_flow_mapping_key');
    return $self->process_empty_scalar($self->scanner->peek_token()->start_mark);
}

sub process_empty_scalar {
    my ( $self, $mark ) = @_;
    return YAML::Perl::Event::Scalar->new(
        anchor     => undef,
        tag        => undef,
        implicit   => [True, False],
        value      => '',
        start_mark => $mark,
        end_mark   => $mark
    );
}

1;
