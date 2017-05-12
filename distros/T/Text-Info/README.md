# NAME

Text::Info - Retrieve information about, and do analysis on, text.

# VERSION

Version 0.01.

# SYNOPSIS

    use Text::Info;

    my $text = Text::Info->new( "Some text..." );

    say "The text is written in language '" . $text->language . "', and";
    say "has a readability score (FRES) of " . $text->readability->fres;

# DESCRIPTION

[Text::Info](https://metacpan.org/pod/Text::Info) is an extensible and easy to use solution for retrieving useful
information about texts based on the [Germanic languages](https://en.wikipedia.org/wiki/Germanic_languages).

For the time being it has a limited feature set, but the plan is to use this
as a basis for NLP-solutions.

The solution is under heavy development, and the API will definitely change.
Please respect these facts if you intend to use it.

Contributions and suggestions are welcome!

# WARNING!

This solution is - and will be - heavily based on language-specific features.
This means that if you use this solution on languages that doesn't have the
required "support modules", you're on your own. For the time being this only
affects the [Text::Info::Readability](https://metacpan.org/pod/Text::Info::Readability) functionality, but will in the future
also include stemming- and stop word-functionality (and probably many other
things).

What you can do to help on this, is to create the missing supported modules,
for example create a Lingua::\_\_::Syllable module specific for your language.

# METHODS

- new()

    Returns a new [Text::Info](https://metacpan.org/pod/Text::Info) object. Can take `text` as a single argument,
    optionally `tld` (top level domain, for better language detection), and/or
    optionally `language` if you want to specify the text's language yourself.

        my $text = Text::Info->new( 'Dette er en norsk tekst.' );

        # ...or...

        my $text = Text::Info->new(
            text => 'Dette er en norsk tekst.',
            tld  => 'no',
        );

        # ...or...

        my $text = Text::Info->new(
            text     => 'Dette er en norsk tekst.'
            language => 'no',
        );

    It really doesn't make sense to set both `tld` and `language`, as the
    former is a helper for detecting the correct language of the text, while
    the latter overrides whatever that detection algorithm returns.

- readability()

    Returns an instance of the text's [Text::Info::Readability](https://metacpan.org/pod/Text::Info::Readability) class, which in turn
    can be used to retrieve [readability information](https://en.wikipedia.org/wiki/Readability_test) about the text in question.

- sentences()

    Returns an array reference of the text's sentences as `Text::Info::Sentence`
    objects. This method is derived from [Text::Info::BASE](https://metacpan.org/pod/Text::Info::BASE).

    Keep in mind that this method tries to remove any separators, so the sentences
    returned should NOT contain those. For example "This is a sentence!" will be
    returned as "This is a sentence".

- sentence\_count()

    Returns the number of sentences in the text. This method is derived from
    [Text::Info::BASE](https://metacpan.org/pod/Text::Info::BASE).

- avg\_sentence\_length()

    Returns the average length of the sentences in the text. This method is derived
    from [Text::Info::BASE](https://metacpan.org/pod/Text::Info::BASE).

- words()

    Returns an array reference containing the text's words. This method is derived
    from [Text::Info::BASE](https://metacpan.org/pod/Text::Info::BASE).

- word\_count()

    Returns the number of words in the text. This is a helper method and is derived
    from [Text::Info::BASE](https://metacpan.org/pod/Text::Info::BASE).

- avg\_word\_length()

    Returns the average length of the words in the text. This is a helper method and
    is derived from [Text::Info::BASE](https://metacpan.org/pod/Text::Info::BASE).

- ngrams( $size )

    Returns an array reference containing the text's ngrams of size `$size`.
    Default size is 2 (i.e. bigrams). This method overrides [Text::Info::BASE](https://metacpan.org/pod/Text::Info::BASE)'s
    `ngrams()` method, as it takes into accounts building ngrams based on the
    text's sentences, not the text's complete list of words.

- unigrams()

    Returns an array reference containing the text's unigrams, i.e. the same
    as `ngrams(1)`. This is a helper method and is derived from [Text::Info::BASE](https://metacpan.org/pod/Text::Info::BASE).

- bigrams()

    Returns an array reference containing the text's bigrams, i.e. the same
    as `ngrams(2)`. This is a helper method and is derived from [Text::Info::BASE](https://metacpan.org/pod/Text::Info::BASE).

- trigrams()

    Returns an array reference containing the text's trigrams, i.e. the same
    as `ngrams(3)`. This is a helper method and is derived from [Text::Info::BASE](https://metacpan.org/pod/Text::Info::BASE).

- quadgrams()

    Returns an array reference containing the text's quadgrams, i.e. the same
    as `ngrams(4)`. This is a helper method and is derived from [Text::Info::BASE](https://metacpan.org/pod/Text::Info::BASE).

- syllable\_count()

    Returns the number of syllables in the text. This method requires that
    Lingua::\_\_::Syllable is available for the language in question. This method
    is derived from [Text::Info::BASE](https://metacpan.org/pod/Text::Info::BASE).

# SEE ALSO

- [Text::Info::Sentence](https://metacpan.org/pod/Text::Info::Sentence)
- [Text::Info::Readability](https://metacpan.org/pod/Text::Info::Readability)

# AUTHOR

Tore Aursand, `<toreau at gmail.com>`

# BUGS

Please report any bugs or feature requests to the web interface at [https://rt.cpan.org/Dist/Display.html?Name=Text-Info](https://rt.cpan.org/Dist/Display.html?Name=Text-Info)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Info

You can also look for information at:

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Text-Info](http://annocpan.org/dist/Text-Info)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Text-Info](http://cpanratings.perl.org/d/Text-Info)

- Search CPAN

    [http://search.cpan.org/dist/Text-Info/](http://search.cpan.org/dist/Text-Info/)

- GitHub

    [https://github.com/toreau/Text-Info](https://github.com/toreau/Text-Info)

# LICENSE AND COPYRIGHT

Copyright 2015 Tore Aursand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
