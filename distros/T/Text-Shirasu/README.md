[![Build Status](https://travis-ci.org/Code-Hex/Text-Shirasu.svg?branch=master)](https://travis-ci.org/Code-Hex/Text-Shirasu) [![MetaCPAN Release](https://badge.fury.io/pl/Text-Shirasu.svg)](https://metacpan.org/release/Text-Shirasu)
# NAME

Text::Shirasu - Text::MeCab wrapped for natural language processing 

# SYNOPSIS

    use utf8;
    use feature ':5.10';
    use Text::Shirasu;
    my $ts = Text::Shirasu->new(cabocha => 1); # you can use Text::CaboCha
    my $normalize = $ts->normalize("昨日の晩御飯は「鮭のふりかけ」と「味噌汁」だけでした。");
    $ts->parse($normalize);

    for my $node (@{ $ts->nodes }) {
        say $node->surface;
    }

    say $ts->join_surface;

    my $filter = $ts->filter(type => [qw/名詞 助動詞/], 記号 => [qw/括弧開 括弧閉/]);
    say $filter->join_surface;

    for my $tree (@{ $ts->trees }) {
        say $tree->surface;
    }

# DESCRIPTION

Text::Shirasu is wrapped [Text::MeCab](https://metacpan.org/pod/Text::MeCab).  
This module is easy to normalize text and filter part of speech.  
Also to use [Text::CaboCha](https://metacpan.org/pod/Text::CaboCha) by setting the cabocha option to true.

# METHODS

## new

    Text::Shirasu->new(
        # If you want to use cabocha
        cabocha => 1,
        # Text::MeCab arguments
        rcfile             => $rcfile,             # Also it will be ailias as mecabrc for Text::CaboCha
        dicdir             => $dicdir,             # Also it will be ailias as mecab_dicdir for Text::CaboCha
        userdic            => $userdic,            # Also it will be ailias as mecab_userdic for Text::CaboCha
        lattice_level      => $lattice_level,
        all_morphs         => $all_morphs,
        output_format_type => $output_format_type,
        partial            => $partial,
        node_format        => $node_format,
        unk_format         => $unk_format,
        bos_format         => $bos_format,
        eos_format         => $eos_format,
        input_buffer_size  => $input_buffer_size,
        allocate_sentence  => $allocate_sentence,
        nbest              => $nbest,
        theta              => $theta,
        
        # Text::CaboCha arguments
        ne            => $ne,
        parser_model  => $parser_model_file,
        chunker_model => $chunker_model_file,
        ne_model      => $ne_tagger_model_file,
    );

## parse

This method wraps the parse method of Text::MeCab.
The analysis result is saved as array reference of Text::Shirasu::Node instance in the Text::Shirasu instance.
Also, If you used cabocha mode, it save as array reference of Text::Shirasu::Tree instance in the Text::Shirasu instance when used this method.
It return Text::Shirasu instance. 

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

    # filtering nodes only
    $ts->filter(type => [qw/名詞/]);
    $ts->filter(type => [qw/名詞 記号/], 記号 => [qw/括弧開 括弧閉/]);

    # filtering trees only
    $ts->filter(tree => 1, node => 0, type => [qw/名詞/]);
    $ts->filter(tree => 1, node => 0, type => [qw/名詞 記号/], 記号 => [qw/括弧開 括弧閉/]);

    # filtering nodes and trees
    $ts->filter(tree => 1, type => [qw/名詞/]);
    $ts->filter(tree => 1, type => [qw/名詞 記号/], 記号 => [qw/括弧開 括弧閉/]);

## join\_surface

Returns a string that combined the surfaces stored in the instance.

    $ts->join_surface

## nodes

Return the array reference of the Text::Shirasu::Node instance.

    $ts->nodes

## trees

Return the array reference of the Text::Shirasu::Tree instance.

    $ts->trees

## mecab

Return the Text::MeCab instance.

    $ts->mecab

## cabocha

Return the Text::CaboCha instance.

    $ts->cabocha

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
