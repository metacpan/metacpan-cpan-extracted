[![Build Status](https://travis-ci.org/Code-Hex/Text-Shirasu.svg?branch=master)](https://travis-ci.org/Code-Hex/Text-Shirasu) [![MetaCPAN Release](https://badge.fury.io/pl/Text-Shirasu.svg)](https://metacpan.org/release/Text-Shirasu)
# NAME

Text::Shirasu - Text::MeCab wrapped for natural language processing 

# SYNOPSIS

    use utf8;
    use feature ':5.10';
    use Text::Shirasu;
    my $ts = Text::Shirasu->new; # this parameter same as Text::MeCab
    my $normalize = $ts->normalize("昨日の晩御飯は「鮭のふりかけ」と「味噌汁」だけでした。");
    $ts->parse($normalize);

    for my $node (@{ $ts->nodes }) {
        say $node->surface;
    }

    say $ts->join_surface;

    my $filter = $ts->filter(type => [qw/名詞 助動詞/], 記号 => [qw/括弧開 括弧閉/]);
    say $filter->join_surface;

# DESCRIPTION

Text::Shirasu is wrapped [Text::MeCab](https://metacpan.org/pod/Text::MeCab).  
This module is easy to normalize text and filter part of speech.

# METHODS

## parse

This method wraps the parse method of Text::MeCab.  
The analysis result is saved as Text::Shirasu::Node instance in the Text::Shirasu instance. So, It will return Text::Shirasu instance.  

    $ts->parse("このおにぎりは「母」が握ってくれたものです。");

## normalize

It will normalize text using [Lingua::JA::NormalizeText](https://metacpan.org/pod/Lingua::JA::NormalizeText).  

    $ts->normalize("あ━ ”（＊）” を〰〰 ’＋１’")
    $ts->normalize("テキスト〰〰", qw/nfkc, alnum_z2h/, \&your_create_routine)

It accepts a string as the first argument, and receives the Lingua::JA::NormalizeText options and subroutines after the second argument.
If you do not specify a subroutine to be used in normalization, use the following Lingua::JA::NormalizeText options and subroutines by default.  

Please read the documentation of [Lingua::JA::NormalizeText](https://metacpan.org/pod/Lingua::JA::NormalizeText) for details on how each Lingua::JA::NormalizeText option works.

Lingua::JA::NormalizeText options

`nfkc nfkd nfc nfd alnum_z2h space_z2h katakana_h2z decode_entities unify_nl unify_whitespaces unify_long_spaces trim old2new_kana old2new_kanji tab2space all_dakuon_normalize square2katakana circled2kana circled2kanji decompose_parenthesized_kanji`

Subroutines

`normalize_hyphen normalize_symbols`

## filter

Please use after parse method execution.   
Filter the surface based on the features stored in the Text::Shirasu instance.
Passing subtype to value with part of speech name as key allows you to more filter the string.

    $ts->filter(type => [qw/名詞/]);
    $ts->filter(type => [qw/名詞 記号/], 記号 => [qw/括弧開 括弧閉/]);

## join\_surface

Returns a string that combined the surfaces stored in the instance.

    $ts->join_surface

## nodes

Return the array reference of the Text::Shirasu::Node instance.

    $ts->nodes

## mecab

Return the Text::MeCab instance.

    $ts->mecab

# SUBROUTINES

These subroutines perform the following substitution.  

## normalize\_hyphen

    s/[˗֊‐‑‒–⁃⁻₋−]/-/g;
    s/[﹣－ｰ—―─━ー]/ー/g;
    s/[~∼∾〜〰～]//g;
    s/ー+/ー/g;

## normalize\_symbols

    tr/。、・「」/｡､･｢｣/;

# LICENSE

Copyright (C) Kei Kamikawa(Code-Hex).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kei Kamikawa <x00.x7f@gmail.com>
