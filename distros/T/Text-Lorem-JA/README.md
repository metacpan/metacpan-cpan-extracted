[![Build Status](https://travis-ci.org/dayflower/p5-Text-Lorem-JA.png?branch=master)](https://travis-ci.org/dayflower/p5-Text-Lorem-JA)
# NAME

Text::Lorem::JA - Japanese Lorem Ipsum generator

# SYNOPSIS

    use Text::Lorem::JA;
    

    # Generated text are represented in Perl internal format (Unicode).
    binmode \*STDOUT, ':encoding(UTF-8)';
    

    my $lorem = Text::Lorem::JA->new();
    

    # Generate a string of text with 10 characters.
    print $lorem->word(10), "\n";
    # => 好きな強みとを考えて
    

    # Generate a string of text with 10 tokens.
    print $lorem->words(10), "\n";
    # => 主要な素質にしばしばあるまいまではっきりつかまえる
    

    # Generate a string of text with 3 sentences.
    # Invoking via class methods are also allowed.
    print Text::Lorem::JA->sentences(3), "\n";
    # => いちばん面白いいい方をはっきりさせない会社があっても、
    #    やがてかわって、許されない。人物の生きている、ほこり、
    #    品位のあらわれである。文明社会は、正しくそういう立場に
    #    いながら、求めて一塊の岩礁に膠着してみる。

# DESCRIPTION

Text::Lorem::JA generates fake Japanese text via Markov chain.

# METHODS

Most of instance methods can be called as class methods.
Generated strings are in Perl's internal format (Unicode).

- `new`

        $lorem = Text::Lorem::JA->new();
        $lorem = Text::Lorem::JA->new( dictionary => ..., chains => ... );

    Creates a new Text::Lorem::JA generator object.

    Can specify dictionary file and chains for generating sentences.

- `word`

        $word = $lorem->word($length);

    Returns a exact given `$length` string.

    Argument length represents number of Unicode characters.  Not bytes.

- `words`

        $words = $lorem->words($number_of_morphems);

    Generates a string composed from morphemes of given number.

    At Japanese language, words are not delimited by whitespaces in normal style.

- `sentence`

        $sentence = $lorem->sentence();

    Generates a single sentence.

- `sentences`

        $sentences = $lorem->sentences($number_of_sentences);

    Generates sentences.

# TOOL

You can use [lorem\_ja](http://search.cpan.org/perldoc?lorem\_ja) executable for generating Japanese Lorem text from CLI.

# LICENSE

Copyright (C) ITO Nobuaki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ITO Nobuaki <dayflower@cpan.org>
