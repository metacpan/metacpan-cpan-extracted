[![Build Status](https://travis-ci.org/Songmu/p5-Text-Markup-Any.png?branch=master)](https://travis-ci.org/Songmu/p5-Text-Markup-Any) [![Coverage Status](https://coveralls.io/repos/Songmu/p5-Text-Markup-Any/badge.png?branch=master)](https://coveralls.io/r/Songmu/p5-Text-Markup-Any?branch=master)
# NAME

Text::Markup::Any - Common Lightweight Markup Language Interface

# SYNOPSIS

    use Text::Markup::Any;

    # OO Interface
    my $md = Text::Markup::Any->new('Text::Markdown');
    my $html = $md->markup('# hoge'); # <h1>hoge</h1>

    # Functional Interface
    my $tx = markupper 'Textile'; # snip 'Text::' in functional inteface.
    my $html = $tx->markup('h1. hoge'); # <h1>hoge</h1>

# DESCRIPTION

Text::Markup::Any is Common Lightweight Markup Language Interface.
Currently supported modules are [Text::Markdown](http://search.cpan.org/perldoc?Text::Markdown), [Text::MultiMarkdown](http://search.cpan.org/perldoc?Text::MultiMarkdown),
[Text::Markdown::Discount](http://search.cpan.org/perldoc?Text::Markdown::Discount), [Text::Markdown::GitHubAPI](http://search.cpan.org/perldoc?Text::Markdown::GitHubAPI),
[Text::Markdown::Hoedown](http://search.cpan.org/perldoc?Text::Markdown::Hoedown), [Text::Xatena](http://search.cpan.org/perldoc?Text::Xatena) and [Text::Textile](http://search.cpan.org/perldoc?Text::Textile).

# AUTHOR

Masayuki Matsuki <y.songmu@gmail.com>

# SEE ALSO

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
