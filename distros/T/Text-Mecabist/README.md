# NAME

Text::Mecabist - Text::MeCab companion for Acmeist

# SYNOPSIS

    use utf8;
    use Text::Mecabist;

    my $parser = Text::Mecabist->new();

    print $parser->parse('庭に鶏', sub {
        my $node = shift;
        $node->text($node->reading .'!') if $node->readable;
    });

    # ニワ!ニ!ニワトリ!

# DESCRIPTION

Text::Mecabist is a sub project from my Japanese transforming Acme toys. 

Although it is overhead exists than using [Text::MeCab](http://search.cpan.org/perldoc?Text::MeCab) directly,
but helpful especially around to encode/decode with mecab encoding.

# METHODS

## Text::Mecabist->new()

    my $parser = Text::Mecabist->new();

Craete parser object. Arguments can take are optional and same as [Text::MeCab](http://search.cpan.org/perldoc?Text::MeCab)\->new().

    my $parser = Text::Mecabist->new({
        node_format => '%m,%H',
        unk_format  => '%m,%H',
        bos_format  => '%m,%H',
        eos_format  => '%m,%H',
        userdic     => 'user.dic',
    });

## Text::Mecabist->encoding()

    print Text::Mecabist->encoding->name; # => "utf8" or something

This class method returns [Encode](http://search.cpan.org/perldoc?Encode)::Encoding object.

## $parser->parse($text \[, $cb \])

Parses text by mecab, returns Text::Mecabist::Document object
that contains HUGE list of Text::Mecabist::Node objects.

$parser encodes $text by mecab encoding automatically.

Optional $cb is called for all of those nodes.

    $doc = $parser->parse('...', sub {
        my $node = shift; # => is a Text::Mecabist::Node
    });

## Text::Mecabist::Document

### $doc->stringify()

Shortcut to $doc->join('text'). Document object is [overload](http://search.cpan.org/perldoc?overload)ing as a string.

    print $doc; # boon

### $doc->nodes()

Accessor. Arrayref of Text::Mecabist::Node-s.

### $doc->join($field)

    $doc = $parser->parse('庭の鶏')
    $text = $doc->join('reading'); # => "ニワノニワトリ"

Return combined text by specific field. Same as

    my $res = "";
    for my $node (@{ $doc->nodes }) {
        $res .= $node->$field;
    }

## Text::Mecabist::Node

### from Text::MeCab::Node

    $node->id;
    $node->length;
    $node->rlength;
    $node->rcattr;
    $node->lcattr;
    $node->stat;
    $node->isbest;
    $node->alpha;
    $node->beta;
    $node->prob;
    $node->wcost;
    $node->cost;
    $node->surface; # decoded
    $node->feature; # decoded
    $node->format;  # decoded

### divided feature

    $node->pos;  # 品詞
    $node->pos1; # 品詞細分類1
    $node->pos2; # 品詞細分類2
    $node->pos3; # 品詞細分類3
    $node->inflection_type; # 活用型
    $node->inflection_form; # 活用形
    $node->lemma;   # 原形
    $node->reading; # 読み
    $node->pronunciation; # 発音
    $node->extra1;
    $node->extra2;
    $node->extra3;
    $node->extra4;
    $node->extra5;
    $node->extra; # all of extra, with comma

### traversal nodes 

    $node->has_next; # 1 or 0
    $node->next; # next Text::MeCab::Node or undef
    $node->has_prev; # 1 or 0
    $node->prev; # prev Text::MeCab::Node or undef

### helper

    $node->readable; # 1 or 0
    $node->is('名詞'); # 1 or 0
    $node->text; # copy of $node->surface but RW.
    $node->skip(0); # skip in join() if set 1
    $node->last(0); # last in join() if set 1

# AUTHOR

Naoki Tomita <tomita@cpan.org>

# LICENSE

Copyright (C) Naoki Tomita.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
